# Mac Setup

## Remove Dock

defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock

## Symbolic Links Setup

touch ~/.hushlogin &&
ln -s ~/dots/General/zsh/.zshrc ~/.zshrc &&
ln -s ~/dots/Mac/git/.gitconfig ~/.gitconfig &&
ln -s ~/dots/Mac/git/.gitignore_global ~/.gitignore_global &&
ln -s ~/dots/Mac/clang/.clangd ~/.clangd &&
ln -s ~/dots/Mac/clang/.clang-format ~/.clang-format &&
mkdir ~/.config/ &&
ln -s ~/dots/Mac/aerospace ~/.config/aerospace &&
ln -s ~/dots/General/kitty ~/.config/kitty &&
ln -s ~/dots/General/nvim ~/.config/nvim &&
ln -s ~/dots/General/ripgrep ~/.config/ripgrep &&
ln -s ~/dots/Mac/karabiner ~/.config/karabiner &&
ln -s ~/dots/Mac/linearmouse ~/.config/linearmouse &&
ln -s ~/dots/General/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json &&
ln -s ~/dots/General/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

## Brown Software

FastX3 (Remote Desktop)
Tunnelblick (VPN)

## Homebrew Formulae (brew leaves | pbcopy)

ack
aria2
automake
bear
bison
btop
c2048
cbonsai
chruby
cmake
cmake-docs
cmatrix
curl
fastfetch
fd
ffmpeg
figlet
fortune
fzf
gcc
gdbm
gh
git
git-lfs
go
go@1.22
gping
grep
imagemagick
jandedobbeleer/oh-my-posh/oh-my-posh
jesseduffield/lazygit/lazygit
jq
libffi
libyaml
lolcat
luarocks
mas
mongosh
moon-buggy
neovim
ollama
openjdk
pandoc
qrencode
ranger
rig
ripgrep
ruby-install
sl
tldr
tree
watch
wget
xkcd
yt-dlp
zoxide
zsh

## Homebrew Casks (brew list --cask | pbcopy)

aerospace
alt-tab
angry-ip-scanner
appcleaner
arc
audacity
baidunetdisk
balenaetcher
betterdiscord-installer
bit-slicer
burp-suite
calibre
chatgpt
discord
docker
epic-games
font-jetbrains-mono-nerd-font
github
google-chrome
hiddenbar
iina
imageoptim
karabiner-elements
kitty
linearmouse
logitech-g-hub
mediamate
microsoft-auto-update
microsoft-excel
microsoft-powerpoint
microsoft-word
minecraft
miniconda
mongodb-compass
moonlight
music-decoy
notion
orange
qbittorrent
qflipper
roblox
robloxstudio
slack
spotify
steam
tetrio
the-unarchiver
visual-studio-code
wechat
whatsapp
wireshark
zoom

## Install Via Command Line

zinit
ani-cli
mov-cli

## Download Via App Store

Amphetamine
Enchanted LLM
Perplexity
Pure Paste
Xcode

## Download Online

Cold Turkey Blocker
KeyboardCleanTool
SideNotes (I Paid)
Stacher
Texts
WinDiskWriter

## xclient.info / 52mac.com

Alfred 5
iA Writer
Logic Pro
Melodyne 5
NotchNook
Octagon
Piezo
WizardOfLegend

Buggy:
SoundSource

No Longer Used:
Yoink

## Alfred Workflows

System Settings
