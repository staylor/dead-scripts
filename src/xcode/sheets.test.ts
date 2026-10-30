import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { syncSheets } from './sheets';

async function fixture(schema: Record<string, string>) {
  const root = await mkdtemp(path.join(tmpdir(), 'lead-sheets-'));
  const scoresDir = path.join(root, 'scores');
  const sheetsDir = path.join(root, 'Sheets');
  await mkdir(scoresDir);
  await mkdir(path.join(sheetsDir, 'pdfs'), { recursive: true });
  await writeFile(path.join(sheetsDir, 'schema.json'), JSON.stringify(schema));
  return { root, scoresDir, sheetsDir };
}

test('copies scores for different artists without relying on a Grateful Dead folder', async (t) => {
  const dirs = await fixture({
    'harbor-home': 'Harbor/Home.pdf',
    'northbound-home': 'Northbound/Home.pdf',
  });
  t.after(() => rm(dirs.root, { recursive: true, force: true }));
  await mkdir(path.join(dirs.scoresDir, 'Harbor'));
  await mkdir(path.join(dirs.scoresDir, 'Northbound'));
  await writeFile(path.join(dirs.scoresDir, 'Harbor/Home.pdf'), 'harbor score');
  await writeFile(path.join(dirs.scoresDir, 'Northbound/Home.pdf'), 'northbound score');
  const result = await syncSheets(
    [
      { slug: 'harbor-home', fileName: 'Harbor Home.pdf' },
      { slug: 'northbound-home', fileName: 'Northbound Home.pdf' },
    ],
    dirs
  );
  assert.deepEqual(result.changed, ['Harbor Home.pdf', 'Northbound Home.pdf']);
  assert.equal(
    await readFile(path.join(dirs.sheetsDir, 'pdfs/Northbound Home.pdf'), 'utf8'),
    'northbound score'
  );
});

test('uses the configured score root when no explicit root is passed', async (t) => {
  const dirs = await fixture({ first: 'configured-score.pdf' });
  const previous = process.env.XCODE_SCORES_DIR;
  process.env.XCODE_SCORES_DIR = dirs.scoresDir;
  t.after(async () => {
    if (previous === undefined) delete process.env.XCODE_SCORES_DIR;
    else process.env.XCODE_SCORES_DIR = previous;
    await rm(dirs.root, { recursive: true, force: true });
  });
  await writeFile(path.join(dirs.scoresDir, 'configured-score.pdf'), 'configured score');
  await syncSheets([{ slug: 'first', fileName: 'First.pdf' }], { sheetsDir: dirs.sheetsDir });
  assert.equal(
    await readFile(path.join(dirs.sheetsDir, 'pdfs/First.pdf'), 'utf8'),
    'configured score'
  );
});

for (const fileName of ['Home.pdf', 'home.pdf']) {
  test(`rejects conflicting output names before writing: ${fileName}`, async (t) => {
    const dirs = await fixture({ first: 'first.pdf', second: 'second.pdf' });
    t.after(() => rm(dirs.root, { recursive: true, force: true }));
    const existing = path.join(dirs.sheetsDir, 'pdfs/Home.pdf');
    await writeFile(existing, 'keep this score');
    await assert.rejects(
      syncSheets(
        [
          { slug: 'first', fileName: 'Home.pdf' },
          { slug: 'second', fileName },
        ],
        dirs
      ),
      /would both write/
    );
    assert.equal(await readFile(existing, 'utf8'), 'keep this score');
  });
}

test('allows recordings to explicitly share the same score', async (t) => {
  const dirs = await fixture({ first: 'shared.pdf', second: './shared.pdf' });
  t.after(() => rm(dirs.root, { recursive: true, force: true }));
  await writeFile(path.join(dirs.scoresDir, 'shared.pdf'), 'shared score');
  await syncSheets(
    [
      { slug: 'first', fileName: 'Shared.pdf' },
      { slug: 'second', fileName: 'Shared.pdf' },
    ],
    dirs
  );
  assert.deepEqual(await readdir(path.join(dirs.sheetsDir, 'pdfs')), ['Shared.pdf']);
});

test('does not write files outside the PDF directory', async (t) => {
  const dirs = await fixture({ first: 'first.pdf' });
  t.after(() => rm(dirs.root, { recursive: true, force: true }));
  await assert.rejects(
    syncSheets([{ slug: 'first', fileName: '../Home.pdf' }], dirs),
    /without directories/
  );
  assert.deepEqual(await readdir(path.join(dirs.sheetsDir, 'pdfs')), []);
});
