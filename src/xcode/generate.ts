import path from 'path';

import { PrismaClient } from '~/prisma/client/client';
import { saveJSON } from '~/utils';
import { syncSheets } from '~/xcode/sheets';

const prisma = new PrismaClient();

const singerCache = new Map();
const writerCache = new Map();
const data: any = { artists: [], singers: [], writers: [] };
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
            writers: true,
          },
        },
      },
    },
  },
});

for (const node of artists) {
  const artist = {
    name: node.name,
    slug: node.slug,
    appleMusicId: node.appleMusicId,
    albums: [] as any[],
  };

  for (const entry of node.albums) {
    const album = {
      name: entry.name,
      slug: entry.slug,
      releaseYear: entry.releaseYear,
      appleMusicId: entry.appleMusicId,
      songs: [] as any[],
    };

    for (const item of entry.songs) {
      let singer;
      if (item.singer) {
        singer = item.singer.slug;
        const { id: _, ...fields } = item.singer;
        singerCache.set(item.singer.slug, fields);
      }
      const writers = [];
      if (item.writers?.length > 0) {
        for (const writer of item.writers) {
          writers.push([writer.slug, writer.contribution]);
          const { id: _, ...fields } = writer;
          writerCache.set(`${writer.slug}:${writer.contribution}`, fields);
        }
      }
      const song = {
        trackNumber: item.trackNumber || undefined,
        discNumber: item.discNumber || undefined,
        songType: item.songType || undefined,
        name: item.name,
        slug: item.slug,
        fileName: item.fileName,
        // when pasting lyrics in Prisma Studio, things get can escaped
        lyrics: item.lyrics?.replaceAll(/\\n/g, '\n') || '',
        singer,
        writers,
        appleMusicId: item.appleMusicId,
      };
      album.songs.push(song);
    }

    artist.albums.push(album);
  }
  data.artists.push(artist);
}

data.singers.push(...Array.from(singerCache.values()));
data.writers.push(...Array.from(writerCache.values()));

const songs = artists.flatMap((artist) => artist.albums.flatMap((album) => album.songs));
const { changed, removed } = await syncSheets(songs);
console.log(`Lead sheets: ${changed.length} updated, ${removed.length} removed`);

const file = path.join(
  process.cwd(),
  'xcode',
  'DeadSheetsKit',
  'Sources',
  'DeadSheetsKit',
  'Resources',
  'seeds.json'
);
saveJSON(file, data);
