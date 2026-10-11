/**
 * Pobieranie danych o zabytkach z Wikidata (SPARQL).
 *
 * Duże zapytanie z UNION + P279* przekracza limit czasu WDQS, dlatego:
 *   1) pobieramy tanie listy identyfikatorów (zabytki rejestrowe + pomniki/rzeźby),
 *   2) szczegóły dociągamy paczkami przez VALUES.
 */

const ENDPOINT = 'https://query.wikidata.org/sparql';
const USER_AGENT =
  'szwto-hackathon-import/1.0 (https://github.com/OlciXs/szwto)';

/** Wrocław */
export const CITY_QID = 'Q1799';

/** Klasy obiektów, które importujemy nawet bez formy ochrony zabytków. */
const SCULPTURE_CLASSES = [
  'Q4989906', // pomnik
  'Q860861', // rzeźba
  'Q179700', // posąg
  'Q575759', // pomnik wojenny
];

const DETAILS_BATCH_SIZE = 150;

export interface WikidataItem {
  qid: string;
  name: string | null;
  description: string | null;
  latitude: number;
  longitude: number;
  imageFile: string | null;
  /** Wartości P571 w formacie "<data>#<precyzja>" */
  inceptions: string[];
  registerNumber: string | null;
  address: string | null;
  sitelinks: number;
  wikipediaTitle: string | null;
  wikipediaUrl: string | null;
  typeLabels: string[];
  heritageQids: string[];
  demolished: boolean;
}

type Binding = Record<string, { type: string; value: string } | undefined>;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function sparql(query: string, attempts = 4): Promise<Binding[]> {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      const response = await fetch(ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          Accept: 'application/sparql-results+json',
          'User-Agent': USER_AGENT,
        },
        body: new URLSearchParams({ query }).toString(),
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const json = (await response.json()) as {
        results: { bindings: Binding[] };
      };
      return json.results.bindings;
    } catch (error) {
      if (attempt === attempts) throw error;
      const wait = 2000 * attempt;
      console.warn(
        `  Wikidata: próba ${attempt} nieudana (${(error as Error).message}), ponawiam za ${wait / 1000}s`,
      );
      await sleep(wait);
    }
  }
  throw new Error('unreachable');
}

const qidOf = (uri: string) => uri.substring(uri.lastIndexOf('/') + 1);

async function fetchIds(query: string): Promise<string[]> {
  const rows = await sparql(query);
  return rows.map((row) => qidOf(row.item!.value));
}

/** Obiekty z formą ochrony (P1435) położone we Wrocławiu i mające współrzędne. */
export function fetchHeritageIds() {
  return fetchIds(`
    SELECT DISTINCT ?item WHERE {
      ?item wdt:P131* wd:${CITY_QID}; wdt:P1435 []; wdt:P625 [] .
    }`);
}

/** Pomniki, rzeźby i posągi we Wrocławiu (również niewpisane do rejestru). */
export function fetchSculptureIds() {
  const classes = SCULPTURE_CLASSES.map((q) => `wd:${q}`).join(' ');
  return fetchIds(`
    SELECT DISTINCT ?item WHERE {
      VALUES ?cls { ${classes} }
      ?item wdt:P31/wdt:P279* ?cls; wdt:P131* wd:${CITY_QID}; wdt:P625 [] .
    }`);
}

