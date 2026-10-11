import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ProfileService } from './profile.service';

class SelectRankDto {
  @IsString()
  rankId: string;
}

@UseGuards(JwtAuthGuard)
@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  getProfile(@CurrentUser() user: AuthUser) {
    return this.profileService.getProfile(user.userId);
  }

  @Patch('rank')
  selectRank(@CurrentUser() user: AuthUser, @Body() dto: SelectRankDto) {
    return this.profileService.selectRank(user.userId, dto.rankId);
  }
}
