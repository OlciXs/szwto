import { readFileSync } from 'fs';
import { join } from 'path';
import { Prisma } from '@prisma/client';

/** Snapshot danych trzymany w repo – seed czyta wyłącznie z niego (bez internetu). */
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
