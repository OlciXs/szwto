/**
 * Buduje snapshot zabytków Wrocławia: Wikidata -> wzbogacenie -> JSON w repo.
 *
 *   npm run import:wroclaw     (potem: npm run seed)
 *
 * Wynik: prisma/data/monuments.wroclaw.json
 */
import { mkdirSync, writeFileSync } from 'fs';
import { dirname } from 'path';
import { MonumentCategory, MonumentSource, Rarity } from '@prisma/client';
import { categorize, isExcluded } from './category-map';
import {
  assignRarities,
  eraFor,
  generatedDescription,
  generatedFunFact,
  heritageLevelFor,
  isMajorRarity,
  parseBuilt,
  visitRadiusFor,
  xpFor,
} from './enrich';
import { Snapshot, SNAPSHOT_PATH, SnapshotMonument } from '../../src/database/snapshot';
import {
  fetchDetails,
  fetchHeritageIds,
  fetchSculptureIds,
  WikidataItem,
} from './wikidata';
import { fetchArticles } from './wikipedia';

const CITY = 'Wrocław';

/**
 * Nazwa wyświetlana = tytuł artykułu z Wikipedii (bez „we Wrocławiu”).
 * Etykiety z Wikidata bywają rejestrowe („Rynek 15”, „Kamienica”, „D. dom handlowy”),
 * a tytuł artykułu to właściwa nazwa („Kamienica Pod Złotym Koszykiem”).
 */
