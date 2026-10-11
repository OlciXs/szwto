import { Module } from '@nestjs/common';
import { ProgressionController } from './progression.controller';
import { ProgressionService } from './progression.service';

/**
 * Tor B – XP, poziomy, rangi i nagrody za poziom (issue #1).
 * Zasady: levels.ts. Nagrody za wizytę składa achievements/rewards.service.ts.
 */
@Module({
  controllers: [ProgressionController],
  providers: [ProgressionService],
  exports: [ProgressionService],
})
export class ProgressionModule {}
