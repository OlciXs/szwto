import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { ProgressionModule } from '../progression/progression.module';
import { FriendsController } from './friends.controller';
import { FriendsService } from './friends.service';

/**
 * Znajomi: unikalny kod gracza (#K7Q2MX), zaproszenia z akceptacją,
 * oznaczenia „ZNAJOMY” w rankingu, komentarzach i profilach.
 */
@Module({
  imports: [ProgressionModule, AchievementsModule],
  controllers: [FriendsController],
  providers: [FriendsService],
  exports: [FriendsService],
})
export class FriendsModule {}
