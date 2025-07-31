import type { Browser } from 'puppeteer';

export async function htmlToPdf(browser: Browser, html: string, file: string) {
  const page = await browser.newPage();
  await page.setContent(html);
  await page.pdf({
    path: file,
    format: 'letter',
    margin: { top: '1in', right: '1in', bottom: '1in', left: '1in' },
  });
}
