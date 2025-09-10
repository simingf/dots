# Mac Setup

## Disable Hold Key For Tilde

defaults write -g ApplePressAndHoldEnabled -bool false

## Remove Dock

defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock

## git-lfs setup

git lfs install --system

## Symbolic Links Setup

ln -s ~/dots/General/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json &&
ln -s ~/dots/General/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
touch ~/.hushlogin &&
ln -s ~/dots/General/zsh/.zshrc ~/.zshrc &&
ln -s ~/dots/Mac/git/.gitconfig ~/.gitconfig &&
ln -s ~/dots/Mac/git/.gitignore_global ~/.gitignore_global &&
ln -s ~/dots/Mac/clang/.clangd ~/.clangd &&
ln -s ~/dots/Mac/clang/.clang-format ~/.clang-format &&
mkdir ~/.config/ &&
ln -s ~/dots/General/kitty ~/.config/kitty &&
ln -s ~/dots/General/nvim ~/.config/nvim &&
ln -s ~/dots/General/ripgrep ~/.config/ripgrep &&
ln -s ~/dots/Mac/aerospace ~/.config/aerospace &&
ln -s ~/dots/Mac/karabiner ~/.config/karabiner &&
ln -s ~/dots/Mac/linearmouse ~/.config/linearmouse &&

## Brown Software

FastX3 (Remote Desktop)
Tunnelblick (VPN)

## Homebrew Formulae

### brew leaves | wc -l (16)

ffmpeg \
fzf \
git \
git-lfs \
go \
imagemagick \
jandedobbeleer/oh-my-posh/oh-my-posh \
jesseduffield/lazygit/lazygit \
luarocks \
neovim \
pandoc \
php \
ripgrep \
tlrc \
yt-dlp \
zoxide

## Homebrew Casks

### brew list --cask | wc -l (46)

nikitabobko/tap/aerospace \
alcove \
aldente \
alfred \
alt-tab \
appcleaner \
arc \
audacity \
baidunetdisk \
bitwarden \
chatgpt \
clop \
discord \
epic-games \
font-jetbrains-mono-nerd-font \
git-credential-manager \
github \
homerow \
iina \
jordanbaird-ice \
karabiner-elements \
keyboardcleantool \
kitty \
linearmouse \
logitech-g-hub \
microsoft-auto-update \
microsoft-excel \
microsoft-powerpoint \
microsoft-word \
middleclick \
miniconda \
monitorcontrol \
moonlight \
music-decoy \
onyx \
protonvpn \
qbittorrent \
qflipper \
roblox \
selfcontrol \
spotify \
steam \
visual-studio-code \
wechat \
whatsapp \
zoom

Paid Casks:
Alcove
AlDente
Alfred
Clop
Homerow
MediaMate (Not Using ATM)

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
