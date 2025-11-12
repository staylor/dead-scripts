import { copyFile } from 'fs/promises';
import path from 'path';

import { cleanupChorus } from '~/lyrics/utils';
import { PrismaClient } from '~/prisma/client/client';
import schema from '~/real-book/schema.json';
import { saveJSON, ICLOUD_DIR } from '~/utils';

const prisma = new PrismaClient();

const data: any = { artists: [] };
const artists = await prisma.artist.findMany({
  include: {
    albums: {
      include: {
        songs: {
          orderBy: {
            trackNumber: 'asc',
          },
          include: {
            singer: true,
          },
        },
      },
    },
  },
});

for (const node of artists) {
  const artist = {
    name: node.name,
    imageFileName: node.imageFileName,
    albums: [] as any[],
  };

  for (const entry of node.albums) {
    const album = {
      name: entry.name,
      releaseYear: entry.releaseYear,
      coverArtFileName: entry.coverArtFileName,
      songs: [] as any[],
    };

    for (const item of entry.songs) {
      const song = {
        trackNumber: item.trackNumber || undefined,
        discNumber: item.discNumber || undefined,
        songType: item.songType || undefined,
        name: item.name,
        fileName: item.fileName,
        lyrics: cleanupChorus(item.lyrics || ''),
        singer: item.singer?.name
          ? {
              name: item.singer?.name,
              imageFileName: item.singer?.imageFileName,
            }
          : undefined,
      };
      album.songs.push(song);
    }

    artist.albums.push(album);
  }
  data.artists.push(artist);
}

const appDir = path.join(process.cwd(), 'xcode', 'leadsheets');

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
    const src = path.join(ICLOUD_DIR, score);
    const dest = path.join(appDir, 'pdfs', pdf!);

    return copyFile(src, dest);
  })
);

const file = path.join(appDir, 'songs.json');
saveJSON(file, data);
