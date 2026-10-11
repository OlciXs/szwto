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
}
