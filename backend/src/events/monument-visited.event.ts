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

/** Każdy moduł wypełnia wyłącznie swoje pole. */
export interface VisitRewards {
  /** progression/ (#1 XP) */
  progression?: {
    xpGained: number;
    totalXp: number;
    level: number;
    levelUp: boolean;
  };
  /** achievements/ (#5) */
  newAchievements?: {
    id: string;
    name: string;
    description: string;
    icon?: string;
  }[];
}
