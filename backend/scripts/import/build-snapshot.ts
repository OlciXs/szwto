/**
 * Buduje snapshot zabytków Wrocławia: Wikidata -> wzbogacenie -> JSON w repo.
 *
 *   npm run import:wroclaw     (potem: npm run seed)
 *
 * Wynik: prisma/data/monuments.wroclaw.json
 */
import { mkdirSync, writeFileSync } from 'fs';
import { dirname } from 'path';
import { MonumentSource } from '@prisma/client';
import { categorize, isExcluded } from './category-map';
import {
  assignRarities,
  eraFor,
  generatedDescription,
  heritageLevelFor,
  parseBuilt,
  visitRadiusFor,
  xpFor,
} from './enrich';
import { Snapshot, SNAPSHOT_PATH, SnapshotMonument } from './snapshot';
import {
  fetchDetails,
  fetchHeritageIds,
  fetchSculptureIds,
  WikidataItem,
} from './wikidata';
import { fetchSummaries } from './wikipedia';

const CITY = 'Wrocław';

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

  const kept = raw.filter((item): item is WikidataItem & { name: string } => {
    if (!item.name) return skip('brak polskiej nazwy'), false;
    if (item.demolished) return skip('wyburzony (P576)'), false;
    if (isExcluded(item.name, item.typeLabels)) return skip('wykluczony typ'), false;
    return true;
  });

  console.log('3/4 Opisy z Wikipedii…');
  const summaries = await fetchSummaries(
    kept.map((i) => i.wikipediaTitle).filter((t): t is string => t !== null),
  );

  console.log('4/4 Wzbogacanie danych…');
  const base = kept.map((item) => {
    const { category, rawType } = categorize(item.typeLabels, item.name);
    const { builtYear, builtLabel } = parseBuilt(item.inceptions);
    const heritageLevel = heritageLevelFor(item.heritageQids);
    const summary = item.wikipediaTitle
      ? summaries.get(item.wikipediaTitle) ?? null
      : null;
    return {
      item,
      externalId: `wd:${item.qid}`,
      category,
      rawType,
      builtYear,
      builtLabel,
      heritageLevel,
      fame: item.sitelinks,
      hasWikipedia: item.wikipediaUrl !== null,
      summary,
    };
  });

  const rarities = assignRarities(base);

  const monuments: SnapshotMonument[] = base
    .map((m) => {
      const rarity = rarities.get(m.externalId)!;
      return {
        externalId: m.externalId,
        source: MonumentSource.WIKIDATA,
        name: m.item.name!,
        description:
          m.summary ??
          generatedDescription({
            rawType: m.rawType,
            address: m.item.address,
            builtLabel: m.builtLabel,
            heritageLevel: m.heritageLevel,
            registerNumber: m.item.registerNumber,
          }),
        descriptionSource: m.summary ? 'wikipedia' : 'generated',
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
    `Ze zdjęciem: ${monuments.filter((m) => m.imageFile).length}, z opisem z Wikipedii: ${
      monuments.filter((m) => m.descriptionSource === 'wikipedia').length
    }`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
