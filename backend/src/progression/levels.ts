/**
 * Poziomy, rangi i nagrody za poziom – jedno źródło prawdy (aplikacja dostaje wynik).
 *
 * XP = XP z wizyt (UserVisited.xpEarned) + premie za osiągnięcia (UserAchievement.xpReward).
 * Na wszystkich zabytkach + osiągnięciach jest ok. 14 tys. XP, czyli ok. 20+ poziom.
 */

/** Próg XP potrzebny do osiągnięcia poziomu: P2 = 50, P3 = 150, P5 = 500, P10 = 2250, P20 = 9500. */
export function xpForLevel(level: number): number {
  return 25 * level * (level - 1);
}

export function levelForXp(xp: number): number {
  let level = 1;
  while (xpForLevel(level + 1) <= xp) level++;
  return level;
}

// ---------- Rangi ----------

export const RANKS = [
  { minLevel: 1, name: 'Turysta' },
  { minLevel: 3, name: 'Spacerowicz' },
  { minLevel: 5, name: 'Odkrywca' },
  { minLevel: 8, name: 'Tropiciel' },
  { minLevel: 11, name: 'Przewodnik' },
  { minLevel: 14, name: 'Kronikarz' },
  { minLevel: 17, name: 'Strażnik Dziedzictwa' },
  { minLevel: 20, name: 'Legenda Wrocławia' },
] as const;

/** Indeks rangi (0..7) – aplikacja dobiera po nim kolor ramki awatara. */
export function rankForLevel(level: number) {
  let index = 0;
  RANKS.forEach((rank, i) => {
    if (level >= rank.minLevel) index = i;
  });
  return { index, name: RANKS[index].name };
}

// ---------- Nagrody za poziom ----------

export type PerkType = 'DISCOVERY_RADIUS' | 'SHOWCASE_SLOTS' | 'RADAR';

interface PerkUnlock {
  level: number;
  type: PerkType;
  value: number;
  label: string;
}

export const PERK_UNLOCKS: PerkUnlock[] = [
  { level: 3, type: 'SHOWCASE_SLOTS', value: 2, label: '2. miejsce w gablotce' },
  { level: 4, type: 'DISCOVERY_RADIUS', value: 300, label: 'Zasięg perełek 300 m' },
  { level: 5, type: 'RADAR', value: 1, label: 'Radar perełek (1 km)' },
  { level: 6, type: 'SHOWCASE_SLOTS', value: 3, label: '3. miejsce w gablotce' },
  { level: 7, type: 'DISCOVERY_RADIUS', value: 350, label: 'Zasięg perełek 350 m' },
  { level: 10, type: 'DISCOVERY_RADIUS', value: 400, label: 'Zasięg perełek 400 m' },
  { level: 10, type: 'SHOWCASE_SLOTS', value: 4, label: '4. miejsce w gablotce' },
  { level: 13, type: 'DISCOVERY_RADIUS', value: 450, label: 'Zasięg perełek 450 m' },
  { level: 15, type: 'SHOWCASE_SLOTS', value: 5, label: '5. miejsce w gablotce' },
  { level: 18, type: 'DISCOVERY_RADIUS', value: 500, label: 'Zasięg perełek 500 m' },
];

export interface Perks {
  /** Promień (m), w którym pojawiają się ukryte perełki */
  discoveryRadius: number;
  /** Liczba miejsc w gablotce (#4) */
  showcaseSlots: number;
  /** Radar: liczba ukrytych perełek w promieniu 1 km */
  radar: boolean;
}

export function perksForLevel(level: number): Perks {
  const perks: Perks = { discoveryRadius: 250, showcaseSlots: 1, radar: false };
  for (const unlock of PERK_UNLOCKS) {
    if (unlock.level > level) continue;
    if (unlock.type === 'DISCOVERY_RADIUS') perks.discoveryRadius = unlock.value;
    if (unlock.type === 'SHOWCASE_SLOTS') perks.showcaseSlots = unlock.value;
    if (unlock.type === 'RADAR') perks.radar = true;
  }
  return perks;
}

/** Nagrody odblokowane po przejściu z poziomu [from] na [to]. */
export function perksUnlockedBetween(from: number, to: number): string[] {
  return PERK_UNLOCKS.filter((u) => u.level > from && u.level <= to).map(
    (u) => u.label,
  );
}

/** Najbliższa nagroda do zdobycia (null = wszystko odblokowane). */
export function nextUnlock(level: number) {
  const next = PERK_UNLOCKS.find((u) => u.level > level);
  return next ? { level: next.level, label: next.label } : null;
}

// ---------- Podsumowanie ----------

export function describeProgress(totalXp: number) {
  const level = levelForXp(totalXp);
  const levelStartXp = xpForLevel(level);
  const nextLevelXp = xpForLevel(level + 1);
  return {
    totalXp,
    level,
    rank: rankForLevel(level),
    levelStartXp,
    nextLevelXp,
    /** 0..1 – postęp do następnego poziomu */
    progress: (totalXp - levelStartXp) / (nextLevelXp - levelStartXp),
    perks: perksForLevel(level),
    nextUnlock: nextUnlock(level),
  };
}

export type ProgressSummary = ReturnType<typeof describeProgress>;
