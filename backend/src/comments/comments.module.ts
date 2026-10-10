import { Module } from '@nestjs/common';

/**
 * Tor D – mini forum przy zabytkach (issue #6).
 *
 * Plan:
 *   - GET /monuments/:id/comments (od najnowszych, z autorem: id, displayName)
 *   - POST /monuments/:id/comments { body ≤ 500 } – tylko gracze, którzy odwiedzili zabytek
 *   - DELETE /comments/:id – tylko własne
 */
@Module({})
export class CommentsModule {}
