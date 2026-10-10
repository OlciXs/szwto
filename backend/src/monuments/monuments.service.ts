import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MonumentsQueryDto } from './dto/monuments-query.dto';
import { toMonumentDetails, toMonumentListItem } from './monument.mapper';

@Injectable()
export class MonumentsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllForUser(userId: number, query: MonumentsQueryDto) {
    const monuments = await this.prisma.monument.findMany({
      where: { category: query.category, rarity: query.rarity },
      orderBy: { id: 'asc' },
      include: { visitedBy: { where: { userId }, select: { visitedAt: true } } },
    });

    return monuments.map(({ visitedBy, ...monument }) =>
      toMonumentListItem(monument, visitedBy[0] ?? null),
    );
  }

  async findOneForUser(userId: number, id: number) {
    const monument = await this.prisma.monument.findUnique({
      where: { id },
      include: { visitedBy: { where: { userId }, select: { visitedAt: true } } },
    });
    if (!monument) {
      throw new NotFoundException('Nie znaleziono zabytku');
    }

    const visitorsCount = await this.prisma.userVisited.count({
      where: { monumentId: id },
    });
    const { visitedBy, ...rest } = monument;
    return toMonumentDetails(rest, visitedBy[0] ?? null, visitorsCount);
  }
}
