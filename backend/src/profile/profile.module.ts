import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { ProgressionModule } from '../progression/progression.module';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';

@Module({
  imports: [ProgressionModule, AchievementsModule],
  controllers: [ProfileController],
  providers: [ProfileService],
})
export class ProfileModule {}
