import { readdir, readFile, rm, writeFile } from 'fs/promises';
import path from 'path';

import { ICLOUD_DIR } from '~/utils';

interface SheetSong {
  slug: string;
  fileName: string | null;
}

/**
 * Copies each song's score from iCloud Drive into `Sheets/pdfs`, finding it through
 * `Sheets/schema.json`. The sheets are committed, so files that haven't changed are left
 * untouched.
 */
export async function syncSheets(
  songs: SheetSong[],
  {
    scoresDir = ICLOUD_DIR,
    sheetsDir = path.join(process.cwd(), 'xcode', 'Sheets'),
  }: { scoresDir?: string; sheetsDir?: string } = {}
) {
  const schema: Record<string, string> = JSON.parse(
    await readFile(path.join(sheetsDir, 'schema.json'), 'utf8')
  );

  const problems = songs.flatMap((song) => {
    if (!song.fileName) {
      return [`${song.slug} has no fileName`];
    }
    if (!schema[song.slug]) {
      return [`${song.slug} has no score in Sheets/schema.json`];
    }
    return [];
  });
  if (problems.length > 0) {
    throw new Error(`Can't update the lead sheets:\n${problems.join('\n')}`);
  }

  const pdfsDir = path.join(sheetsDir, 'pdfs');
  const pdfs = songs.map((song) => song.fileName!);
  const changed: string[] = [];

  for (const song of songs) {
    const score = await readFile(path.join(scoresDir, schema[song.slug]));
    const destination = path.join(pdfsDir, song.fileName!);
    const current = await readFile(destination).catch(() => undefined);
    if (!current?.equals(score)) {
      await writeFile(destination, score);
      changed.push(song.fileName!);
    }
  }

  const keep = new Set(pdfs);
  const removed = (await readdir(pdfsDir)).filter(
    (file) => file.endsWith('.pdf') && !keep.has(file)
  );
  await Promise.all(removed.map((file) => rm(path.join(pdfsDir, file))));

  return { changed, removed };
}
