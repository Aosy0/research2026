#!/usr/bin/env bash
# Install TeX Live 2021 (the version Overleaf pins) on Linux.
#
# Reproduces the same frozen release as install/setup-texlive2021.ps1 does on
# Windows, so every machine compiles the WISS2026 template to the same PDF.
# The existing system TeX Live (if any) is not touched: nothing is installed
# system-wide and PATH is never modified. Only the install directory below is
# written.
#
# Usage:
#   install/setup-texlive2021.sh
#   TEXLIVE_INSTALL_PREFIX="$HOME/opt/texlive" install/setup-texlive2021.sh
#
# Takes ~15-40 min depending on the mirror.
#
# Working historic mirrors (verified 2026-09, same as the Windows setup):
#   https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final  (default)
#   http://ftp.uni-kl.de/pub/tug/historic/systems/texlive/2021/tlnet-final

set -euo pipefail

REPO="${REPO:-https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2021/tlnet-final}"
PREFIX="${TEXLIVE_INSTALL_PREFIX:-$HOME/texlive}"
TLROOT="$PREFIX/2021"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$SCRIPT_DIR/texlive2021-linux.profile"
if [ ! -f "$PROFILE" ]; then
  echo "profile not found: $PROFILE" >&2
  exit 1
fi

find_bin() {
  # TeX Live 2021 uses bin/<arch>-linux; the arch varies per machine.
  # platex is a symlink (-> eptex), so do not restrict to -type f.
  find "$TLROOT/bin" -maxdepth 2 \( -type f -o -type l \) -name platex 2>/dev/null | head -n 1
}

if [ -n "$(find_bin)" ]; then
  echo "TeX Live 2021 already present at $TLROOT (skipping base install)."
else
  WORK="$(mktemp -d)"
  ZIP="$WORK/install-tl.zip"
  echo "Downloading installer from $REPO ..."
  curl -fSL --retry 3 -o "$ZIP" "$REPO/install-tl.zip"
  unzip -q -o "$ZIP" -d "$WORK"
  INSTALLER="$(find "$WORK" -name install-tl -type f | head -n 1)"
  chmod +x "$INSTALLER"

  echo "Installing TeX Live 2021 to $TLROOT (this takes a while) ..."
  TEXLIVE_INSTALL_PREFIX="$PREFIX" "$INSTALLER" -no-gui -profile "$PROFILE" -repository "$REPO"
fi

PLATEX="$(find_bin)"
if [ -z "$PLATEX" ]; then
  echo "installation failed: platex not found under $TLROOT/bin" >&2
  exit 1
fi
BIN="$(dirname "$PLATEX")"
export PATH="$BIN:$PATH"

echo "=== platex ==="
"$PLATEX" --version | head -n 1

echo "=== installing extras (sttools, nidanfloat) ==="
"$BIN/tlmgr" --repository "$REPO" install sttools nidanfloat

echo "=== done. Build with WISS2026_Template_demo/build.sh ==="
