import { Module } from '@nestjs/common';

/**
 * Tor B – achievementy / odznaki (issue #5).
 *
 * Plan:
 *   - definitions.ts: lista { id, nazwa, opis, filtr (category / era / rarity / builtYear), próg }
 *   - listener @OnEvent(MONUMENT_VISITED) zwracający { newAchievements }
 *   - GET /achievements (wszystkie z postępem) – liczone z wizyt, bez osobnej tabeli
 */
@Module({})
export class AchievementsModule {}
