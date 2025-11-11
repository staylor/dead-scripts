import { exec } from 'node:child_process';

const artists = [
  [
    'bob-weir',
    'https://is1-ssl.mzstatic.com/image/thumb/AMCArtistImages211/v4/d4/02/c2/d402c294-59f8-62a8-13d7-86d6c7a57387/ami-identity-ac4e734d5033edaa37f415c0f7c2e051-2025-08-29T16-07-58.574Z_cropped.png/{w}x{h}bb.jpg',
  ],
  [
    'jerry-garcia',
    'https://is1-ssl.mzstatic.com/image/thumb/Features125/v4/b7/c9/44/b7c94498-4089-0b36-ffea-9838b13026d6/mzl.slafzagq.jpg/{w}x{h}bb.jpg',
  ],
  [
    'grateful-dead',
    'https://is1-ssl.mzstatic.com/image/thumb/Features125/v4/7e/7a/fa/7e7afa5b-5325-e4fb-6f08-3ca5269edbaa/mza_5644264792160067741.png/{w}x{h}bb.jpg',
  ],
];

artists.forEach(([slug, url]) => {
  const resized = url.replace(/\{(w|h)\}/g, '1024');

  exec(`curl -o xcode/leadsheets/artists/${slug}.jpg ${resized}`);
});
