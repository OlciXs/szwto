import { Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { execFileSync } from 'child_process';
import { join } from 'path';
import { isSeedNeeded, seedMonuments } from './monument-seed';
import { readSnapshot } from './snapshot';

/**
 * Automatyczne przygotowanie bazy przy starcie serwera – żeby deploy na Renderze
 * nie wymagał ręcznych komend ani zmian w panelu:
 *   1) prisma migrate deploy (przed nasłuchiwaniem),
 *   2) seed zabytków, jeśli baza ich nie ma (w tle, po starcie).
 *
 * Włączone automatycznie na Renderze (ustawia RENDER=true) albo przez AUTO_DB_SETUP=true.
 * Wyłączenie: AUTO_DB_SETUP=false. Lokalnie domyślnie wyłączone – używaj
 * `npx prisma migrate deploy` i `npm run seed`.
 */

const logger = new Logger('DatabaseSetup');

const SCHEMA_PATH = join(__dirname, '..', '..', 'prisma', 'schema.prisma');

/** Pierwsza migracja – stan bazy sprzed refaktoru (User, Monument, UserVisited). */
const BASELINE_MIGRATION = '20261010192723_init';

export function isAutoSetupEnabled(): boolean {
  const flag = process.env.AUTO_DB_SETUP;
  if (flag === 'false') return false;
  return flag === 'true' || process.env.RENDER === 'true';
}

function prisma(args: string[]): string {
  const cli = require.resolve('prisma/build/index.js');
  return execFileSync(process.execPath, [cli, ...args, '--schema', SCHEMA_PATH], {
    encoding: 'utf8',
    stdio: 'pipe',
  });
}

function outputOf(error: unknown): string {
  const e = error as { stdout?: string; stderr?: string; message?: string };
  return `${e.stdout ?? ''}\n${e.stderr ?? ''}\n${e.message ?? ''}`;
}

export function runMigrations() {
  logger.log('prisma migrate deploy…');
  try {
    logger.log(prisma(['migrate', 'deploy']).trim().split('\n').pop() ?? '');
  } catch (error) {
    const output = outputOf(error);
    // P3005: baza ma tabele, ale nie ma historii migracji (np. założona przez `db push`).
    // Oznaczamy pierwszą migrację jako zastosowaną i próbujemy ponownie.
    if (!output.includes('P3005')) {
      logger.error(output);
      throw error;
    }
    logger.warn(
      `Baza bez historii migracji (P3005) – oznaczam ${BASELINE_MIGRATION} jako zastosowaną.`,
    );
    prisma(['migrate', 'resolve', '--applied', BASELINE_MIGRATION]);
    logger.log(prisma(['migrate', 'deploy']).trim().split('\n').pop() ?? '');
  }
}

export async function seedIfNeeded(client: PrismaClient) {
  const snapshot = readSnapshot();
  if (!(await isSeedNeeded(client, snapshot))) {
    logger.log(`Zabytki aktualne (${snapshot.count}) – pomijam seed.`);
    return;
  }
  logger.log(`Wgrywam ${snapshot.count} zabytków ze snapshotu…`);
  const { total, removed } = await seedMonuments(client, snapshot, (m) =>
    logger.log(m),
  );
  logger.log(`Seed zakończony: ${total} zabytków (usunięto starych: ${removed}).`);
}
