import { Logger } from '@nestjs/common';

/**
 * Darmowy Render usypia serwer po 15 min bez ruchu – pierwsze żądanie po przerwie
 * (np. rejestracja) trwa wtedy ~30–60 s. Serwer co 10 min odpytuje sam siebie
 * przez publiczny adres, więc nie zasypia.
 *
 * Działa tylko na Renderze (RENDER=true, adres z RENDER_EXTERNAL_URL – ustawia go Render).
 * Wyłączenie: KEEP_ALIVE=false. Uwaga: darmowy plan ma 750 h/mies. na całe konto –
 * jeden serwis działający non stop zużywa ~744 h.
 */
const INTERVAL_MS = 10 * 60 * 1000;

export function startKeepAlive() {
  const url = process.env.RENDER_EXTERNAL_URL;
  if (process.env.RENDER !== 'true' || !url || process.env.KEEP_ALIVE === 'false') {
    return;
  }

  const logger = new Logger('KeepAlive');
  logger.log(`Podtrzymywanie serwera: ${url} co ${INTERVAL_MS / 60000} min`);
  setInterval(() => {
    fetch(url).catch((error) => logger.warn(`Ping nieudany: ${error}`));
  }, INTERVAL_MS);
}
