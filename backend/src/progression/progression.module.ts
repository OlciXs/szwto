import { Module } from '@nestjs/common';

/**
 * Tor B – XP i poziomy (issue #1).
 *
 * Plan:
 *   - listener @OnEvent(MONUMENT_VISITED) zwracający { progression } (events/monument-visited.event.ts)
 *   - XP = suma UserVisited.xpEarned, poziom liczony z XP
 *   - sekcja XP/poziom w GET /profile
 */
@Module({})
export class ProgressionModule {}
