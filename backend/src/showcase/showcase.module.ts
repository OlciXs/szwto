import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { ProgressionModule } from '../progression/progression.module';
import { ShowcaseController } from './showcase.controller';
import { ShowcaseService } from './showcase.service';

/**
 * Tor D – gablotka na profilu (issue #4).
 * Liczba miejsc = nagroda za poziom (progression/levels.ts), tylko odwiedzone zabytki.
 */
@Module({
  imports: [ProgressionModule, AchievementsModule],
  controllers: [ShowcaseController],
  providers: [ShowcaseService],
  exports: [ShowcaseService],
})
export class ShowcaseModule {}
