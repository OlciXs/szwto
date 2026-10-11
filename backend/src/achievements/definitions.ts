import { Era, MonumentCategory, Rarity } from '@prisma/client';

/**
 * Definicje osiągnięć (#5). Dodanie nowego = jeden wpis poniżej.
 * Postęp liczony jest ze statystyk gracza (PlayerStats) – patrz achievements.service.ts.
 * Ikony to nazwy, które aplikacja mapuje na ikony Material (features/achievements/).
 */

export type AchievementGroup =
  | 'KOLEKCJA'
  | 'RZADKOSC'
  | 'KATEGORIE'
  | 'EPOKI'
  | 'SZLAKI'
  | 'AKTYWNOSC'
  | 'SEKRETNE';

export const GROUP_LABELS: Record<AchievementGroup, string> = {
  KOLEKCJA: 'Kolekcja',
  RZADKOSC: 'Rzadkość',
  KATEGORIE: 'Rodzaje zabytków',
  EPOKI: 'Epoki',
  SZLAKI: 'Szlaki',
  AKTYWNOSC: 'Aktywność',
  SEKRETNE: 'Sekretne',
};

export type Tier = 'BRONZE' | 'SILVER' | 'GOLD';

/** Statystyki gracza – liczone raz przy każdej ocenie osiągnięć. */
export interface PlayerStats {
  visitedCount: number;
  byCategory: Partial<Record<MonumentCategory, number>>;
  byEra: Partial<Record<Era, number>>;
  byRarity: Partial<Record<Rarity, number>>;
  before1900: number;
  minorVisited: number;
  unescoVisited: number;
  visitedExternalIds: Set<string>;
  categoriesCovered: number;
  erasCovered: number;
  maxVisitsPerDay: number;
  nightVisits: number;
  morningVisits: number;
  wikipediaArticlesRead: number;
  /** Tor D – społeczność */
  commentsCount: number;
  showcaseCount: number;
  friendsCount: number;
}

/** Liczności w bazie – żeby cele „wszystkie X” nie rozjechały się po imporcie. */
export interface MonumentTotals {
  byCategory: Partial<Record<MonumentCategory, number>>;
  byRarity: Partial<Record<Rarity, number>>;
  categories: number;
  eras: number;
}

export interface AchievementDefinition {
  id: string;
  name: string;
  description: string;
  icon: string;
  group: AchievementGroup;
  tier?: Tier;
  xp: number;
  /** Sekretne – nazwa i opis ukryte do czasu odblokowania */
  secret?: boolean;
  target: number | ((totals: MonumentTotals) => number);
  progress: (stats: PlayerStats) => number;
}

const TIER_XP: Record<Tier, number> = { BRONZE: 25, SILVER: 50, GOLD: 100 };
const TIERS: Tier[] = ['BRONZE', 'SILVER', 'GOLD'];

/** Osiągnięcie w trzech stopniach (brąz / srebro / złoto). */
function tiered(
  base: Omit<AchievementDefinition, 'id' | 'tier' | 'xp' | 'target' | 'description'> & {
    id: string;
    describe: (target: number) => string;
  },
  targets: [number, number, number | ((totals: MonumentTotals) => number)],
): AchievementDefinition[] {
  return TIERS.map((tier, i) => {
    const target = targets[i];
    return {
      id: `${base.id}-${i + 1}`,
      name: base.name,
      description:
        typeof target === 'number' ? base.describe(target) : base.describe(0),
      icon: base.icon,
      group: base.group,
      progress: base.progress,
      tier,
      xp: TIER_XP[tier],
      target,
    };
  });
}

const category = (c: MonumentCategory) => (s: PlayerStats) => s.byCategory[c] ?? 0;
const era = (e: Era) => (s: PlayerStats) => s.byEra[e] ?? 0;
const visitedAll = (ids: string[]) => (s: PlayerStats) =>
  ids.filter((id) => s.visitedExternalIds.has(id)).length;

// ---------- Szlaki (ręcznie dobrane zestawy – externalId z Wikidata) ----------

