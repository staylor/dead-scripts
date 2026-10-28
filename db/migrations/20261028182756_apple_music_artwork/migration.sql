-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Album" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "releaseYear" INTEGER,
    "appleMusicId" TEXT,
    "artistId" INTEGER,
    CONSTRAINT "Album_artistId_fkey" FOREIGN KEY ("artistId") REFERENCES "Artist" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Album" ("artistId", "id", "name", "releaseYear", "slug") SELECT "artistId", "id", "name", "releaseYear", "slug" FROM "Album";
DROP TABLE "Album";
ALTER TABLE "new_Album" RENAME TO "Album";
CREATE UNIQUE INDEX "Album_name_key" ON "Album"("name");
CREATE UNIQUE INDEX "Album_slug_key" ON "Album"("slug");
CREATE TABLE "new_Artist" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "appleMusicId" TEXT
);
INSERT INTO "new_Artist" ("id", "name", "slug") SELECT "id", "name", "slug" FROM "Artist";
DROP TABLE "Artist";
ALTER TABLE "new_Artist" RENAME TO "Artist";
CREATE UNIQUE INDEX "Artist_name_key" ON "Artist"("name");
CREATE UNIQUE INDEX "Artist_slug_key" ON "Artist"("slug");
CREATE TABLE "new_Singer" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "appleMusicId" TEXT
);
INSERT INTO "new_Singer" ("id", "name", "slug") SELECT "id", "name", "slug" FROM "Singer";
DROP TABLE "Singer";
ALTER TABLE "new_Singer" RENAME TO "Singer";
CREATE UNIQUE INDEX "Singer_name_key" ON "Singer"("name");
CREATE UNIQUE INDEX "Singer_slug_key" ON "Singer"("slug");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- Each album keeps the cover the app bundled before: these are the releases it came from.
UPDATE "Album" SET "appleMusicId" = '663678672' WHERE "slug" = 'grateful-dead';
UPDATE "Album" SET "appleMusicId" = '663665553' WHERE "slug" = 'anthem-of-the-sun';
UPDATE "Album" SET "appleMusicId" = '663597904' WHERE "slug" = 'aoxomoxoa';
UPDATE "Album" SET "appleMusicId" = '20885553' WHERE "slug" = 'live-dead';
UPDATE "Album" SET "appleMusicId" = '663696329' WHERE "slug" = 'workingmans-dead';
UPDATE "Album" SET "appleMusicId" = '664831661' WHERE "slug" = 'american-beauty';
UPDATE "Album" SET "appleMusicId" = '20885501' WHERE "slug" = 'skull-and-roses';
UPDATE "Album" SET "appleMusicId" = '20885461' WHERE "slug" = 'europe-72';
UPDATE "Album" SET "appleMusicId" = '663663258' WHERE "slug" = 'wake-of-the-flood';
UPDATE "Album" SET "appleMusicId" = '663668215' WHERE "slug" = 'from-the-mars-hotel';
UPDATE "Album" SET "appleMusicId" = '663665016' WHERE "slug" = 'blues-for-allah';
UPDATE "Album" SET "appleMusicId" = '663672224' WHERE "slug" = 'shakedown-street';
UPDATE "Album" SET "appleMusicId" = '663667314' WHERE "slug" = 'terrapin-station';
UPDATE "Album" SET "appleMusicId" = '663697282' WHERE "slug" = 'go-to-heaven';
UPDATE "Album" SET "appleMusicId" = '663662522' WHERE "slug" = 'in-the-dark';
UPDATE "Album" SET "appleMusicId" = '663965011' WHERE "slug" = 'built-to-last';
UPDATE "Album" SET "appleMusicId" = '307938974' WHERE "slug" = 'so-many-roads';
UPDATE "Album" SET "appleMusicId" = '307793560' WHERE "slug" = 'ladies-and-gentlman-the-grateful-dead';
UPDATE "Album" SET "appleMusicId" = '366394085' WHERE "slug" = 'crimson-white-and-indigo';
UPDATE "Album" SET "appleMusicId" = '558274264' WHERE "slug" = 'so-glad-you-made-it';
UPDATE "Album" SET "appleMusicId" = '663700579' WHERE "slug" = 'complete-studio-rarities-collection';
UPDATE "Album" SET "appleMusicId" = '999637526' WHERE "slug" = '30-trips-around-the-sun';
UPDATE "Album" SET "appleMusicId" = '1647459819' WHERE "slug" = 'ace';
UPDATE "Album" SET "appleMusicId" = '1139010553' WHERE "slug" = 'garcia';
UPDATE "Album" SET "appleMusicId" = '1139060274' WHERE "slug" = 'reflections';
UPDATE "Album" SET "appleMusicId" = '1280522177' WHERE "slug" = 'cats-under-the-stars';

UPDATE "Artist" SET "appleMusicId" = '1273063' WHERE "slug" = 'grateful-dead';
UPDATE "Artist" SET "appleMusicId" = '6563017' WHERE "slug" = 'bob-weir';
UPDATE "Artist" SET "appleMusicId" = '931545' WHERE "slug" = 'jerry-garcia';

UPDATE "Singer" SET "appleMusicId" = '931545' WHERE "slug" = 'jerry-garcia';
UPDATE "Singer" SET "appleMusicId" = '6563017' WHERE "slug" = 'bob-weir';
UPDATE "Singer" SET "appleMusicId" = '549301' WHERE "slug" = 'phil-lesh';
