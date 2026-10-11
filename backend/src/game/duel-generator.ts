import { Monument } from '@prisma/client';
import { commonsThumbUrl } from '../common/commons.util';
import { haversineDistanceMeters } from '../common/geo.util';

export class SeededRng {
  private s: number;

  constructor(seed: number) {
    this.s = Math.abs(seed) % 2147483647;
    if (this.s <= 0) this.s = 1;
  }

  next(): number {
    this.s = (this.s * 16807) % 2147483647;
    return (this.s - 1) / 2147483646;
  }

  nextInt(max: number): number {
    if (max <= 0) return 0;
    return Math.floor(this.next() * max);
  }
}

export interface DuelCardItem {
  id: number;
  name: string;
  category: string;
  rawType: string | null;
  rarity: string;
  builtLabel: string | null;
  thumbUrl: string | null;
  latitude: number;
  longitude: number;
}

export interface DuelRound {
  roundNumber: number; // 1, 2, 3
  centerMonument: DuelCardItem;
  creatorMonument: DuelCardItem;
  opponentMonument: DuelCardItem;
  creatorDistanceMeters: number;
  opponentDistanceMeters: number;
  closer: 'CREATOR' | 'OPPONENT';
}

function formatDuelCard(m: Monument): DuelCardItem {
  return {
    id: m.id,
    name: m.name,
    category: m.category,
    rawType: m.rawType,
    rarity: m.rarity,
    builtLabel: m.builtLabel,
    thumbUrl: m.imageFile ? commonsThumbUrl(m.imageFile, 330) : null,
    latitude: m.latitude,
    longitude: m.longitude,
  };
}

export function generateDuelRounds(
  seed: number,
  creatorMonuments: Monument[],
  opponentMonuments: Monument[],
  allCenterMonuments: Monument[],
  roundsCount = 3,
): DuelRound[] {
  const rng = new SeededRng(seed);
  const rounds: DuelRound[] = [];

  const usedCenterIds = new Set<number>();
  const usedCreatorIds = new Set<number>();
  const usedOpponentIds = new Set<number>();

  for (let roundIdx = 0; roundIdx < roundsCount; roundIdx++) {
    // 1. Karta z puli gracza 1
    let creatorPool = creatorMonuments.filter((m) => !usedCreatorIds.has(m.id));
    if (creatorPool.length === 0) creatorPool = creatorMonuments;
    const creatorChoice = creatorPool[rng.nextInt(creatorPool.length)];
    usedCreatorIds.add(creatorChoice.id);

    // 2. Karta z puli gracza 2
    let opponentPool = opponentMonuments.filter(
      (m) => !usedOpponentIds.has(m.id) && m.id !== creatorChoice.id,
    );
    if (opponentPool.length === 0) {
      opponentPool = opponentMonuments.filter((m) => m.id !== creatorChoice.id);
      if (opponentPool.length === 0) opponentPool = opponentMonuments;
    }
    const opponentChoice = opponentPool[rng.nextInt(opponentPool.length)];
    usedOpponentIds.add(opponentChoice.id);

    // 3. Losowa karta na środku ze wszystkich zabytków (inna niż karty graczy)
    let centerPool = allCenterMonuments.filter(
      (m) =>
        m.id !== creatorChoice.id &&
        m.id !== opponentChoice.id &&
        !usedCenterIds.has(m.id),
    );
    if (centerPool.length === 0) {
      centerPool = allCenterMonuments.filter(
        (m) => m.id !== creatorChoice.id && m.id !== opponentChoice.id,
      );
    }
    const centerChoice = centerPool[rng.nextInt(centerPool.length)];
    usedCenterIds.add(centerChoice.id);

    // 4. Obliczenie odległości
    const creatorDist = Math.round(
      haversineDistanceMeters(
        centerChoice.latitude,
        centerChoice.longitude,
        creatorChoice.latitude,
        creatorChoice.longitude,
      ),
    );

    const opponentDist = Math.round(
      haversineDistanceMeters(
        centerChoice.latitude,
        centerChoice.longitude,
        opponentChoice.latitude,
        opponentChoice.longitude,
      ),
    );

    const closer = creatorDist <= opponentDist ? 'CREATOR' : 'OPPONENT';

    rounds.push({
      roundNumber: roundIdx + 1,
      centerMonument: formatDuelCard(centerChoice),
      creatorMonument: formatDuelCard(creatorChoice),
      opponentMonument: formatDuelCard(opponentChoice),
      creatorDistanceMeters: creatorDist,
      opponentDistanceMeters: opponentDist,
      closer,
    });
  }

  return rounds;
}
