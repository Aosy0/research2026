#!/usr/bin/env bash
# Build the WISS2026 template with TeX Live 2021 (the version Overleaf pins).
#
# Equivalent to WISS2026_Template_demo/build.ps1 on Windows: TeX Live 2021 is
# prepended to PATH only for this invocation, so the system TeX Live (if any)
# is left untouched and the template files are never modified.
#
# Usage:
#   WISS2026_Template_demo/build.sh            # build
#   WISS2026_Template_demo/build.sh --clean    # remove out/ first
#
# Output: WISS2026_Template_demo/out/wiss_template.pdf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${TEXLIVE_INSTALL_PREFIX:-$HOME/texlive}"
TLROOT="$PREFIX/2021"

if [ "$#" -gt 0 ] && { [ "$1" = "--clean" ] || [ "$1" = "-Clean" ]; }; then
  rm -rf "$SCRIPT_DIR/out"
  shift
fi

# platex is a symlink (-> eptex), so do not restrict to -type f.
PLATEX="$(find "$TLROOT/bin" -maxdepth 2 \( -type f -o -type l \) -name platex 2>/dev/null | head -n 1)"
if [ -z "$PLATEX" ]; then
  echo "TeX Live 2021 not found at $TLROOT." >&2
  echo "Run install/setup-texlive2021.sh first." >&2
  exit 1
fi
BIN="$(dirname "$PLATEX")"
export PATH="$BIN:$PATH"

cd "$SCRIPT_DIR"
# latexmkrc in this directory selects platex -> pbibtex -> dvipdfmx and out/.
if [ "$#" -eq 0 ]; then
  set -- wiss_template.tex
fi
exec latexmk "$@"
