import {
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RewardsService } from '../achievements/rewards.service';
import { haversineDistanceMeters } from '../common/geo.util';
import { FriendsService } from '../friends/friends.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { CreateCommentDto } from './dto/comment.dto';

/** Minimalny odstęp między komentarzami jednego gracza (prosta ochrona przed spamem). */
const COMMENT_COOLDOWN_MS = 10_000;
const PAGE_SIZE = 30;

@Injectable()
export class CommentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly rewards: RewardsService,
    private readonly friends: FriendsService,
  ) {}

  /** Komentarze od najnowszych; [before] = id ostatniego z poprzedniej strony. */
  async list(viewerId: number, monumentId: number, before?: number) {
    const monument = await this.findMonument(monumentId);
    const [comments, total, visit] = await Promise.all([
      this.prisma.comment.findMany({
        where: { monumentId, ...(before ? { id: { lt: before } } : {}) },
        orderBy: { id: 'desc' },
        take: PAGE_SIZE,
        include: { user: { select: { id: true, displayName: true } } },
      }),
      this.prisma.comment.count({ where: { monumentId } }),
      this.prisma.userVisited.findUnique({
        where: { userId_monumentId: { userId: viewerId, monumentId } },
      }),
    ]);

    const [authors, friendIds] = await Promise.all([
      this.progression.getSummaries([...new Set(comments.map((c) => c.userId))]),
      this.friends.friendIds(viewerId),
    ]);

    return {
      total,
      /** Pisać mogą tylko gracze, którzy odwiedzili zabytek ORAZ są na miejscu */
      visited: visit !== null,
      visitRadius: monument.visitRadius,
      hasMore: comments.length === PAGE_SIZE,
      comments: comments.map((c) => {
        const author = authors.get(c.userId);
        return {
          id: c.id,
          body: c.body,
          createdAt: c.createdAt,
          isMine: c.userId === viewerId,
          author: {
            id: c.user.id,
            displayName: c.user.displayName,
            level: author?.level ?? 1,
            rankIndex: author?.rank.index ?? 0,
            rankName: author?.rank.name ?? 'Turysta',
            isFriend: friendIds.has(c.userId),
          },
        };
      }),
    };
  }

  async create(userId: number, monumentId: number, dto: CreateCommentDto) {
    const monument = await this.findMonument(monumentId);

    const visit = await this.prisma.userVisited.findUnique({
      where: { userId_monumentId: { userId, monumentId } },
    });
    if (!visit) {
      throw new ForbiddenException('Odwiedź ten zabytek, aby dodać komentarz.');
    }

    const distance = haversineDistanceMeters(
      dto.latitude,
      dto.longitude,
      monument.latitude,
      monument.longitude,
    );
    if (distance > monument.visitRadius) {
      throw new ForbiddenException(
        `Komentować możesz tylko na miejscu – podejdź na ${monument.visitRadius} m (jesteś ${Math.round(distance)} m od zabytku).`,
      );
    }

    const last = await this.prisma.comment.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    if (last && Date.now() - last.createdAt.getTime() < COMMENT_COOLDOWN_MS) {
      throw new HttpException(
        'Zwolnij trochę – kolejny komentarz za kilka sekund.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const comment = await this.prisma.comment.create({
      data: { userId, monumentId, body: dto.body },
    });
    return {
      id: comment.id,
      rewards: await this.rewards.settle(userId, 0), // np. „Głos zabrany”
    };
  }

  async remove(userId: number, commentId: number) {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Nie znaleziono komentarza');
    if (comment.userId !== userId) {
      throw new ForbiddenException('Możesz usuwać tylko własne komentarze.');
    }
    await this.prisma.comment.delete({ where: { id: commentId } });
    return { deleted: true };
  }

  private async findMonument(id: number) {
    const monument = await this.prisma.monument.findUnique({ where: { id } });
    if (!monument) throw new NotFoundException('Nie znaleziono zabytku');
    return monument;
  }
}
