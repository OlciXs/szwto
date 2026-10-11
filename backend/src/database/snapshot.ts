import { readFileSync } from 'fs';
import { join } from 'path';
import { Prisma } from '@prisma/client';

/**
 * Snapshot danych zabytków trzymany w repo (prisma/data/monuments.wroclaw.json).
 * Tworzy go `npm run import:wroclaw`, czytają: seed (CLI) i automatyczny setup bazy.
 * Ścieżka działa zarówno z src/database (ts-node), jak i dist/database (build).
 */
export const SNAPSHOT_PATH = join(
  __dirname,
  '..',
  '..',
  'prisma',
  'data',
  'monuments.wroclaw.json',
);

export type SnapshotMonument = Omit<Prisma.MonumentCreateInput, 'id'> & {
  externalId: string;
};

export interface Snapshot {
  generatedAt: string;
  city: string;
  sources: string[];
  license: string;
  count: number;
  monuments: SnapshotMonument[];
}

export function readSnapshot(): Snapshot {
  return JSON.parse(readFileSync(SNAPSHOT_PATH, 'utf8')) as Snapshot;
}
