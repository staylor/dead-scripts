import fs from 'node:fs';
import path from 'node:path';

import { JSDOM } from 'jsdom';

import { ICLOUD_DIR } from '~/utils';

import type { Song } from './types';

const cacheDir = path.join(process.cwd(), '.cache');

export function getAuthorFile(slug: string) {
  const filename = `${slug}.json`;
  return path.join(cacheDir, filename);
}

export function getSongFile(slug: string) {
  const songFile = `${slug}.json`;
  return path.join(cacheDir, 'lyrics', songFile);
}

export function getIcloudFile(song: Song) {
  const songFile = `${song.slug}.pdf`;
  return path.join(ICLOUD_DIR, song.title.charAt(0), song.title, songFile);
}

function stripNotes(text: string) {
  return text.replaceAll(/\(note [a-zA-Z0-9]+?\)/g, '');
}

export function getLyricsFromContent(content: string) {
  const dom = new JSDOM(content);
  const doc = dom.window.document;
  const title = doc.title;
  let authors = doc.querySelector('p')?.textContent?.trim().split('\n');
  if (authors) {
    authors = authors
      .filter((author) => author.includes('Music: ') || author.includes('Lyrics: '))
      .map(stripNotes);
  }
  const blockquotes = Array.from(doc.querySelectorAll('blockquote'));
  let lyrics = blockquotes[0]?.textContent?.trim();
  if (blockquotes.length > 1) {
    const notes = blockquotes
      .find((quote) => quote.innerHTML.includes('href="#note'))
      ?.textContent?.trim();
    // if the blockquote contains notes
    if (notes) {
      lyrics = notes;
      console.log(`${title} contains notes!`);
    } else {
      // find the largest blockquote
      lyrics = blockquotes
        .map(({ textContent }) => textContent?.trim() || '')
        .reduce((a: string, b: string) => (a.length > b.length ? a : b), '');
      console.log(`${title} has to guess by picking the largest :(`);
    }
  }
  if (!lyrics) {
    return { title, authors };
  }
  return { title, authors, lyrics: stripNotes(lyrics) };
}
