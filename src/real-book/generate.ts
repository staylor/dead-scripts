import * as fs from 'fs/promises';
import path from 'path';

import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';

import { ICLOUD_DIR } from '../utils';

import { createPages } from './pages';
import schema from './schema.json';
import { loadPDF } from './utils';

async function mergePDFs(paths: string[], pdfDir: string) {
  const mergedPdf = await PDFDocument.create();

  for (const pdfPath of paths) {
    const pdf = await loadPDF(pdfDir, pdfPath);
    const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
    copiedPages.forEach((page) => mergedPdf.addPage(page));
  }

  const font = await mergedPdf.embedFont(StandardFonts.Helvetica);

  const pages = mergedPdf.getPages();
  pages.forEach((page, idx) => {
    if (idx < 2) {
      return;
    }

    const { width } = page.getSize();
    const pageNumber = `${idx + 1}`;

    page.drawText(pageNumber, {
      x: width / 2 - 20, // centered
      y: 20, // 20 units from bottom
      size: 12,
      font,
      color: rgb(0, 0, 0),
    });
  });

  return mergedPdf.save();
}

async function orderPages(pdfDir: string) {
  const balanced = await Promise.all(
    schema.map(async (data) => {
      if (!data.title) {
        return data.files;
      }

      const loaded = await Promise.all(data.files.map((file) => loadPDF(pdfDir, file)));
      const count = loaded.reduce((acc, pdf) => {
        acc += pdf.getPageCount();
        return acc;
      }, 0);

      if (count % 2 === 0) {
        return data.files;
      }

      return [...data.files, 'blank.pdf'];
    })
  );
  return balanced.flatMap((arr) => arr);
}

await createPages();

const pdfs = await orderPages(ICLOUD_DIR);
const contents = await mergePDFs(pdfs, ICLOUD_DIR);
const filename = path.resolve(ICLOUD_DIR, 'real-book.pdf');
await fs.writeFile(filename, contents);

console.log('Real Book saved to', filename);

process.exit(0);
