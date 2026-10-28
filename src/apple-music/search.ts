import dotenv from '@dotenvx/dotenvx';

import { PrismaClient } from '~/prisma/client/client';

import { generateToken } from './jwt';

dotenv.config();

interface Resource {
  id: string;
  attributes: { name: string; artistName?: string };
}

const prisma = new PrismaClient();
const token = generateToken();
let missed = 0;

async function search(type: 'albums' | 'artists', term: string): Promise<Resource[]> {
  // The API rate-limits.
  await new Promise((resolve) => setTimeout(resolve, 1000));

  const url = `https://api.music.apple.com/v1/catalog/us/search?types=${type}&limit=25&term=${encodeURIComponent(term)}`;
  const response = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!response.ok) {
    throw new Error(`Searching Apple Music for "${term}" failed with ${response.status}`);
  }
  const { results } = await response.json();
  return results[type]?.data ?? [];
}

const sameName = (a: string, b: string) =>
  a.replaceAll('’', "'").toLowerCase() === b.replaceAll('’', "'").toLowerCase();

async function lookUp(
  name: string,
  candidates: Resource[],
  isMatch: (candidate: Resource) => boolean,
  save: (appleMusicId: string) => Promise<unknown>
) {
  const matches = candidates.filter(isMatch);
  if (matches.length === 1) {
    await save(matches[0].id);
    console.log(`✅ ${name}: ${matches[0].id}`);
    return;
  }

  missed += 1;
  console.log(`🚫 ${name}`);
  for (const { id, attributes } of candidates.slice(0, 5)) {
    console.log(
      `   ${id}  ${[attributes.name, attributes.artistName].filter(Boolean).join(' · ')}`
    );
  }
}

const albums = await prisma.album.findMany({
  where: { appleMusicId: null },
  include: { artist: true },
});
for (const album of albums) {
  const artistName = album.artist?.name;
  await lookUp(
    album.name,
    await search('albums', [artistName, album.name].filter(Boolean).join(' ')),
    ({ attributes }) =>
      sameName(attributes.name, album.name) && attributes.artistName === artistName,
    (appleMusicId) => prisma.album.update({ where: { id: album.id }, data: { appleMusicId } })
  );
}

for (const artist of await prisma.artist.findMany({ where: { appleMusicId: null } })) {
  await lookUp(
    artist.name,
    await search('artists', artist.name),
    ({ attributes }) => sameName(attributes.name, artist.name),
    (appleMusicId) => prisma.artist.update({ where: { id: artist.id }, data: { appleMusicId } })
  );
}

for (const singer of await prisma.singer.findMany({ where: { appleMusicId: null } })) {
  await lookUp(
    singer.name,
    await search('artists', singer.name),
    ({ attributes }) => sameName(attributes.name, singer.name),
    (appleMusicId) => prisma.singer.update({ where: { id: singer.id }, data: { appleMusicId } })
  );
}

if (missed > 0) {
  console.log(
    `\nSet the ${missed} marked 🚫 in Prisma Studio (pnpm prisma studio). Those that aren't on Apple Music can stay empty.`
  );
}

await prisma.$disconnect();
