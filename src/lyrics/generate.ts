import { existsSync, copyFileSync } from 'node:fs';

import puppeteer from 'puppeteer';

import { slugify } from '../slugify';

import { createDocxFile } from './docx';
import { jsonToPdf } from './pdf';
import {
  getAuthorFile,
  getIcloudFile,
  getLyricsFromContent,
  getSongFile,
  readJSON,
  saveJSON,
} from './utils';

const lyricists = [
  ['robert-hunter', 'Robert Hunter', 'https://whitegum.com/cgi-bin/cgiwrap/acsa/findhun3.pl'],
  [
    'john-perry-barlow',
    'John Perry Barlow',
    'https://whitegum.com/cgi-bin/cgiwrap/acsa/findbarl.pl',
  ],
];

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();

// Create JSON index of songs, so that this can be replayed idempotently without the network
for (const [slug, name, url] of lyricists) {
  const songsFile = getAuthorFile(slug);
  if (existsSync(songsFile)) {
    console.log(`Songs file exists for ${name}`);
    continue;
  }

  console.log(`Extracting songs for ${name}`);

  await page.goto(url);

  const songs = await page.evaluate(() => {
    const songs = Array.from(document.querySelectorAll('td b a')) as HTMLAnchorElement[];
    return songs.map((song) => ({
      text: song.textContent?.trim() || '',
      url: song.href,
      slug: '',
    }));
  });
  // evaluate changes scope
  songs.forEach((song) => {
    song.slug = slugify(song.text);
  });

  saveJSON(songsFile, songs);
}

// Loop again, extracting data for each song
for (const [slug, , url] of lyricists) {
  const songsFile = getAuthorFile(slug);

  const songs = readJSON(songsFile);
  for (const song of songs) {
    const songFile = getSongFile(song.slug);
    if (existsSync(songFile)) {
      continue;
    }

    console.log(`Extracting song info for ${song.text}`);

    await page.goto(url);

    await page.evaluate((song) => {
      const links = Array.from(document.querySelectorAll('td b a')) as HTMLAnchorElement[];
      const elem = links.find((link) => link.href === song.url);

      elem?.click();
    }, song);

    await page.waitForNavigation({ waitUntil: 'networkidle2' });

    for (const frame of page.frames()) {
      const frameUrl = frame.url();
      if (!frameUrl.startsWith('https://whitegum.com/~acsa/songfile/')) {
        continue;
      }

      const content = await frame.content();
      const data = getLyricsFromContent(content);
      saveJSON(songFile, { ...data, slug: song.slug, url: song.url });
    }
  }
}

for (const [slug] of lyricists) {
  const authorFile = getAuthorFile(slug);
  const songs = readJSON(authorFile);

  for (const song of songs) {
    const songFile = getSongFile(song.slug);
    if (!existsSync(songFile)) {
      continue;
    }
    const data = readJSON(songFile);
    if (!data.lyrics) {
      continue;
    }

    // Create docx file in case we need to edit later and generate new PDF
    await createDocxFile(data);
    const filename = await jsonToPdf(browser, data);

    // Save file to iCloud folder to update book
    const dest = getIcloudFile(data);
    if (!existsSync(dest)) {
      continue;
    }
    console.log('Copying', data.title, 'to iCloud');
    copyFileSync(filename, dest);
  }
}

await browser.close();

process.exit(0);
