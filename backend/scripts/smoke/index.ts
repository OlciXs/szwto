/**
 * Smoke testy API:
 *   npm run smoke                                   (lokalnie, http://localhost:3000)
 *   npm run smoke -- --url https://szwto.onrender.com
 *
 * Testy są wczytywane automatycznie ze scripts/smoke/checks/*.ts w kolejności nazw
 * (01-core.ts, 02-progression.ts, …) – każdy tor dodaje swój plik, bez konfliktów.
 * Uwaga: każde uruchomienie zakłada nowe konto testowe (smoke_…@test.local).
 */
import { readdirSync } from 'fs';
import { join } from 'path';
import { Api, SmokeCheck, SmokeContext } from './lib';

function parseUrl(): string {
  const index = process.argv.indexOf('--url');
  const url =
    index !== -1 ? process.argv[index + 1] : process.env.API_URL ?? 'http://localhost:3000';
  return url.replace(/\/$/, '');
}

async function main() {
  const baseUrl = parseUrl();
  console.log(`Smoke testy: ${baseUrl}\n`);

  const ctx: SmokeContext = { api: new Api(baseUrl), state: {} };

  try {
    await fetch(baseUrl);
  } catch {
    console.error(
      `❌ Brak połączenia z ${baseUrl}. Uruchom backend w osobnym terminalu: npm run start:dev`,
    );
    process.exit(1);
  }

  const dir = join(__dirname, 'checks');
  const files = readdirSync(dir)
    .filter((f) => f.endsWith('.ts'))
    .sort();

  let passed = 0;
  let total = 0;
  for (const file of files) {
    const { checks } = (await import(join(dir, file))) as { checks: SmokeCheck[] };
    console.log(`— ${file}`);
    for (const check of checks) {
      total++;
      try {
        const detail = await check.run(ctx);
        passed++;
        console.log(`  ✅ ${check.name}${detail ? ` — ${detail}` : ''}`);
      } catch (error) {
        console.log(`  ❌ ${check.name}\n     ${(error as Error).message}`);
        console.log(`\nWynik: ${passed}/${total} (kolejne testy pominięte – zależą od tego)`);
        process.exit(1);
      }
    }
  }

  console.log(`\nWynik: ${passed}/${total} ✅ Wszystko działa.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
