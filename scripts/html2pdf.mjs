#!/usr/bin/env node
// html2pdf.mjs - render an HTML file to PDF with headless Chrome via Puppeteer.
//
// Replaces the previous wkhtmltopdf invocation in build.sh (cmd_pdf). Chrome
// produces correct text reading order and tagged (accessible / ATS-parseable)
// PDFs, and it waits for @font-face fonts deterministically
// (networkidle0 + document.fonts.ready), which retires the FontAwesome load
// race that QtWebKit/wkhtmltopdf worked around with --javascript-delay.
//
// Scale-to-fit: the moderncv print layout is a fixed ~1060px-wide desktop grid
// (forced via `min-width: $lg-layout-min` in the print @media block). wkhtmltopdf
// shrank that to the paper width via its "smart shrinking" feature; Chrome does
// not, so without help the layout overflows and clips off the right edge. We
// measure the laid-out width under print media and set page.pdf `scale` so the
// content fits the printable width, reproducing the old behavior.
//
// Usage:   node scripts/html2pdf.mjs <input.html> <output.pdf>
//
// Browser selection (env PDF_BROWSER, set from build.sh; default "chrome"):
//   chrome / system  - the locally installed Google Chrome (no download needed).
//   bundled          - a Chromium managed by Puppeteer, for machines without
//                      Chrome. Install it once with `npm run install-browser`.
//   <path>           - an explicit browser executable path.
// PUPPETEER_EXECUTABLE_PATH, if set, overrides all of the above.

import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer';

const [input, output] = process.argv.slice(2);
if (!input || !output) {
  console.error('Usage: node scripts/html2pdf.mjs <input.html> <output.pdf>');
  process.exit(1);
}

const url = pathToFileURL(resolve(input)).href;

// Letter page geometry, in CSS pixels (96px/in).
const PAGE_WIDTH_PX = 8.5 * 96; // 816
const MARGIN_IN = 0.5;
const PRINTABLE_WIDTH_PX = PAGE_WIDTH_PX - 2 * MARGIN_IN * 96; // 720

const browserPref = process.env.PDF_BROWSER || 'chrome';
const launchOptions = { headless: true };
if (process.env.PUPPETEER_EXECUTABLE_PATH) {
  launchOptions.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
} else if (browserPref === 'bundled') {
  // Leave channel/executablePath unset so Puppeteer uses its managed Chromium.
} else if (browserPref === 'chrome' || browserPref === 'system') {
  launchOptions.channel = 'chrome';
} else {
  // Any other value is treated as an explicit executable path.
  launchOptions.executablePath = browserPref;
}

let browser;
try {
  browser = await puppeteer.launch(launchOptions);
} catch (err) {
  if (browserPref === 'bundled') {
    console.error(
      'Could not launch a Puppeteer-managed browser. Install one first with:\n' +
        '  npm run install-browser',
    );
  }
  throw err;
}
try {
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle0' });
  await page.evaluateHandle('document.fonts.ready');

  // Measure the laid-out width under print media so we can shrink it to fit.
  // Use the body's border-box width (offsetWidth), not scrollWidth: the grid's
  // float:right / negative-margin rules inflate scrollWidth with phantom
  // overhang, which would over-shrink the page and leave it centered and narrow.
  await page.emulateMediaType('print');
  const layoutWidth = await page.evaluate(() => document.body.offsetWidth);
  const scale = Math.min(1, PRINTABLE_WIDTH_PX / layoutWidth);

  await page.pdf({
    path: output,
    format: 'Letter',
    printBackground: true,
    displayHeaderFooter: false,
    tagged: true,
    scale,
    margin: {
      top: `${MARGIN_IN}in`,
      right: `${MARGIN_IN}in`,
      bottom: `${MARGIN_IN}in`,
      left: `${MARGIN_IN}in`,
    },
  });
} finally {
  await browser.close();
}
