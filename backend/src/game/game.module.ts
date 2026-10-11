import { Module } from '@nestjs/common';

/**
 * Tor E – Geoguessr 1v1 (issue #3).
 *
 * Plan:
 *   - GET /game/round – środek C + opcje A/B (tylko obiekty ze zdjęciem), odpowiedź sprawdza serwer
 *   - POST /duels, POST /duels/:code/join, POST /duels/:code/answers – pojedynek asynchroniczny,
 *     rundy generowane deterministycznie z Duel.seed (bez tabeli rund)
 */
@Module({})
export class GameModule {}
