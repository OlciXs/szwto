import { Body, Controller, Get, HttpCode, Post, UseGuards } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AchievementsService } from './achievements.service';
import { EventDto } from './dto/event.dto';
import { RewardsService } from './rewards.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class AchievementsController {
  constructor(
    private readonly achievements: AchievementsService,
    private readonly rewards: RewardsService,
  ) {}

  /** Wszystkie osiągnięcia z postępem (sekretne bez nazwy, dopóki nieodblokowane). */
  @Get('achievements')
  list(@CurrentUser() user: AuthUser) {
    return this.achievements.list(user.userId);
  }

  /** Zdarzenie gracza, np. { type: "WIKIPEDIA_OPENED", monumentId } – może odblokować osiągnięcie. */
  @Post('events')
  @HttpCode(200)
  async event(@CurrentUser() user: AuthUser, @Body() dto: EventDto) {
    await this.achievements.recordEvent(user.userId, dto.type, dto.monumentId);
    return { recorded: true, rewards: await this.rewards.settle(user.userId, 0) };
  }
}
