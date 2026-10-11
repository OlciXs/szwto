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
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateDuelDto } from './dto/create-duel.dto';
import { SubmitAnswersDto } from './dto/submit-answers.dto';
import { GameService } from './game.service';

@UseGuards(JwtAuthGuard)
@Controller('game')
export class GameController {
  constructor(private readonly gameService: GameService) {}

  /** Sprawdza czy gracz i jego znajomi spełniają kryterium min. 10 kart. */
  @Get('eligibility')
  getEligibility(@CurrentUser() user: AuthUser) {
    return this.gameService.getEligibility(user.userId);
  }

  /** Zwraca historię i aktywne pojedynki zalogowanego gracza. */
  @Get('duels')
  getUserDuels(@CurrentUser() user: AuthUser) {
    return this.gameService.getUserDuels(user.userId);
  }

  /** Tworzy nowy pojedynek 1v1 (ze znajomym lub botem treningowym). */
  @Post('duels')
  @HttpCode(201)
  createDuel(@CurrentUser() user: AuthUser, @Body() dto: CreateDuelDto) {
    return this.gameService.createDuel(user.userId, dto);
  }

  /** Usuwa pojedynek użytkownika z historii i listy aktywnych gier. */
  @Delete('duels/:id')
  removeDuel(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.gameService.removeDuel(user.userId, id);
  }

  /** Pobiera dane pojedynku i 3 rundy z kartami. */
  @Get('duels/:id')
  getDuel(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.gameService.getDuel(user.userId, id);
  }

  /** Przesyła odpowiedzi gracza na 3 rundy i oblicza wynik. */
  @Post('duels/:id/answers')
  @HttpCode(200)
  submitAnswers(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: SubmitAnswersDto,
  ) {
    return this.gameService.submitAnswers(user.userId, id, dto);
  }
}
