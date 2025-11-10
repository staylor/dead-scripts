// import fs from 'node:fs';

import type { Browser } from 'puppeteer';

import { htmlToPdf } from '~/utils';

import { cleanupChorus } from './utils';

interface Song {
  title: string;
  authors: string[];
  lyrics: string;
  slug: string;
}

export async function jsonToPdf(browser: Browser, song: Song) {
  const filename = `${process.cwd()}/pdf/${song.slug}.pdf`;
  // Uncomment to skip existing
  // if (fs.existsSync(filename)) {
  //   return filename;
  // }

  console.log('Creating PDF for:', song.title);

  const lines = cleanupChorus(song.lyrics).split('\n');
  let hasChorus = false;

  const styledHtml = `
    <html>
    <head>
      <style>
        body { font-family: 'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', sans-serif; margin: 0; padding: 0; }
        h1 { font-size: 18pt; line-height: 18pt; font-weight: bold; margin: 0 0 12pt; padding: 0; }
        h2 { font-size: 12pt; line-height: 1.2; font-weight: normal; margin: 0; padding: 0; }
        h3 { font-size: 11pt; line-height: 1.2; font-weight: normal; margin: 0; padding: 0; }
        h3:last-of-type { margin-bottom: 18pt; }
        p { font-size: 13pt; line-height: 1.2; margin: 0; padding: 0; }
        .break { margin-bottom: 12pt; }
        .chorus { margin: 12pt 0; }
        ${lines.length > 50 ? `.columns { column-count: 2; column-gap: 40px; }` : ''}
        strong { font-weight: bold; }
        em { font-style: italic; }
      </style>
    </head>
    <body>
      <h1>${song.title}</h1>
      ${song.authors.map((text) => `<h3>${text}</h3>`).join('')}
      <div class="columns">
      ${lines
        .map((line) => {
          const trimmed = line.trim();
          const text = trimmed;

          if (line === '') {
            return `<p class="break"></p>`;
          }

          if (line === 'Chorus' || line === 'Chorus - repeated') {
            const chorus = `<p${hasChorus ? ' class="chorus"' : ''}><strong>${line}</strong></p>`;

            if (line === 'Chorus') {
              hasChorus = true;
            }

            return chorus;
          }

          return `<p>${text}</p>`;
        })
        .join('')}
      </div>  
    </body>
    </html>
  `;

  return htmlToPdf(browser, styledHtml, filename);
}
