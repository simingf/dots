#!/usr/bin/env bash
set -euo pipefail

DOTS="$(cd "$(dirname "$0")/.." && pwd)"

step() { echo "==> $*"; }

step "Disable press-and-hold (tilde key)"
defaults write -g ApplePressAndHoldEnabled -bool false

step "Hide Dock"
defaults write com.apple.dock autohide-delay -float 1000
killall Dock

step "git-lfs system install"
git lfs install --system

step "Dotfiles (stow)"
touch ~/.hushlogin
stow --dir="$DOTS" --target="$HOME" .

step "Homebrew bundle"
brew bundle install --file="$DOTS/Brewfile"

step "Default file handlers (duti → VS Code)"
duti "$DOTS/scripts/duti.conf"

echo ""
echo "Done. Manual steps remaining:"
echo "  - Alfred themes: import from $DOTS/manual/alfred/themes/ via Alfred Preferences → Appearance"
echo "  - Enhancer for YouTube: import $DOTS/manual/enhancer_for_youtube/config.json via extension settings"
echo "  - App Store: Yoink, Klack, Amphetamine, Googly Eyes"
echo "  - Online: ZoomHider, IsThereNet, Coder Desktop"
