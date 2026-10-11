import { Module } from '@nestjs/common';
import { MonumentsController } from './monuments.controller';
import { MonumentsService } from './monuments.service';

/** Katalog zabytków: lista na mapę, szczegóły, filtry. Tor A. */
@Module({
  controllers: [MonumentsController],
  providers: [MonumentsService],
  exports: [MonumentsService],
})
export class MonumentsModule {}
