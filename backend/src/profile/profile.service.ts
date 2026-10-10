import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: number) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        createdAt: true,
        visited: {
          select: {
            visitedAt: true,
            monument: {
              select: {
                id: true,
                name: true,
                description: true,
                latitude: true,
                longitude: true,
              },
            },
          },
          orderBy: { visitedAt: 'desc' },
        },
      },
    });

    const totalMonuments = await this.prisma.monument.count();

    return {
      id: user.id,
      email: user.email,
      createdAt: user.createdAt,
      visitedCount: user.visited.length,
      totalMonuments,
      recentVisits: user.visited.slice(0, 5).map((v) => ({
        monumentId: v.monument.id,
        monumentName: v.monument.name,
        monumentDescription: v.monument.description,
        latitude: v.monument.latitude,
        longitude: v.monument.longitude,
        visitedAt: v.visitedAt,
      })),
    };
  }
}
