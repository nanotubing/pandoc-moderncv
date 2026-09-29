# Changelog

## Unreleased

### 2026-09-29 — Personal build settings move to `cv/build.conf`

`build.sh` no longer needs editing to personalize a build. It sources an optional `cv/build.conf`, which keeps user-specific values in `cv/` alongside the resume content (already ignored by this repo's `.gitignore`), so a private fork's `build.sh` can stay identical to upstream and merge cleanly.

- **`RESUME_NAME`** — base name for the named PDF copies made by `build` (`<RESUME_NAME>.pdf` / `<RESUME_NAME>_full.pdf`), replacing the hard-coded `John_Doe`. The default is unchanged.
- **`deploy()`** — `./build.sh deploy` now runs a user-defined shell function instead of a fixed copy to a hard-coded path, so deployment can be any command: `cp`, `scp`, `rsync`, a custom script. With no `deploy()` defined, the command exits with an error pointing at the example rather than writing anywhere.
- **Fixed:** the old `cmd_deploy` quoted its destination as `"~/src/example.com/resume"`, so the `~` never expanded and `mkdir -p` created a literal `./~/src/…` directory inside the repository.
- **`scaffolds/build.conf`** — a commented starter file, copied into `cv/` by `./build.sh scaffold`, with `cp`, `scp`, and custom-script deploy examples.

### 2026-09-07 — Renamed the project to Pandoc-MarkdownResume

The repository is now `nanotubing/Pandoc-MarkdownResume` (formerly `pandoc-moderncv`); GitHub redirects the old URLs. The checked-in files were updated to match:

- **`templates/pdf.metadata`** — the ExifTool `Creator` field stamped into every exported PDF is now `Pandoc-MarkdownResume`. This is the only user-visible artifact of the rename outside the docs.
- **`README.md`** — product name in prose, plus the GitHub Pages preview links and the `gh-pages` screenshot URLs, which now point at the new repo name (and use `https://` / `raw.githubusercontent.com` instead of the legacy `raw.github.com` redirect). A note records the former name.
- **`package.json` / `package-lock.json`** — the package is now named `pandoc-markdownresume` and marked `private`. `package.json` previously had no `name`, so npm derived the lock's name from the checkout directory; pinning it keeps the lockfile stable across clones.
- **`build.sh`, `scripts/html2pdf.mjs`** — header/inline comments only; no build logic depends on the project name.

Historical entries below are left as written, and the upstream fork attribution to [barraq/pandoc-moderncv](https://github.com/barraq/pandoc-moderncv) is unchanged — that project keeps its own name.

## 2.1 — 2026-07-27

ATS-legibility release. The PDF renderer moves off the unmaintained wkhtmltopdf to headless Chrome, which produces a *tagged* PDF with a declared reading order and decomposes typographic ligatures — the two properties that most affect how a CV parses in an Applicant Tracking System. Two follow-up fixes to the list markers and the `Title` metadata complete the change. There is no intended change to the visual output.

### 2026-07-27 — PDF renderer: wkhtmltopdf → headless Chrome (Puppeteer)

#### Switched the PDF renderer to headless Chrome via Puppeteer (`build.sh`, `scripts/html2pdf.mjs`)

The PDF build no longer uses **wkhtmltopdf** (an unmaintained engine built on Qt 4.8 WebKit). `cmd_pdf` now renders `dist/cv-pdf.html` with **headless Google Chrome driven by Puppeteer** (new helper `scripts/html2pdf.mjs`).

**Why this improves ATS legibility.** Applicant Tracking Systems read the PDF's text layer, and two properties of the old wkhtmltopdf output degraded that:

- **Untagged output.** wkhtmltopdf produced an *untagged* PDF (no structure tree), so a parser had no declared reading order and had to reconstruct one from glyph coordinates — fragile on this floated, partly two-column layout. Chrome emits a **tagged PDF** (`StructTreeRoot`, `MarkInfo /Marked true`) whose logical structure follows the HTML source order, giving ATS and assistive tech an explicit, correct reading order instead of a guess.
- **Ligatures broke keyword matching.** Palatino renders "fl"/"fi" as single ligature glyphs. wkhtmltopdf exported those as the ligature codepoint (e.g. `ﬂ`, U+FB02), so a word like "Leaflet" extracted as "Leaﬂet" and would never match a recruiter's keyword search (any word containing "fl" or "fi" was affected). Chrome's text extraction decomposes them to plain ASCII, so such words now **extract as matchable text**.

Deterministic font loading is a further benefit: the helper awaits `document.fonts.ready` before printing, guaranteeing FontAwesome and all `@font-face` assets are painted. This **retires the `--javascript-delay 1500` workaround** (see 2026-06-04) and the never-implemented data-URI font-embed follow-up it pointed to — both existed only to paper over wkhtmltopdf's async font-load race.

Rendering details handled in `scripts/html2pdf.mjs`:

- **Scale-to-fit.** The moderncv print layout is a fixed ~1060px desktop grid (`min-width: $lg-layout-min`). wkhtmltopdf shrank it to the paper via its "smart shrinking" feature; Chrome does not, so the helper measures the laid-out width (`document.body.offsetWidth`) and sets `page.pdf({ scale })` to fit the printable area, reproducing the previous proportions. Without it the layout overflows and clips off the right edge.
- Page geometry (Letter, 0.5in margins), background printing (the colored section markers), and tagged output are all configured in the `page.pdf()` call rather than relying on CSS `@page`.

#### Configurable browser via `PDF_BROWSER` (`build.sh`, `scripts/html2pdf.mjs`, `puppeteer.config.cjs`)

The renderer uses the full **`puppeteer`** package (rather than `puppeteer-core`, which is the "bring your own browser" build and cannot supply a Chromium). `PDF_BROWSER` in `build.sh` selects the browser:

- `chrome` (default) — the system-installed Google Chrome; no download.
- `bundled` — a Puppeteer-managed Chromium, for machines without Chrome; install it once with `npm run install-browser`.
- `<path>` — an explicit browser executable.

`puppeteer.config.cjs` sets `skipDownload: true` so `npm install` stays lean (no automatic ~150 MB Chromium download); the managed browser is fetched only on demand by `npm run install-browser`.

### 2026-07-27 — ATS legibility: native list bullets & clean Title metadata

Two follow-ups to the headless-Chrome renderer switch, both improving how the PDF parses in an Applicant Tracking System.

#### Experience bullets: native markers, aligned with the text (`stylesheets/style.scss`)

The experience bullets were drawn with an absolutely-positioned pseudo-element (`li::before { content: '\25CF'; position: absolute }`). Because that marker is out-of-flow generated content, it was written into the PDF *after* each line's text — so a naive content-stream / copy-paste extraction read the `●` on its own line after the bullet text, and the floated layout further clumped every job header before every bullet.

Replaced it with a **native `list-style-type: disc` marker** (`list-style-position: outside`) on the experience `> ul`, tinted via `li::marker { color: $section-rectangle-color }`. The marker is now in-flow and tagged as a list label (`Lbl`), so tag-aware parsers read a real list structure and the bullets interleave correctly with the job they belong to. Because `disc` is a *graphical* marker rather than a text glyph, naive extraction is also **cleaner** than before: each bullet line comes out as pure text with no stray `●` character injected.

`disc` specifically — rather than a custom `list-style-type: '\25CF'` string or a `::marker { content }` bullet — because those custom-marker techniques are **Chrome-only**. Safari and Firefox ignore them, which left the on-screen HTML with no visible bullets at all (the CSS reset sets `list-style: none`, so there was no fallback).

**Alignment and spacing** were corrected at the same time. `@include span-full` gives the `<ul>` `width: 100%` + `float: right`; with the default `content-box` sizing the `padding-left` overflowed past that width and pushed the marker into the left margin, hard against the text. Adding `box-sizing: border-box` keeps the list box inside the text column, and `padding-left: 1.2em` acts as a hanging indent — the disc now sits on the body-text left edge (aligned with the surrounding paragraphs and job titles), with a clear gap to the item text and wrapped lines self-aligning to that text.

#### Clean PDF `Title` metadata (`build.sh`, `cmd_pdf`)

A CV `title:` may use literal `|` separators; pandoc backslash-escapes them when stringifying `$title$` through `templates/pdf.metadata`, so a title like `Jane Doe | Engineer` landed in the PDF `Title` as `Jane Doe \| Engineer`. `cmd_pdf` now unescapes `build/pdftags.txt` (`sed 's/\\|/|/g'`) before ExifTool writes it, so the `Title` — which some ATS read directly — is clean.

---

## 2.0 — 2026-06-05

First public release of the modernized toolchain: Ruby, Compass, and Susy replaced with Dart Sass (via npm) and a `build.sh` driver, with no change to the visual output. The dated entries below detail the individual changes that make up this release.

---

## 2026-06-04 — FontAwesome glyph race in PDF

### Missing external-link/contact glyphs in PDF (`build.sh`)

FontAwesome glyphs (the external-link icon before each company entry, contact icons) intermittently failed to render in the PDF — reliably absent on the shorter public CV, present on the longer private CV.

Root cause: wkhtmltopdf's QtWebKit engine loads `@font-face` fonts asynchronously and sometimes snapshots the page for printing before FontAwesome finishes loading, leaving the `:before` pseudo-element glyphs unpainted. The font file is still embedded in the PDF (eventually pulled in), but the icons never paint. The shorter public document renders fast enough to beat the font load and lose the glyphs; the longer private document renders slowly enough that the font arrives first. Because it is a timing race, it is sensitive to system load and presents as intermittent.

Fixed by adding `--javascript-delay 1500` to the `wkhtmltopdf` invocation in `cmd_pdf`, which gives the font time to load before the print snapshot. This is a timing-based workaround; the robust permanent fix considered at the time was embedding the font as a base64 `data:` URI so it loads synchronously. (Superseded by the 2.1 renderer switch, which removed the race at its source.)

---

## 2026-06-04 — Housekeeping

### schema.org microdata fix (`templates/cv.html`)

The `<header>` element had a doubled `http://` prefix in its `itemtype` attribute (`http://http://schema.org/Person`) since the original fork. Corrected to `http://schema.org/Person`. No rendering impact; invalid structured data.

### Remove unused SCSS variables (`stylesheets/_settings.scss`)

Removed `$quote-color`, `$subsection-color`, and `$hint-color`. All three were upstream Compass template leftovers never referenced anywhere in the stylesheet.

### `build.sh` usage comment and dead CLI margins (`build.sh`)

- Added the missing `./build.sh build` entry to the usage comment at the top of the file.
- Corrected the `deploy` description, which still read "build public PDF+HTML" after the build/deploy split in April 2026.
- Removed `--margin-left`, `--margin-right`, `--margin-top`, and `--margin-bottom` flags from the `wkhtmltopdf` invocation in `cmd_pdf`. The CSS `@page` margin (1.5cm) takes precedence over wkhtmltopdf CLI margins when `--print-media-type` is active, so these flags were dead code.

### Dependency lockfile (`package-lock.json`)

Committed `package-lock.json` so that `npm ci` resolves the same Sass version on every machine. Without it, `npm install` re-resolves `^1.77.0` on each run and can silently pick up a different patch release.

---

## 2026-05-22 — PDF blank page fix

### Blank trailing page in PDF (`stylesheets/style.scss`)

The `<footer>` element in `templates/cv.html` always renders, even when empty (no `footer` metadata, `display-lastupdate` off). The CSS applied `rhythm-margin(1, 1)` to every `footer` — about 5em of margin and padding (~21mm) — creating a phantom block at the bottom of the last page that pushed the document onto a blank extra page.

Fixed by adding `footer { margin: 0; padding: 0; }` to the `@media print, projection` block. If the footer has visible content (e.g., `display-lastupdate: true`), it will still render correctly, just without the extra whitespace.

---

## 2026-04-29 — Separate Build and Deploy

### Build and Deploy split (`build.sh`)

Refactored the build process to separate building CV variants from deployment. Previously, `cmd_deploy()` was responsible for building both the private and public CV PDFs/HTML files before copying them to the site directory. This has been split into two discrete commands:

- **`./build.sh build`** — Generates both private and public CV variants:
  - Private versions: `cv_private.pdf`, `cv_private.html`, `John_Doe_full.pdf`
  - Public versions: `cv_public.pdf`, `cv_public.html`, `John_Doe.pdf`
- **`./build.sh deploy`** — Simply copies pre-built public CV files to `~/src/example.com/resume/`

Benefits:
- Clearer separation of concerns (build vs. deployment)
- Allows building CV variants without immediately deploying
- `deploy` can now be called independently after `build`, or as part of a CI/CD pipeline
- Updated README.md and dispatch table to reflect the new command

---



### PDF page break fix (`cv/cv.md`)

Pandoc merges consecutive lines separated only by trailing double-spaces into a single `<p>` block. The CSS rule `page-break-inside: avoid !important` on `p` was then forcing entire job entries (company link + title + all bullets) onto one page, leaving large blank gaps when the block was too tall. Fixed by separating job titles from bullet lists with a blank line in `cv.md`, which causes pandoc to render bullets as `<ul><li>` elements instead of `<br />`-separated lines inside a `<p>`. Page breaks now fall naturally within bullet lists.

### FontAwesome icons in PDF (`stylesheets/_fonts.scss`, `build.sh`)

FontAwesome glyphs (external link icon, contact icons) were rendering as question mark boxes in the PDF but correctly in HTML. Two causes:

1. **Query strings in font URLs** — `@font-face` URLs had `?v=4.0.3` suffixes which wkhtmltopdf resolves literally (looking for filenames containing `?`). Removed from all non-IE-hack URLs in `_fonts.scss`.

2. **wkhtmltopdf relative path resolution bug** — wkhtmltopdf resolves `@font-face` URLs relative to the HTML file, not the CSS file. Since the CSS lives in `dist/stylesheets/` and references `../fonts/`, wkhtmltopdf looks in the wrong directory. Workaround: `cmd_pdf` now generates a PDF-specific stylesheet (`dist/style-pdf.css`) with font paths rewritten from `../fonts/` to `fonts/`, alongside a PDF-specific HTML file (`dist/cv-pdf.html`) that references it. With both files in the same directory (`dist/`), the font path resolves correctly whether measured from the HTML or CSS.

The `cmd_html` after-body loop was also updated to exclude `cv-pdf.html` (a PDF-only build artifact) to prevent it from being appended to the main `dist/cv.html` as unstyled duplicate content.

### CSS spacing improvements (`stylesheets/style.scss`)

- **Experience bullets** — Replaced markdown `* item  ` (trailing double-space) syntax with proper `<ul><li>` rendering. Added `section > ul li::before` with `content: '\25CF'` and `color: $section-rectangle-color` to render colored round bullets consistent with the existing footer separator style.
- **Bullet list top margin** — Reduced from `leader(1)` (~1.28em) to `0.25em` to sit closer to the preceding job title.
- **Section title gap** — Added `> h2 + p, > h2 + ul, > h2 + dl { margin-top: 0.35em }` to reduce the gap between section headings and the first content element, without affecting spacing between subsequent paragraphs.
- **Education entry spacing** — Added `#education > dl > dt, #education > dl > dd { margin-top: 0.45em }` to tighten the gap between education entries specifically.

### SCSS deprecation warnings (`stylesheets/_mixins.scss`, `_layouts.scss`, `style.scss`, `build.sh`)

Dart Sass emits two categories of deprecation warnings for this codebase:

- **Slash division** (`/` used for division) — Fixed by adding `@use "sass:math"` to `_mixins.scss`, `_layouts.scss`, and `style.scss`, and replacing all `/` division expressions with `math.div()`. This is a hard error in Dart Sass 2.0.
- **`@import` rules** — Migrating to `@use`/`@forward` would require namespacing every variable and mixin reference throughout the stylesheets, a significant refactor with no functional benefit for this project. Suppressed with `--silence-deprecation=import` in the `build.sh` sass invocation instead.

### Build script readability (`build.sh`)

The after-body exclusion check in `cmd_html` was refactored from a compound `[[ ... || ... || ... ]] && continue` test to a `case` statement on `basename`, which is easier to read and extend.

---

## 2026-03-24 — Toolchain Modernization

### Why

The project was forked from [barraq/pandoc-moderncv](https://github.com/barraq/pandoc-moderncv) and had accumulated significant dependency rot. The core issue was **Compass**, the Ruby-based SCSS compiler and utility framework. Compass is effectively unmaintained and increasingly difficult to install on modern macOS systems — its gem dependencies conflict with current Ruby versions and it relies on native extensions that no longer build cleanly. The companion grid library **Susy 2** is similarly abandoned.

The goal of this work is to eliminate Ruby as a build dependency entirely, replace the legacy SCSS tooling with modern equivalents, simplify the build system, and remove a handful of other outdated artifacts — all without changing the visual output of the resume.

---

### Changes

#### Removed Ruby / Compass / Susy

**Deleted:** `.ruby-version`

The project no longer requires Ruby. Compass and Susy are gone. All functionality they provided has been reimplemented directly in SCSS or replaced by Dart Sass.

**Why Dart Sass:** It is the official, actively maintained Sass implementation. It is available as an npm package (`sass`), requires no native compilation, and works on any platform with Node.js. Compass has been in maintenance-only mode for years and produces deprecation warnings even on current Ruby.

---

#### New: `package.json`

Added a root-level `package.json` that tracks `sass` as a dev dependency. Running `npm install` is now the only setup step needed for SCSS compilation.

---

#### New: `stylesheets/_reset.scss`

Compass provided a CSS reset via `@import "compass/reset"`. This has been replaced with a standalone `_reset.scss` that reproduces the same reset rules (based on Eric Meyer's reset) without any Ruby dependency. The output CSS is functionally identical.

---

#### Rewritten: `stylesheets/_mixins.scss`

Compass provided two major groups of utilities that were used throughout `style.scss`:

**Vertical rhythm** (`compass/typography/vertical_rhythm`):
- `establish-baseline` — sets `font-size` and `line-height` on `html`
- `adjust-font-size-to($size, $lines)` — sets font-size + proportional line-height
- `rhythm($lines, $font-size)` — calculates em spacing relative to a font-size
- `leader($lines)` / `trailer($lines)` — margin-top / margin-bottom helpers
- `@include rhythm($top, $bottom)` — shorthand for symmetric margins and padding

All of these have been reimplemented as custom SCSS functions and mixins. The math is identical to what Compass produced; output values were verified against the compiled `dist/stylesheets/style.css`.

**Susy 2 float grid**:
Susy provided a 12-column percentage-based float grid. It compiled `@include span(8 of 12)` into the appropriate `float`, `width`, and `margin-right` declarations. The grid used:
- Container max-width: 59em (12 columns × 5em column-unit − 1em half-gutter)
- Column widths: percentage of container (e.g., 8 cols = 66.10%)
- Gutter: 1em (half of `$gutter-width`) as `margin-right`

This has been replaced with custom mixins (`span`, `span-last`, `span-full`, `push`, `pull`, `pad`, `container`) that produce percentage values matching Susy's output exactly. The `pct()` helper function converts em values to container-relative percentages.

Compass selector helpers (`nest()`, `headings()`) and the unit conversion function (`convert-length()`) have been replaced with direct SCSS equivalents.

---

#### Updated: `stylesheets/_layouts.scss`

Removed the `$susy: (...)` configuration map, which was only needed to configure the Susy gem. The underlying grid variables (`$total-columns`, `$column-width`, `$gutter-width`) are unchanged. Two new derived variables were added:

- `$half-gutter` — `$gutter-width / 2` (the actual margin-right Susy used between columns)
- `$container-width` — total grid width in em (59em), used for percentage calculations

---

#### Rewritten: `stylesheets/style.scss`

All Compass and Susy imports and mixin calls replaced with the new custom implementations:

- `@import "compass/reset"` → `@import "reset"`
- `@import "compass/typography/vertical_rhythm"` → removed (functions are now in `_mixins.scss`)
- `@import "susy"` → removed
- `@include establish-baseline` → inline `html { font-size / line-height }` block
- `@include span(last N of M)` → `@include span-last(N)`
- `@include span(N of M)` → `@include span(N)` (or `@include span-full` for full-width)
- `@include push(N)` / `@include pull(N of M)` → updated mixin calls
- `gutter()` → `pct($half-gutter)` (percentage of container)
- `span(N)` function → `span-width(N)` function
- `convert-length($qrcode-width, em)` → `px2em($qrcode-width)`
- `#{nest(...)}` selector helper → direct SCSS selectors
- `#{headings(2)}` → `h2, h3, h4, h5, h6`

---

#### Replaced: `Makefile` → `build.sh`

**Deleted:** `Makefile`

The Makefile was the build driver. It was straightforward but unfamiliar syntax for most contributors, and its dependency model added no real value for a project with this simple a build graph.

The old `build.sh` was a deployment-only wrapper that called `make pdf` and copied files to the site directory.

Both have been merged into a single new `build.sh` with one bash function per build target:

| Command | Replaces |
| :--- | :--- |
| `./build.sh style` | `make style` |
| `./build.sh media` | `make media` |
| `./build.sh parts` | `make parts` |
| `./build.sh html` | `make html` |
| `./build.sh pdf` | `make pdf` |
| `./build.sh scaffold` | `make scaffold` |
| `./build.sh clean` | `make clean` |
| `./build.sh deploy` | old `build.sh` (deployment to site) |

Additional improvements over the Makefile:
- Uses `SCRIPT_DIR` instead of a hardcoded path (`~/Documents/GitHub/pandoc-moderncv/`)
- Safer bash: `set -euo pipefail`

---

#### Updated: `templates/cv.html`

Removed the IE9 HTML5 shim:

```html
<!--[if lt IE 9]>
  <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
```

IE9 reached end of life in 2016. Beyond being dead code, this block loaded a script over plain `http://` (a mixed-content issue on any HTTPS-hosted page).

---

#### Updated: `README.md`

Rewrote the Requirements, Installation, and Getting Started sections to reflect the new toolchain. Replaced all `make` command references with `./build.sh` equivalents. Removed the Troubleshooting section, which was entirely focused on Compass/Ruby gem installation problems that no longer apply. Added a Build Commands reference table and an SCSS Architecture section.

---

## Upstream history (barraq/pandoc-moderncv)

The following releases predate the fork.

### 1.0.2

- Introduce protected address (#3)
- Fix wrong PDF generation with wkhtmltopdf (#9)
- Upgrade requirements: Pandoc > 1.13
- Upgrade to Compass 1.0 and Susy 2.1
- Improved README documentation
- Bug fixes (#10, #8)

### 1.0.1

- Improved README documentation
- Add support for setting PDF metadata (#2)

### 1.0.0

- Initial version
