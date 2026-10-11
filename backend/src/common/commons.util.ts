import { createHash } from 'crypto';

/**
 * Zdjęcia z Wikimedia Commons. W bazie trzymamy tylko nazwę pliku,
 * a adresy budujemy tutaj.
 *
 * Używamy BEZPOŚREDNICH adresów upload.wikimedia.org (ścieżka z hasha MD5 nazwy),
 * a nie Special:FilePath – tamten przekierowuje bez nagłówków CORS, przez co
 * obrazki nie ładują się we Flutter Web. Serwer generuje tylko standardowe
 * szerokości miniatur (np. 330, 500, 1280) – inne zwracają błąd 400.
 *
 * Licencja: każde zdjęcie wymaga podpisu – w aplikacji pokazujemy link `pageUrl`.
 */
export type CommonsThumbWidth = 330 | 500 | 1280;

export interface MonumentImage {
  thumbUrl: string;
  fullUrl: string;
  pageUrl: string;
}

export function commonsThumbUrl(file: string, width: CommonsThumbWidth = 330): string {
  const name = file.replace(/ /g, '_');
  const hash = createHash('md5').update(name).digest('hex');
  const encoded = encodeURIComponent(name);
  return `https://upload.wikimedia.org/wikipedia/commons/thumb/${hash[0]}/${hash.slice(0, 2)}/${encoded}/${width}px-${encoded}`;
}

export function commonsImage(file: string | null): MonumentImage | null {
  if (!file) return null;
  return {
    thumbUrl: commonsThumbUrl(file, 500),
    fullUrl: commonsThumbUrl(file, 1280),
    pageUrl: `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(file.replace(/ /g, '_'))}`,
  };
}
