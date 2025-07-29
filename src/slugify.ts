import slugifyUtil from 'slugify';

const removePattern = /[#,$*_+~.()[]\/'"!-:@]/g;

export function slugify(value: string): string {
  return slugifyUtil(value, {
    lower: true,
    strict: true,
    remove: removePattern,
  });
}
