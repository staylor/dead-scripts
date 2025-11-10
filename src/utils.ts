import { readFileSync, writeFileSync } from 'fs';

import type { Browser } from 'puppeteer';

export const ICLOUD_DIR = '/Users/scott/Documents/Scores/Lead Sheets/Grateful Dead';

const MARGIN = '1in';

export async function htmlToPdf(browser: Browser, html: string, file: string) {
  const page = await browser.newPage();
  await page.setContent(html);
  await page.pdf({
    path: file,
    format: 'legal',
    margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN },
  });

  return file;
}

export function readJSON(file: string) {
  return JSON.parse(readFileSync(file, { encoding: 'utf-8' }));
}

export function saveJSON(file: string, data: any) {
  writeFileSync(file, JSON.stringify(data, null, 2));
}
