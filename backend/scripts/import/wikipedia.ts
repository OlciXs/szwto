import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';

/**
 * Opisy zabytków z polskiej Wikipedii (#6 + edukacyjny charakter gry):
 *   - summary:     1–2 zdania – zajawka widoczna przed wizytą,
 *   - description: wstęp, sekcje historyczne, potem pozostałe (do 6000 znaków, akapity) – po wizycie.
 * Pełne teksty artykułów są cache'owane lokalnie (.cache/), więc zmiana sposobu
 * cięcia tekstu nie wymaga ponownego pobierania.
 * Licencja treści: CC BY-SA 4.0 – w aplikacji pokazujemy źródło z linkiem.
 */

const USER_AGENT =
  'szwto-hackathon-import/1.0 (https://github.com/OlciXs/szwto)';
const API = 'https://pl.wikipedia.org/w/api.php';
const CACHE_FILE = join(__dirname, '.cache', 'wikipedia-articles.json');
const CONCURRENCY = 2;
const MAX_ATTEMPTS = 5;

const SUMMARY_MAX = 300;
/** Decyzja zespołu: zwięźle – maks. 5 akapitów (~2 min czytania). */
const DESCRIPTION_MAX_PARAGRAPHS = 5;
const DESCRIPTION_MAX = 3500;
const FUN_FACT_MAX = 320;

/**
 * Słowa zapowiadające ciekawostkę (waga). Zdanie z najwyższym wynikiem,
 * spoza opisu, zostaje „ciekawostką” przy zabytku.
 */
const FUN_FACT_HINTS: [RegExp, number][] = [
  [/legend|podobno|według podań|mówi się|przesąd|klątw|duch/i, 4],
  [/najstarsz|największ|najwyższ|najdłuższ|najcenniejsz|najmniejsz|najpiękniejsz/i, 4],
  [/jedyn[ayoe]|unikat|rekord|pierwsz[ayoe] w|pierwszy raz/i, 3],
  [/ciekawostk|zaskakuj|nietypow|osobliw|tajemnic|zagadk|skarb|ukryt/i, 3],
  [/film|serial|kręcono|piosenk|powieś|poet|pisarz|malarz|kompozytor/i, 2],
  [/nazywan|przezwisk|potoczn|zwan[aeyo]/i, 2],
  [/wojn|oblężeni|bombardowa|powódź|pożar/i, 1],
];

/** Sekcje opowiadające historię obiektu – trafiają do opisu w pierwszej kolejności. */
const HISTORY_SECTION = /histori|dzieje|budow|powstan|losy|po 1945|okres|czasy|wiek/i;
/** Sekcje, których nigdy nie bierzemy. */
const SKIPPED_SECTION =
  /zobacz też|przypisy|bibliografia|linki zewnętrzne|uwagi|galeria|literatura|źródła|filmografia/i;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

type Cache = Record<string, string | null>;

export interface ArticleText {
  summary: string;
  description: string;
  /** Zdanie-ciekawostka spoza opisu (null, gdy nic nie pasuje). */
  funFact: string | null;
}

// ---------- Cache ----------

function loadCache(): Cache {
  return existsSync(CACHE_FILE)
    ? (JSON.parse(readFileSync(CACHE_FILE, 'utf8')) as Cache)
    : {};
}

function saveCache(cache: Cache) {
  mkdirSync(dirname(CACHE_FILE), { recursive: true });
  writeFileSync(CACHE_FILE, JSON.stringify(cache));
}

// ---------- Pobieranie ----------

