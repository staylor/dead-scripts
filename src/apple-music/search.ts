import dotenv from '@dotenvx/dotenvx';

import { generateToken } from './jwt';

dotenv.config();

const searchUrl = (term: string) =>
  `https://api.music.apple.com/v1/catalog/us/search?term=${encodeURIComponent(term)}`;

export const search = (slug: string, artist: string, album: string) =>
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
