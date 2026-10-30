import dotenv from '@dotenvx/dotenvx';

import { PrismaClient } from '~/prisma/client/client';
import { saveJSON } from '~/utils';

import { generateToken } from './jwt';
import { matchRecording } from './matching';

dotenv.config();

const CACHED_FILE = '.cache/playlist.json';

async function fetchPlaylist() {
  const playlistID = process.argv[2] ?? 'pl.u-xrY5WFkedj2p';
  const playlistUrl = `https://api.music.apple.com/v1/catalog/us/playlists/${encodeURIComponent(playlistID)}?include=tracks`;

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
const recordings = await prisma.song.findMany({
  select: {
    id: true,
    name: true,
    album: { select: { name: true, artist: { select: { name: true } } } },
  },
});

async function updateSong(
  id: string,
  name: string,
  attributes: { artistName: string; albumName: string }
) {
  const song = matchRecording(recordings, { ...attributes, name });
  if (!song) {
    console.warn(
      `🚫 ${attributes.artistName} · ${attributes.albumName} · ${name}: no unique match`
    );
    return;
  }
  await prisma.song.update({ where: { id: song.id }, data: { appleMusicId: id } });
  console.log(id, name, '✅');
}

for (const track of tracks) {
  if (track.type !== 'songs') continue;
  if (track.attributes.artistName !== 'Grateful Dead') {
    await updateSong(track.id, track.attributes.name, track.attributes);
    continue;
  }
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
      await updateSong(track.id, title, track.attributes);
    }
    continue;
  }

  await updateSong(track.id, name, track.attributes);
}
