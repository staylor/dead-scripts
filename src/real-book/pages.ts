import path from 'path';

import puppeteer from 'puppeteer';

import { htmlToPdf } from '../utils';

import { ICLOUD_DIR } from './constants';
import schema from './schema.json';

export async function createPages() {
  const browser = await puppeteer.launch({ headless: true });

  const html = `<html>
    <head>
      <style>
        * { margin: 0; padding: 0;}
        body { font-family: 'Helvetica Neue', sans-serif; }
        h1 { font-size: 30pt; line-height: 1.2; font-weight: bold; }
        h2 { font-size: 20pt; line-height: 1.2; font-weight: normal; }
      </style>
    </head>
    <body>
      <h1>Grateful Dead</h1>
      <h2>Real Book</h2>
    </body>
  </html>`;

  await htmlToPdf(browser, html, path.join(ICLOUD_DIR, 'page-one.pdf'));
  await htmlToPdf(browser, '', path.join(ICLOUD_DIR, 'blank.pdf'));

  let count = 0;
  const items = [];

  for (const entry of schema) {
    if (entry.title) {
      items.push(
        `<li><strong>${String(count + 1).padStart(2, '0')}</strong> <span>${entry.title}</span></li>`
      );
    }
    count += entry.files.length;
  }

  const toc = `<html>
    <head>
      <style>
        * { margin: 0; padding: 0;}
        body { font-family: 'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', sans-serif; }
        ul { column-count: 3; column-gap: 20pt; }
        li { display: flex; align-items: flex-start; margin-bottom: 10pt; font-size: 10pt; line-height: 1.2; }
        strong { width: 30px; flex: 0 0 auto; }
        span { flex: 1 1 auto; }
      </style>
    </head>
    <body>
      <ul>
        ${items.join('')}
      </ul>
    </body>
  </html>`;

  await htmlToPdf(browser, toc, path.join(ICLOUD_DIR, 'table-of-contents.pdf'));
}
