import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';

/**
 * Krótkie opisy historyczne (#6) – streszczenia artykułów z polskiej Wikipedii.
 * Wyniki są cache'owane lokalnie, żeby ponowny import nie pytał API od nowa.
 * Licencja treści: CC BY-SA – w aplikacji pokazujemy źródło z linkiem.
 */

const USER_AGENT =
  'szwto-hackathon-import/1.0 (https://github.com/OlciXs/szwto)';
const CACHE_FILE = join(__dirname, '.cache', 'wikipedia-summaries.json');
const MAX_LENGTH = 700;
const CONCURRENCY = 2;
const MAX_ATTEMPTS = 5;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

type Cache = Record<string, string | null>;

function loadCache(): Cache {
  return existsSync(CACHE_FILE)
    ? (JSON.parse(readFileSync(CACHE_FILE, 'utf8')) as Cache)
    : {};
}

function saveCache(cache: Cache) {
  mkdirSync(dirname(CACHE_FILE), { recursive: true });
  writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 1));
}

/** Przycina tekst do pełnych zdań mieszczących się w limicie. */
function trimToSentences(text: string): string {
  const clean = text.replace(/\s+/g, ' ').trim();
  if (clean.length <= MAX_LENGTH) return clean;
  const cut = clean.slice(0, MAX_LENGTH);
  const lastDot = cut.lastIndexOf('. ');
  return lastDot > 200 ? cut.slice(0, lastDot + 1) : `${cut.trimEnd()}…`;
}

async function fetchSummary(title: string): Promise<string | null> {
  const url = `https://pl.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(
    title.replace(/ /g, '_'),
  )}`;
  for (let attempt = 1; ; attempt++) {
    const response = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
    if (response.status === 404) return null;
    if (response.status === 429 && attempt < MAX_ATTEMPTS) {
      // limit zapytań – czekamy coraz dłużej
      await sleep(2000 * attempt);
      continue;
    }
    if (!response.ok) throw new Error(`HTTP ${response.status} dla ${title}`);
    const json = (await response.json()) as { extract?: string; type?: string };
    if (json.type === 'disambiguation' || !json.extract) return null;
    return trimToSentences(json.extract);
  }
}

/** Zwraca mapę tytuł -> streszczenie (null, gdy brak). */
export async function fetchSummaries(
  titles: string[],
): Promise<Map<string, string | null>> {
  const cache = loadCache();
  const missing = [...new Set(titles)].filter((t) => !(t in cache));
  console.log(
    `  Wikipedia: ${titles.length - missing.length} z cache, ${missing.length} do pobrania`,
  );

  let done = 0;
  const queue = [...missing];
  const worker = async () => {
    for (let title = queue.shift(); title; title = queue.shift()) {
      try {
        cache[title] = await fetchSummary(title);
      } catch (error) {
        console.warn(`  Wikipedia: pominięto "${title}" (${(error as Error).message})`);
      }
      await sleep(150);
      if (++done % 50 === 0) {
        console.log(`  Wikipedia: ${done}/${missing.length}`);
        saveCache(cache);
      }
    }
  };
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  saveCache(cache);

  return new Map(titles.map((t) => [t, cache[t] ?? null]));
}
