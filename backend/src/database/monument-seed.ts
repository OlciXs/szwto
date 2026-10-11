import { PrismaClient } from '@prisma/client';
import { Snapshot } from './snapshot';

const CONCURRENCY = 10;

type Log = (message: string) => void;

/**
 * Wgrywa zabytki ze snapshotu. Idempotentne:
 *   - istniejące są aktualizowane po externalId (wizyty graczy zostają),
 *   - zabytki spoza snapshotu (np. stare przykładowe) są usuwane.
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
  const total = await prisma.monument.count();
  return { total, removed: removed.count };
}

/** Czy baza ma dokładnie zestaw zabytków ze snapshotu (po externalId)? */
export async function isSeedNeeded(
  prisma: PrismaClient,
  snapshot: Snapshot,
): Promise<boolean> {
  const ids = snapshot.monuments.map((m) => m.externalId);
  const [total, matching] = await Promise.all([
    prisma.monument.count(),
    prisma.monument.count({ where: { externalId: { in: ids } } }),
  ]);
  return total !== ids.length || matching !== ids.length;
}
