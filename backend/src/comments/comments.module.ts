import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { FriendsModule } from '../friends/friends.module';
import { ProgressionModule } from '../progression/progression.module';
import { CommentsController } from './comments.controller';
import { CommentsService } from './comments.service';

/**
 * Tor D – mini forum przy zabytkach (issue #6).
 * Pisać mogą gracze, którzy odwiedzili zabytek I są teraz na miejscu.
 */
@Module({
  imports: [ProgressionModule, AchievementsModule, FriendsModule],
  controllers: [CommentsController],
  providers: [CommentsService],
})
export class CommentsModule {}