function displayNameFor(item: WikidataItem & { wikipediaTitle: string }): string {
  return item.wikipediaTitle
    .replace(/_/g, ' ')
    .replace(/\s+we Wrocławiu(?=$|\s*\()/, '')
    .replace(/\s*\(Wrocław\)$/, '')
    .trim();
}

const distanceMeters = (
  a: { latitude: number; longitude: number },
  b: { latitude: number; longitude: number },
) =>
  Math.hypot(
    (a.latitude - b.latitude) * 111_320,
    (a.longitude - b.longitude) * 111_320 * Math.cos((a.latitude * Math.PI) / 180),
  );

/**
 * Zabezpieczenie przed duplikatami: ten sam artykuł Wikipedii albo ta sama nazwa
 * w promieniu 150 m. Zostaje obiekt bardziej rozpoznawalny (więcej Wikipedii).
 */
/** Rzadkie kamienice zostają tylko z porządnym opisem z Wikipedii (znaki). */
const TENEMENT_MIN_DESCRIPTION = 900;
/** …i gdy w promieniu tylu metrów nie ma już innej zachowanej kamienicy. */
const TENEMENT_MIN_DISTANCE = 80;

/**
 * Decyzja zespołu: kamienice stały „w rzędzie” i zaśmiecały mapę. Zostają:
 *  - epickie i legendarne,
 *  - rzadkie z bogatym opisem, które nie sąsiadują z inną zachowaną kamienicą.
 * Pospolite kamienice odpadają.
 */
function pruneTenements<
  T extends {
    category: MonumentCategory;
    externalId: string;
    fame: number;
    item: { latitude: number; longitude: number };
    article: { description: string } | null;
  },
>(items: T[], rarities: Map<string, Rarity>, onSkip: () => void): T[] {
  const others = items.filter((m) => m.category !== MonumentCategory.KAMIENICA);
  const tenements = items.filter((m) => m.category === MonumentCategory.KAMIENICA);
  const rarityOf = (m: T) => rarities.get(m.externalId)!;

  const keptTenements = tenements.filter(
    (m) => rarityOf(m) === Rarity.EPIC || rarityOf(m) === Rarity.LEGENDARY,
  );
  const candidates = tenements
    .filter(
      (m) =>
        rarityOf(m) === Rarity.RARE &&
        (m.article?.description.length ?? 0) >= TENEMENT_MIN_DESCRIPTION,
    )
    .sort(
      (a, b) =>
        b.fame - a.fame ||
        (b.article?.description.length ?? 0) - (a.article?.description.length ?? 0),
    );
  for (const m of candidates) {
    const tooClose = keptTenements.some(
      (k) => distanceMeters(k.item, m.item) < TENEMENT_MIN_DISTANCE,
    );
    if (!tooClose) keptTenements.push(m);
  }

  const keptIds = new Set(keptTenements.map((m) => m.externalId));
  tenements.filter((m) => !keptIds.has(m.externalId)).forEach(onSkip);
  return [...others, ...keptTenements];
}

function removeDuplicates<T extends WikidataItem & { wikipediaTitle: string }>(
  items: T[],
  onDuplicate: () => void,
): T[] {
  const sorted = [...items].sort((a, b) => b.sitelinks - a.sitelinks);
  const kept: T[] = [];
  for (const item of sorted) {
    const name = displayNameFor(item).toLowerCase();
    const duplicate = kept.some(
      (k) =>
        k.wikipediaTitle === item.wikipediaTitle ||
        (displayNameFor(k).toLowerCase() === name && distanceMeters(k, item) < 150),
    );
    if (duplicate) onDuplicate();
    else kept.push(item);
  }
  return kept;
}

function countBy<T>(items: T[], key: (item: T) => string | null | undefined) {
  const counts: Record<string, number> = {};
  for (const item of items) {
    const k = key(item) ?? '—';
    counts[k] = (counts[k] ?? 0) + 1;
  }
  return Object.fromEntries(Object.entries(counts).sort((a, b) => b[1] - a[1]));
}

async function main() {
  console.log('1/4 Pobieranie identyfikatorów z Wikidata…');
  const heritageIds = await fetchHeritageIds();
  const sculptureIds = await fetchSculptureIds();
  const ids = [...new Set([...heritageIds, ...sculptureIds])];
  console.log(
    `  zabytki rejestrowe: ${heritageIds.length}, pomniki/rzeźby: ${sculptureIds.length}, razem: ${ids.length}`,
  );

  console.log('2/4 Pobieranie szczegółów…');
  const raw = await fetchDetails(ids);

  const skipped: Record<string, number> = {};
  const skip = (reason: string) => (skipped[reason] = (skipped[reason] ?? 0) + 1);

  const filtered = raw.filter(
    (item): item is WikidataItem & { wikipediaTitle: string } => {
      if (item.demolished) return skip('wyburzony (P576)'), false;
      // Decyzja zespołu: tylko obiekty z artykułem na polskiej Wikipedii –
      // odpadają anonimowe kamienice/oficyny i rekordy-duplikaty z rejestru.
      if (!item.wikipediaTitle) return skip('brak artykułu na pl.wikipedii'), false;
      if (isExcluded(item.name ?? '', item.typeLabels)) return skip('wykluczony typ'), false;
      return true;
    },
  );
  const kept = removeDuplicates(filtered, () => skip('duplikat'));

  console.log('3/4 Opisy z Wikipedii…');
  const articles = await fetchArticles(kept.map((i) => i.wikipediaTitle));

  console.log('4/4 Wzbogacanie danych…');
  const base = kept.map((item) => {
    const name = displayNameFor(item);
    const { category, rawType } = categorize(item.typeLabels, name);
    const { builtYear, builtLabel } = parseBuilt(item.inceptions);
    const heritageLevel = heritageLevelFor(item.heritageQids);
    return {
      item,
      name,
      externalId: `wd:${item.qid}`,
      category,
      rawType,
      builtYear,
      builtLabel,
      heritageLevel,
      fame: item.sitelinks,
      hasWikipedia: true,
      article: articles.get(item.wikipediaTitle) ?? null,
    };
  });

  // Rzadkość liczymy na pełnym zbiorze – usunięcie kamienic nie zmienia,
  // które zabytki są legendarne/epickie.
  const rarities = assignRarities(base);
  const pruned = pruneTenements(base, rarities, () => skip('kamienica (mało istotna)'));

  const monuments: SnapshotMonument[] = pruned
    .map((m) => {
      const rarity = rarities.get(m.externalId)!;
      const generated = generatedDescription({
        rawType: m.rawType,
        address: m.item.address,
        builtLabel: m.builtLabel,
        heritageLevel: m.heritageLevel,
        registerNumber: m.item.registerNumber,
      });
      return {
        externalId: m.externalId,
        source: MonumentSource.WIKIDATA,
        name: m.name,
        summary: m.article?.summary ?? generated,
        description: m.article?.description ?? generated,
        funFact:
          m.article?.funFact ??
          generatedFunFact({
            builtYear: m.builtYear,
            builtLabel: m.builtLabel,
            fame: m.fame,
            heritageLevel: m.heritageLevel,
          }),
        descriptionSource: m.article ? 'wikipedia' : 'generated',
        isMajor: isMajorRarity(rarity),
        category: m.category,
        rawType: m.rawType,
        latitude: m.item.latitude,
        longitude: m.item.longitude,
        city: CITY,
        address: m.item.address,
        imageFile: m.item.imageFile,
        builtYear: m.builtYear,
        builtLabel: m.builtLabel,
        era: eraFor(m.builtYear),
        registerNumber: m.item.registerNumber,
        heritageLevel: m.heritageLevel,
        fame: m.fame,
        wikipediaUrl: m.item.wikipediaUrl,
        rarity,
        xp: xpFor(rarity, m.category),
        visitRadius: visitRadiusFor(m.category, m.item.typeLabels),
      };
    })
    .sort((a, b) => a.externalId.localeCompare(b.externalId));

  const snapshot: Snapshot = {
    generatedAt: new Date().toISOString(),
    city: CITY,
    sources: ['Wikidata (CC0)', 'Wikipedia (CC BY-SA 4.0)'],
    license:
      'Dane: Wikidata CC0. Opisy z Wikipedii: CC BY-SA 4.0. Zdjęcia: Wikimedia Commons (licencja każdego pliku osobno).',
    count: monuments.length,
    monuments,
  };

  mkdirSync(dirname(SNAPSHOT_PATH), { recursive: true });
  writeFileSync(SNAPSHOT_PATH, JSON.stringify(snapshot, null, 1));

  console.log(`\nZapisano ${monuments.length} zabytków -> ${SNAPSHOT_PATH}`);
  console.log('Pominięte:', skipped);
  console.log('Kategorie:', countBy(monuments, (m) => m.category));
  console.log('Rarity:', countBy(monuments, (m) => m.rarity));
  console.log('Epoki:', countBy(monuments, (m) => m.era));
  console.log(
    `Ciekawostki: ${monuments.filter((m) => m.funFact).length}/${monuments.length}`,
  );
  const fromWiki = monuments.filter((m) => m.descriptionSource === 'wikipedia');
  const avgLength = Math.round(
    fromWiki.reduce((sum, m) => sum + (m.description?.length ?? 0), 0) /
      Math.max(1, fromWiki.length),
  );
  console.log(
    `Główne (zawsze widoczne): ${monuments.filter((m) => m.isMajor).length}, ukryte perełki: ${
      monuments.filter((m) => !m.isMajor).length
    }`,
  );
  console.log(
    `Ze zdjęciem: ${monuments.filter((m) => m.imageFile).length}, z opisem z Wikipedii: ${
      fromWiki.length
    } (średnio ${avgLength} znaków)`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
