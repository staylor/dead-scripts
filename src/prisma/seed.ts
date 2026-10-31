import { PrismaClient } from '~/prisma/client/client';
import { readJSON } from '~/utils';
import { catalogFile, restoreCatalog } from '~/xcode/catalog';

const prisma = new PrismaClient();
try {
  await restoreCatalog(prisma, readJSON(catalogFile));
} finally {
  await prisma.$disconnect();
}
