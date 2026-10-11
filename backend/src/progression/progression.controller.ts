import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ProgressionService } from './progression.service';

@UseGuards(JwtAuthGuard)
@Controller('progression')
export class ProgressionController {
  constructor(private readonly progression: ProgressionService) {}

  /** Poziom, ranga, XP i nagrody za poziom (np. zasięg perełek). */
  @Get()
  get(@CurrentUser() user: AuthUser) {
    return this.progression.getProgress(user.userId);
  }
}
