import { copyFile } from 'fs/promises';
import path from 'path';

import schema from '~/real-book/schema.json';
import { slugify } from '~/slugify';
import { readJSON, saveJSON, ICLOUD_DIR } from '~/utils';

const appDir = path.join(process.cwd(), 'xcode', 'leadsheets');
const lyricsDir = path.join(process.cwd(), '.cache', 'lyrics');
const songs: any[] = [];

await Promise.all(
  schema.map(async (entry) => {
    if (!entry.title) {
      return;
    }

    const score = entry.files.find((file) => file.endsWith('Score.pdf'));
    if (!score) {
      return;
    }

    const pdf = score.split('/').pop();
    const slug = slugify(entry.title);

    let lyrics = '';
    try {
      const data = readJSON(path.join(lyricsDir, `${slug}.json`));
      lyrics = data.lyrics || '';
    } catch {}

    songs.push({
      name: entry.title,
      albumName: '',
      fileName: pdf!,
      lyrics,
    });

    const src = path.join(ICLOUD_DIR, score);
    const dest = path.join(appDir, 'pdfs', pdf!);

    return copyFile(src, dest);
  })
);

const file = path.join(appDir, 'songs.json');
saveJSON(file, songs);
