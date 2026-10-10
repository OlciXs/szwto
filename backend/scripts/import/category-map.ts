import { MonumentCategory } from '@prisma/client';

/**
 * Mapowanie etykiet typów z Wikidata (P31, po polsku) na kategorie gry.
 * Reguły sprawdzane są w kolejności – wygrywa pierwsza pasująca kategoria,
 * dlatego bardziej konkretne kategorie są wyżej.
 */
const CATEGORY_RULES: [MonumentCategory, RegExp][] = [
  [MonumentCategory.MOST, /most|kładka|wiadukt/],
  [
    MonumentCategory.SAKRALNY,
    /kości|kaplic|kapliczk|katedr|bazylik|klasztor|synagog|cerkiew|sobór|kolegiat|świątyni|plebani|kanonia|dom zakonny|organistówka|wspólnota religijna|dzwonnic/,
  ],
  [MonumentCategory.PALAC, /pałac|willa|dwór|dworski|zamek|rezydencj/],
  [
    MonumentCategory.POMNIK,
    /pomnik(?!owe drzewo)|kamień pamiątkowy|miejsce pamięci|miejsce historyczne|obelisk|tablica pamiątkowa|grobowiec|mauzoleum|stolperstein|pręgierz/i,
  ],
  [
    MonumentCategory.RZEZBA,
    /rzeźb|posąg|fontann|popiersi|neon|instalacja|^kolumna$/,
  ],
  [
    MonumentCategory.PARK,
    /park|ogród|ogrody|cmentarz|skwer|aleja|zoolog|botaniczny|esplanada|altana|pergola|kąpielisko|herpetarium|słoniarnia|ptaszarnia|woliera/i,
  ],
  [
    MonumentCategory.PUBLICZNY,
    /ratusz|rathaus|gmach|szpital|sanatorium|uniwersyt|uczelni|szkoł|bursa|dom studencki|dormitorium|instytut|teatr|opera|kino|widownia|muzeum|instytucja kultury|budynek kulturalny|hala|pawilon|dom towarowy|dom handlowy|sklep|apteka|bank|poczta|hotel|restauracja|biurowiec|administracyjn|użyteczności publicznej|zakład karny|siedziba policji|remiza|stadion|trybuna|pływalnia|dom dziecka|kostnica|rynek/,
  ],
  [
    MonumentCategory.TECHNICZNY,
    /dworzec|stacja|peron|wieża|magazyn|spichlerz|schron|blokhauz|fort|bastion|baszta|basteja|arsenał|wartownia|kordegarda|brama|przemysł|młyn|elektrown|ciepłowni|kotłowni|przepompowni|hydrotechniczn|śluza|jaz|nabrzeże|rezerwuar|filtr|browar|warsztat|ślusarnia|maszynownia|wagonownia|zajezdnia|garaż|wozownia|stajnia|silos|słup|nastawnia|port lotniczy|lądowisko|zabytek techniki|cyjanometr|meteorologiczna|wiata|studnia|budynek gospodarczy|\bkas[ay]?\b/i,
  ],
  [
    MonumentCategory.KAMIENICA,
    /kamienic|^dom$|budynek mieszkalny|blok mieszkalny|oficyna|osiedle|zespół mieszkaniowy/,
  ],
];

/** Etykiety zbyt ogólne, by pokazywać je jako typ obiektu. */
const GENERIC_LABELS = new Set([
  'zabytek architektury',
  'budynek',
  'budowla',
  'kompleks budynków',
  'zespół architektoniczny',
  'wojewódzki zabytek nieruchomy w Polsce',
]);

/** Obiekty, których nie importujemy (decyzja zespołu: bez krasnali). */
const EXCLUDED_TYPE = /krasnal|nieistniejący/i;

/** Typy "obszarowe" / przyrodnicze – wykluczamy, jeśli obiekt nie ma innego typu. */
const NON_VISITABLE_TYPE =
  /drzew|kategoria w projekcie|część miasta|część miejscowości|obszar chroniony/;

export function isExcluded(name: string, typeLabels: string[]): boolean {
  if (/krasnal/i.test(name)) return true;
  if (typeLabels.some((t) => EXCLUDED_TYPE.test(t))) return true;
  return (
    typeLabels.length > 0 &&
    typeLabels.every((t) => NON_VISITABLE_TYPE.test(t))
  );
}

function matchRules(labels: string[]) {
  for (const [category, pattern] of CATEGORY_RULES) {
    const match = labels.find((label) => pattern.test(label));
    if (match) return { category, rawType: match };
  }
  return null;
}

/**
 * Część obiektów ma w Wikidata tylko ogólny typ ("budynek"), ale nazwa mówi
 * więcej ("Kamienica Pod Srebrnym Pucharem"). Sprawdzamy WYŁĄCZNIE początek nazwy –
 * cała nazwa dawałaby fałszywe trafienia (np. "ul. Kościuszki" -> kościół).
 */
function categorizeByName(name: string) {
  const words = name.toLowerCase().split(/[\s,]+/);
  const twoWords = words.slice(0, 2).join(' ');
  const byPhrase = matchRules([twoWords]);
  if (byPhrase) return { category: byPhrase.category, rawType: twoWords };
  const byWord = matchRules([words[0]]);
  return byWord ? { category: byWord.category, rawType: words[0] } : null;
}

export function categorize(
  typeLabels: string[],
  name: string,
): {
  category: MonumentCategory;
  rawType: string | null;
} {
  const byType = matchRules(typeLabels);
  if (byType) return byType;

  const byName = categorizeByName(name);
  if (byName) return byName;

  const specific = typeLabels.find((label) => !GENERIC_LABELS.has(label));
  return {
    category: MonumentCategory.ARCHITEKTURA,
    rawType: specific ?? typeLabels[0] ?? null,
  };
}
