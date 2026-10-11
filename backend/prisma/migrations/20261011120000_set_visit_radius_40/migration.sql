-- Ujednolicenie geofencingu: każdy zabytek można odznaczyć z odległości maks. 40 m.
UPDATE "Monument" SET "visitRadius" = 40;

ALTER TABLE "Monument" ALTER COLUMN "visitRadius" SET DEFAULT 40;
