import { exec } from 'child_process';
import { copyFile } from 'fs/promises';
import path from 'path';

import { PrismaClient } from '~/prisma/client/client';
import schema from '~/real-book/schema.json';
import { saveJSON, ICLOUD_DIR } from '~/utils';

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
    imageFileName: node.imageFileName,
    albums: [] as any[],
  };

  for (const entry of node.albums) {
    const album = {
      name: entry.name,
      slug: entry.slug,
      releaseYear: entry.releaseYear,
      coverArtFileName: entry.coverArtFileName,
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

const appDir = path.join(process.cwd(), 'xcode', 'leadsheets', 'Resources');

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

const file = path.join(appDir, 'seeds.json');
saveJSON(file, data);

// generate images for tvOS
exec('cd xcode; swift ./convert_pdfs.swift');
