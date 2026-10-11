import {
  Era,
  HeritageLevel,
  MonumentCategory,
  Rarity,
} from '@prisma/client';

/**
 * Atrybuty pochodne liczone RAZ przy imporcie. Z nich korzystają funkcje gry:
 *   era/builtYear  -> achievementy (#5), rarity (#2)
 *   category       -> XP (#1), achievementy (#5), filtry mapy
 *   rarity/xp      -> karty (#2), XP (#1), trudność w grze (#3)
 * Zmiana wzorów = ponowne uruchomienie `npm run import:wroclaw` i `npm run seed`.
 */

// ---------- Data powstania ----------

const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
  'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX', 'XXI'];

export interface BuiltInfo {
  builtYear: number | null;
  builtLabel: string | null;
}

/**
 * Wejście: wartości P571 "1861-01-01T00:00:00Z#9" (#precyzja Wikibase:
 * 7 = wiek, 8 = dekada, 9+ = rok). Bierzemy najwcześniejszą datę.
 * Wiek w Wikidata zapisany jest jako rok kończący wiek: 1300#7 = XIII wiek.
 */
export function parseBuilt(inceptions: string[]): BuiltInfo {
  const parsed = inceptions
    .map((value) => {
      const [date, precision] = value.split('#');
      const year = Number.parseInt(date, 10);
      return { year, precision: Number(precision) };
    })
    .filter((v) => Number.isFinite(v.year) && v.year > 900 && v.year < 2100)
    .map(({ year, precision }) => {
      if (precision <= 7) {
        const century = year % 100 === 0 ? year / 100 : Math.floor(year / 100) + 1;
        return {
          // środek wieku – do porównań typu "sprzed 1900"
          year: (century - 1) * 100 + 50,
          label: `${ROMAN[century - 1] ?? century} wiek`,
        };
      }
      if (precision === 8) {
        const decade = Math.floor(year / 10) * 10;
        return { year: decade + 5, label: `lata ${decade}.` };
      }
      return { year, label: `${year} r.` };
    })
    .sort((a, b) => a.year - b.year);

  const first = parsed[0];
  return first
    ? { builtYear: first.year, builtLabel: first.label }
    : { builtYear: null, builtLabel: null };
}

export function eraFor(year: number | null): Era | null {
  if (year === null) return null;
  if (year < 1500) return Era.SREDNIOWIECZE;
  if (year < 1800) return Era.NOWOZYTNOSC;
  if (year < 1900) return Era.WIEK_XIX;
  if (year < 1946) return Era.WIEK_XX;
  return Era.POWOJENNE;
}

// ---------- Forma ochrony ----------

const HERITAGE_BY_QID: Record<string, HeritageLevel> = {
  Q9259: HeritageLevel.UNESCO, // światowe dziedzictwo UNESCO
  Q15981101: HeritageLevel.POMNIK_HISTORII,
  Q29940414: HeritageLevel.REJESTR, // wojewódzki zabytek nieruchomy w Polsce
  Q21438156: HeritageLevel.REJESTR, // ochrona zabytków w Polsce
  Q56337681: HeritageLevel.EWIDENCJA, // gminny zabytek nieruchomy
  Q25406836: HeritageLevel.EWIDENCJA, // wojewódzka ewidencja zabytków
  Q116959328: HeritageLevel.EWIDENCJA, // dobra kultury współczesnej we Wrocławiu
};

const HERITAGE_ORDER: HeritageLevel[] = [
  HeritageLevel.UNESCO,
  HeritageLevel.POMNIK_HISTORII,
  HeritageLevel.REJESTR,
  HeritageLevel.EWIDENCJA,
];

export function heritageLevelFor(qids: string[]): HeritageLevel {
  const levels = new Set(qids.map((q) => HERITAGE_BY_QID[q]).filter(Boolean));
  return HERITAGE_ORDER.find((level) => levels.has(level)) ?? HeritageLevel.BRAK;
}

// ---------- Rarity ----------

const HERITAGE_SCORE: Record<HeritageLevel, number> = {
  UNESCO: 8,
  POMNIK_HISTORII: 5,
  REJESTR: 1,
  EWIDENCJA: 0,
  BRAK: 0,
};

const CATEGORY_SCORE: Partial<Record<MonumentCategory, number>> = {
  SAKRALNY: 1,
  PALAC: 1,
  MOST: 1,
};

export interface RarityInput {
  heritageLevel: HeritageLevel;
  builtYear: number | null;
  fame: number;
  category: MonumentCategory;
  hasWikipedia: boolean;
}

export function rarityScore(m: RarityInput): number {
  const year = m.builtYear;
  const age =
    year === null ? 0 : year < 1400 ? 4 : year < 1600 ? 3 : year < 1800 ? 2 : year < 1900 ? 1 : 0;
  return (
    HERITAGE_SCORE[m.heritageLevel] +
    age +
    Math.log2(1 + m.fame) * 1.5 +
    (CATEGORY_SCORE[m.category] ?? 0) +
    (m.hasWikipedia ? 1 : 0)
  );
}

