import { copyFile } from 'fs/promises';
import path from 'path';

import { cleanupChorus } from '~/lyrics/utils';
import metadata from '~/real-book/metadata.json';
import schema from '~/real-book/schema.json';
import { slugify } from '~/slugify';
import { readJSON, saveJSON, ICLOUD_DIR } from '~/utils';

const appDir = path.join(process.cwd(), 'xcode', 'leadsheets');
const lyricsDir = path.join(process.cwd(), '.cache', 'lyrics');

const all = metadata as any;
const refMap: Record<string, any> = {};
for (const [slug, { artist, ...album }] of Object.entries(metadata.albums)) {
  const resolved = all.artists[artist];
  resolved.albums ||= [];
  const entry = album as any;
  entry.songs ||= [];
  refMap[slug] = entry;
  resolved.albums.push(entry);
}
const artists = {
  artists: Object.values(metadata.artists),
};

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
    const { album, ...meta } = all.songs[slug];
    const lookup = refMap[album];

    let lyrics = '';
    try {
      const data = readJSON(path.join(lyricsDir, `${slug}.json`));
      lyrics = cleanupChorus(data.lyrics || '');
    } catch {}

    lookup.songs.push({
      ...meta,
      name: entry.title,
      fileName: pdf!,
      lyrics,
    });

    const src = path.join(ICLOUD_DIR, score);
    const dest = path.join(appDir, 'pdfs', pdf!);

    return copyFile(src, dest);
  })
);

const file = path.join(appDir, 'songs.json');
saveJSON(file, artists);
