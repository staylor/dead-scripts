import path from 'node:path';

import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'schema.prisma',
  migrations: {
    path: path.join('db', 'migrations'),
    seed: 'tsx src/prisma/seed.ts',
  },
  views: {
    path: path.join('db', 'views'),
  },
  typedSql: {
    path: path.join('db', 'queries'),
  },
  engine: 'classic',
  datasource: {
    url: 'file:dev.db',
  },
});
