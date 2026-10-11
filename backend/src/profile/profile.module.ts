import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { ProgressionModule } from '../progression/progression.module';
import { ShowcaseModule } from '../showcase/showcase.module';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';

@Module({
  imports: [ProgressionModule, AchievementsModule, ShowcaseModule],
  controllers: [ProfileController],
  providers: [ProfileService],
})
export class ProfileModule {}
