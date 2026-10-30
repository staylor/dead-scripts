DROP INDEX "Song_name_key";
DROP INDEX "Album_name_key";
DROP INDEX "Artist_name_key";
DROP INDEX "Singer_name_key";

CREATE INDEX "Song_name_idx" ON "Song"("name");
CREATE INDEX "Album_name_idx" ON "Album"("name");
CREATE INDEX "Artist_name_idx" ON "Artist"("name");
CREATE INDEX "Singer_name_idx" ON "Singer"("name");
