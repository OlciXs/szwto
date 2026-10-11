import { Module } from '@nestjs/common';
import { ProgressionModule } from '../progression/progression.module';
import { AchievementsController } from './achievements.controller';
import { AchievementsService } from './achievements.service';
import { RewardsListener } from './rewards.listener';
import { RewardsService } from './rewards.service';

/**
 * Tor B – osiągnięcia / odznaki (issue #5) + składanie nagród za akcje gracza.
 * Definicje: definitions.ts. Po wizycie: RewardsListener -> RewardsService.
 */
@Module({
  imports: [ProgressionModule],
  controllers: [AchievementsController],
  providers: [AchievementsService, RewardsService, RewardsListener],
  exports: [AchievementsService],
})
export class AchievementsModule {}
