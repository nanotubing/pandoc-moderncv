// Puppeteer configuration.
//
// Keep `npm install` lean: do NOT auto-download a Chromium build. The PDF build
// defaults to the system-installed Google Chrome (PDF_BROWSER=chrome in
// build.sh). To render with a Puppeteer-managed Chromium instead — e.g. on a
// machine without Chrome installed — set PDF_BROWSER=bundled and install the
// browser once with `npm run install-browser`.
module.exports = {
  skipDownload: true,
};
