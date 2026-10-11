import { Monument, UserVisited } from '@prisma/client';

/**
 * Zdarzenie emitowane przez VisitsService po PIERWSZYM odwiedzeniu zabytku.
 *
 * Moduły nagród (XP, achievementy, …) nasłuchują go przez:
 *   @OnEvent(MONUMENT_VISITED)
 *   handle(event: MonumentVisitedEvent): Promise<Partial<VisitRewards>>
 * Zwrócony fragment trafia do odpowiedzi POST /monuments/:id/visit (pole `rewards`).
 * Dzięki temu nowy moduł NIE musi zmieniać kodu wizyt.
 */
export const MONUMENT_VISITED = 'monument.visited';

export interface MonumentVisitedEvent {
  userId: number;
  monument: Monument;
  visit: UserVisited;
}

/** Nagrody za akcję – wypełnia achievements/rewards.service.ts. */
export interface VisitRewards {
  /** XP i poziom (#1) – policzone PO premiach za nowe osiągnięcia */
  progression?: {
    /** XP za akcję łącznie z premiami za osiągnięcia */
    xpGained: number;
    totalXp: number;
    level: number;
    levelUp: boolean;
    rank: string;
    rankUp: boolean;
    /** Nagrody za poziom odblokowane tą akcją, np. „Zasięg perełek 300 m” */
    newPerks: string[];
  };
  /** Nowo odblokowane osiągnięcia (#5) */
  newAchievements?: {
    id: string;
    name: string;
    description: string;
    icon: string;
    tier: 'BRONZE' | 'SILVER' | 'GOLD' | null;
    xp: number;
  }[];
}
