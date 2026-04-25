#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOC_DIR="$REPO_ROOT/doc"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required tool: %s\n' "$1" >&2
    exit 1
  fi
}

render_pdf() {
  local input_html="$1"
  local output_pdf="$2"
  weasyprint "$input_html" "$output_pdf"
  printf 'Generated %s\n' "$output_pdf"
}

require_tool pandoc
require_tool weasyprint

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gbs-maglev-docs.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MAGLEV_HTML="$TMP_DIR/MAGLEV-BRANCH-USAGE.html"

pandoc \
  --from=gfm \
  --to=html5 \
  --standalone \
  --metadata title="Using the MagLev Branch" \
  "$DOC_DIR/MAGLEV-BRANCH-USAGE.md" \
  -o "$MAGLEV_HTML"

render_pdf "$MAGLEV_HTML" "$DOC_DIR/MAGLEV-BRANCH-USAGE.pdf"
render_pdf "$DOC_DIR/USER-MANUAL-REFERENCE.html" "$DOC_DIR/USER-MANUAL-REFERENCE.pdf"
render_pdf "$DOC_DIR/GemStone-Pharo-Bridge-User-Manual.html" "$DOC_DIR/GemStone-Pharo-Bridge-User-Manual.pdf"
