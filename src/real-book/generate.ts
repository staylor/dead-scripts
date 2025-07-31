import * as fs from 'fs/promises';
import path from 'path';

import { PDFDocument } from 'pdf-lib';

import { ICLOUD_DIR } from './constants';
import { createPages } from './pages';
import schema from './schema.json';

async function mergePDFs(paths: string[], pdfDir: string) {
  const mergedPdf = await PDFDocument.create();

  for (const pdfPath of paths) {
    const file = path.resolve(pdfDir, pdfPath);
    const pdfBytes = await fs.readFile(file);
    const pdf = await PDFDocument.load(pdfBytes);
    const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
    copiedPages.forEach((page) => mergedPdf.addPage(page));
  }

  return mergedPdf.save();
}

const pdfs = schema.flatMap((data) => data.files);

await createPages();

const contents = await mergePDFs(pdfs, ICLOUD_DIR);
const filename = path.resolve(ICLOUD_DIR, 'real-book.pdf');
await fs.writeFile(filename, contents);

console.log(`Merged PDF saved to ${filename}`);

process.exit(0);
