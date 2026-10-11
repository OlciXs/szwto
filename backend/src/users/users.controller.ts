import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Query,
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

  /** Ranking graczy; ?scope=friends – tylko znajomi (musi być przed /users/:id). */
  @Get('leaderboard')
  leaderboard(@CurrentUser() user: AuthUser, @Query('scope') scope?: string) {
    return this.users.leaderboard(user.userId, scope === 'friends' ? 'friends' : 'all');
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
