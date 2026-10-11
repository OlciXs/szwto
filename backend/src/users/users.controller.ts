import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { IsString, Matches, MaxLength } from 'class-validator';
import { DISPLAY_NAME_PATTERN } from '../auth/dto/auth.dto';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';

class UpdateMeDto {
  @IsString()
  @MaxLength(24)
  @Matches(DISPLAY_NAME_PATTERN, {
    message: 'Nazwa gracza: 3–24 znaki (litery, cyfry, _ . -)',
  })
  displayName: string;
}

@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  /** Ranking graczy (musi być przed /users/:id). */
  @Get('leaderboard')
  leaderboard(@CurrentUser() user: AuthUser) {
    return this.users.leaderboard(user.userId);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateMeDto) {
    return this.users.updateDisplayName(user.userId, dto.displayName);
  }

  /** Publiczny profil gracza (bez e-maila). */
  @Get(':id')
  profile(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.users.publicProfile(user.userId, id);
  }
}
