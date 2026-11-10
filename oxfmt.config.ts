import { createConfig } from '@wonderboymusic/oxc-config/oxfmt';

export default createConfig({
  // Only code was formatted before, through ESLint
  ignorePatterns: ['**/*.{json,md,toml,yml,yaml}'],
});