function detailsQuery(qids: string[]) {
  const values = qids.map((q) => `wd:${q}`).join(' ');
  return `
    SELECT ?item
      (SAMPLE(?name_) AS ?name)
      (SAMPLE(?desc_) AS ?desc)
      (SAMPLE(?coord_) AS ?coord)
      (SAMPLE(?image_) AS ?image)
      (SAMPLE(?register_) AS ?register)
      (SAMPLE(?address_) AS ?address)
      (SAMPLE(?sitelinks_) AS ?sitelinks)
      (SAMPLE(?article_) AS ?article)
      (SAMPLE(?demolished_) AS ?demolished)
      (GROUP_CONCAT(DISTINCT CONCAT(STR(?inc_), "#", STR(?incPrec_)); separator="|") AS ?inceptions)
      (GROUP_CONCAT(DISTINCT ?typeLabel_; separator="|") AS ?types)
      (GROUP_CONCAT(DISTINCT STR(?heritage_); separator="|") AS ?heritage)
    WHERE {
      VALUES ?item { ${values} }
      ?item wdt:P625 ?coord_ ; wikibase:sitelinks ?sitelinks_ .
      OPTIONAL { ?item rdfs:label ?name_ FILTER(LANG(?name_) = "pl") }
      OPTIONAL { ?item schema:description ?desc_ FILTER(LANG(?desc_) = "pl") }
      OPTIONAL { ?item wdt:P18 ?image_ }
      OPTIONAL { ?item wdt:P3424 ?register_ }
      OPTIONAL { ?item wdt:P6375 ?address_ }
      OPTIONAL { ?item wdt:P576 ?demolished_ }
      OPTIONAL {
        ?item p:P571/psv:P571 ?incNode .
        ?incNode wikibase:timeValue ?inc_ ; wikibase:timePrecision ?incPrec_ .
      }
      OPTIONAL {
        ?item wdt:P31 ?type_ .
        ?type_ rdfs:label ?typeLabel_ FILTER(LANG(?typeLabel_) = "pl")
      }
      OPTIONAL { ?item wdt:P1435 ?heritage_ }
      OPTIONAL {
        ?article_ schema:about ?item ;
                  schema:isPartOf <https://pl.wikipedia.org/> .
      }
    }
    GROUP BY ?item`;
}

/** "Point(17.0398 51.1135)" -> [lng, lat] */
function parsePoint(wkt: string): [number, number] | null {
  const match = /Point\(([-\d.]+) ([-\d.]+)\)/.exec(wkt);
  return match ? [Number(match[1]), Number(match[2])] : null;
}

const split = (value?: string) =>
  value ? value.split('|').filter((v) => v.length > 0) : [];

function parseItem(row: Binding): WikidataItem | null {
  const point = row.coord ? parsePoint(row.coord.value) : null;
  if (!point) return null;

  const image = row.image?.value;
  // tytuł może zawierać "/" (np. "Rynek 11/12"), więc bierzemy wszystko po "/wiki/";
  // linki do stron kategorii pomijamy
  const articleRaw = row.article?.value;
  const article =
    articleRaw && !articleRaw.includes('/wiki/Kategoria:') ? articleRaw : undefined;

  return {
    qid: qidOf(row.item!.value),
    name: row.name?.value ?? null,
    description: row.desc?.value ?? null,
    longitude: point[0],
    latitude: point[1],
    imageFile: image
      ? decodeURIComponent(image.substring(image.lastIndexOf('/') + 1))
      : null,
    inceptions: split(row.inceptions?.value),
    registerNumber: row.register?.value ?? null,
    address: row.address?.value ?? null,
    sitelinks: Number(row.sitelinks?.value ?? 0),
    wikipediaUrl: article ?? null,
    wikipediaTitle: article
      ? decodeURIComponent(article.substring(article.indexOf('/wiki/') + 6))
      : null,
    typeLabels: split(row.types?.value),
    heritageQids: split(row.heritage?.value).map(qidOf),
    demolished: row.demolished !== undefined,
  };
}

export async function fetchDetails(qids: string[]): Promise<WikidataItem[]> {
  const items: WikidataItem[] = [];
  for (let i = 0; i < qids.length; i += DETAILS_BATCH_SIZE) {
    const batch = qids.slice(i, i + DETAILS_BATCH_SIZE);
    const rows = await sparql(detailsQuery(batch));
    for (const row of rows) {
      const item = parseItem(row);
      if (item) items.push(item);
    }
    console.log(
      `  szczegóły: ${Math.min(i + DETAILS_BATCH_SIZE, qids.length)}/${qids.length}`,
    );
    await sleep(500); // grzecznie wobec WDQS
  }
  return items;
}
