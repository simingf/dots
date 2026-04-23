# Mac Setup

## Disable Hold Key For Tilde

defaults write -g ApplePressAndHoldEnabled -bool false

## Remove Dock

defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock

## git-lfs setup

git lfs install --system

## Dotfiles Setup

touch ~/.hushlogin
cd ~/dots && stow . --target ~

## Manual Setup

- **Alfred themes** — import from `manual/alfred/themes/` via Alfred Preferences → Appearance
- **Enhancer for YouTube** — import `manual/enhancer_for_youtube/config.json` via extension settings
- **Iris CE layout** — import `manual/iris_ce/iris_ce_rev__1.layout.json` via VIA configurator (https://caniusevia.com/)

## Homebrew Formulae

### brew leaves | wc -l (31)

black \
btop \
ffmpeg \
fzf \
git \
git-extras \
git-lfs \
go \
hashicorp/tap/nomad \
hashicorp/tap/vault \
imagemagick \
itsfrank/tap/portpal \
jandedobbeleer/oh-my-posh/oh-my-posh \
lazygit \
luarocks \
neovim \
openjdk \
php \
prettier \
ripgrep \
ruby \
ruff \
sapling \
stow \
temporal \
tlrc \
tree \
uv \
watchman \
wget \
zoxide

## Homebrew Casks

### brew list --cask | wc -l (34)

1password \
aerospace \
alcove \
aldente \
alfred \
alt-tab \
appcleaner \
bitwarden \
crossover \
discord \
docker-desktop \
epic-games \
firefox \
font-jetbrains-mono-nerd-font \
git-credential-manager \
google-chrome \
iina \
jordanbaird-ice \
karabiner-elements \
keyboardcleantool \
kitty \
linearmouse \
middleclick \
miniconda \
monitorcontrol \
portpal-app \
postman \
qflipper \
slack \
spotify \
steam \
wechat \
zoom

Paid Casks:
Alcove
AlDente
Alfred
Crossover

## Download Via App Store

### Paid:

Yoink
rcmd
Klack

### Free:

Amphetamine
Googly Eyes
Xcode

## Download Online

### Paid:

SideNotes

### Free:

Mousecape
Cold Turkey Blocker
Stacher

## xclient.info / 52mac.com / macked.app

LookAway (1.12.2) (NO LIFETIME LICENSE)
Cleanshot X (4.7.6, 5/6) (NO LIFETIME LICENSE)
Logic Pro
Melodyne 5

## Alfred Workflows

Amazon Suggest
Arc Tabs and Spaces
Calculate Anything
Google Suggest
System Settings
Thumbnail Navigation
Youtube Suggest

## Work

### Download Online

Roblox
Roblox Studio
Logitech G Hub
