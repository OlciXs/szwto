import { PrismaClient } from '@prisma/client';
import { readSnapshot } from '../scripts/import/snapshot';

/**
 * Ładuje zabytki ze snapshotu (prisma/data/monuments.wroclaw.json).
 * Skrypt jest idempotentny – można go uruchamiać wielokrotnie:
 *   - istniejące zabytki są aktualizowane (po externalId), więc wizyty zostają,
 *   - zabytki spoza snapshotu (np. stare przykładowe) są usuwane.
 * Snapshot odświeża: npm run import:wroclaw
 */

const prisma = new PrismaClient();
const CONCURRENCY = 10;

async function main() {
  const snapshot = readSnapshot();
  const monuments = snapshot.monuments;
  console.log(
    `Snapshot z ${snapshot.generatedAt}: ${monuments.length} zabytków (${snapshot.city})`,
  );

  const queue = [...monuments];
  let done = 0;
  const worker = async () => {
    for (let m = queue.shift(); m; m = queue.shift()) {
      await prisma.monument.upsert({
        where: { externalId: m.externalId },
        update: m,
        create: m,
      });
      if (++done % 200 === 0) console.log(`  ${done}/${monuments.length}`);
    }
  };
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));

  const removed = await prisma.monument.deleteMany({
    where: { externalId: { notIn: monuments.map((m) => m.externalId) } },
  });

  const total = await prisma.monument.count();
  console.log(
    `Seed zakończony: ${total} zabytków w bazie (usunięto spoza snapshotu: ${removed.count}).`,
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
