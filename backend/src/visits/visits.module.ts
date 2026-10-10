import { Module } from '@nestjs/common';
import { VisitsController } from './visits.controller';
import { VisitsService } from './visits.service';

/**
 * Odznaczanie zabytków (geofencing). Po pierwszej wizycie emituje
 * zdarzenie MONUMENT_VISITED – nagrody dodają inne moduły (events/).
 */
@Module({
  controllers: [VisitsController],
  providers: [VisitsService],
})
export class VisitsModule {}
