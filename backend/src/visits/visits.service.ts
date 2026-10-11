import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { haversineDistanceMeters } from '../common/geo.util';
import {
  MONUMENT_VISITED,
  MonumentVisitedEvent,
  VisitRewards,
} from '../events/monument-visited.event';
import { PrismaService } from '../prisma/prisma.service';
import { VisitDto } from './dto/visit.dto';

@Injectable()
export class VisitsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: EventEmitter2,
  ) {}

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

    // Promień zależy od obiektu (duże obiekty mają większy) – patrz scripts/import/enrich.ts
    if (distance > monument.visitRadius) {
      throw new BadRequestException(
        `Za daleko od zabytku (${Math.round(distance)} m, wymagane ≤ ${monument.visitRadius} m)`,
      );
    }

    const existing = await this.prisma.userVisited.findUnique({
      where: { userId_monumentId: { userId, monumentId } },
    });

    // Ponowne odwiedzenie nie tworzy duplikatu i nie przyznaje nagród drugi raz
    const visit =
      existing ??
      (await this.prisma.userVisited.create({
        data: { userId, monumentId, xpEarned: monument.xp },
      }));

    let rewards: VisitRewards = {};
    if (!existing) {
      const event: MonumentVisitedEvent = { userId, monument, visit };
      const results = await this.events.emitAsync(MONUMENT_VISITED, event);
      rewards = Object.assign({}, ...results.filter(Boolean));
    }

    return {
      success: true,
      message: existing
        ? `Zabytek „${monument.name}” był już odznaczony.`
        : `Zabytek „${monument.name}” został odznaczony!`,
      alreadyVisited: existing !== null,
      distanceMeters: Math.round(distance * 10) / 10,
      visitedAt: visit.visitedAt,
      xpEarned: existing ? 0 : visit.xpEarned,
      rewards,
    };
  }
}
