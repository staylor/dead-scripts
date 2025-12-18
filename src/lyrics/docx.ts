import fs from 'node:fs';

import { Document, Paragraph, TextRun, HeadingLevel, Packer } from 'docx';

interface Song {
  title: string;
  authors: string[];
  lyrics: string;
  slug: string;
}

function createParagraph(text: string, opts = {}, textOpts = {}) {
  const styles = { font: 'Helvetica Neue Light', color: '#000000' };
  return new Paragraph({
    ...opts,
    children: [new TextRun({ ...styles, ...textOpts, text })],
  });
}

export async function createDocxFile(song: Song) {
  const filename = `${process.cwd()}/docx/${song.slug}.docx`;
  // if (fs.existsSync(filename)) {
  //   return filename;
  // }

  const lines = song.lyrics.split('\n');

  const document = new Document({
    revision: 1,
    sections: [
      {
        properties: {
          // This sets the page to Legal instead of A4 when opening in Pages
          page: {
            size: {
              orientation: 'portrait',
              width: 8.5 * 1440, // 8.5 inches × 1440 = 12240 twips
              height: 14 * 1440, // 14 inches × 1440 = 15840 twips
            },
          },
        },
        children: [
          createParagraph(
            song.title,
            {
              heading: HeadingLevel.TITLE,
            },
            {
              size: 36,
              bold: true,
            }
          ),
          createParagraph(' ', {}, { size: 24 }),
          ...song.authors.map((text) => createParagraph(text, { heading: HeadingLevel.HEADING_3 })),
        ],
      },
      {
        properties: {
          type: 'continuous',
          column: {
            count: lines.length > 50 ? 2 : 1,
            equalWidth: true,
          },
        },
        children: [
          ...lines.map((line) => {
            const trimmed = line.trim();
            let text = trimmed;
            if (['[chorus]', '[chorus - repeated]'].includes(text)) {
              text = text.replace(/[\[\]]/g, '').replace('chorus', 'Chorus');
            }
            return createParagraph(
              text,
              {},
              { size: 26, bold: text === 'Chorus' || text === 'Chorus - repeated' }
            );
          }),
        ],
      },
    ],
  });

  try {
    const buffer = await Packer.toBuffer(document);
    fs.writeFileSync(filename, buffer);
    console.log(`${song.slug}.docx created successfully!`);
    return filename;
  } catch (error) {
    console.error('Error creating document:', error);
  }
}
