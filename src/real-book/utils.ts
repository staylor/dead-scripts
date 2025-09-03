import * as fs from 'fs/promises';
import path from 'path';

import { PDFDocument } from 'pdf-lib';

export async function loadPDF(pdfDir: string, pdfPath: string) {
  const file = path.resolve(pdfDir, pdfPath);
  const pdfBytes = await fs.readFile(file);
  return PDFDocument.load(pdfBytes);
}
