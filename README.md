**Pandoc-MarkdownResume** A modern resume generation tool built on the original [barraq/pandoc-moderncv](https://github.com/barraq/pandoc-moderncv). The build toolchain has been modernized: Ruby, Compass, and Susy have been replaced with Dart Sass (via npm) and a plain bash script. THis tool is fairly cus­tomiz­able, al­low­ing you to use predefined themes and to define your own style by changing colors, fonts, etc.

With **Pandoc-MarkdownResume** simply **write your resume in Markdown**, compile it and publish it in a snap!

Pandoc-MarkdownResume currently supports **pdf** and **html5** export formats. The html5 output is responsive and supports rendering for small to large screens.


**Note:** this project was previously named *Pandoc-ModernCV*. The repository is now `nanotubing/Pandoc-MarkdownResume`; old links redirect.

## Features

- write your resume in Markdown
- choose between themes
- customize your style
- export to HTML5
    + responsive layout (mobile, tablet, desktop)
    + print layout
- export to PDF
    + Letter format ready
    + PDF metadata (title, author, etc.)
    + tagged (accessible / ATS-friendly) structure
- publish public & private resume versions

## Preview & Screenshots

### HTML5

Live **html5** preview [here](https://nanotubing.github.io/Pandoc-MarkdownResume/preview/cv.html)

| ![Pandoc-MarkdownResume large-screen preview ](https://raw.githubusercontent.com/nanotubing/Pandoc-MarkdownResume/gh-pages/media/images/large-screen.png) |
| :----: |
| **Screenshot of the HTML scaffold resume taken for a large screen.**  |
| See also [medium-screen preview](https://raw.githubusercontent.com/nanotubing/Pandoc-MarkdownResume/gh-pages/media/images/medium-screen.png) or [small-screen preview](https://raw.githubusercontent.com/nanotubing/Pandoc-MarkdownResume/gh-pages/media/images/small-screen.png) |

### PDF

Live **pdf** preview [here](https://nanotubing.github.io/Pandoc-MarkdownResume/preview/cv.pdf)

| ![Pandoc-MarkdownResume PDF export preview ](https://raw.githubusercontent.com/nanotubing/Pandoc-MarkdownResume/gh-pages/media/images/cv-pdf.png) |
| :----: |
| **Screenshot of the PDF scaffold resume.** Notice the QR-Code  |

## Requirements

For building your resume in HTML you need:

- [Node.js & npm](https://nodejs.org/) — for Dart Sass
- [RSync](http://rsync.samba.org/)
- [Pandoc](https://pandoc.org/) (>= 1.13)

For exporting your resume to PDF you need:

- [Google Chrome](https://www.google.com/chrome/) — the PDF is rendered with headless Chrome via [Puppeteer](https://pptr.dev/) (installed by `npm install`). On a machine without Chrome, a Puppeteer-managed Chromium can be used instead (see Installation).
- [ExifTool](https://exiftool.org/)

## Installation

Installation instructions target MacOS, but this should probably run without issue in Linux systems.

Install Node.js dependencies (Dart Sass and Puppeteer):

    $ npm install

This does **not** download a browser. By default the PDF build uses your
system-installed **Google Chrome**. To render with a Puppeteer-managed Chromium
instead — e.g. on a machine without Chrome — install one once:

    $ npm run install-browser

and set `PDF_BROWSER=bundled` when building (see below).

Install **Pandoc** via Homebrew or the [official installer](https://pandoc.org/installing.html):

    $ brew install pandoc

Install **ExifTool** via Homebrew:

    $ brew install exiftool

**rsync** is pre-installed on macOS. On other systems you may need to install it via your package manager (e.g. `apt install rsync`, `dnf install rsync`, or `pacman -S rsync`). You are done!

## Getting Started

The simplest way to get started is to use the provided scaffold:

    $ ./build.sh scaffold
    $ ./build.sh html

This creates a starter resume in the `cv/` directory and builds an HTML version. To open it:

    $ open dist/cv.html

To export to PDF:

    $ ./build.sh pdf

To build both private and public variants:

    $ ./build.sh build

To deploy, define a `deploy()` function in `cv/build.conf` (see [Personal build settings](#personal-build-settings)), then run:

    $ ./build.sh deploy

### Personal build settings

Settings specific to you live in `cv/build.conf`, next to your resume content, so `build.sh` itself stays generic. The file is optional and is sourced as bash by `build.sh`. `./build.sh scaffold` creates a commented starter copy; if your `cv/` directory already exists, copy it in yourself:

    $ cp scaffolds/build.conf cv/

It supports:

| Setting | Purpose |
| :--- | :--- |
| `RESUME_NAME` | Base name for the named PDF copies from `./build.sh build` — `dist/<RESUME_NAME>.pdf` (public) and `dist/<RESUME_NAME>_full.pdf` (private). Default: `John_Doe` |
| `deploy()` | A shell function run by `./build.sh deploy`. It can contain any commands — `cp` to a local site checkout, `scp`/`rsync` to a server, a call to your own script — and runs from the repository root with `$DIST_DIR` and `$RESUME_NAME` available. Without it, `./build.sh deploy` exits with an error |

For example:

    RESUME_NAME=Jane_Smith

    deploy() {
        scp "$DIST_DIR/cv_public.pdf" user@example.com:/var/www/resume/$RESUME_NAME.pdf
    }

### PDF rendering

The PDF is rendered by headless Chrome via Puppeteer (`scripts/html2pdf.mjs`),
which produces a **tagged, ATS-friendly** PDF. Which browser it uses is
controlled by the `PDF_BROWSER` setting:

| `PDF_BROWSER` | Browser used |
| :--- | :--- |
| `chrome` (default) | System-installed Google Chrome; no download |
| `bundled` | Puppeteer-managed Chromium (`npm run install-browser` first) |
| `<path>` | An explicit browser executable |

You can set it either way:

- **As an environment variable**, to override the default for a single build:

      $ PDF_BROWSER=bundled ./build.sh build

- **By editing `build.sh`**, to change the default permanently — update the line near the top of the file:

      PDF_BROWSER=${PDF_BROWSER:-chrome}   # change "chrome" to e.g. "bundled"

  Because of the `${PDF_BROWSER:-chrome}` form, an environment variable (when set) still takes precedence over this default.

## Build Commands

| Command | Description |
| :--- | :--- |
| `./build.sh` | Default: builds HTML |
| `./build.sh style` | Compile SCSS to CSS only |
| `./build.sh media` | Copy fonts and images to dist/ |
| `./build.sh parts` | Build supplemental HTML parts from cv/*.md |
| `./build.sh html` | Full HTML build |
| `./build.sh pdf` | Build PDF from HTML |
| `./build.sh scaffold` | Create starter cv/ directory |
| `./build.sh clean` | Remove dist/ and build/ |
| `./build.sh build` | Build both private and public resume variants |
| `./build.sh deploy` | Run the `deploy()` function defined in `cv/build.conf` |

## ATS Legibility

Many employers screen resumes with an **Applicant Tracking System (ATS)** — software that parses a PDF's text and sorts it into fields (name, contact details, work history, skills) before a human reads it. When the parser garbles or drops content, strong applications get filtered out for reasons unrelated to the candidate. Pandoc-MarkdownResume is built to parse cleanly.

**What should happen when this resume is scanned:**

- **Real, selectable text** — the PDF is text, not an image, so every character is extractable without OCR.
- **Correct reading order** — the PDF is *tagged* (it carries a logical structure tree), so a parser reads it in the intended order: each job's title and dates, then that job's bullets, then the next job — not a scrambled dump.
- **Bullets read as a list** — experience bullets use native list markers, so the PDF carries real list structure (tagged list items) and each bullet's text extracts on its own clean line — no bullet glyph mixed into the copied text, and none of the markers drifting onto separate lines the way an absolutely-positioned bullet would.
- **Keywords match** — skills and technologies extract as plain ASCII, so a recruiter's keyword search finds them; typographic ligatures that would turn a word like "Leaflet" into an unmatchable "Leaﬂet" are decomposed by the renderer.
- **Clean metadata** — the PDF `Title`, `Author`, and `Subject` fields come from your resume metadata, which some systems read directly.
- **Familiar structure** — a single-column body, conventional section headings (Experience, Education, Skills…), and `Month YYYY` date ranges are all shapes parsers expect.

**Why it matters:** an ATS that misreads the reading order can staple your bullets to the wrong job, skip a keyword because of a stray ligature, or lose a detail in surrounding noise — and each of those is a silent rejection you never find out about. A tagged PDF with clean, in-order text is what separates being parsed *accurately* from being parsed *wrong*.

**Check it yourself:** open the PDF, select all, copy, and paste into a plain-text editor. It should read top-to-bottom in the right order, each bullet on its own line with its text, and your contact details intact. The renderer that produces this is described under [PDF rendering](#pdf-rendering).

## Customize

### Metadata

Your resume can be customized with metadata. Metadata are located between two --- separators at the top of the cv.md file and are formated using the YAML format:

    ---
    lang: en
    title: Résumé Title
    firstname: Firstname
    lastname: Lastname
    photo: images/picture.png
    email: contact@yoursite.com
    mobile: '+1 (234) 567 890'
    address:
      city: City
      country: Country
    settings:
      protect-mobile: true
      protect-email: true
    ---

    put here your *resume* data

Currently Pandoc-MarkdownResume supports the following metadata:

| key                     |  type    | value                          |
| :---------------------- | :------: | :----------------------------- |
| lang                    | string   | en                             |
| title                   | string   | Résumé Title                   |
| firstname               | string   | Firstname                      |
| lastname                | string   | Lastname                       |
| photo                   | url      | path/to/photo.png              |
| qrcode                  | url      | images/qrcode.png              |
| contact                 | url      | http://contact.yoursite.com    |
| homepage                | url      | http://yoursite.com            |
| email                   | email    | contact@yoursite.com           |
| mobile                  | string   | '+1 (234) 567 890'             |
| phone                   | string   | '+2 (345) 678 901'             |
| fax                     | string   | '+3 (456) 789 012'             |
| footer                  | markdown | **custom** *markdown* text     |
| **address**             | map      |                                |
|   street                | string   | 123 Example St                 |
|   city                  | string   | City                           |
|   zip                   | string   | 12345                          |
|   country               | string   | Country                        |
| **settings**            | map      |                                |
| protect-email           | boolean  | true/false (default: false)    |
| protect-mobile          | boolean  | true/false (default: false)    |
| protect-phone           | boolean  | true/false (default: false)    |
| protect-fax             | boolean  | true/false (default: false)    |
| protect-address         | boolean  | true/false (default: false)    |
| display-lastupdate      | boolean  | true/false (default: false)    |

### Private & Public resume

It is often handy to hide/show specific information in your resume depending on where it is published/sent. Pandoc-MarkdownResume supports **public** and **private** versions:

* when **public**:
    - protected metadata are removed.
    - *cv/public.md* is displayed just after the header and before the resume body.
* when **private**:
    - protected metadata are displayed.
    - *cv/private.md* is displayed just after the header and before the resume body.

#### Protecting Metadata

Currently Pandoc-MarkdownResume can protect the following metadata:

* email
* mobile
* phone
* fax
* address

Metadata can be (un)protected independently:

    ---
    ...
    settings:
      protect-mobile: true # this protects *mobile*
      protect-email: false # this unprotects *email*
    ---

#### Building Private/Public resume

The variant is selected with an environment variable. To build a public resume:

    $ public_cv=true ./build.sh html
    $ public_cv=true ./build.sh pdf

To build a private resume:

    $ private_cv=true ./build.sh html
    $ private_cv=true ./build.sh pdf

### Themes

Currently Pandoc-MarkdownResume supports a single theme: classic.

> Feel free to contribute and send your custom theme!

### Colors, Fonts, Icons

All themes can be customized through variables defined in *stylesheets/_settings.scss*. Currently the variables are:

    $base-font-size: 18px;
    $base-line-height: 23px;

    $photo-width: 182px;
    $qrcode-width: 100px;

    // Size
    $h1-font-size:      $base-font-size*2;
    $h1-line-multiple:  2;
    $h2-font-size:      $base-font-size*1.5;
    $h2-line-multiple:  1.5;
    $h3-font-size:      $base-font-size*1.2;
    $h3-line-multiple:  1;

    // Colors
    $firstname-color: rgb(0, 0, 0);
    $familyname-color: rgb(0, 0, 0);
    $title-color: rgb(89, 89, 89);
    $address-color: rgb(0, 0, 0);
    $section-rectangle-color: rgb(191, 191, 191);
    $section-title-color: rgb(89, 89, 89);

    // Icons
    $external-link-icon: $fa-var-external-link;
    $email-icon: $fa-var-envelope-o;
    $phone-icon: $fa-var-phone;
    $mobile-icon: $fa-var-mobile;
    $fax-icon: $fa-var-print;

## Authoring Notes

### Bullet lists in experience entries

To get proper `<ul><li>` rendering (required for correct PDF page breaks and styled bullets), separate the job title line from the first bullet with a **blank line**:

```markdown
**Job Title**, Start - End

* First bullet
* Second bullet
```

Without the blank line, pandoc merges the title and bullets into a single `<p>` with `<br />` separators. The CSS `page-break-inside: avoid` on `p` then prevents page breaks within the entire block, which can push large entries to the next page and leave most of the previous page blank.

## SCSS Architecture

The stylesheet system uses plain Dart Sass with no external CSS frameworks:

| File | Purpose |
| :--- | :--- |
| `_reset.scss` | CSS reset (replaces Compass reset) |
| `_settings.scss` | Colors, font sizes, icon variables |
| `_fa-var.scss` | FontAwesome icon variable map (`$fa-var-*`) |
| `_mixins.scss` | Vertical rhythm functions and float grid system (replaces Compass/Susy) |
| `_layouts.scss` | Responsive breakpoint variables and grid dimensions |
| `_fonts.scss` | FontAwesome @font-face and icon placeholder selectors |
| `style.scss` | Main entry point — imports all partials and defines layout rules |

To recompile the CSS after changing any `.scss` file:

    $ ./build.sh style
