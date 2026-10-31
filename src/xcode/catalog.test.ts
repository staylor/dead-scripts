import assert from 'node:assert/strict';
import { mkdtemp, readdir, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import test, { type TestContext } from 'node:test';

import { PrismaClient } from '~/prisma/client/client';

import { catalogFile, exportCatalog, restoreCatalog } from './catalog';

async function emptyDatabase(t: TestContext) {
  const root = await mkdtemp(path.join(tmpdir(), 'catalog-'));
  const file = path.join(root, 'catalog.db');
  const db = new DatabaseSync(file);
  const migrations = path.resolve(import.meta.dirname, '../../db/migrations');
  for (const entry of (await readdir(migrations, { withFileTypes: true })).sort((a, b) =>
    a.name.localeCompare(b.name)
  )) {
    if (entry.isDirectory()) {
      db.exec(await readFile(path.join(migrations, entry.name, 'migration.sql'), 'utf8'));
    }
  }
  db.close();

  const prisma = new PrismaClient({ datasourceUrl: `file:${file}` });
  t.after(async () => {
    await prisma.$disconnect();
    await rm(root, { recursive: true, force: true });
  });
  return prisma;
}

test('the committed catalog restores into a database that exports it unchanged', async (t) => {
  const prisma = await emptyDatabase(t);
  const committed = await readFile(catalogFile, 'utf8');
  await restoreCatalog(prisma, JSON.parse(committed));
  const exported = await exportCatalog(prisma);
  assert.deepEqual(JSON.parse(JSON.stringify(exported)), JSON.parse(committed));
  assert.equal(JSON.stringify(exported, null, 2), committed);
});

test('restoring leaves a database that already has a catalog untouched', async (t) => {
  const prisma = await emptyDatabase(t);
  await prisma.artist.create({ data: { name: 'Harbor', slug: 'harbor' } });
  await assert.rejects(
    restoreCatalog(prisma, JSON.parse(await readFile(catalogFile, 'utf8'))),
    /already has a catalog/
  );
  assert.deepEqual(await prisma.artist.findMany({ select: { slug: true } }), [{ slug: 'harbor' }]);
  assert.equal(await prisma.song.count(), 0);
});
