import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';

test('names can repeat after migration while slugs, data and relationships stay intact', () => {
  const db = new DatabaseSync(':memory:');
  try {
    const directory = path.resolve(import.meta.dirname, '../../db/migrations');
    const migrations = readdirSync(directory, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
    const change = migrations.indexOf('20261030160000_multi_artist_names');
    assert.notEqual(change, -1);
    for (const migration of migrations.slice(0, change)) {
      db.exec(readFileSync(path.join(directory, migration, 'migration.sql'), 'utf8'));
    }
    db.exec("INSERT INTO Artist (id, name, slug) VALUES (1, 'Harbor', 'harbor');");
    db.exec("INSERT INTO Singer (id, name, slug) VALUES (1, 'Casey', 'casey-one');");
    db.exec(
      "INSERT INTO Album (id, name, slug, artistId) VALUES (1, 'Greatest Hits', 'harbor-hits', 1);"
    );
    db.exec(
      "INSERT INTO Song (id, name, slug, albumId, singerId) VALUES (1, 'Home', 'harbor-home', 1, 1);"
    );
    const original = db.prepare('SELECT * FROM Song WHERE id = 1').get();
    const inserts = [
      "INSERT INTO Artist (id, name, slug) VALUES (2, 'Harbor', 'another-harbor');",
      "INSERT INTO Singer (id, name, slug) VALUES (2, 'Casey', 'casey-two');",
      "INSERT INTO Album (id, name, slug, artistId) VALUES (2, 'Greatest Hits', 'another-harbor-hits', 2);",
      "INSERT INTO Song (id, name, slug, albumId, singerId) VALUES (2, 'Home', 'another-harbor-home', 2, 2);",
    ];
    for (const sql of inserts) assert.throws(() => db.exec(sql), /UNIQUE constraint/);
    for (const migration of migrations.slice(change)) {
      db.exec(readFileSync(path.join(directory, migration, 'migration.sql'), 'utf8'));
    }
    for (const sql of inserts) db.exec(sql);
    assert.deepEqual(db.prepare('SELECT * FROM Song WHERE id = 1').get(), original);
    for (const table of ['Song', 'Album', 'Artist', 'Singer']) {
      const record = db.prepare(`SELECT slug FROM ${table} WHERE id = 1`).get()!;
      assert.throws(
        () =>
          db
            .prepare(`INSERT INTO ${table} (name, slug) VALUES (?, ?)`)
            .run('Another Name', record.slug),
        /UNIQUE constraint/
      );
    }
    assert.deepEqual(db.prepare('PRAGMA foreign_key_check').all(), []);
  } finally {
    db.close();
  }
});
