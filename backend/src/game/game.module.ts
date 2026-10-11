import { Module } from '@nestjs/common';
import { FriendsModule } from '../friends/friends.module';
import { GameController } from './game.controller';
import { GameService } from './game.service';

/**
 * Tor E – Pojedynki Geoguessr 1v1.
 * Wymóg: min. 10 odblokowanych kart gracza i oponenta.
 * 3 rundy: losowa karta gracza, losowa karta oponenta, karta środkowa.
 * Gracz wskazuje, która karta leży bliżej środka.
 */
@Module({
  imports: [FriendsModule],
  controllers: [GameController],
  providers: [GameService],
  exports: [GameService],
})
export class GameModule {}
