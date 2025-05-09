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

## Homebrew Formulae (brew leaves | pbcopy)

ffmpeg \
fzf \
gcc \
git \
git-lfs \
go \
imagemagick \
jandedobbeleer/oh-my-posh/oh-my-posh \
jesseduffield/lazygit/lazygit \
neovim \
ripgrep \
tlrc \
zoxide \
zsh

## Homebrew Casks (brew list --cask | pbcopy)

nikitabobko/tap/aerospace \
alfred \
alt-tab \
appcleaner \
arc \
audacity \
baidunetdisk \
chatgpt \
discord \
docker \
epic-games \
font-jetbrains-mono-nerd-font \
github \
hiddenbar \
homerow \
iina \
itsycal \
karabiner-elements \
kitty \
linearmouse \
mactex \
maintenance \
mediamate \
microsoft-auto-update \
microsoft-excel \
microsoft-powerpoint \
microsoft-word \
miniconda \
monitorcontrol \
moonlight \
music-decoy \
protonvpn \
qbittorrent \
qflipper \
reminders-menubar \
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
Alfred
Homerow
MediaMate

## Download Via App Store

Yoink (Paid)
Klack (Paid)
Amphetamine
Googly Eyes
Xcode

## Download Online

SideNotes (Paid)
Cold Turkey Blocker
KeyboardCleanTool
Stacher

## xclient.info / 52mac.com

Logic Pro
Melodyne 5

## Alfred Workflows

System Settings
Send to Yoink
