import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FriendshipStatus } from '@prisma/client';
import { RewardsService } from '../achievements/rewards.service';
import { PrismaService } from '../prisma/prisma.service';
import { ProgressionService } from '../progression/progression.service';
import { normalizeFriendCode } from './friend-code';

/** Relacja oglądającego z innym graczem. */
export type FriendStatus = 'NONE' | 'OUTGOING' | 'INCOMING' | 'FRIENDS';

@Injectable()
export class FriendsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly progression: ProgressionService,
    private readonly rewards: RewardsService,
  ) {}

  /** Id zaakceptowanych znajomych (do oznaczeń „ZNAJOMY” w rankingu, komentarzach). */
  async friendIds(userId: number): Promise<Set<number>> {
    const rows = await this.prisma.friendship.findMany({
      where: {
        status: FriendshipStatus.ACCEPTED,
        OR: [{ requesterId: userId }, { addresseeId: userId }],
      },
      select: { requesterId: true, addresseeId: true },
    });
    return new Set(
      rows.map((r) => (r.requesterId === userId ? r.addresseeId : r.requesterId)),
    );
  }

  async statusBetween(me: number, other: number): Promise<FriendStatus> {
    if (me === other) return 'NONE';
    const row = await this.findBetween(me, other);
    if (!row) return 'NONE';
    if (row.status === FriendshipStatus.ACCEPTED) return 'FRIENDS';
    return row.requesterId === me ? 'OUTGOING' : 'INCOMING';
  }

  /** Mój kod, znajomi oraz zaproszenia przychodzące i wysłane. */
  async overview(userId: number) {
    const [me, rows] = await Promise.all([
      this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
        select: { friendCode: true },
      }),
      this.prisma.friendship.findMany({
        where: { OR: [{ requesterId: userId }, { addresseeId: userId }] },
        orderBy: { createdAt: 'desc' },
        include: {
          requester: { select: { id: true, displayName: true, friendCode: true } },
          addressee: { select: { id: true, displayName: true, friendCode: true } },
        },
      }),
    ]);

    const others = rows.map((r) => (r.requesterId === userId ? r.addressee : r.requester));
    const summaries = await this.progression.getSummaries(others.map((o) => o.id));
    const toDto = (user: { id: number; displayName: string; friendCode: string }) => {
      const s = summaries.get(user.id);
      return {
        id: user.id,
        displayName: user.displayName,
        friendCode: user.friendCode,
        level: s?.level ?? 1,
        rankIndex: s?.rank.index ?? 0,
        rankName: s?.rank.name ?? 'Turysta',
        totalXp: s?.totalXp ?? 0,
        visitedCount: s?.visitedCount ?? 0,
      };
    };

    const accepted = rows.filter((r) => r.status === FriendshipStatus.ACCEPTED);
    return {
      myCode: me.friendCode,
      friends: accepted
        .map((r) => toDto(r.requesterId === userId ? r.addressee : r.requester))
        .sort((a, b) => b.totalXp - a.totalXp),
      incoming: rows
        .filter((r) => r.status === FriendshipStatus.PENDING && r.addresseeId === userId)
        .map((r) => toDto(r.requester)),
      outgoing: rows
        .filter((r) => r.status === FriendshipStatus.PENDING && r.requesterId === userId)
        .map((r) => toDto(r.addressee)),
    };
  }

  /**
   * Zaproszenie po kodzie. Jeśli ta osoba już zaprosiła nas – od razu akceptujemy.
   */
  async addByCode(userId: number, rawCode: string) {
    const code = normalizeFriendCode(rawCode);
    const target = await this.prisma.user.findUnique({ where: { friendCode: code } });
    if (!target) throw new NotFoundException(`Nie ma gracza z kodem #${code}.`);
    if (target.id === userId) {
      throw new BadRequestException('To Twój własny kod – podaj kod znajomego.');
    }

    const existing = await this.findBetween(userId, target.id);
    if (existing?.status === FriendshipStatus.ACCEPTED) {
      throw new ConflictException(`${target.displayName} jest już Twoim znajomym.`);
    }
    if (existing && existing.requesterId === userId) {
      throw new ConflictException(`Zaproszenie do ${target.displayName} już czeka na akceptację.`);
    }
    if (existing) {
      return this.acceptRow(userId, existing.id, target.displayName);
    }

    await this.prisma.friendship.create({
      data: { requesterId: userId, addresseeId: target.id },
    });
    return {
      status: 'PENDING' as const,
      message: `Wysłano zaproszenie do ${target.displayName}.`,
      rewards: null,
    };
  }

  async accept(userId: number, requesterId: number) {
    const row = await this.prisma.friendship.findUnique({
      where: { requesterId_addresseeId: { requesterId, addresseeId: userId } },
      include: { requester: { select: { displayName: true } } },
    });
    if (!row || row.status !== FriendshipStatus.PENDING) {
      throw new NotFoundException('Nie ma takiego zaproszenia.');
    }
    return this.acceptRow(userId, row.id, row.requester.displayName);
  }

  /** Usuwa znajomego, odrzuca zaproszenie albo anuluje wysłane. */
  async remove(userId: number, otherId: number) {
    const row = await this.findBetween(userId, otherId);
    if (!row) throw new NotFoundException('Nie ma takiej znajomości ani zaproszenia.');
    await this.prisma.friendship.delete({ where: { id: row.id } });
    return { removed: true };
  }

  private async acceptRow(userId: number, friendshipId: number, name: string) {
    await this.prisma.friendship.update({
      where: { id: friendshipId },
      data: { status: FriendshipStatus.ACCEPTED, acceptedAt: new Date() },
    });
    return {
      status: 'ACCEPTED' as const,
      message: `${name} jest teraz Twoim znajomym!`,
      rewards: await this.rewards.settle(userId, 0), // np. „Pierwszy znajomy”
    };
  }

  private findBetween(a: number, b: number) {
    return this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: a, addresseeId: b },
          { requesterId: b, addresseeId: a },
        ],
      },
    });
  }
}
