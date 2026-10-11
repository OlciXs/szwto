import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Monument } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { CreateDuelDto } from './dto/create-duel.dto';
import { SubmitAnswersDto } from './dto/submit-answers.dto';
import { generateDuelRounds, SeededRng, DuelRound } from './duel-generator';

const MIN_CARDS_REQUIRED = 10;
const BOT_DISPLAY_NAME = 'Wrocławski Przewodnik';

@Injectable()
export class GameService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly friends: FriendsService,
  ) {}

  /** Sprawdza kwalifikację do gry (wymóg min. 10 kart) dla gracza i jego znajomych. */
  async getEligibility(userId: number) {
    const [myVisitedCount, friendsOverview] = await Promise.all([
      this.prisma.userVisited.count({ where: { userId } }),
      this.friends.overview(userId),
    ]);

    const friendsList = friendsOverview.friends.map((f) => ({
      id: f.id,
      displayName: f.displayName,
      friendCode: f.friendCode,
      level: f.level,
      rankIndex: f.rankIndex,
      rankName: f.rankName,
      totalXp: f.totalXp,
      visitedCount: f.visitedCount,
      isEligible: f.visitedCount >= MIN_CARDS_REQUIRED,
    }));

    return {
      myVisitedCount,
      isEligible: myVisitedCount >= MIN_CARDS_REQUIRED,
      minCardsRequired: MIN_CARDS_REQUIRED,
      friends: friendsList,
    };
  }

  /** Tworzy nowy pojedynek 1v1 (ze znajomym lub botem treningowym). */
  async createDuel(userId: number, dto: CreateDuelDto) {
    const myCount = await this.prisma.userVisited.count({ where: { userId } });
    if (myCount < MIN_CARDS_REQUIRED) {
      throw new BadRequestException(
        `Musisz mieć co najmniej ${MIN_CARDS_REQUIRED} odblokowanych kart, aby grać w pojedynki (masz ${myCount}/${MIN_CARDS_REQUIRED}).`,
      );
    }

    let opponentId: number | null = null;
    let opponentName = BOT_DISPLAY_NAME;

    if (dto.opponentId && !dto.isBot) {
      if (dto.opponentId === userId) {
        throw new BadRequestException('Nie możesz zagrać pojedynku ze samym sobą.');
      }

      const opponent = await this.prisma.user.findUnique({
        where: { id: dto.opponentId },
        select: { id: true, displayName: true },
      });
      if (!opponent) {
        throw new NotFoundException('Nie znaleziono wybranego gracza.');
      }

      const oppCount = await this.prisma.userVisited.count({
        where: { userId: dto.opponentId },
      });
      if (oppCount < MIN_CARDS_REQUIRED) {
        throw new BadRequestException(
          `Gracz ${opponent.displayName} musi mieć co najmniej ${MIN_CARDS_REQUIRED} odblokowanych kart (ma ${oppCount}/${MIN_CARDS_REQUIRED}).`,
        );
      }

      opponentId = dto.opponentId;
      opponentName = opponent.displayName;
    }

    // Wygeneruj unikalny kod
    const code = Math.random().toString(36).substring(2, 8).toUpperCase();
    const seed = Math.floor(Math.random() * 2000000000) + 1;

    const duel = await this.prisma.duel.create({
      data: {
        code,
        seed,
        rounds: 3,
        creatorId: userId,
        opponentId,
      },
      include: {
        creator: { select: { id: true, displayName: true } },
        opponent: { select: { id: true, displayName: true } },
      },
    });

    return {
      id: duel.id,
      code: duel.code,
      seed: duel.seed,
      rounds: duel.rounds,
      creatorId: duel.creatorId,
      creatorName: duel.creator.displayName,
      opponentId: duel.opponentId,
      opponentName: duel.opponent?.displayName ?? opponentName,
      isBot: duel.opponentId === null,
      createdAt: duel.createdAt,
    };
  }

  /** Zwraca listę pojedynków użytkownika (aktywnych i zakończonych). */
  async getUserDuels(userId: number) {
    const duels = await this.prisma.duel.findMany({
      where: {
        OR: [{ creatorId: userId }, { opponentId: userId }],
      },
      orderBy: { createdAt: 'desc' },
      take: 30,
      include: {
        creator: { select: { id: true, displayName: true } },
        opponent: { select: { id: true, displayName: true } },
      },
    });

    return duels.map((d) => {
      const isCreator = d.creatorId === userId;
      const myScore = isCreator ? d.creatorScore : d.opponentScore;
      const opponentScore = isCreator ? d.opponentScore : d.creatorScore;
      const hasPlayed = myScore !== null;
      const opponentHasPlayed = opponentScore !== null;
      const isFinished = d.finishedAt !== null;

      let status: 'YOUR_TURN' | 'WAITING_OPPONENT' | 'FINISHED';
      if (isFinished) {
        status = 'FINISHED';
      } else if (!hasPlayed) {
        status = 'YOUR_TURN';
      } else {
        status = 'WAITING_OPPONENT';
      }

      return {
        id: d.id,
        code: d.code,
        rounds: d.rounds,
        createdAt: d.createdAt,
        finishedAt: d.finishedAt,
        isCreator,
        creator: d.creator,
        opponent: d.opponent ?? { id: 0, displayName: BOT_DISPLAY_NAME },
        isBot: d.opponentId === null,
        myScore,
        opponentScore,
        hasPlayed,
        opponentHasPlayed,
        isFinished,
        status,
      };
    });
  }

  /** Pobiera szczegóły pojedynku i generuje 3 rundy. */
  async getDuel(userId: number, duelId: number) {
    const duel = await this.prisma.duel.findUnique({
      where: { id: duelId },
      include: {
        creator: { select: { id: true, displayName: true } },
        opponent: { select: { id: true, displayName: true } },
      },
    });

    if (!duel) throw new NotFoundException('Nie znaleziono pojedynku.');

    const isCreator = duel.creatorId === userId;
    const isOpponent = duel.opponentId === userId;

    if (!isCreator && !isOpponent) {
      throw new ForbiddenException('Nie masz dostępu do tego pojedynku.');
    }

    const { rounds } = await this.resolveDuelRounds(duel);

    const myScore = isCreator ? duel.creatorScore : duel.opponentScore;
    const opponentScore = isCreator ? duel.opponentScore : duel.creatorScore;

    return {
      id: duel.id,
      code: duel.code,
      seed: duel.seed,
      roundsCount: duel.rounds,
      createdAt: duel.createdAt,
      finishedAt: duel.finishedAt,
      isCreator,
      creator: duel.creator,
      opponent: duel.opponent ?? { id: 0, displayName: BOT_DISPLAY_NAME },
      isBot: duel.opponentId === null,
      myScore,
      opponentScore,
      hasPlayed: myScore !== null,
      isFinished: duel.finishedAt !== null,
      rounds,
    };
  }

  /** Zapisuje odpowiedzi gracza dla 3 rund i oblicza wynik. */
  async submitAnswers(userId: number, duelId: number, dto: SubmitAnswersDto) {
    const duel = await this.prisma.duel.findUnique({
      where: { id: duelId },
      include: {
        creator: { select: { id: true, displayName: true } },
        opponent: { select: { id: true, displayName: true } },
      },
    });

    if (!duel) throw new NotFoundException('Nie znaleziono pojedynku.');

    const isCreator = duel.creatorId === userId;
    const isOpponent = duel.opponentId === userId;

    if (!isCreator && !isOpponent) {
      throw new ForbiddenException('Nie masz dostępu do tego pojedynku.');
    }

    if (isCreator && duel.creatorScore !== null) {
      throw new BadRequestException('Już rozegrałeś swoje rundy w tym pojedynku.');
    }
    if (isOpponent && duel.opponentScore !== null) {
      throw new BadRequestException('Już rozegrałeś swoje rundy w tym pojedynku.');
    }

    const { rounds } = await this.resolveDuelRounds(duel);

    // Sprawdź odpowiedzi
    let score = 0;
    const roundResults = rounds.map((r, idx) => {
      const playerChoice = dto.answers[idx]; // 'CREATOR' | 'OPPONENT'
      const isCorrect = playerChoice === r.closer;
      if (isCorrect) score++;

      return {
        roundNumber: r.roundNumber,
        yourChoice: playerChoice,
        closer: r.closer,
        isCorrect,
        centerMonument: r.centerMonument,
        creatorMonument: r.creatorMonument,
        opponentMonument: r.opponentMonument,
        creatorDistanceMeters: r.creatorDistanceMeters,
        opponentDistanceMeters: r.opponentDistanceMeters,
      };
    });

    let updatedCreatorScore = duel.creatorScore;
    let updatedOpponentScore = duel.opponentScore;
    let finishedAt = duel.finishedAt;

    if (isCreator) {
      updatedCreatorScore = score;
      if (duel.opponentId === null) {
        // Gra z botem – deterministyczny wynik bota z tego samego seeda
        const rng = new SeededRng(duel.seed + 999);
        // Bot ma wynik np. 1..3
        updatedOpponentScore = 1 + rng.nextInt(3);
        finishedAt = new Date();
      } else if (duel.opponentScore !== null) {
        finishedAt = new Date();
      }
    } else {
      updatedOpponentScore = score;
      if (duel.creatorScore !== null) {
        finishedAt = new Date();
      }
    }

    await this.prisma.duel.update({
      where: { id: duel.id },
      data: {
        creatorScore: updatedCreatorScore,
        opponentScore: updatedOpponentScore,
        finishedAt,
      },
    });

    const isFinished = finishedAt !== null;
    let winner: 'YOU' | 'OPPONENT' | 'DRAW' | null = null;
    if (isFinished) {
      const myFinal = isCreator ? updatedCreatorScore! : updatedOpponentScore!;
      const oppFinal = isCreator ? updatedOpponentScore! : updatedCreatorScore!;
      if (myFinal > oppFinal) winner = 'YOU';
      else if (myFinal < oppFinal) winner = 'OPPONENT';
      else winner = 'DRAW';
    }

    return {
      score,
      totalRounds: duel.rounds,
      roundResults,
      isFinished,
      myScore: score,
      opponentScore: isCreator ? updatedOpponentScore : updatedCreatorScore,
      winner,
    };
  }

  /** Rozwiązuje pule kart i deterministycznie generuje rundy. */
  private async resolveDuelRounds(duel: {
    seed: number;
    creatorId: number;
    opponentId: number | null;
  }) {
    // 1. Pula kart twórcy
    const creatorVisits = await this.prisma.userVisited.findMany({
      where: { userId: duel.creatorId },
      include: { monument: true },
      orderBy: { monumentId: 'asc' },
    });
    let creatorMonuments = creatorVisits.map((v) => v.monument);

    // Awaryjnie (jeśli w testach mniej niż 10)
    if (creatorMonuments.length === 0) {
      creatorMonuments = await this.prisma.monument.findMany({ take: 20 });
    }

    // 2. Pula kart oponenta
    let opponentMonuments: Monument[] = [];
    if (duel.opponentId !== null) {
      const opponentVisits = await this.prisma.userVisited.findMany({
        where: { userId: duel.opponentId },
        include: { monument: true },
        orderBy: { monumentId: 'asc' },
      });
      opponentMonuments = opponentVisits.map((v) => v.monument);
    }

    if (opponentMonuments.length === 0) {
      // Dla bota lub fallback: weź próbkę innych zabytków
      opponentMonuments = await this.prisma.monument.findMany({
        where: { id: { notIn: creatorMonuments.map((m) => m.id) } },
        take: 30,
        orderBy: { id: 'asc' },
      });
      if (opponentMonuments.length === 0) {
        opponentMonuments = await this.prisma.monument.findMany({ take: 30 });
      }
    }

    // 3. Pula środkowych zabytków
    const centerMonuments = await this.prisma.monument.findMany({
      where: { imageFile: { not: null } },
      orderBy: { id: 'asc' },
    });

    const allCenter = centerMonuments.length >= 10
      ? centerMonuments
      : await this.prisma.monument.findMany({ orderBy: { id: 'asc' } });

    const rounds = generateDuelRounds(
      duel.seed,
      creatorMonuments,
      opponentMonuments,
      allCenter,
      3,
    );

    return { rounds };
  }
}
