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
HTMLTOPDF=${HTMLTOPDF:-wkhtmltopdf}
PRIVATE_CV=${private_cv:-false}
PUBLIC_CV=${public_cv:-false}

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
    # wkhtmltopdf resolves @font-face URLs relative to the HTML file, not the CSS
    # file. Putting the PDF CSS alongside cv.html (in dist/) and rewriting font
    # paths from ../fonts/ to fonts/ makes both resolve to dist/fonts/ correctly.
    sed 's|\.\./fonts/|fonts/|g' \
        "$DIST_DIR/stylesheets/style.css" > "$DIST_DIR/style-pdf.css"
    sed 's|href="stylesheets/style.css"|href="style-pdf.css"|' \
        "$DIST_DIR/cv.html" > "$DIST_DIR/cv-pdf.html"

    # wkhtmltopdf's QtWebKit loads @font-face fonts asynchronously and may snapshot
    # the page for printing before FontAwesome finishes loading, dropping the
    # external-link/contact glyphs (the :before icons). This race surfaces on the
    # shorter public CV, which renders fast enough to beat the font load.
    # --javascript-delay gives the font time to arrive before the snapshot.
    # See proposed_changes.md (#12) for the more robust data-URI font embed.
    wkhtmltopdf \
        --enable-local-file-access \
        --print-media-type \
        --page-size Letter \
        --javascript-delay 1500 \
        "$DIST_DIR/cv-pdf.html" "$DIST_DIR/cv.pdf"

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
    #preserve private resume before we build the public
    PRIVATE_CV=true cmd_pdf
    set -x  # Enable command echoing
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/cv_private.pdf"
    cp "$DIST_DIR/cv.pdf"  "$DIST_DIR/John_Doe_full.pdf"
    cp "$DIST_DIR/cv.html" "$DIST_DIR/cv_private.html"
    set +x  # Disable command echoing

    PUBLIC_CV=true cmd_pdf
    #also rename and preserve the public resume
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
