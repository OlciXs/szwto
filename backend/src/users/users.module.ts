import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { ProgressionModule } from '../progression/progression.module';
import { ShowcaseModule } from '../showcase/showcase.module';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

/** Tor D – publiczne profile, ranking, zmiana nazwy gracza. */
@Module({
  imports: [ProgressionModule, AchievementsModule, ShowcaseModule],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
