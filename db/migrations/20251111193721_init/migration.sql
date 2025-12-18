-- CreateTable
CREATE TABLE "Song" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "lyrics" TEXT,
    "fileName" TEXT,
    "trackNumber" INTEGER,
    "discNumber" INTEGER,
    "songType" TEXT,
    "albumId" INTEGER,
    "singerId" INTEGER,
    CONSTRAINT "Song_albumId_fkey" FOREIGN KEY ("albumId") REFERENCES "Album" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Song_singerId_fkey" FOREIGN KEY ("singerId") REFERENCES "Singer" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Album" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "releaseYear" INTEGER,
    "coverArtFileName" TEXT,
    "artistId" INTEGER,
    CONSTRAINT "Album_artistId_fkey" FOREIGN KEY ("artistId") REFERENCES "Artist" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Artist" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "imageFileName" TEXT
);

-- CreateTable
CREATE TABLE "Singer" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "Writer" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "contribution" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_SongToWriter" (
    "A" INTEGER NOT NULL,
    "B" INTEGER NOT NULL,
    CONSTRAINT "_SongToWriter_A_fkey" FOREIGN KEY ("A") REFERENCES "Song" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "_SongToWriter_B_fkey" FOREIGN KEY ("B") REFERENCES "Writer" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "Song_name_key" ON "Song"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Song_slug_key" ON "Song"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Album_name_key" ON "Album"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Album_slug_key" ON "Album"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Artist_name_key" ON "Artist"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Artist_slug_key" ON "Artist"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Singer_name_key" ON "Singer"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Singer_slug_key" ON "Singer"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Writer_slug_contribution_key" ON "Writer"("slug", "contribution");

-- CreateIndex
CREATE UNIQUE INDEX "_SongToWriter_AB_unique" ON "_SongToWriter"("A", "B");

-- CreateIndex
CREATE INDEX "_SongToWriter_B_index" ON "_SongToWriter"("B");
