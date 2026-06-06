**Pandoc-ModernCV** provides Pandoc fa­cil­i­ties for type­set­ting modern **cur­ricu­lums vi­tae in markdown**. Inspired by the well known Latex ModernCV, it is fairly cus­tomiz­able, al­low­ing you to use predefined themes and to define your own style by changing colors, fonts, etc.

> With **Pandoc-ModernCV** simply **write your CV in Markdown**, compile it and publish it in a snap!

Pandoc-ModernCV currently supports **pdf** and **html5** export formats. The html5 output is responsive and supports rendering for small to large screens.

> A modern resume generation tool built on the original [barraq/pandoc-moderncv](https://github.com/barraq/pandoc-moderncv). The build toolchain has been modernized: Ruby, Compass, and Susy have been replaced with Dart Sass (via npm) and a plain bash script.

## Features

> Writing a CV has never been so simple!

- write your CV in Markdown
- choose between themes
- customize your style
- export to HTML5
    + responsive layout (mobile, tablet, desktop)
    + print layout
- export to PDF
    + Letter format ready
    + PDF tags (title, author, etc.)
- publish public & private CV

## Preview & Screenshots

### HTML5

Live **html5** preview [here](http://nanotubing.github.io/pandoc-moderncv/preview/cv.html)

| ![Pandoc-ModernCV large-screen preview ](https://raw.github.com/nanotubing/pandoc-moderncv/gh-pages/media/images/large-screen.png) |
| :----: |
| **Screenshot of the HTML scaffold CV taken for a large screen.**  |
| See also [medium-screen preview](https://raw.github.com/nanotubing/pandoc-moderncv/gh-pages/media/images/medium-screen.png) or [small-screen preview](https://raw.github.com/nanotubing/pandoc-moderncv/gh-pages/media/images/small-screen.png) |

### PDF

Live **pdf** preview [here](http://nanotubing.github.io/pandoc-moderncv/preview/cv.pdf)

| ![Pandoc-ModernCV PDF export preview ](https://raw.github.com/nanotubing/pandoc-moderncv/gh-pages/media/images/cv-pdf.png) |
| :----: |
| **Screenshot of the PDF scaffold CV.** Notice the QR-Code  |

## Requirements

For building your CV in HTML you need:

- [Node.js & npm](https://nodejs.org/) — for Dart Sass
- [RSync](http://rsync.samba.org/)
- [Pandoc](https://pandoc.org/) (>= 1.13)

For exporting your CV to PDF you need:

- [wkhtmltopdf](https://wkhtmltopdf.org/)
- [ExifTool](https://exiftool.org/)

## Installation

Install Node.js dependencies (Dart Sass):

    $ npm install

Install **wkhtmltopdf** via Homebrew (macOS):

    $ brew install wkhtmltopdf

Install **Pandoc** via Homebrew or the [official installer](https://pandoc.org/installing.html):

    $ brew install pandoc

Install **ExifTool** via Homebrew:

    $ brew install exiftool

**rsync** is pre-installed on macOS. You are done!

## Getting Started

The simplest way to get started is to use the provided scaffold:

    $ ./build.sh scaffold
    $ ./build.sh html

This creates a starter CV in the `cv/` directory and builds an HTML version. To open it:

    $ open dist/cv.html

To export to PDF:

    $ ./build.sh pdf

To build both private and public variants:

    $ ./build.sh build

To deploy, edit the destination path in `cmd_deploy` (in `build.sh`), then run:

    $ ./build.sh deploy

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
| `./build.sh build` | Build both private and public CV variants |
| `./build.sh deploy` | Copy public CV to the site directory set in `build.sh` |

## Customize

### Metadata

Your CV can be customized with metadata. Metadata are located between two --- separators at the top of the cv.md file and are formated using the YAML format:

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

    put here your *CV* data

Currently Pandoc-ModernCV supports the following metadata:

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

### Private & Public CV

It is often handy to hide/show specific information in your CV depending on where it is published/sent. Pandoc-ModernCV supports **public** and **private** CVs:

* when **public**:
    - protected metadata are removed.
    - *cv/public.md* is displayed just after the header and before the CV body.
* when **private**:
    - protected metadata are displayed.
    - *cv/private.md* is displayed just after the header and before the CV body.

#### Protecting Metadata

Currently Pandoc-ModernCV can protect the following metadata:

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

#### Building Private/Public CV

The variant is selected with an environment variable. To build a public CV:

    $ public_cv=true ./build.sh html
    $ public_cv=true ./build.sh pdf

To build a private CV:

    $ private_cv=true ./build.sh html
    $ private_cv=true ./build.sh pdf

### Themes

Currently pandoc-moderncv supports a single theme: classic.

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
