import { PrismaClient } from '~/prisma/client/client';
import { slugify } from '~/slugify';

import song from '.cache/lyrics/the-wheel.json';

const prisma = new PrismaClient();

// const authors = song.authors.map((text) => {
//   const [contribution, name] = text.split(': ').map((part) => part.trim());
//   return {
//     name,
//     slug: slugify(name),
//     contribution: contribution.toLowerCase(),
//   };
// });
// const writers = await Promise.all(
//   authors.map((author) =>
//     prisma.writer.upsert({
//       where: { slug_contribution: { slug: author.slug, contribution: author.contribution } },
//       update: {},
//       create: author,
//     })
//   )
// );

const slug = slugify(song.title);
// const album = await prisma.album.findUnique({ where: { slug: 'terrapin-station' } });
// const singer = await prisma.singer.findUnique({ where: { slug: 'bob-weir' } });
// const trackNumber = 4;
const data = {
  name: song.title,
  slug,
  // lyrics: song.lyrics,
  // fileName: `${song.title} Score.pdf`,
  // trackNumber,
  // album: {
  //   connect: { id: album?.id },
  // },
  // singer: {
  //   connect: { id: singer?.id },
  // },
  // writers: {
  //   connect: writers.map(({ id }) => ({ id })),
  // },
};

await prisma.song.upsert({
  where: { slug },
  update: { lyrics: song.lyrics },
  create: data,
});

// await prisma.song.create({});

// Don't hardcode
// const slug = 'greatest-story-ever-told';
// const lyrics =
//   "Moses come riding up on a quasar \nHis spurs was a-jingling, the door was ajar\nHis buckle was silver, his manner was bold \nI asked him to come on in out of the cold\nHis brain was boiling, his reason was spent\nNothing is borrowed, nothing is lent\nI asked him for mercy, he gave me a gun\nNow and again these things just got to be done\n\nAbraham and Isaac sitting on a fence \nGet right to work if you have any sense\nYou know the one thing we need is a left-hand monkey wrench\n\nGideon come in with his eyes on the floor\nSays, \"you ain't got a hinge, you can't close the door\"\nMoses stood up a full six foot ten\nSaid \"you can't close the door when the wall's caved in\"\nI asked him for water he poured me some wine \nWe finished the bottle then broke into mine\nYou get what you come for, you're ready to go\nAnd it's one in ten thousand done come for the show\n\nAbraham and Isaac digging on a well \nMama come quick with the water witch spell\nCool clear water where you can't never tell";

// await prisma.song.update({
//   where: { slug },
//   data: {
//     lyrics,
//   },
// });
