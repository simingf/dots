#!/usr/bin/env bash
set -euo pipefail

BREWFILE="${1:-$HOME/dots/Brewfile}"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

brew bundle dump --force --tap --formula --cask --no-restart --file="$TMPFILE"

{
  cat <<'EOF'
# file location: ${HOME}/dots/Brewfile
# Usage: brew bundle install --file=~/dots/Brewfile
#
# Aliases:
#   alias bbd='brew bundle dump --force --file=~/dots/Brewfile'
#   alias bbi='brew bundle install --file=~/dots/Brewfile'
#   alias bbc='brew bundle check --file=~/dots/Brewfile'
#   alias bbclean='brew bundle cleanup --file=~/dots/Brewfile'

# Install all casks to /Applications and adopt any existing app already present
cask_args appdir: "/Applications", fontdir: "/Library/Fonts", adopt: true

# ---- Taps ----
EOF
  grep '^tap ' "$TMPFILE" | sort
  echo
  echo "# ---- Formulae ----"
  grep '^brew ' "$TMPFILE" | sort
  echo
  echo "# ---- Casks ----"
  grep '^cask ' "$TMPFILE" | sed 's/, args: .*//' | sort
} > "$BREWFILE"

n_taps=$(grep -c '^tap ' "$BREWFILE" || true)
n_formulae=$(grep -c '^brew ' "$BREWFILE" || true)
n_casks=$(grep -c '^cask ' "$BREWFILE" || true)
echo "Wrote $BREWFILE: $n_taps taps, $n_formulae leaves, $n_casks casks."
