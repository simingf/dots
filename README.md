# Mac Setup

## Disable Hold Key For Tilde

```bash
defaults write -g ApplePressAndHoldEnabled -bool false
```

## Remove Dock

```bash
defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock
```

## Fix Chrome Jumping to Wrong Workspace

macOS's `workspaces-auto-swoosh` makes it jump to the Space where an app was last active instead of staying put. Disabling it fixes this.

```bash
defaults write com.apple.dock workspaces-auto-swoosh -bool NO
killall Dock
```

## git-lfs setup

```bash
git lfs install --system
```

## Dotfiles Setup

```bash
touch ~/.hushlogin
cd ~/dots && stow . --target ~
```

## Manual Setup

- **Alfred themes** — import from `manual/alfred/themes/` via Alfred Preferences → Appearance
- **Enhancer for YouTube** — import `manual/enhancer_for_youtube/config.json` via extension settings
- **Iris CE layout** — import `manual/iris_ce/iris_ce_rev__1.layout.json` via VIA configurator (https://caniusevia.com/)

## Homebrew

```bash
brew bundle install --file=~/dots/Brewfile
```

### Paid Casks

- Alcove
- AlDente
- Alfred
- Crossover
- LookAway

## Download Via App Store

### Paid:

Yoink
rcmd (currently not installed)
Klack

### Free:

Amphetamine
Googly Eyes
Xcode (currently not installed)

## Download Online

### Paid:

SideNotes (currently not installed)

### Free:

ZoomHider
IsThereNet
Coder Desktop
Karabiner-EventViewer (companion to Karabiner-Elements)
Mousecape (currently not installed)
Cold Turkey Blocker (currently not installed)
Stacher (currently not installed)

## Roblox / Work Apps

Managed and installed by Roblox IT:

- Falcon
- GlobalProtect
- Jamf Self Service
- Roscan
- Santa

## xclient.info / 52mac.com / macked.app

Cleanshot X (4.7.6, 5/6) (NO LIFETIME LICENSE)

## Alfred Workflows

Amazon Suggest
Arc Tabs and Spaces
Calculate Anything
Google Suggest
System Settings
Thumbnail Navigation
Youtube Suggest
