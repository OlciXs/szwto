import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { MonumentCategory } from '@prisma/client';
import { AchievementsService } from '../achievements/achievements.service';
import { commonsThumbUrl } from '../common/commons.util';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { ShowcaseService } from '../showcase/showcase.service';
import { SELECTABLE_RANKS } from './ranks';

/**
 * Własny profil gracza. Sekcje innych modułów (XP, achievementy, gablotka)
 * dopisujemy tu jako osobne pola – każdy tor dodaje swoje.
 */
@Injectable()
export class ProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly achievements: AchievementsService,
    private readonly showcase: ShowcaseService,
  ) {}

  private async rankOptions(userId: number, level: number) {
    const totals = await this.prisma.monument.groupBy({
      by: ['category'],
      _count: true,
    });
    const visited = await this.prisma.userVisited.findMany({
      where: { userId },
      select: { monument: { select: { category: true } } },
    });
    const visitedByCategory = new Map<string, number>();
    for (const item of visited) {
      const key = item.monument.category;
      visitedByCategory.set(key, (visitedByCategory.get(key) ?? 0) + 1);
    }

    const achievementIds = new Set(
      (
        await this.prisma.userAchievement.findMany({
          where: { userId },
          select: { achievementId: true },
        })
      ).map((item) => item.achievementId),
    );

    const eligibility = SELECTABLE_RANKS.map((rank) => {
      if (rank.kind === 'LEVEL') return level >= rank.minLevel!;
      if (rank.kind === 'ACHIEVEMENT') return achievementIds.has(rank.achievementId!);
      const total = totals.find((item) => item.category === rank.category)?._count ?? 0;
      return total > 0 && (visitedByCategory.get(rank.category!) ?? 0) >= total;
    });

    const percentages = await Promise.all(
      SELECTABLE_RANKS.map(async (rank) => {
        if (rank.kind === 'LEVEL') {
          const users = await this.prisma.user.findMany({
            select: { id: true },
          });
          const summaries = await this.progression.getSummaries(users.map((user) => user.id));
          return [...summaries.values()].filter((item) => item.level >= rank.minLevel!).length;
        }
        if (rank.kind === 'ACHIEVEMENT') {
          return this.prisma.userAchievement.count({
            where: { achievementId: rank.achievementId! },
          });
        }
        const total = totals.find((item) => item.category === rank.category)?._count ?? 0;
        if (!total) return 0;
        const grouped = await this.prisma.userVisited.groupBy({
          by: ['userId'],
          where: { monument: { category: rank.category } },
          _count: true,
        });
        return grouped.filter((item) => item._count === total).length;
      }),
    );
    const userCount = await this.prisma.user.count();
    return SELECTABLE_RANKS.map((rank, index) => ({
      ...rank,
      unlocked: eligibility[index],
      percentage: userCount ? Math.round((percentages[index] / userCount) * 1000) / 10 : 0,
    }));
  }

  async getProfile(userId: number) {
    // Osiągnięcia „wstecz” – np. za wizyty sprzed wprowadzenia osiągnięć
    await this.achievements.evaluate(userId);

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        friendCode: true,
        selectedRankId: true,
        createdAt: true,
        visited: {
          select: {
            visitedAt: true,
            xpEarned: true,
            monument: {
              select: {
                id: true,
                name: true,
                description: true,
                latitude: true,
                longitude: true,
                category: true,
                rarity: true,
                imageFile: true,
              },
            },
          },
          orderBy: { visitedAt: 'desc' },
        },
      },
    });

    const [categoryTotals, progression, achievements, showcase, friendsCount, incomingRequests] =
      await Promise.all([
        this.prisma.monument.groupBy({ by: ['category'], _count: true }),
        this.progression.getProgress(userId), // tor B
        this.achievements.summary(userId), // tor B
        this.showcase.getForUser(userId), // tor D
        this.prisma.friendship.count({
          where: { status: 'ACCEPTED', OR: [{ requesterId: userId }, { addresseeId: userId }] },
        }),
        this.prisma.friendship.count({ where: { status: 'PENDING', addresseeId: userId } }),
      ]);

    const visitedByCategory = new Map<MonumentCategory, number>();
    for (const visit of user.visited) {
      const category = visit.monument.category;
      visitedByCategory.set(category, (visitedByCategory.get(category) ?? 0) + 1);
    }

    const categoryProgress = categoryTotals.map(({ category, _count }) => ({
      category,
      visited: visitedByCategory.get(category) ?? 0,
      total: _count,
    }));

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      visitedCount: user.visited.length,
      totalMonuments: categoryTotals.reduce((sum, item) => sum + item._count, 0),
      categoryProgress,
      selectedRankId: user.selectedRankId,
      rankOptions: await this.rankOptions(userId, progression.level),
      progression,
      achievements,
      showcase,
      // znajomi
      friendCode: user.friendCode,
      friendsCount,
      incomingRequests,
      recentVisits: user.visited.slice(0, 5).map((v) => ({
        monumentId: v.monument.id,
        monumentName: v.monument.name,
        monumentDescription: v.monument.description,
        latitude: v.monument.latitude,
        longitude: v.monument.longitude,
        category: v.monument.category,
        rarity: v.monument.rarity,
        thumbUrl: v.monument.imageFile
          ? commonsThumbUrl(v.monument.imageFile, 330)
          : null,
        xpEarned: v.xpEarned,
        visitedAt: v.visitedAt,
      })),
    };
  }

  async selectRank(userId: number, rankId: string) {
    const profile = await this.getProfile(userId);
    const rank = profile.rankOptions.find((item) => item.id === rankId);
    if (!rank) throw new NotFoundException('Nie znaleziono rangi');
    if (!rank.unlocked) throw new ForbiddenException('Ta ranga nie jest jeszcze odblokowana');
    await this.prisma.user.update({
      where: { id: userId },
      data: { selectedRankId: rankId },
    });
    return { selectedRankId: rankId };
  }
}
