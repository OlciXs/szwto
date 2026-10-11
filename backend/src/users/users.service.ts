import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AchievementsService } from '../achievements/achievements.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { ShowcaseService } from '../showcase/showcase.service';

const LEADERBOARD_SIZE = 50;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly achievements: AchievementsService,
    private readonly showcase: ShowcaseService,
  ) {}

  /** Publiczny profil – NIGDY nie zawiera e-maila. */
  async publicProfile(viewerId: number, userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, displayName: true, createdAt: true },
    });
    if (!user) throw new NotFoundException('Nie znaleziono gracza');

    const [progress, visitedCount, achievements, showcase] = await Promise.all([
      this.progression.getProgress(userId),
      this.prisma.userVisited.count({ where: { userId } }),
      this.achievements.summary(userId),
      this.showcase.getForUser(userId),
    ]);

    return {
      id: user.id,
      displayName: user.displayName,
      createdAt: user.createdAt,
      isMe: user.id === viewerId,
      level: progress.level,
      rank: progress.rank,
      totalXp: progress.totalXp,
      visitedCount,
      achievements,
      showcase,
    };
  }

  /** Ranking po XP (+ pozycja oglądającego, nawet poza pierwszą pięćdziesiątką). */
  async leaderboard(viewerId: number) {
    const [users, summaries] = await Promise.all([
      this.prisma.user.findMany({ select: { id: true, displayName: true } }),
      this.progression.getSummaries(),
    ]);

    const ranked = users
      .map((u) => {
        const s = summaries.get(u.id);
        return {
          id: u.id,
          displayName: u.displayName,
          totalXp: s?.totalXp ?? 0,
          visitedCount: s?.visitedCount ?? 0,
          level: s?.level ?? 1,
          rankIndex: s?.rank.index ?? 0,
          rankName: s?.rank.name ?? 'Turysta',
        };
      })
      .sort(
        (a, b) =>
          b.totalXp - a.totalXp || b.visitedCount - a.visitedCount || a.id - b.id,
      )
      .map((entry, i) => ({ ...entry, position: i + 1, isMe: entry.id === viewerId }));

    return {
      totalPlayers: ranked.length,
      entries: ranked.slice(0, LEADERBOARD_SIZE),
      me: ranked.find((e) => e.isMe) ?? null,
    };
  }

  async updateDisplayName(userId: number, displayName: string) {
    const name = displayName.trim();
    const taken = await this.prisma.user.findUnique({ where: { displayName: name } });
    if (taken && taken.id !== userId) {
      throw new ConflictException('Ta nazwa gracza jest już zajęta');
    }
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { displayName: name },
      select: { id: true, displayName: true },
    });
    return user;
  }
}
