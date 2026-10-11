import { Injectable } from '@nestjs/common';
import { Era, MonumentCategory, Rarity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  ACHIEVEMENT_BY_ID,
  ACHIEVEMENTS,
  AchievementDefinition,
  AchievementGroup,
  GROUP_LABELS,
  MonumentTotals,
  PlayerStats,
  resolveTarget,
} from './definitions';

export const EVENT_TYPES = ['WIKIPEDIA_OPENED'] as const;
export type EventType = (typeof EVENT_TYPES)[number];

const GROUP_ORDER: AchievementGroup[] = [
  'KOLEKCJA',
  'RZADKOSC',
  'KATEGORIE',
  'EPOKI',
  'SZLAKI',
  'AKTYWNOSC',
  'SEKRETNE',
];

/** Godzina i dzień w czasie polskim – do osiągnięć „Nocny marek”, „Maraton”. */
const warsawFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Europe/Warsaw',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  hourCycle: 'h23',
});

function warsawTime(date: Date) {
  const parts = Object.fromEntries(
    warsawFormat.formatToParts(date).map((p) => [p.type, p.value]),
  );
  return { day: `${parts.year}-${parts.month}-${parts.day}`, hour: Number(parts.hour) };
}

const increment = <K extends string>(map: Partial<Record<K, number>>, key: K) => {
  map[key] = (map[key] ?? 0) + 1;
};

/** Kształt odblokowanego osiągnięcia w odpowiedziach API (toast w aplikacji). */
export function toUnlockedDto(def: AchievementDefinition) {
  return {
    id: def.id,
    name: def.name,
    description: def.description,
    icon: def.icon,
    tier: def.tier ?? null,
    xp: def.xp,
  };
}

@Injectable()
export class AchievementsService {
  constructor(private readonly prisma: PrismaService) {}

  async computeStats(userId: number): Promise<PlayerStats> {
    const [visits, wikiArticles] = await Promise.all([
      this.prisma.userVisited.findMany({
        where: { userId },
        select: {
          visitedAt: true,
          monument: {
            select: {
              externalId: true,
              category: true,
              era: true,
              builtYear: true,
              rarity: true,
              isMajor: true,
              heritageLevel: true,
            },
          },
        },
      }),
      this.prisma.userEvent.findMany({
        where: { userId, type: 'WIKIPEDIA_OPENED', monumentId: { not: null } },
        distinct: ['monumentId'],
        select: { monumentId: true },
      }),
    ]);

    const byCategory: Partial<Record<MonumentCategory, number>> = {};
    const byEra: Partial<Record<Era, number>> = {};
    const byRarity: Partial<Record<Rarity, number>> = {};
    const perDay: Record<string, number> = {};
    const stats: PlayerStats = {
      visitedCount: visits.length,
      byCategory,
      byEra,
      byRarity,
      before1900: 0,
      minorVisited: 0,
      unescoVisited: 0,
      visitedExternalIds: new Set(),
      categoriesCovered: 0,
      erasCovered: 0,
      maxVisitsPerDay: 0,
      nightVisits: 0,
      morningVisits: 0,
      wikipediaArticlesRead: wikiArticles.length,
    };

    for (const { visitedAt, monument: m } of visits) {
      increment(byCategory, m.category);
      increment(byRarity, m.rarity);
      if (m.era) increment(byEra, m.era);
      if (m.builtYear !== null && m.builtYear < 1900) stats.before1900++;
      if (!m.isMajor) stats.minorVisited++;
      if (m.heritageLevel === 'UNESCO') stats.unescoVisited++;
      stats.visitedExternalIds.add(m.externalId);

      const { day, hour } = warsawTime(visitedAt);
      perDay[day] = (perDay[day] ?? 0) + 1;
      if (hour >= 22 || hour < 4) stats.nightVisits++;
      if (hour >= 5 && hour < 7) stats.morningVisits++;
    }

    stats.categoriesCovered = Object.keys(byCategory).length;
    stats.erasCovered = Object.keys(byEra).length;
    stats.maxVisitsPerDay = Math.max(0, ...Object.values(perDay));
    return stats;
  }

