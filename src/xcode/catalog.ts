import path from 'path';

import type { PrismaClient, Singer, Writer } from '~/prisma/client/client';

/** The app's catalog, which is also the database's seed. */
export const catalogFile = path.join(
  process.cwd(),
  'xcode',
  'DeadSheetsKit',
  'Sources',
  'DeadSheetsKit',
  'Resources',
  'seeds.json'
);

export interface CatalogSong {
  trackNumber?: number;
  discNumber?: number;
  songType?: string;
  name: string;
  slug: string;
  fileName: string | null;
  lyrics: string;
  singer?: string;
  writers: [slug: string, contribution: string][];
  appleMusicId: string | null;
}

export interface CatalogAlbum {
  name: string;
  slug: string;
  releaseYear: number | null;
  appleMusicId: string | null;
  songs: CatalogSong[];
}

export interface CatalogArtist {
  name: string;
  slug: string;
  appleMusicId: string | null;
  albums: CatalogAlbum[];
}

export interface Catalog {
  artists: CatalogArtist[];
  singers: Omit<Singer, 'id'>[];
  writers: Omit<Writer, 'id'>[];
}

export async function exportCatalog(prisma: PrismaClient): Promise<Catalog> {
  const artists = await prisma.artist.findMany({
    orderBy: { id: 'asc' },
    include: {
      albums: {
        orderBy: { id: 'asc' },
        include: {
          songs: {
            orderBy: [{ trackNumber: 'asc' }, { id: 'asc' }],
            include: {
              singer: true,
              writers: { orderBy: { id: 'asc' } },
            },
          },
        },
      },
    },
  });

  const songs = artists.flatMap((artist) => artist.albums.flatMap((album) => album.songs));
  const singers = new Map(
    songs.flatMap(({ singer }) => (singer ? [[singer.slug, singer] as const] : []))
  );
  const writers = new Map(
    songs.flatMap((song) =>
      song.writers.map((writer) => [`${writer.slug}:${writer.contribution}`, writer] as const)
    )
  );

  return {
    artists: artists.map((artist) => ({
      name: artist.name,
      slug: artist.slug,
      appleMusicId: artist.appleMusicId,
      albums: artist.albums.map((album) => ({
        name: album.name,
        slug: album.slug,
        releaseYear: album.releaseYear,
        appleMusicId: album.appleMusicId,
        songs: album.songs.map((song) => ({
          trackNumber: song.trackNumber || undefined,
          discNumber: song.discNumber || undefined,
          songType: song.songType || undefined,
          name: song.name,
          slug: song.slug,
          fileName: song.fileName,
          // Lyrics pasted into Prisma Studio can arrive with escaped newlines.
          lyrics: song.lyrics?.replaceAll(/\\n/g, '\n') || '',
          singer: song.singer?.slug,
          writers: song.writers.map((writer): [string, string] => [
            writer.slug,
            writer.contribution,
          ]),
          appleMusicId: song.appleMusicId,
        })),
      })),
    })),
    singers: [...singers.values()].map(({ id: _, ...singer }) => singer),
    writers: [...writers.values()].map(({ id: _, ...writer }) => writer),
  };
}

/**
 * Fills an empty database from an export, so that exporting it again gives the same catalog. The
 * export breaks ties by ID, so rows are created one at a time in catalog order: Prisma doesn't keep
 * the order of nested creates.
 */
export async function restoreCatalog(prisma: PrismaClient, catalog: Catalog) {
  const counts = await Promise.all([
    prisma.artist.count(),
    prisma.album.count(),
    prisma.song.count(),
    prisma.singer.count(),
    prisma.writer.count(),
  ]);
  if (counts.some((count) => count > 0)) {
    throw new Error(
      'The database already has a catalog. To replace it with the export, run `prisma migrate reset`.'
    );
  }

  const albums = catalog.artists.flatMap((artist) =>
    artist.albums.map((album) => ({ artist, album }))
  );
  await prisma.$transaction([
    prisma.singer.createMany({ data: catalog.singers }),
    prisma.writer.createMany({ data: writersInCreditOrder(catalog) }),
    prisma.artist.createMany({
      data: catalog.artists.map((artist) => ({
        name: artist.name,
        slug: artist.slug,
        appleMusicId: artist.appleMusicId,
      })),
    }),
    ...albums.map(({ artist, album }) =>
      prisma.album.create({
        data: {
          name: album.name,
          slug: album.slug,
          releaseYear: album.releaseYear,
          appleMusicId: album.appleMusicId,
          artist: { connect: { slug: artist.slug } },
        },
      })
    ),
    ...albums.flatMap(({ album }) =>
      album.songs.map((song) =>
        prisma.song.create({
          data: {
            name: song.name,
            slug: song.slug,
            lyrics: song.lyrics || null,
            fileName: song.fileName,
            trackNumber: song.trackNumber,
            discNumber: song.discNumber,
            songType: song.songType,
            appleMusicId: song.appleMusicId,
            album: { connect: { slug: album.slug } },
            singer: song.singer ? { connect: { slug: song.singer } } : undefined,
            writers: {
              connect: song.writers.map(([slug, contribution]) => ({
                slug_contribution: { slug, contribution },
              })),
            },
          },
        })
      )
    ),
  ]);
}

/**
 * The export lists a song's writers by ID, so they are created in an order that keeps every
 * song's credits as exported. Songs that disagree fall back to the order of `writers`.
 */
function writersInCreditOrder({ artists, writers }: Catalog) {
  const key = (slug: string, contribution: string) => `${slug}:${contribution}`;
  const creditedBefore = new Map<string, Set<string>>();
  for (const song of artists.flatMap((artist) => artist.albums.flatMap((album) => album.songs))) {
    for (let index = 1; index < song.writers.length; index++) {
      const writer = key(...song.writers[index]);
      const earlier = creditedBefore.get(writer) ?? new Set();
      creditedBefore.set(writer, earlier.add(key(...song.writers[index - 1])));
    }
  }

  const remaining = [...writers];
  const created = new Set<string>();
  const ordered: Catalog['writers'] = [];
  while (remaining.length > 0) {
    const ready = remaining.findIndex((writer) =>
      [...(creditedBefore.get(key(writer.slug, writer.contribution)) ?? [])].every((other) =>
        created.has(other)
      )
    );
    const [next] = remaining.splice(Math.max(ready, 0), 1);
    created.add(key(next.slug, next.contribution));
    ordered.push(next);
  }
  return ordered;
}
