import fs from 'node:fs';

import dotenv from '@dotenvx/dotenvx';

import all from '../real-book/metadata.json';

import { generateToken } from './jwt';

dotenv.config();

const metadata = all as any;

const searchUrl = (term: string) =>
  `https://api.music.apple.com/v1/catalog/us/search?term=${encodeURIComponent(term)}`;

const search = (slug: string, artist: string, album: string) =>
  fetch(searchUrl([artist, album].join(' ')), {
    headers: {
      Authorization: `Bearer ${generateToken()}`,
    },
  })
    .then((response) => response.json())
    .then(({ results }) => {
      const node = results.albums.data.find(
        ({ attributes: { name, artistName } }: any) =>
          artistName === artist && name.toLowerCase() === album.toLowerCase()
      );
      if (node) {
        console.log(slug, node.attributes.artwork.url);
      } else {
        console.log(slug, JSON.stringify(results.albums.data));
      }
    });

Object.entries(metadata.albums).forEach(async ([slug, data]) => {
  if (fs.existsSync(`xcode/leadsheets/albums/${slug}.jpg`)) {
    console.log(slug, 'already saved.');
    return;
  }

  const album = data as any;
  const artist = metadata.artists[album.artist].name;

  await search(slug, artist, album.name);

  // The API rate-limits
  await new Promise((resolve) => setTimeout(resolve, 1000));
});
