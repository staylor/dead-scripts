import { createConfig } from '@wonderboymusic/oxc-config/oxlint';

export default createConfig({
  overrides: [
    {
      files: ['**/*.test.ts'],
      rules: {
        // The tests use node:test, which has no test.each
        'vitest/prefer-each': 'off',
      },
    },
  ],
});
