import { execFileSync } from 'child_process';
import { readdir, readFile, rm, writeFile } from 'fs/promises';
import path from 'path';

import { ICLOUD_DIR } from '~/utils';

interface SheetSong {
  slug: string;
  fileName: string | null;
}

const convertScript = path.join(process.cwd(), 'xcode', 'convert_pdfs.swift');

/**
 * Copies each song's score from iCloud Drive into `Sheets/pdfs`, finding it through
 * `Sheets/schema.json`, and renders tvOS images for the scores that changed. The sheets are
 * committed, so files that haven't changed are left untouched.
 */
export async function syncSheets(
  songs: SheetSong[],
  {
    scoresDir = ICLOUD_DIR,
    sheetsDir = path.join(process.cwd(), 'xcode', 'Sheets'),
  }: { scoresDir?: string; sheetsDir?: string } = {}
) {
  const schema: Record<string, string> = JSON.parse(
    await readFile(path.join(sheetsDir, 'schema.json'), 'utf8')
  );

  const problems = songs.flatMap((song) => {
    if (!song.fileName) {
      return [`${song.slug} has no fileName`];
    }
    if (!schema[song.slug]) {
      return [`${song.slug} has no score in Sheets/schema.json`];
    }
    return [];
  });
  if (problems.length > 0) {
    throw new Error(`Can't update the lead sheets:\n${problems.join('\n')}`);
  }

  const pdfsDir = path.join(sheetsDir, 'pdfs');
  const imagesDir = path.join(sheetsDir, 'images');
  const pdfs = songs.map((song) => song.fileName!);
  const changed: string[] = [];

  for (const song of songs) {
    const score = await readFile(path.join(scoresDir, schema[song.slug]));
    const destination = path.join(pdfsDir, song.fileName!);
    const current = await readFile(destination).catch(() => undefined);
    if (!current?.equals(score)) {
      await writeFile(destination, score);
      changed.push(song.fileName!);
    }
  }

  const removed = [
    ...(await removeAllExcept(pdfsDir, new Set(pdfs), '.pdf')),
    ...(await removeAllExcept(imagesDir, new Set(pdfs.map(imageName)), '.png')),
  ];

  const images = new Set(await readdir(imagesDir));
  const rendered = pdfs.filter((pdf) => changed.includes(pdf) || !images.has(imageName(pdf)));
  if (rendered.length > 0) {
    // convert_pdfs.swift reads Sheets/pdfs and writes Sheets/images relative to where it runs.
    execFileSync('swift', [convertScript, ...rendered], {
      cwd: path.dirname(sheetsDir),
      stdio: 'inherit',
    });
  }

  return { changed, rendered, removed };
}

function imageName(pdf: string) {
  return pdf.replace(/\.pdf$/, '.png');
}

async function removeAllExcept(dir: string, keep: Set<string>, extension: string) {
  const stale = (await readdir(dir)).filter((file) => file.endsWith(extension) && !keep.has(file));
  await Promise.all(stale.map((file) => rm(path.join(dir, file))));
  return stale;
}
