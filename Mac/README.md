# Mac Setup

## Disable Hold Key For Tilde

defaults write -g ApplePressAndHoldEnabled -bool false

## Remove Dock

defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock

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

## Homebrew Formulae (brew leaves | pbcopy) 18

ffmpeg \
fzf \
gcc \
git \
git-lfs \
go \
imagemagick \
jandedobbeleer/oh-my-posh/oh-my-posh \
jesseduffield/lazygit/lazygit \
luarocks \
neovim \
node \
pandoc \
ripgrep \
tlrc \
yt-dlp \
zoxide \
zsh

## Homebrew Casks (brew list --cask | pbcopy) 52

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
crossover \
discord \
docker \
docker-desktop \
epic-games \
font-jetbrains-mono-nerd-font \
github \
homerow \
iina \
jordanbaird-ice \
karabiner-elements \
keyboardcleantool \
kitty \
linearmouse \
mactex \
mediamate \
microsoft-auto-update \
microsoft-excel \
microsoft-powerpoint \
microsoft-word \
middleclick \
miniconda \
monitorcontrol \
moonlight \
music-decoy \
nvidia-geforce-now \
onyx \
prefs-editor \
protonvpn \
qbittorrent \
qflipper \
roblox \
selfcontrol \
slack \
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
Crossover (plist)
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

2FA-Read Code
Amazon Suggest
Amphetamine Dose
Arc Tabs and Spaces
Currency Converter
Device Battery
Google Suggest
Send to Yoink
Share with AirDrop
System Settings
Thumbnail Navigation
TimeZones
Unit Converter
Youtube Suggest