const TRAIL_TUMSKI = ['wd:Q910211', 'wd:Q3581720', 'wd:Q11741013', 'wd:Q7852706'];
const TRAIL_RYNEK = ['wd:Q910225', 'wd:Q11793915', 'wd:Q11830567', 'wd:Q106096055', 'wd:Q11723611'];
const TRAIL_MOSTY = ['wd:Q745733', 'wd:Q7852706', 'wd:Q11785821', 'wd:Q7116782', 'wd:Q8075698'];
const TRAIL_HALA = ['wd:Q155743', 'wd:Q11814615', 'wd:Q11815667', 'wd:Q489439'];
const PILLORY = 'wd:Q11830567';

export const ACHIEVEMENTS: AchievementDefinition[] = [
  // ---------- Kolekcja ----------
  { id: 'visits-1', name: 'Pierwszy krok', description: 'Odwiedź pierwszy zabytek.', icon: 'footprint', group: 'KOLEKCJA', xp: 25, target: 1, progress: (s) => s.visitedCount },
  { id: 'visits-10', name: 'Dziesiątka', description: 'Odwiedź 10 zabytków.', icon: 'explore', group: 'KOLEKCJA', xp: 50, target: 10, progress: (s) => s.visitedCount },
  { id: 'visits-50', name: 'Pół setki', description: 'Odwiedź 50 zabytków.', icon: 'map', group: 'KOLEKCJA', xp: 100, target: 50, progress: (s) => s.visitedCount },
  { id: 'visits-100', name: 'Setka', description: 'Odwiedź 100 zabytków.', icon: 'workspace_premium', group: 'KOLEKCJA', xp: 150, target: 100, progress: (s) => s.visitedCount },

  // ---------- Rzadkość ----------
  { id: 'legendary-1', name: 'Pierwsza legenda', description: 'Odwiedź legendarny zabytek.', icon: 'star', group: 'RZADKOSC', xp: 50, target: 1, progress: (s) => s.byRarity.LEGENDARY ?? 0 },
  { id: 'legendary-5', name: 'Kolekcjoner legend', description: 'Odwiedź 5 legendarnych zabytków.', icon: 'stars', group: 'RZADKOSC', xp: 100, target: 5, progress: (s) => s.byRarity.LEGENDARY ?? 0 },
  { id: 'legendary-all', name: 'Wszystkie legendy', description: 'Odwiedź wszystkie legendarne zabytki Wrocławia.', icon: 'military_tech', group: 'RZADKOSC', xp: 250, target: (t) => t.byRarity.LEGENDARY ?? 0, progress: (s) => s.byRarity.LEGENDARY ?? 0 },
  { id: 'epic-10', name: 'Epicka dziesiątka', description: 'Odwiedź 10 epickich zabytków.', icon: 'diamond', group: 'RZADKOSC', xp: 100, target: 10, progress: (s) => s.byRarity.EPIC ?? 0 },
  ...tiered({ id: 'gems', name: 'Łowca perełek', describe: (n) => `Odwiedź ${n} ukrytych perełek.`, icon: 'auto_awesome', group: 'RZADKOSC', progress: (s) => s.minorVisited }, [5, 20, 50]),

  // ---------- Rodzaje zabytków ----------
  ...tiered({ id: 'sacral', name: 'Pielgrzym', describe: (n) => `Odwiedź ${n} obiektów sakralnych.`, icon: 'church', group: 'KATEGORIE', progress: category('SAKRALNY') }, [3, 10, 25]),
  ...tiered({ id: 'bridges', name: 'Miasto mostów', describe: (n) => (n ? `Odwiedź ${n} mostów.` : 'Odwiedź wszystkie mosty.'), icon: 'water', group: 'KATEGORIE', progress: category('MOST') }, [3, 6, (t) => t.byCategory.MOST ?? 0]),
  ...tiered({ id: 'tenements', name: 'Kamienicznik', describe: (n) => (n ? `Odwiedź ${n} kamienic.` : 'Odwiedź wszystkie kamienice.'), icon: 'apartment', group: 'KATEGORIE', progress: category('KAMIENICA') }, [3, 10, (t) => t.byCategory.KAMIENICA ?? 0]),
  ...tiered({ id: 'palaces', name: 'Pałacowy bywalec', describe: (n) => `Odwiedź ${n} pałaców lub willi.`, icon: 'castle', group: 'KATEGORIE', progress: category('PALAC') }, [3, 10, 20]),
  ...tiered({ id: 'monuments', name: 'Strażnik pamięci', describe: (n) => `Odwiedź ${n} pomników.`, icon: 'account_balance', group: 'KATEGORIE', progress: category('POMNIK') }, [3, 15, 40]),
  ...tiered({ id: 'art', name: 'Miłośnik sztuki', describe: (n) => `Odwiedź ${n} rzeźb lub fontann.`, icon: 'palette', group: 'KATEGORIE', progress: category('RZEZBA') }, [3, 8, 15]),
  ...tiered({ id: 'parks', name: 'Zielone płuca', describe: (n) => `Odwiedź ${n} parków lub cmentarzy.`, icon: 'park', group: 'KATEGORIE', progress: category('PARK') }, [3, 8, 15]),
  ...tiered({ id: 'technical', name: 'Inżynier', describe: (n) => `Odwiedź ${n} obiektów techniki lub fortyfikacji.`, icon: 'factory', group: 'KATEGORIE', progress: category('TECHNICZNY') }, [3, 10, 20]),
  ...tiered({ id: 'public', name: 'Obywatel', describe: (n) => `Odwiedź ${n} budynków publicznych.`, icon: 'location_city', group: 'KATEGORIE', progress: category('PUBLICZNY') }, [3, 10, 20]),
  { id: 'all-categories', name: 'Wszechstronny', description: 'Odwiedź zabytek z każdego rodzaju.', icon: 'category', group: 'KATEGORIE', xp: 150, target: (t) => t.categories, progress: (s) => s.categoriesCovered },

  // ---------- Epoki ----------
  { id: 'era-medieval', name: 'Średniowieczny wędrowiec', description: 'Odwiedź 3 zabytki sprzed 1500 roku.', icon: 'shield', group: 'EPOKI', xp: 50, target: 3, progress: era('SREDNIOWIECZE') },
  { id: 'era-modern', name: 'Barok i renesans', description: 'Odwiedź 5 zabytków z lat 1500–1799.', icon: 'brush', group: 'EPOKI', xp: 50, target: 5, progress: era('NOWOZYTNOSC') },
  { id: 'era-19', name: 'Wiek pary', description: 'Odwiedź 5 zabytków z XIX wieku.', icon: 'train', group: 'EPOKI', xp: 50, target: 5, progress: era('WIEK_XIX') },
  { id: 'era-20', name: 'Modernista', description: 'Odwiedź 5 zabytków z lat 1900–1945.', icon: 'architecture', group: 'EPOKI', xp: 50, target: 5, progress: era('WIEK_XX') },
  { id: 'era-postwar', name: 'Powojenna odbudowa', description: 'Odwiedź 3 zabytki powstałe po 1945 roku.', icon: 'construction', group: 'EPOKI', xp: 50, target: 3, progress: era('POWOJENNE') },
  { id: 'before-1900', name: 'Sprzed 1900', description: 'Odwiedź 10 zabytków powstałych przed 1900 rokiem.', icon: 'hourglass_bottom', group: 'EPOKI', xp: 75, target: 10, progress: (s) => s.before1900 },
  { id: 'all-eras', name: 'Podróż w czasie', description: 'Odwiedź zabytek z każdej epoki.', icon: 'history', group: 'EPOKI', xp: 150, target: (t) => t.eras, progress: (s) => s.erasCovered },

  // ---------- Szlaki ----------
  { id: 'trail-tumski', name: 'Szlak Ostrowa Tumskiego', description: 'Archikatedra, kościół św. Idziego, Kolegiata i Most Tumski.', icon: 'route', group: 'SZLAKI', xp: 75, target: TRAIL_TUMSKI.length, progress: visitedAll(TRAIL_TUMSKI) },
  { id: 'trail-rynek', name: 'Serce Rynku', description: 'Ratusz, Nowy Ratusz, Pręgierz, Fontanna Niedźwiadek i Jaś i Małgosia.', icon: 'route', group: 'SZLAKI', xp: 75, target: TRAIL_RYNEK.length, progress: visitedAll(TRAIL_RYNEK) },
  { id: 'trail-bridges', name: 'Mosty Odry', description: 'Mosty Grunwaldzki, Tumski, Piaskowy, Oławski i Zwierzyniecki.', icon: 'route', group: 'SZLAKI', xp: 75, target: TRAIL_MOSTY.length, progress: visitedAll(TRAIL_MOSTY) },
  { id: 'trail-hala', name: 'Wokół Hali Stulecia', description: 'Hala Stulecia, Pawilon Czterech Kopuł, Pergola i Iglica.', icon: 'route', group: 'SZLAKI', xp: 75, target: TRAIL_HALA.length, progress: visitedAll(TRAIL_HALA) },
  { id: 'unesco', name: 'Światowe dziedzictwo', description: 'Odwiedź obiekt z listy UNESCO.', icon: 'public', group: 'SZLAKI', xp: 75, target: 1, progress: (s) => s.unescoVisited },

  // ---------- Aktywność ----------
  ...tiered({ id: 'reader', name: 'Mól książkowy', describe: (n) => `Przeczytaj na Wikipedii o ${n} różnych zabytkach.`, icon: 'menu_book', group: 'AKTYWNOSC', progress: (s) => s.wikipediaArticlesRead }, [1, 5, 20]),
  { id: 'marathon', name: 'Maraton', description: 'Odwiedź 5 zabytków jednego dnia.', icon: 'bolt', group: 'AKTYWNOSC', xp: 75, target: 5, progress: (s) => s.maxVisitsPerDay },
  { id: 'comment-1', name: 'Głos zabrany', description: 'Dodaj pierwszy komentarz pod zabytkiem.', icon: 'forum', group: 'AKTYWNOSC', xp: 50, target: 1, progress: (s) => s.commentsCount },
  { id: 'comment-10', name: 'Przewodnik forum', description: 'Dodaj 10 komentarzy pod zabytkami.', icon: 'forum', group: 'AKTYWNOSC', xp: 100, target: 10, progress: (s) => s.commentsCount },
  { id: 'friends-1', name: 'Pierwszy znajomy', description: 'Dodaj pierwszego znajomego.', icon: 'group', group: 'AKTYWNOSC', xp: 25, target: 1, progress: (s) => s.friendsCount },
  { id: 'friends-3', name: 'Towarzyski', description: 'Miej 3 znajomych w grze.', icon: 'group', group: 'AKTYWNOSC', xp: 75, target: 3, progress: (s) => s.friendsCount },
  { id: 'curator', name: 'Kurator', description: 'Wystaw 3 zabytki w swojej gablotce.', icon: 'collections', group: 'AKTYWNOSC', xp: 75, target: 3, progress: (s) => s.showcaseCount },

  // ---------- Sekretne ----------
  { id: 'night-owl', name: 'Nocny marek', description: 'Odwiedź zabytek między 22:00 a 4:00.', icon: 'nightlight', group: 'SEKRETNE', xp: 50, secret: true, target: 1, progress: (s) => s.nightVisits },
  { id: 'early-bird', name: 'Ranny ptaszek', description: 'Odwiedź zabytek między 5:00 a 7:00.', icon: 'wb_twilight', group: 'SEKRETNE', xp: 50, secret: true, target: 1, progress: (s) => s.morningVisits },
  { id: 'pillory', name: 'Pod pręgierzem', description: 'Stań pod wrocławskim pręgierzem.', icon: 'gavel', group: 'SEKRETNE', xp: 50, secret: true, target: 1, progress: (s) => (s.visitedExternalIds.has(PILLORY) ? 1 : 0) },
];

export const ACHIEVEMENT_BY_ID = new Map(ACHIEVEMENTS.map((a) => [a.id, a]));

export function resolveTarget(def: AchievementDefinition, totals: MonumentTotals) {
  return Math.max(1, typeof def.target === 'number' ? def.target : def.target(totals));
}
