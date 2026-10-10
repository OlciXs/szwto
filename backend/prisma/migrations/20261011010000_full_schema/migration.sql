-- CreateEnum
CREATE TYPE "MonumentSource" AS ENUM ('WIKIDATA', 'OSM', 'MANUAL');

-- CreateEnum
CREATE TYPE "MonumentCategory" AS ENUM ('KAMIENICA', 'PALAC', 'SAKRALNY', 'MOST', 'POMNIK', 'RZEZBA', 'PARK', 'PUBLICZNY', 'TECHNICZNY', 'ARCHITEKTURA');

-- CreateEnum
CREATE TYPE "Rarity" AS ENUM ('COMMON', 'RARE', 'EPIC', 'LEGENDARY');

-- CreateEnum
CREATE TYPE "Era" AS ENUM ('SREDNIOWIECZE', 'NOWOZYTNOSC', 'WIEK_XIX', 'WIEK_XX', 'POWOJENNE');

-- CreateEnum
CREATE TYPE "HeritageLevel" AS ENUM ('UNESCO', 'POMNIK_HISTORII', 'REJESTR', 'EWIDENCJA', 'BRAK');

-- DropIndex
DROP INDEX "Monument_name_key";

-- AlterTable
ALTER TABLE "Monument" ADD COLUMN     "address" TEXT,
ADD COLUMN     "builtLabel" TEXT,
ADD COLUMN     "builtYear" INTEGER,
ADD COLUMN     "category" "MonumentCategory",
ADD COLUMN     "city" TEXT NOT NULL DEFAULT 'Wrocław',
ADD COLUMN     "descriptionSource" TEXT,
ADD COLUMN     "era" "Era",
ADD COLUMN     "externalId" TEXT,
ADD COLUMN     "fame" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "heritageLevel" "HeritageLevel" NOT NULL DEFAULT 'BRAK',
ADD COLUMN     "imageFile" TEXT,
ADD COLUMN     "rarity" "Rarity" NOT NULL DEFAULT 'COMMON',
ADD COLUMN     "rawType" TEXT,
ADD COLUMN     "registerNumber" TEXT,
ADD COLUMN     "source" "MonumentSource" NOT NULL DEFAULT 'MANUAL',
ADD COLUMN     "visitRadius" INTEGER NOT NULL DEFAULT 50,
ADD COLUMN     "wikipediaUrl" TEXT,
ADD COLUMN     "xp" INTEGER NOT NULL DEFAULT 10,
ALTER COLUMN "description" DROP NOT NULL;

-- Uzupełnienie istniejących wierszy (baza produkcyjna ma już dane).
-- Stare zabytki dostają tymczasowy klucz "legacy:<id>" – seed usuwa je,
-- bo nie występują w snapshocie importu.
UPDATE "Monument" SET "externalId" = 'legacy:' || "id", "category" = 'ARCHITEKTURA';
ALTER TABLE "Monument" ALTER COLUMN "externalId" SET NOT NULL,
ALTER COLUMN "category" SET NOT NULL;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "displayName" TEXT;
-- Istniejący użytkownicy: nazwa z części e-maila przed "@" + id (unikalna)
UPDATE "User" SET "displayName" = split_part("email", '@', 1) || '_' || "id";
ALTER TABLE "User" ALTER COLUMN "displayName" SET NOT NULL;

-- AlterTable
ALTER TABLE "UserVisited" ADD COLUMN     "xpEarned" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "ShowcaseSlot" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "slot" INTEGER NOT NULL,
    "monumentId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ShowcaseSlot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Comment" (
    "id" SERIAL NOT NULL,
    "monumentId" INTEGER NOT NULL,
    "userId" INTEGER NOT NULL,
    "body" VARCHAR(500) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Duel" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "seed" INTEGER NOT NULL,
    "rounds" INTEGER NOT NULL DEFAULT 5,
    "creatorId" INTEGER NOT NULL,
    "opponentId" INTEGER,
    "creatorScore" INTEGER,
    "opponentScore" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMP(3),

    CONSTRAINT "Duel_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ShowcaseSlot_userId_slot_key" ON "ShowcaseSlot"("userId", "slot");

-- CreateIndex
CREATE UNIQUE INDEX "ShowcaseSlot_userId_monumentId_key" ON "ShowcaseSlot"("userId", "monumentId");

-- CreateIndex
CREATE INDEX "Comment_monumentId_createdAt_idx" ON "Comment"("monumentId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Duel_code_key" ON "Duel"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Monument_externalId_key" ON "Monument"("externalId");

-- CreateIndex
CREATE INDEX "Monument_category_idx" ON "Monument"("category");

-- CreateIndex
CREATE INDEX "Monument_city_idx" ON "Monument"("city");

-- CreateIndex
CREATE UNIQUE INDEX "User_displayName_key" ON "User"("displayName");

-- CreateIndex
CREATE INDEX "UserVisited_monumentId_idx" ON "UserVisited"("monumentId");

-- AddForeignKey
ALTER TABLE "ShowcaseSlot" ADD CONSTRAINT "ShowcaseSlot_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShowcaseSlot" ADD CONSTRAINT "ShowcaseSlot_monumentId_fkey" FOREIGN KEY ("monumentId") REFERENCES "Monument"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_monumentId_fkey" FOREIGN KEY ("monumentId") REFERENCES "Monument"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Duel" ADD CONSTRAINT "Duel_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Duel" ADD CONSTRAINT "Duel_opponentId_fkey" FOREIGN KEY ("opponentId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

