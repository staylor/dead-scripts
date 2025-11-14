import { exec } from 'node:child_process';

const albums = [
  [
    'reflections',
    'https://is1-ssl.mzstatic.com/image/thumb/Music60/v4/27/77/84/277784c7-b62a-57c8-d4a9-5229439132ca/20.jpg/{w}x{h}bb.jpg',
  ],
];

albums.forEach(([slug, url]) => {
  const resized = url.replace(/\{(w|h)\}/g, '1024');

  exec(`curl -o xcode/leadsheets/albums/${slug}.jpg ${resized}`);
});
