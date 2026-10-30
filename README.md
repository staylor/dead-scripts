# dead-scripts

Install dependencies with [pnpm](https://pnpm.io) (`pnpm install`). The `packageManager` field in `package.json` pins the version.

## `pnpm lyrics`

There are too many songs in the Grateful Dead universe to attempt to copy-paste them by hand and create PDFs that can be used in a collection, so we must automate file generation as much as possible.

This script uses `puppeteer` to scrape all of the Robert Hunter and John Perry Barlow lyrics from whitegum.com. The site originates from the '90s, so it uses Perl and `<frameset>`s, and won't let you access individual `<frame>` contents directly in the browser, so Puppeteer is used to:

- scrape the index-like pages for each lyricist to get the title and URLs for each song, and save to a JSON file for each lyricist
- in the JSON output, we create a slug for every song, so we can identify it across datasets
- we then load the JSON for each lyricist and loop through every song
- for each song's URL, we can't navigate directly to it in a browser, because individual `<frame>` URLs cannot be loaded outside of the `<frameset>` - so instead, we must load the index page for the lyricist, find the `<a>` in the page that matches the song's URL, and click the link using Puppeteer within `page.evaluate()` and wait for it to load
- once the page has loaded, we can use Puppeteer to loop through each `<frame>` and find the one that has a URL with the pattern used for song pages - for that frame, we read its content and pass it to `JSDOM`
- once in `JSDOM`, we use heuristics to figure out which `<blockquote>` in the output contains the lyrics
- we save the lyrics to a JSON file with some metadata about the song, also scraped from the page

> We store these JSON files in `.cache`, so we can replay the script idempotently later, even if the network is down. Once we store the JSON for every song, we don't need to hit whitegum dot com ever again, or worry about being rate-limited or blocked. Many other Dead lyrics sites forbid scraping (I tried).

We then loop through the index pages for each lyricist again to:

- generate a PDF of each song using `puppeteer` - Puppeteer allows you load HTML/CSS and then save it to a PDF, pretty cool!
- generate a DOCX file of each using the `docx` lib - we do this in case we want to edit any of the pages later. Since this is automated, we lose nothing by running this script for every song. We use the same-ish styles from the PDF script to create identical formatted content.

## `pnpm real-book`

**tl;dr creates a Grateful Dead Real Book by combining many PDFs into 1 PDF - a collection/book of lyrics and lead sheets.**

The main advantages to programmatically creating this book are the following:

- use HTML/CSS to create PDFs for cover page, Table of Contents, etc
- Table of Contents is dynamic, so you can author pages out-of-order and always have an up-to-date TOC sorted automatically with accurate page numbers
- Page layout is determined by a schema written in JSON, PDFs are combined using `pdf-lib`
- TODO: page numbers can be added to existing PDFs programmatically, so you never have to consider managing these manually

## `pnpm xcode`

Exports all artists, albums and songs in the database to the Dead Sheets app in [`xcode/`](xcode/README.md): `seeds.json` and the score PDFs listed in `xcode/Sheets/schema.json`. The output is committed, so only run it when songs or scores change. `pnpm apple-music` looks up the Apple Music IDs of albums, artists and singers that don't have one, and lists candidates for those it can't match. The app shows their artwork from Apple Music, so none of it is bundled. Apple Music IDs are optional; ambiguous artist or singer names need an ID set manually.

The database uses globally unique slugs, not unique display names. Different artists can have songs called “Home” or albums called “Greatest Hits”; give each recording and release a distinct slug and preserve existing slugs. After backing up the database, apply schema changes with `pnpm exec prisma migrate deploy` and regenerate the client with `pnpm exec prisma generate`. The multi-artist migration changes only name indexes, not existing rows or IDs.

Set `XCODE_SCORES_DIR=/path/to/scores` to export scores from another root. `xcode/Sheets/schema.json` maps song slugs to paths under that root, so each artist can have its own folder. The existing Grateful Dead scores folder remains the default. Output PDF filenames must be distinct, including case, unless recordings explicitly share the same source score. Conflicting filenames are rejected before any score is written.

The lyrics scraper, Real Book generator and legacy seed script remain specific to the original Grateful Dead collection. They are not required to add other artists to the database or export the app.

## Tests

`pnpm test` (Node.js 24) checks database migrations, recording matching and score export using temporary data. It does not use your database, iCloud files or Apple Music credentials.
