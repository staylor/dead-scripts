import assert from 'node:assert/strict';
import test from 'node:test';

import { duplicateNames, matchRecording, sameName } from './matching';

const recordings = [
  { id: 1, name: 'Home', album: { name: 'Greatest Hits', artist: { name: 'Harbor Trio' } } },
  { id: 2, name: 'Home', album: { name: 'Greatest Hits', artist: { name: 'Northbound' } } },
  { id: 3, name: 'Home', album: { name: 'Live', artist: { name: 'Harbor Trio' } } },
];

test('matches the recording by artist, album and title rather than title alone', () => {
  assert.equal(
    matchRecording(recordings, {
      name: 'Home',
      artistName: 'Northbound',
      albumName: 'Greatest Hits',
    })?.id,
    2
  );
  assert.equal(
    matchRecording(recordings, { name: 'Home', artistName: 'Harbor Trio', albumName: 'Live' })?.id,
    3
  );
});

test('does not guess when names are ambiguous or the release is missing', () => {
  const track = { name: 'Home', artistName: 'Harbor Trio', albumName: 'Greatest Hits' };
  assert.equal(matchRecording([...recordings, { ...recordings[0], id: 4 }], track), undefined);
  assert.equal(matchRecording(recordings, { ...track, albumName: 'Another Release' }), undefined);
  assert.equal(matchRecording([{ id: 5, name: 'Home', album: null }], track), undefined);
});

test('compares names consistently across case, whitespace and Unicode forms', () => {
  assert.equal(sameName('DON’T STOP', " don't stop "), true);
  assert.equal(sameName('Björk', 'Bjo\u0308rk'), true);
  assert.equal(
    matchRecording(recordings, {
      name: ' HOME ',
      artistName: 'northbound',
      albumName: 'GREATEST HITS',
    })?.id,
    2
  );
});

test('identifies ambiguous artist and singer names without treating them as identities', () => {
  assert.deepEqual(
    duplicateNames([{ name: 'Northbound' }, { name: ' NORTHBOUND ' }, { name: 'Harbor Trio' }]),
    new Set(['northbound'])
  );
});
