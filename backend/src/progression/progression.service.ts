import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { describeProgress } from './levels';

@Injectable()
export class ProgressionService {
  constructor(private readonly prisma: PrismaService) {}

  async getTotalXp(userId: number) {
    const [visits, achievements] = await Promise.all([
      this.prisma.userVisited.aggregate({
        where: { userId },
        _sum: { xpEarned: true },
      }),
      this.prisma.userAchievement.aggregate({
        where: { userId },
        _sum: { xpReward: true },
      }),
    ]);
    const visitXp = visits._sum.xpEarned ?? 0;
    const achievementXp = achievements._sum.xpReward ?? 0;
    return { visitXp, achievementXp, totalXp: visitXp + achievementXp };
  }

  async getProgress(userId: number) {
    const { visitXp, achievementXp, totalXp } = await this.getTotalXp(userId);
    return { ...describeProgress(totalXp), visitXp, achievementXp };
  }

  /**
   * XP, poziom i liczba wizyt wielu graczy naraz (ranking, autorzy komentarzy).
   * Bez [userIds] – wszyscy gracze.
   */
  async getSummaries(userIds?: number[]) {
    const where = userIds ? { userId: { in: userIds } } : {};
    const [visits, achievements] = await Promise.all([
      this.prisma.userVisited.groupBy({
        by: ['userId'],
        where,
        _sum: { xpEarned: true },
        _count: true,
      }),
      this.prisma.userAchievement.groupBy({
        by: ['userId'],
        where,
        _sum: { xpReward: true },
      }),
    ]);

    const result = new Map<number, { totalXp: number; visitedCount: number }>();
    for (const id of userIds ?? []) result.set(id, { totalXp: 0, visitedCount: 0 });
    for (const v of visits) {
      result.set(v.userId, { totalXp: v._sum.xpEarned ?? 0, visitedCount: v._count });
    }
    for (const a of achievements) {
      const entry = result.get(a.userId) ?? { totalXp: 0, visitedCount: 0 };
      entry.totalXp += a._sum.xpReward ?? 0;
      result.set(a.userId, entry);
    }
    return new Map(
      [...result].map(([id, s]) => {
        const progress = describeProgress(s.totalXp);
        return [
          id,
          { ...s, level: progress.level, rank: progress.rank },
        ] as const;
      }),
    );
  }
}
