import { PrismaClient } from '@prisma/client';
import { createHash } from 'crypto';
import { Snapshot } from './snapshot';

const CONCURRENCY = 10;
const SNAPSHOT_META_KEY = 'monumentsSnapshotHash';

type Log = (message: string) => void;

/** Odcisk zawartości snapshotu – zmienia się przy każdej zmianie danych lub opisów. */
export function snapshotHash(snapshot: Snapshot): string {
  return createHash('sha1')
    .update(JSON.stringify(snapshot.monuments))
    .digest('hex');
}

/**
 * Wgrywa zabytki ze snapshotu. Idempotentne:
 *   - istniejące są aktualizowane po externalId (wizyty graczy zostają),
 *   - zabytki spoza snapshotu są usuwane (razem z wizytami na nich),
 *   - zapisuje hash snapshotu w AppMeta (patrz isSeedNeeded).
 */
export async function seedMonuments(
  prisma: PrismaClient,
  snapshot: Snapshot,
  log: Log = console.log,
) {
  const monuments = snapshot.monuments;
  const queue = [...monuments];
  let done = 0;

  const worker = async () => {
    for (let m = queue.shift(); m; m = queue.shift()) {
      await prisma.monument.upsert({
        where: { externalId: m.externalId },
        update: m,
        create: m,
      });
      if (++done % 200 === 0) log(`  ${done}/${monuments.length}`);
    }
  };
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));

  const removed = await prisma.monument.deleteMany({
    where: { externalId: { notIn: monuments.map((m) => m.externalId) } },
  });

  const hash = snapshotHash(snapshot);
  await prisma.appMeta.upsert({
    where: { key: SNAPSHOT_META_KEY },
    update: { value: hash },
    create: { key: SNAPSHOT_META_KEY, value: hash },
  });

  const total = await prisma.monument.count();
  return { total, removed: removed.count };
}

/** Czy wgrany snapshot różni się od tego w repo (albo baza jest pusta)? */
export async function isSeedNeeded(
  prisma: PrismaClient,
  snapshot: Snapshot,
): Promise<boolean> {
  const meta = await prisma.appMeta.findUnique({
    where: { key: SNAPSHOT_META_KEY },
  });
  return meta?.value !== snapshotHash(snapshot);
}
