#!/bin/bash
# Sets an orange Finder label on every Homebrew cask .app in /Applications.
set -euo pipefail

tag_orange() {
    osascript - "$1" <<'AS' >/dev/null 2>&1 || true
on run {p}
    tell application "Finder"
        set label index of (POSIX file p as alias) to 1
    end tell
end run
AS
}

casks=$(brew list --cask 2>/dev/null) || true

if [[ -z "$casks" ]]; then
    echo "No Homebrew casks installed."
    exit 0
fi

while IFS= read -r cask; do
    while IFS= read -r app; do
        [[ -z "$app" ]] && continue
        path="/Applications/$app"
        if [[ -e "$path" ]]; then
            echo "  → $path"
            tag_orange "$path"
        fi
    done < <(brew info --cask "$cask" --json=v2 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    for c in data.get("casks", []):
        for a in c.get("artifacts", []):
            if isinstance(a, dict) and "app" in a:
                for app in a["app"]:
                    print(app)
except Exception:
    pass
')
done <<< "$casks"

echo "Done."