/** Pełny tekst artykułu (bez wikikodu, z nagłówkami "== Sekcja =="). */
async function fetchExtract(title: string): Promise<string | null> {
  const params = new URLSearchParams({
    action: 'query',
    prop: 'extracts',
    explaintext: '1',
    exsectionformat: 'wiki',
    redirects: '1',
    format: 'json',
    formatversion: '2',
    titles: title,
  });
  for (let attempt = 1; ; attempt++) {
    const response = await fetch(`${API}?${params}`, {
      headers: { 'User-Agent': USER_AGENT },
    });
    if (response.status === 429 && attempt < MAX_ATTEMPTS) {
      await sleep(2000 * attempt);
      continue;
    }
    if (!response.ok) throw new Error(`HTTP ${response.status} dla ${title}`);
    const json = (await response.json()) as {
      query?: { pages?: { extract?: string; missing?: boolean }[] };
    };
    const page = json.query?.pages?.[0];
    return page && !page.missing && page.extract ? page.extract : null;
  }
}

// ---------- Cięcie tekstu ----------

/** Skróty, po których kropka NIE kończy zdania. */
const ABBREVIATIONS = new Set([
  'św', 'ul', 'r', 'w', 'wg', 'tzw', 'in', 'pl', 'al', 'dr', 'prof', 'ok',
  'im', 'ks', 'nr', 's', 'zm', 'ur', 'bp', 'abp', 'gen', 'płk', 'tj', 'np',
]);

