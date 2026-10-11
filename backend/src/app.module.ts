import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { AchievementsModule } from './achievements/achievements.module';
import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { CommentsModule } from './comments/comments.module';
import { GameModule } from './game/game.module';
import { MonumentsModule } from './monuments/monuments.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfileModule } from './profile/profile.module';
import { ProgressionModule } from './progression/progression.module';
import { ShowcaseModule } from './showcase/showcase.module';
import { UsersModule } from './users/users.module';
import { FriendsModule } from './friends/friends.module';
import { VisitsModule } from './visits/visits.module';

/**
 * Każda funkcja to osobny moduł w swoim folderze (patrz docs/ARCHITECTURE.md).
 * Moduły nie wołają się nawzajem przy wizycie – komunikują się zdarzeniami (events/).
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    EventEmitterModule.forRoot(),
    PrismaModule,
    AuthModule,
    // Tor A – mapa i zabytki
    MonumentsModule,
    VisitsModule,
    // Tor B – XP i achievementy
    ProgressionModule,
    AchievementsModule,
    // Tor D – społeczność
    UsersModule,
    FriendsModule,
    ShowcaseModule,
    CommentsModule,
    // Tor E – gra
    GameModule,
    ProfileModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
