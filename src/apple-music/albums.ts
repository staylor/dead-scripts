import { exec } from 'node:child_process';

const albums = [
  [
    'so-many-roads',
    'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/2e/63/54/2e63549a-e2c2-3551-6285-76755b685d9f/mzi.lbgbxtgx.jpg/{w}x{h}bb.jpg',
  ],
];

albums.forEach(([slug, url]) => {
  const resized = url.replace(/\{(w|h)\}/g, '1024');

  exec(`curl -o xcode/leadsheets/albums/${slug}.jpg ${resized}`);
});