/** Indeksy końców zdań (pozycja tuż za kropką/!/?). */
function sentenceEnds(text: string): number[] {
  const ends: number[] = [];
  const pattern = /[.!?](?=\s+[A-ZĄĆĘŁŃÓŚŹŻ0-9„"(])/g;
  for (let m = pattern.exec(text); m; m = pattern.exec(text)) {
    const before = text.slice(0, m.index).split(/\s+/).pop() ?? '';
    const word = before.replace(/^.*[.(]/, '').toLowerCase();
    if (m[0] === '.' && (ABBREVIATIONS.has(word) || /^[IVXLC]+$/.test(before))) {
      continue; // "św. Jana", "XIV w. Budowla", "XIV. wiek"
    }
    ends.push(m.index + 1);
  }
  return ends;
}

/** Przycina tekst do pełnych zdań mieszczących się w limicie. */
function cutToSentences(text: string, max: number): string {
  if (text.length <= max) return text;
  const fitting = sentenceEnds(text).filter((end) => end <= max);
  const end = fitting.pop();
  return end && end > max * 0.35 ? text.slice(0, end) : `${text.slice(0, max).trimEnd()}…`;
}

interface Section {
  title: string;
  level: number;
  paragraphs: string[];
}

function splitSections(extract: string): { lead: string[]; sections: Section[] } {
  const lead: string[] = [];
  const sections: Section[] = [];
  let current: Section | null = null;

  for (const rawLine of extract.split('\n')) {
    const line = rawLine.replace(/\s+/g, ' ').trim();
    if (!line) continue;
    const heading = /^(=+)\s*(.+?)\s*=+$/.exec(line);
    if (heading) {
      current = { title: heading[2], level: heading[1].length, paragraphs: [] };
      sections.push(current);
    } else if (current) {
      current.paragraphs.push(line);
    } else {
      lead.push(line);
    }
  }
  return { lead, sections };
}

/**
 * Grupuje podsekcje pod sekcjami najwyższego poziomu (==), żeby decyzja
 * „bierzemy / pomijamy” dotyczyła całego rozdziału (np. Historia z podrozdziałami).
 */
function topLevelChapters(sections: Section[]): { title: string; paragraphs: string[] }[] {
  const chapters: { title: string; paragraphs: string[] }[] = [];
  for (const section of sections) {
    if (section.level <= 2 || chapters.length === 0) {
      chapters.push({ title: section.title, paragraphs: [...section.paragraphs] });
    } else {
      chapters[chapters.length - 1].paragraphs.push(...section.paragraphs);
    }
  }
  return chapters;
}

export function buildArticleText(extract: string): ArticleText | null {
  const { lead, sections } = splitSections(extract);
  if (lead.length === 0 && sections.length === 0) return null;

  const chapters = topLevelChapters(sections).filter(
    (c) => !SKIPPED_SECTION.test(c.title) && c.paragraphs.length > 0,
  );
  const history = chapters.filter((c) => HISTORY_SECTION.test(c.title));
  const rest = chapters.filter((c) => !HISTORY_SECTION.test(c.title));

  const candidates = [
    ...lead,
    ...history.flatMap((c) => c.paragraphs),
    ...rest.flatMap((c) => c.paragraphs),
  ];

  // Akapity dokładamy w całości (maks. 5), ostatni ewentualnie przycinamy do pełnych zdań
  const paragraphs: string[] = [];
  let length = 0;
  for (const paragraph of candidates) {
    if (paragraphs.length >= DESCRIPTION_MAX_PARAGRAPHS) break;
    const remaining = DESCRIPTION_MAX - length;
    if (remaining < 200) break;
    if (paragraph.length <= remaining) {
      paragraphs.push(paragraph);
      length += paragraph.length + 2;
    } else {
      paragraphs.push(cutToSentences(paragraph, remaining));
      break;
    }
  }
  const description = paragraphs.join('\n\n');

  const firstParagraph = lead[0] ?? candidates[0] ?? '';
  return {
    summary: cutToSentences(firstParagraph, SUMMARY_MAX),
    description,
    funFact: pickFunFact(candidates, description),
  };
}

/** Dzieli akapit na zdania (z tą samą obsługą skrótów co przycinanie). */
function splitSentences(paragraph: string): string[] {
  const sentences: string[] = [];
  let start = 0;
  for (const end of sentenceEnds(paragraph)) {
    sentences.push(paragraph.slice(start, end).trim());
    start = end;
  }
  sentences.push(paragraph.slice(start).trim());
  return sentences.filter((s) => s.length > 0);
}

/**
 * Ciekawostka: najlepiej punktowane zdanie z całego artykułu, którego NIE ma
 * już w opisie. Odrzucamy zdania zbyt krótkie/długie i zaczynające się od zaimka
 * (bez kontekstu brzmią dziwnie, np. „Jego wnętrze…”).
 */
function pickFunFact(paragraphs: string[], description: string): string | null {
  let best: { sentence: string; score: number } | null = null;
  for (const paragraph of paragraphs) {
    for (const sentence of splitSentences(paragraph)) {
      if (sentence.length < 50 || sentence.length > FUN_FACT_MAX) continue;
      if (description.includes(sentence)) continue;
      if (/^(jego|jej|ich|ten|ta|to|te|on|ona|oni|tam|tu|w nim|w niej)\b/i.test(sentence)) continue;
      // tylko pełne zdania: wielka litera na początku (nie liczba rzymska typu „XX w.”),
      // kropka na końcu, domknięte nawiasy i cudzysłowy
      if (!/^[A-ZĄĆĘŁŃÓŚŹŻ„"]/.test(sentence) || /^[IVXLC]+\b/.test(sentence)) continue;
      if (!/[.!?]$/.test(sentence)) continue;
      const count = (ch: string) => sentence.split(ch).length - 1;
      if (count('(') !== count(')') || count('„') !== count('”')) continue;
      let score = 0;
      for (const [pattern, weight] of FUN_FACT_HINTS) {
        if (pattern.test(sentence)) score += weight;
      }
      if (/\d/.test(sentence)) score += 0.5;
      if (score >= 3 && (!best || score > best.score)) best = { sentence, score };
    }
  }
  return best?.sentence ?? null;
}

// ---------- API modułu ----------

/** Zwraca mapę tytuł -> teksty (null, gdy artykułu brak). */
export async function fetchArticles(
  titles: string[],
): Promise<Map<string, ArticleText | null>> {
  const cache = loadCache();
  const unique = [...new Set(titles)];
  const missing = unique.filter((t) => !(t in cache));
  console.log(
    `  Wikipedia: ${unique.length - missing.length} z cache, ${missing.length} do pobrania`,
  );

  let done = 0;
  const queue = [...missing];
  const worker = async () => {
    for (let title = queue.shift(); title; title = queue.shift()) {
      try {
        cache[title] = await fetchExtract(title);
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

  return new Map(
    unique.map((t) => {
      const extract = cache[t];
      return [t, extract ? buildArticleText(extract) : null];
    }),
  );
}
