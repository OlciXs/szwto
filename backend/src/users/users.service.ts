import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AchievementsService } from '../achievements/achievements.service';
import { FriendsService } from '../friends/friends.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { ShowcaseService } from '../showcase/showcase.service';

const LEADERBOARD_SIZE = 50;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly achievements: AchievementsService,
    private readonly showcase: ShowcaseService,
    private readonly friends: FriendsService,
  ) {}

  /** Publiczny profil – NIGDY nie zawiera e-maila. */
  async publicProfile(viewerId: number, userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, displayName: true, friendCode: true, createdAt: true },
    });
    if (!user) throw new NotFoundException('Nie znaleziono gracza');

    const [progress, visitedCount, achievements, showcase, friendStatus] = await Promise.all([
      this.progression.getProgress(userId),
      this.prisma.userVisited.count({ where: { userId } }),
      this.achievements.summary(userId),
      this.showcase.getForUser(userId),
      this.friends.statusBetween(viewerId, userId),
    ]);

    return {
      id: user.id,
      displayName: user.displayName,
      /** Publiczny tag gracza – po nim można zaprosić do znajomych */
      friendCode: user.friendCode,
      createdAt: user.createdAt,
      isMe: user.id === viewerId,
      /** NONE | OUTGOING (zaprosiłem) | INCOMING (zaprosił mnie) | FRIENDS */
      friendStatus,
      isFriend: friendStatus === 'FRIENDS',
      level: progress.level,
      rank: progress.rank,
      totalXp: progress.totalXp,
      visitedCount,
      achievements,
      showcase,
    };
  }

  /**
   * Ranking po XP (+ pozycja oglądającego, nawet poza pierwszą pięćdziesiątką).
   * [scope] = 'friends' – tylko znajomi i oglądający.
   */
  async leaderboard(viewerId: number, scope: 'all' | 'friends' = 'all') {
    const friendIds = await this.friends.friendIds(viewerId);
    const where =
      scope === 'friends' ? { id: { in: [viewerId, ...friendIds] } } : undefined;
    const [users, summaries] = await Promise.all([
      this.prisma.user.findMany({ where, select: { id: true, displayName: true } }),
      this.progression.getSummaries(scope === 'friends' ? [viewerId, ...friendIds] : undefined),
    ]);

    const ranked = users
      .map((u) => {
        const s = summaries.get(u.id);
        return {
          id: u.id,
          displayName: u.displayName,
          totalXp: s?.totalXp ?? 0,
          visitedCount: s?.visitedCount ?? 0,
          level: s?.level ?? 1,
          rankIndex: s?.rank.index ?? 0,
          rankName: s?.rank.name ?? 'Turysta',
        };
      })
      .sort(
        (a, b) =>
          b.totalXp - a.totalXp || b.visitedCount - a.visitedCount || a.id - b.id,
      )
      .map((entry, i) => ({
        ...entry,
        position: i + 1,
        isMe: entry.id === viewerId,
        isFriend: friendIds.has(entry.id),
      }));

    return {
      totalPlayers: ranked.length,
      entries: ranked.slice(0, LEADERBOARD_SIZE),
      me: ranked.find((e) => e.isMe) ?? null,
    };
  }

  async updateDisplayName(userId: number, displayName: string) {
    const name = displayName.trim();
    const taken = await this.prisma.user.findUnique({ where: { displayName: name } });
    if (taken && taken.id !== userId) {
      throw new ConflictException('Ta nazwa gracza jest już zajęta');
    }
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { displayName: name },
      select: { id: true, displayName: true },
    });
    return user;
  }
}
