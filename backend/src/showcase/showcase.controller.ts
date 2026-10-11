import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Put,
  UseGuards,
} from '@nestjs/common';
import { IsInt } from 'class-validator';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ShowcaseService } from './showcase.service';

class SetSlotDto {
  @IsInt({ message: 'monumentId musi być liczbą' })
  monumentId: number;
}

@UseGuards(JwtAuthGuard)
@Controller('showcase')
export class ShowcaseController {
  constructor(private readonly showcase: ShowcaseService) {}

  /** Moja gablotka. */
  @Get()
  mine(@CurrentUser() user: AuthUser) {
    return this.showcase.getForUser(user.userId);
  }

  @Put(':slot')
  set(
    @CurrentUser() user: AuthUser,
    @Param('slot', ParseIntPipe) slot: number,
    @Body() dto: SetSlotDto,
  ) {
    return this.showcase.setSlot(user.userId, slot, dto.monumentId);
  }

  @Delete(':slot')
  clear(@CurrentUser() user: AuthUser, @Param('slot', ParseIntPipe) slot: number) {
    return this.showcase.clearSlot(user.userId, slot);
  }
}
