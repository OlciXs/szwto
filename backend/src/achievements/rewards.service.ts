import { Injectable } from '@nestjs/common';
import { VisitRewards } from '../events/monument-visited.event';
import { levelForXp, perksUnlockedBetween, rankForLevel } from '../progression/levels';
import { ProgressionService } from '../progression/progression.service';
import { AchievementsService } from './achievements.service';

/**
 * Składa nagrody za akcję gracza (wizyta, otwarcie Wikipedii):
 *   1) sprawdza i zapisuje nowe osiągnięcia (dają premię XP),
 *   2) przelicza poziom PO premiach – dzięki temu „Nowy poziom!” zawsze się zgadza.
 */
@Injectable()
export class RewardsService {
  constructor(
    private readonly achievements: AchievementsService,
    private readonly progression: ProgressionService,
  ) {}

  /** [actionXp] – XP za tę akcję, które jest już zapisane w bazie (np. wizyta). */
  async settle(userId: number, actionXp: number): Promise<Required<VisitRewards>> {
    const { totalXp: current } = await this.progression.getTotalXp(userId);
    const startXp = current - actionXp;
    const levelBefore = levelForXp(startXp);

    const newAchievements = await this.achievements.evaluate(userId);
    const after = await this.progression.getProgress(userId);

    return {
      progression: {
        xpGained: after.totalXp - startXp,
        totalXp: after.totalXp,
        level: after.level,
        levelUp: after.level > levelBefore,
        rank: after.rank.name,
        rankUp: after.rank.index !== rankForLevel(levelBefore).index,
        newPerks: perksUnlockedBetween(levelBefore, after.level),
      },
      newAchievements,
    };
  }
}
