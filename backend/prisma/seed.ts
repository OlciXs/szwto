import { PrismaClient } from '@prisma/client';
import { seedMonuments } from '../src/database/monument-seed';
import { readSnapshot } from '../src/database/snapshot';

/**
 * Ładuje zabytki ze snapshotu (prisma/data/monuments.wroclaw.json).
 * Skrypt jest idempotentny – można go uruchamiać wielokrotnie.
 * Snapshot odświeża: npm run import:wroclaw
 * (Na Renderze seed uruchamia się sam przy starcie – src/database/database-setup.ts)
 */

const prisma = new PrismaClient();

async function main() {
  const snapshot = readSnapshot();
  console.log(
    `Snapshot z ${snapshot.generatedAt}: ${snapshot.count} zabytków (${snapshot.city})`,
  );
  const { total, removed } = await seedMonuments(prisma, snapshot);
  console.log(
    `Seed zakończony: ${total} zabytków w bazie (usunięto spoza snapshotu: ${removed}).`,
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
