import { Injectable } from '@nestjs/common';
import { AchievementsService } from '../achievements/achievements.service';
import { commonsThumbUrl } from '../common/commons.util';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { ShowcaseService } from '../showcase/showcase.service';

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

  async getProfile(userId: number) {
    // Osiągnięcia „wstecz” – np. za wizyty sprzed wprowadzenia osiągnięć
    await this.achievements.evaluate(userId);

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
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

    const [totalMonuments, progression, achievements, showcase] = await Promise.all([
      this.prisma.monument.count(),
      this.progression.getProgress(userId), // tor B
      this.achievements.summary(userId), // tor B
      this.showcase.getForUser(userId), // tor D
    ]);

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      visitedCount: user.visited.length,
      totalMonuments,
      progression,
      achievements,
      showcase,
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
}
