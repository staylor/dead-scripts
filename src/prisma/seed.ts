import fs from 'node:fs';
import path from 'node:path';

import { cleanupChorus } from '~/lyrics/utils';
import {
  PrismaClient,
  type Album,
  type Artist,
  type Writer,
  type Singer,
} from '~/prisma/client/client';
import metadata from '~/real-book/metadata.json';
import schema from '~/real-book/schema.json';
import { slugify } from '~/slugify';
import { readJSON } from '~/utils';

const lyricsDir = path.join(process.cwd(), '.cache', 'lyrics');
const songsDir = path.join(process.cwd(), 'src', 'songs');

const prisma = new PrismaClient();

async function seedWriters(entries: string[]) {
  const writers: Writer[] = [];

  for (const author of entries) {
    const [contrib, names] = author.split(':').map((text) => text.trim());
    let sep: string[] = [names];
    if (names.includes('/')) {
      sep = names.split('/').map((text) => text.trim());
    } else if (names.includes(',')) {
      sep = names.split(',').map((text) => text.trim());
    }
    const contribution = contrib.toLowerCase();

    for (const name of sep) {
      const slug = slugify(name);

      const record = await prisma.writer.upsert({
        where: { slug_contribution: { slug, contribution } },
        update: {},
        create: {
          name,
          slug,
          contribution,
        },
      });
      writers.push(record);
    }
  }

  return writers;
}

function fetchLyricsData(slug: string) {
  const cached = path.join(lyricsDir, `${slug}.json`);
  if (fs.existsSync(cached)) {
    return readJSON(cached);
  }

  const manual = path.join(songsDir, `${slug}.json`);
  if (fs.existsSync(manual)) {
    return readJSON(manual);
  }
}

async function main() {
  const artists: Record<string, Artist> = {};
  const albums: Record<string, Album> = {};
  const singers: Record<string, Singer> = {};

  for (const [slug, data] of Object.entries(metadata.artists)) {
    const fields = {
      imageFileName: data.imageFileName,
    };
    artists[slug] = await prisma.artist.upsert({
      where: { slug },
      update: {
        ...fields,
      },
      create: {
        name: data.name,
        slug,
        ...fields,
      },
    });
  }

  for (const [slug, data] of Object.entries(metadata.albums)) {
    const fields = {
      coverArtFileName: data.coverArtFileName,
      releaseYear: data.releaseYear,
      artist: {
        connect: { id: artists[data.artist].id },
      },
    };
    albums[slug] = await prisma.album.upsert({
      where: { slug },
      update: {
        ...fields,
      },
      create: {
        name: data.name,
        slug,
        ...fields,
      },
    });
  }

  for (const [slug, data] of Object.entries(metadata.singers)) {
    singers[slug] = await prisma.singer.upsert({
      where: { slug },
      update: {},
      create: {
        name: data.name,
        slug,
      },
    });
  }

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
      const songs = metadata.songs as any;
      const meta = songs[slug];

      let lyrics = '';
      const writers: Writer[] = [];

      const data = fetchLyricsData(slug);
      if (data?.lyrics) {
        lyrics = cleanupChorus(data.lyrics || '');
      }

      // These are from the scraped lyrics output, which is why this is so gross
      if (data?.authors) {
        const result = await seedWriters(data.authors);
        writers.push(...result);
      }

      const fields = {
        name: entry.title,
        fileName: pdf!,
        lyrics: lyrics || undefined,
        trackNumber: meta.trackNumber,
        songType: meta.songType,
        album: {
          connect: { id: albums[meta.album].id },
        },
        singer: meta.singer
          ? {
              connect: { id: singers[meta.singer].id },
            }
          : undefined,
        writers: {
          connect: writers.map(({ id }) => ({ id })),
        },
      };

      await prisma.song.upsert({
        where: { slug },
        update: {
          ...fields,
        },
        create: {
          slug,
          ...fields,
        },
      });
    })
  );
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
