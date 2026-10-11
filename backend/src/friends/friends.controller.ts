import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FriendsService } from './friends.service';

class AddFriendDto {
  @IsString()
  @MinLength(4, { message: 'Podaj kod znajomego, np. #K7Q2MX' })
  @MaxLength(12)
  code: string;
}

@UseGuards(JwtAuthGuard)
@Controller('friends')
export class FriendsController {
  constructor(private readonly friends: FriendsService) {}

  /** Mój kod, znajomi, zaproszenia przychodzące i wysłane. */
  @Get()
  overview(@CurrentUser() user: AuthUser) {
    return this.friends.overview(user.userId);
  }

  /** { code: "#K7Q2MX" } – zaproszenie (albo akceptacja, jeśli ta osoba zaprosiła nas). */
  @Post()
  @HttpCode(200)
  add(@CurrentUser() user: AuthUser, @Body() dto: AddFriendDto) {
    return this.friends.addByCode(user.userId, dto.code);
  }

  @Post(':userId/accept')
  @HttpCode(200)
  accept(@CurrentUser() user: AuthUser, @Param('userId', ParseIntPipe) userId: number) {
    return this.friends.accept(user.userId, userId);
  }

  /** Usuń znajomego / odrzuć zaproszenie / anuluj wysłane. */
  @Delete(':userId')
  remove(@CurrentUser() user: AuthUser, @Param('userId', ParseIntPipe) userId: number) {
    return this.friends.remove(user.userId, userId);
  }
}
