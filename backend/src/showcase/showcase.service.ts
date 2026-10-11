import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { toMonumentCard } from '../monuments/monument.mapper';
import { PrismaService } from '../prisma/prisma.service';
import { PERK_UNLOCKS } from '../progression/levels';
import { ProgressionService } from '../progression/progression.service';
import { RewardsService } from '../achievements/rewards.service';

/** Maksymalna liczba miejsc w gablotce (kolejne odblokowuje poziom – levels.ts). */
export const MAX_SHOWCASE_SLOTS = 5;

/** Poziom, na którym odblokowuje się miejsce o numerze [slot] (0 = od początku). */
function unlockLevelForSlot(slot: number): number {
  if (slot === 0) return 1;
  const unlock = PERK_UNLOCKS.find(
    (u) => u.type === 'SHOWCASE_SLOTS' && u.value === slot + 1,
  );
  return unlock?.level ?? Number.MAX_SAFE_INTEGER;
}

@Injectable()
export class ShowcaseService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly rewards: RewardsService,
  ) {}

  /** Gablotka gracza: 5 miejsc, każde puste / z zabytkiem / zablokowane. */
  async getForUser(userId: number) {
    const [progress, slots] = await Promise.all([
      this.progression.getProgress(userId),
      this.prisma.showcaseSlot.findMany({
        where: { userId },
        include: { monument: true },
      }),
    ]);
    const unlockedSlots = progress.perks.showcaseSlots;
    const bySlot = new Map(slots.map((s) => [s.slot, s.monument]));

    return {
      unlockedSlots,
      maxSlots: MAX_SHOWCASE_SLOTS,
      slots: Array.from({ length: MAX_SHOWCASE_SLOTS }, (_, slot) => {
        const monument = bySlot.get(slot);
        return {
          slot,
          locked: slot >= unlockedSlots,
          unlockLevel: unlockLevelForSlot(slot),
          // Zabytek ze zablokowanego miejsca (np. po zmianie zasad) też pokazujemy
          monument: monument ? toMonumentCard(monument) : null,
        };
      }),
    };
  }

  async setSlot(userId: number, slot: number, monumentId: number) {
    this.assertSlotRange(slot);
    const progress = await this.progression.getProgress(userId);
    if (slot >= progress.perks.showcaseSlots) {
      throw new ForbiddenException(
        `To miejsce odblokujesz na poziomie ${unlockLevelForSlot(slot)}.`,
      );
    }

    const visit = await this.prisma.userVisited.findUnique({
      where: { userId_monumentId: { userId, monumentId } },
    });
    if (!visit) {
      throw new BadRequestException('W gablotce możesz wystawić tylko odwiedzony zabytek.');
    }

    await this.prisma.$transaction([
      // ten sam zabytek w innym miejscu -> przenosimy zamiast duplikować
      this.prisma.showcaseSlot.deleteMany({
        where: { userId, monumentId, slot: { not: slot } },
      }),
      this.prisma.showcaseSlot.upsert({
        where: { userId_slot: { userId, slot } },
        update: { monumentId },
        create: { userId, slot, monumentId },
      }),
    ]);

    return {
      showcase: await this.getForUser(userId),
      rewards: await this.rewards.settle(userId, 0), // np. „Kurator”
    };
  }

  async clearSlot(userId: number, slot: number) {
    this.assertSlotRange(slot);
    await this.prisma.showcaseSlot.deleteMany({ where: { userId, slot } });
    return { showcase: await this.getForUser(userId) };
  }

  private assertSlotRange(slot: number) {
    if (slot < 0 || slot >= MAX_SHOWCASE_SLOTS) {
      throw new BadRequestException(`Numer miejsca: 0–${MAX_SHOWCASE_SLOTS - 1}.`);
    }
  }
}
