import { PrismaClient } from '~/prisma/client/client';
import { saveJSON } from '~/utils';
import { catalogFile, exportCatalog } from '~/xcode/catalog';
import { syncSheets } from '~/xcode/sheets';

const prisma = new PrismaClient();
const catalog = await exportCatalog(prisma);
await prisma.$disconnect();

const songs = catalog.artists.flatMap((artist) => artist.albums.flatMap((album) => album.songs));
const { changed, removed } = await syncSheets(songs);
console.log(`Lead sheets: ${changed.length} updated, ${removed.length} removed`);

saveJSON(catalogFile, catalog);
