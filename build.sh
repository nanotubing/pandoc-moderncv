#!/usr/bin/env bash
# build.sh - Build and deploy script for pandoc-moderncv
# Replaces Makefile + old build.sh (deployment wrapper)
#
# Usage:
#   ./build.sh               # default: html
#   ./build.sh style         # compile SCSS only
#   ./build.sh media         # copy fonts and images
#   ./build.sh parts         # build HTML parts from supplemental .md files
#   ./build.sh html          # full HTML build (media + style + parts + pandoc)
#   ./build.sh pdf           # build PDF from HTML
#   ./build.sh scaffold      # create starter cv/ directory
#   ./build.sh clean         # remove dist/ and build/
#   ./build.sh build         # build both private and public CV variants (PDF + HTML)
#   ./build.sh deploy        # copy pre-built public CV to example.com

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SRC_DIR=cv
BUILD_DIR=build
FONTS_DIR=fonts
DIST_DIR=dist
IMAGES_DIR=$SRC_DIR/images
SCAFFOLDS_DIR=scaffolds
DATE=$(date +'%Y:%m:%d')
PRIVATE_CV=${private_cv:-false}
PUBLIC_CV=${public_cv:-false}

# Browser used to render the PDF (scripts/html2pdf.mjs). Options:
#   chrome   - system-installed Google Chrome (default; no download needed)
#   bundled  - Chromium managed by Puppeteer, for machines without Chrome;
#              install it once with `npm run install-browser`
#   <path>   - an explicit browser executable path
PDF_BROWSER=${PDF_BROWSER:-chrome}

# ---- Targets ----

cmd_style() {
    mkdir -p "$DIST_DIR/stylesheets"
    npx sass \
        --style=compressed \
        --no-source-map \
        --silence-deprecation=import \
        stylesheets/style.scss \
        "$DIST_DIR/stylesheets/style.css"
}

cmd_media() {
    mkdir -p "$DIST_DIR"
    rsync -rupE "$FONTS_DIR" "$DIST_DIR"
    rsync -rupE "$IMAGES_DIR" "$DIST_DIR"
}

cmd_parts() {
    mkdir -p "$BUILD_DIR"
    for src in "$SRC_DIR"/*.md; do
        name=$(basename "$src" .md)
        [[ "$name" == "cv" ]] && continue
        pandoc \
            --section-divs \
            --from markdown+header_attributes \
            --variable=date:"$DATE" \
            --to html5 -o "$BUILD_DIR/$name.html" "$src"
    done
}

cmd_html() {
    cmd_media
    cmd_style
    cmd_parts

    local before_body=("--variable=privatecv")
    if [[ "$PRIVATE_CV" == "true" ]]; then
        before_body=("--variable=privatecv" "--include-before-body" "$BUILD_DIR/private.html")
    elif [[ "$PUBLIC_CV" == "true" ]]; then
        before_body=("--include-before-body" "$BUILD_DIR/public.html")
    fi

    local after_body=()
    for f in "$BUILD_DIR"/*.html; do
        # cv-pdf.html is a PDF-only artifact; including it here would duplicate
        # the entire resume as unstyled content at the bottom of dist/cv.html.
        case "$(basename "$f")" in
            public.html|private.html|cv-pdf.html) continue ;;
        esac
        after_body+=("$f")
    done

    pandoc --standalone \
        --section-divs \
        --template templates/cv.html \
        --from markdown+yaml_metadata_block+header_attributes+definition_lists+smart \
        --to html5 \
        "${before_body[@]}" \
        "${after_body[@]+"${after_body[@]}"}" \
        --variable=date:"$DATE" \
        --css stylesheets/style.css \
        --output "$DIST_DIR/cv.html" "$SRC_DIR/cv.md"
}

cmd_pdf() {
    cmd_html
    pandoc \
        --from markdown+yaml_metadata_block \
        --template templates/pdf.metadata \
        --wrap=none \
        --variable=date:"$DATE" \
        --output "$BUILD_DIR/pdftags.txt" "$SRC_DIR/cv.md"
    # pandoc backslash-escapes literal "|" characters in metadata when
    # stringifying $title$ through the metadata template, so a title containing
    # them would otherwise land in the PDF Title as "... \| ...". Unescape it.
    sed 's/\\|/|/g' "$BUILD_DIR/pdftags.txt" > "$BUILD_DIR/pdftags.clean" \
        && mv "$BUILD_DIR/pdftags.clean" "$BUILD_DIR/pdftags.txt"
    # Put the PDF CSS alongside cv.html (in dist/) and rewrite font paths from
    # ../fonts/ to fonts/ so both the HTML and the CSS resolve @font-face URLs to
    # dist/fonts/. (wkhtmltopdf resolved @font-face relative to the HTML file; this
    # layout is also correct for Chrome, which resolves relative to the CSS file.)
    sed 's|\.\./fonts/|fonts/|g' \
        "$DIST_DIR/stylesheets/style.css" > "$DIST_DIR/style-pdf.css"
    sed 's|href="stylesheets/style.css"|href="style-pdf.css"|' \
        "$DIST_DIR/cv.html" > "$DIST_DIR/cv-pdf.html"

    # Render with headless Chrome via Puppeteer (scripts/html2pdf.mjs). Chrome
    # produces correct reading order and tagged (ATS-parseable) PDFs, and waits
    # for @font-face fonts deterministically, so the FontAwesome load race that
    # required wkhtmltopdf's --javascript-delay no longer applies. Letter size,
    # margins, and background printing are configured in the helper script.
    PDF_BROWSER="$PDF_BROWSER" node scripts/html2pdf.mjs "$DIST_DIR/cv-pdf.html" "$DIST_DIR/cv.pdf"

    xargs exiftool "$DIST_DIR/cv.pdf" < "$BUILD_DIR/pdftags.txt"
}

cmd_scaffold() {
    if [[ -d "$SRC_DIR" ]]; then
        echo "$SRC_DIR already exists!"
    else
        rsync -rupE "$SCAFFOLDS_DIR/" "$SRC_DIR/"
        echo "$SRC_DIR created, enjoy!"
    fi
}

cmd_clean() {
    rm -rf "$DIST_DIR" "$BUILD_DIR"
}

cmd_build() {
    PRIVATE_CV=true cmd_pdf
    set -x  # Enable command echoing
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/cv_private.pdf"
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/John_Doe_full.pdf"
    cp "$DIST_DIR/cv.html" "$DIST_DIR/cv_private.html"
    set +x  # Disable command echoing

    PUBLIC_CV=true cmd_pdf
    set -x  # Enable command echoing
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/cv_public.pdf"
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/John_Doe.pdf"
    cp "$DIST_DIR/cv.html" "$DIST_DIR/cv_public.html"
    set +x  # Disable command echoing
}

cmd_deploy() {
    set -x  # Enable command echoing
    local dest="~/src/example.com/resume"
    mkdir -p "$dest"
    cp "$DIST_DIR/cv_public.pdf"  "$dest/John_Doe.pdf"
    cp "$DIST_DIR/cv_public.html" "$dest/index.html"
    rsync -rupE "$DIST_DIR/fonts"       "$dest"
    rsync -rupE "$DIST_DIR/images"      "$dest"
    rsync -rupE "$DIST_DIR/stylesheets" "$dest"
    set +x  # Disable command echoing
}

# ---- Dispatch ----

case "${1:-html}" in
    style|media|parts|html|pdf|scaffold|clean|build|deploy)
        "cmd_${1:-html}"
        ;;
    *)
        echo "Usage: $0 {style|media|parts|html|pdf|scaffold|clean|build|deploy}"
        exit 1
        ;;
esac