/** Udział (od góry rankingu) poszczególnych poziomów rzadkości. */
const RARITY_SHARES: [Rarity, number][] = [
  [Rarity.LEGENDARY, 0.03],
  [Rarity.EPIC, 0.09],
  [Rarity.RARE, 0.23],
];

/** Przydziela rarity wg percentyli wyniku – rozkład jest stały niezależnie od danych. */
export function assignRarities<T extends RarityInput & { externalId: string }>(
  items: T[],
): Map<string, Rarity> {
  const ranked = [...items].sort(
    (a, b) =>
      rarityScore(b) - rarityScore(a) ||
      b.fame - a.fame ||
      a.externalId.localeCompare(b.externalId),
  );
  const result = new Map<string, Rarity>();
  let index = 0;
  for (const [rarity, share] of RARITY_SHARES) {
    const end = index + Math.round(items.length * share);
    for (; index < end && index < ranked.length; index++) {
      result.set(ranked[index].externalId, rarity);
    }
  }
  for (; index < ranked.length; index++) {
    result.set(ranked[index].externalId, Rarity.COMMON);
  }
  // Obiekty UNESCO zawsze legendarne
  for (const item of items) {
    if (item.heritageLevel === HeritageLevel.UNESCO) {
      result.set(item.externalId, Rarity.LEGENDARY);
    }
  }
  return result;
}

// ---------- Zabytki główne / ukryte perełki ----------

/**
 * Główne zabytki (Major POI) są zawsze widoczne na mapie; pozostałe to ukryte
 * perełki, które pojawiają się dopiero w zasięgu gracza (aplikacja).
 */
export function isMajorRarity(rarity: Rarity): boolean {
  return rarity === Rarity.LEGENDARY || rarity === Rarity.EPIC;
}

// ---------- XP (#1) ----------

export const RARITY_XP: Record<Rarity, number> = {
  COMMON: 10,
  RARE: 25,
  EPIC: 60,
  LEGENDARY: 150,
};

/** Premia za typ obiektu (issue #1: "exp za rzeźby i inne rodzaje zabytków"). */
export const CATEGORY_XP_BONUS: Partial<Record<MonumentCategory, number>> = {
  RZEZBA: 5,
  POMNIK: 5,
  MOST: 5,
};

export function xpFor(rarity: Rarity, category: MonumentCategory): number {
  return RARITY_XP[rarity] + (CATEGORY_XP_BONUS[category] ?? 0);
}

// ---------- Promień odwiedzin ----------

const CATEGORY_RADIUS: Record<MonumentCategory, number> = {
  KAMIENICA: 40,
  PALAC: 75,
  SAKRALNY: 75,
  MOST: 75,
  POMNIK: 40,
  RZEZBA: 40,
  PARK: 150,
  PUBLICZNY: 75,
  TECHNICZNY: 75,
  ARCHITEKTURA: 50,
};

const HUGE_AREA = /układ urbanistyczny|stare miasto|port lotniczy|osiedle|wielki zespół|ogród zoologiczny/;
const LARGE_AREA = /zespół|kompleks|park|ogród|cmentarz|stadion|esplanada|aleja|plac|rynek|ulica|centrum/;

/** Duże obiekty mają współrzędne środka – 50 m od środka bywa nieosiągalne. */
export function visitRadiusFor(category: MonumentCategory, typeLabels: string[]): number {
  const base = CATEGORY_RADIUS[category];
  if (typeLabels.some((t) => HUGE_AREA.test(t))) return Math.max(base, 400);
  if (typeLabels.some((t) => LARGE_AREA.test(t))) return Math.max(base, 200);
  return base;
}

// ---------- Opis zastępczy ----------

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

export function generatedDescription(m: {
  rawType: string | null;
  address: string | null;
  builtLabel: string | null;
  heritageLevel: HeritageLevel;
  registerNumber: string | null;
}): string {
  const parts: string[] = [];
  const type = m.rawType ? capitalize(m.rawType) : 'Obiekt zabytkowy';
  parts.push(`${type} we Wrocławiu${m.address ? `, ${m.address}` : ''}.`);
  if (m.builtLabel) {
    parts.push(`Powstanie: ${m.builtLabel}${m.builtLabel.endsWith('.') ? '' : '.'}`);
  }
  switch (m.heritageLevel) {
    case HeritageLevel.UNESCO:
      parts.push('Obiekt z listy światowego dziedzictwa UNESCO.');
      break;
    case HeritageLevel.POMNIK_HISTORII:
      parts.push('Obiekt uznany za pomnik historii.');
      break;
    case HeritageLevel.REJESTR:
      parts.push(
        `Obiekt wpisany do rejestru zabytków${m.registerNumber ? ` (nr ${m.registerNumber})` : ''}.`,
      );
      break;
    case HeritageLevel.EWIDENCJA:
      parts.push('Obiekt ujęty w ewidencji zabytków.');
      break;
  }
  return parts.join(' ');
}
