import fs from 'node:fs';

import dotenv from '@dotenvx/dotenvx';

import { PrismaClient } from '~/prisma/client/client';
import { readJSON, saveJSON } from '~/utils';

import { generateToken } from './jwt';

dotenv.config();

const CACHED_FILE = '.cache/playlist.json';

async function fetchPlaylist() {
  // if (fs.existsSync(CACHED_FILE)) {
  //   return readJSON(CACHED_FILE);
  // }

  const REAL_BOOK_ID = 'pl.u-xrY5WFkedj2p';

  const playlistUrl = `https://api.music.apple.com/v1/catalog/us/playlists/${encodeURIComponent(REAL_BOOK_ID)}?include=tracks`;

  return fetch(playlistUrl, {
    headers: {
      Authorization: `Bearer ${generateToken()}`,
    },
  })
    .then((response) => response.json())
    .then(({ data }) => {
      const tracks = data[0].relationships.tracks.data;

      saveJSON(CACHED_FILE, tracks);

      return tracks;
    });
}

const prisma = new PrismaClient();
const tracks = await fetchPlaylist();

async function updateSong(id: string, name: string) {
  const song = await prisma.song.update({ where: { name }, data: { appleMusicId: id } });

  console.log(id, name, song ? '✅' : '🚫');
}

for (const track of tracks) {
  let name = track.attributes.name;
  if (name.match(/[([]/)) {
    name = name.split(/[([]/)[0].trim();
  }

  if (name === 'Brown-Eyed Woman') {
    name = 'Brown-Eyed Women';
  } else if (name === "That's It For the Other One") {
    name = 'The Other One';
  } else if (name === 'Turn On Your Love Light') {
    name = 'Turn On Your Lovelight';
  } else if (name === "Not Fade Away / Goin' Down the Road Feeling Bad") {
    const names = name.split(' / ');
    for (const title of names) {
      await updateSong(track.id, title);
    }
    continue;
  }

  await updateSong(track.id, name);
}
