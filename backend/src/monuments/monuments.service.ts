import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { haversineDistanceMeters } from '../common/geo.util';
import { PrismaService } from '../prisma/prisma.service';
import { VisitDto } from './dto/visit.dto';

/** Maksymalna odległość użytkownika od zabytku, przy której można go odznaczyć. */
export const VISIT_RADIUS_METERS = 50;

@Injectable()
export class MonumentsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllForUser(userId: number) {
    const monuments = await this.prisma.monument.findMany({
      orderBy: { id: 'asc' },
      include: { visitedBy: { where: { userId } } },
    });

    return monuments.map((monument) => ({
      id: monument.id,
      name: monument.name,
      description: monument.description,
      latitude: monument.latitude,
      longitude: monument.longitude,
      visited: monument.visitedBy.length > 0,
      visitedAt: monument.visitedBy[0]?.visitedAt ?? null,
    }));
  }

  async visit(userId: number, monumentId: number, dto: VisitDto) {
    const monument = await this.prisma.monument.findUnique({
      where: { id: monumentId },
    });
    if (!monument) {
      throw new NotFoundException('Nie znaleziono zabytku');
    }

    const distance = haversineDistanceMeters(
      dto.latitude,
      dto.longitude,
      monument.latitude,
      monument.longitude,
    );

    if (distance > VISIT_RADIUS_METERS) {
      throw new BadRequestException('Za daleko od zabytku');
    }

    // upsert: ponowne odwiedzenie tego samego zabytku nie tworzy duplikatu
    const record = await this.prisma.userVisited.upsert({
      where: { userId_monumentId: { userId, monumentId } },
      update: {},
      create: { userId, monumentId },
    });

    return {
      success: true,
      message: `Zabytek „${monument.name}” został odznaczony!`,
      distanceMeters: Math.round(distance * 10) / 10,
      visitedAt: record.visitedAt,
    };
  }
}
