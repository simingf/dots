#!/usr/bin/env bash
set -euo pipefail

BREWFILE="${1:-$HOME/dots/Brewfile}"

if [[ ! -f "$BREWFILE" ]]; then
  echo "Brewfile not found: $BREWFILE" >&2
  exit 1
fi

# Extract formulae from Brewfile (handles tap-prefixed entries like hashicorp/tap/vault)
brewfile_formulae=$(grep '^brew ' "$BREWFILE" \
  | sed 's/brew "\(.*\)".*/\1/' \
  | sed 's|.*/||' \
  | sort)

# Extract casks (strip tap prefix if any, e.g. nikitabobko/tap/aerospace -> aerospace)
brewfile_casks=$(grep '^cask ' "$BREWFILE" \
  | sed 's/cask "\(.*\)".*/\1/' \
  | sed 's|.*/||' \
  | sort)

installed_formulae=$(brew leaves | sed 's|.*/||' | sort)
installed_casks=$(brew list --cask | sort)

formula_only_brewfile=$(comm -23 <(echo "$brewfile_formulae") <(echo "$installed_formulae"))
formula_only_installed=$(comm -13 <(echo "$brewfile_formulae") <(echo "$installed_formulae"))
cask_only_brewfile=$(comm -23 <(echo "$brewfile_casks") <(echo "$installed_casks"))
cask_only_installed=$(comm -13 <(echo "$brewfile_casks") <(echo "$installed_casks"))

exit_code=0

print_diff() {
  local label="$1" items="$2"
  if [[ -n "$items" ]]; then
    echo "$label"
    echo "$items" | sed 's/^/  /'
    exit_code=1
  fi
}

print_diff "Formulae in Brewfile but not installed:" "$formula_only_brewfile"
print_diff "Formulae installed but not in Brewfile:" "$formula_only_installed"
print_diff "Casks in Brewfile but not installed:"    "$cask_only_brewfile"
print_diff "Casks installed but not in Brewfile:"    "$cask_only_installed"

n_formulae=$(echo "$installed_formulae" | wc -l | tr -d ' ')
n_casks=$(echo "$installed_casks" | wc -l | tr -d ' ')
echo "$n_formulae leaves, $n_casks casks installed."

if [[ $exit_code -eq 0 ]]; then
  echo "Brewfile is in sync."
fi

exit $exit_code
