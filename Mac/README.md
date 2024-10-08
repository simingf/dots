# Mac Setup

## Remove Dock

defaults write com.apple.dock autohide-delay -float 1000; killall Dock
defaults delete com.apple.dock autohide-delay; killall Dock

## Symbolic Links Setup

touch ~/.hushlogin &&
ln -s ~/dots/Mac/zsh/.zshrc ~/.zshrc &&
ln -s ~/dots/Mac/git/.gitconfig ~/.gitconfig &&
ln -s ~/dots/Mac/git/.gitignore_global ~/.gitignore_global &&
ln -s ~/dots/Mac/clang/.clangd ~/.clangd &&
ln -s ~/dots/Mac/clang/.clang-format ~/.clang-format &&
mkdir ~/.config/ &&
ln -s ~/dots/Mac/yabai ~/.config/yabai &&
ln -s ~/dots/Mac/skhd ~/.config/skhd &&
ln -s ~/dots/Mac/linearmouse ~/.config/linearmouse &&
ln -s ~/dots/General/kitty ~/.config/kitty &&
ln -s ~/dots/General/nvim ~/.config/nvim

## Brown Software

FastX3 (Remote Desktop)
Tunnelblick (VPN)

## Homebrew Formulae (brew leaves | pbcopy)

ack
aria2
bear
btop
c2048
cbonsai
cmake
cmatrix
curl
fastfetch
fd
ffmpeg
figlet
fortune
fzf
gcc
gh
git
git-lfs
gping
grep
imagemagick
jesseduffield/lazygit/lazygit
jq
koekeishiya/formulae/skhd
koekeishiya/formulae/yabai
llm
llvm
lolcat
lua
mas
moon-buggy
neovim
node
openjdk
pandoc
qrencode
rig
ripgrep
sl
tldr
tree
watch
wget
xkcd
yt-dlp
zsh

## Homebrew Casks (brew list --cask | pbcopy)

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
hiddenbar
iina
imageoptim
itsycal
karabiner-elements
kitty
linearmouse
logitech-g-hub
microsoft-auto-update
microsoft-excel
microsoft-powerpoint
microsoft-word
minecraft
miniconda
moonlight
music-decoy
notion
orange
qbittorrent
qflipper
rectangle
selfcontrol
slack
spaceid
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

oh-my-zsh
powerlevel10k
ani-cli
mov-cli

## Download Via App Store

Amphetamine
Pure Paste
Xcode

## Download Online

KeyboardCleanTool
MediaMate (I Paid)
ProNotes
SideNotes (I Paid)
Stacher
WinDiskWriter

## xclient.info / 52mac.com

Alfred 5
iA Writer
Logic Pro
Melodyne 5
Octagon
SoundSource
WizardOfLegend
Yoink

## Alfred Workflows

System Settings