  async computeTotals(): Promise<MonumentTotals> {
    const [byCategory, byRarity, byEra] = await Promise.all([
      this.prisma.monument.groupBy({ by: ['category'], _count: true }),
      this.prisma.monument.groupBy({ by: ['rarity'], _count: true }),
      this.prisma.monument.groupBy({ by: ['era'], _count: true, where: { era: { not: null } } }),
    ]);
    return {
      byCategory: Object.fromEntries(byCategory.map((g) => [g.category, g._count])),
      byRarity: Object.fromEntries(byRarity.map((g) => [g.rarity, g._count])),
      categories: byCategory.length,
      eras: byEra.length,
    };
  }

  /** Sprawdza wszystkie osiągnięcia i zapisuje nowo odblokowane. Zwraca nowe. */
  async evaluate(userId: number) {
    const [stats, totals, existing] = await Promise.all([
      this.computeStats(userId),
      this.computeTotals(),
      this.prisma.userAchievement.findMany({
        where: { userId },
        select: { achievementId: true },
      }),
    ]);
    const owned = new Set(existing.map((a) => a.achievementId));

    const unlocked = ACHIEVEMENTS.filter(
      (def) => !owned.has(def.id) && def.progress(stats) >= resolveTarget(def, totals),
    );
    if (unlocked.length > 0) {
      await this.prisma.userAchievement.createMany({
        data: unlocked.map((def) => ({
          userId,
          achievementId: def.id,
          xpReward: def.xp,
        })),
        skipDuplicates: true,
      });
    }
    return unlocked.map(toUnlockedDto);
  }

  /** Wszystkie osiągnięcia z postępem gracza (GET /achievements). */
  async list(userId: number) {
    await this.evaluate(userId); // odblokowania „wstecz”
    const [stats, totals, owned] = await Promise.all([
      this.computeStats(userId),
      this.computeTotals(),
      this.prisma.userAchievement.findMany({ where: { userId } }),
    ]);
    const unlockedAt = new Map(owned.map((a) => [a.achievementId, a.unlockedAt]));

    const achievements = [...ACHIEVEMENTS]
      .sort((a, b) => GROUP_ORDER.indexOf(a.group) - GROUP_ORDER.indexOf(b.group))
      .map((def) => {
        const target = resolveTarget(def, totals);
        const unlocked = unlockedAt.has(def.id);
        const hidden = def.secret && !unlocked;
        return {
          id: def.id,
          name: hidden ? '???' : def.name,
          description: hidden ? 'Sekretne osiągnięcie – odkryj je sam!' : def.description,
          icon: hidden ? 'help' : def.icon,
          group: def.group,
          groupLabel: GROUP_LABELS[def.group],
          tier: def.tier ?? null,
          xp: def.xp,
          secret: def.secret ?? false,
          target,
          progress: hidden ? 0 : Math.min(def.progress(stats), target),
          unlocked,
          unlockedAt: unlockedAt.get(def.id) ?? null,
        };
      });

    return {
      unlockedCount: owned.filter((a) => ACHIEVEMENT_BY_ID.has(a.achievementId)).length,
      total: ACHIEVEMENTS.length,
      achievements,
    };
  }

  /** Krótkie podsumowanie do profilu. */
  async summary(userId: number) {
    const owned = await this.prisma.userAchievement.findMany({
      where: { userId },
      orderBy: { unlockedAt: 'desc' },
    });
    const known = owned.filter((a) => ACHIEVEMENT_BY_ID.has(a.achievementId));
    return {
      unlockedCount: known.length,
      total: ACHIEVEMENTS.length,
      recent: known.slice(0, 3).map((a) => ({
        ...toUnlockedDto(ACHIEVEMENT_BY_ID.get(a.achievementId)!),
        unlockedAt: a.unlockedAt,
      })),
    };
  }

  async recordEvent(userId: number, type: EventType, monumentId?: number) {
    await this.prisma.userEvent.create({
      data: { userId, type, monumentId: monumentId ?? null },
    });
  }
}
