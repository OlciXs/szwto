import { Module } from '@nestjs/common';

/**
 * Tor D – publiczne profile i ranking (issues #4, #6).
 *
 * Plan:
 *   - GET /users/:id – publiczny profil (displayName, poziom, gablotka, achievementy; BEZ e-maila)
 *   - GET /users/leaderboard – ranking po XP / liczbie odwiedzin
 *   - PATCH /users/me – zmiana displayName
 */
@Module({})
export class UsersModule {}
