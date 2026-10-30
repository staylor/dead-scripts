export const normalizedName = (name: string) =>
  name.normalize().trim().replaceAll('’', "'").toLowerCase();

export const sameName = (a: string, b: string) => normalizedName(a) === normalizedName(b);

export function duplicateNames(entries: { name: string }[]): Set<string> {
  const seen = new Set<string>();
  const duplicates = new Set<string>();
  for (const { name } of entries) {
    const normalized = normalizedName(name);
    if (seen.has(normalized)) duplicates.add(normalized);
    seen.add(normalized);
  }
  return duplicates;
}

interface Recording {
  id: number;
  name: string;
  album: { name: string; artist: { name: string } | null } | null;
}

export function matchRecording<T extends Recording>(
  recordings: T[],
  track: { name: string; artistName: string; albumName: string }
): T | undefined {
  const matches = recordings.filter(
    (song) =>
      song.album?.artist &&
      sameName(song.name, track.name) &&
      sameName(song.album.name, track.albumName) &&
      sameName(song.album.artist.name, track.artistName)
  );
  return matches.length === 1 ? matches[0] : undefined;
}
