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

ack \
ffmpeg \
fzf \
gcc \
git \
git-lfs \
jandedobbeleer/oh-my-posh/oh-my-posh \
jesseduffield/lazygit/lazygit \
neovim \
tlrc \
zoxide \
zsh

## Homebrew Casks (brew list --cask | pbcopy)

nikitabobko/tap/aerospace \
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
iina \
karabiner-elements \
kitty \
linearmouse \
mactex \
mediamate \
microsoft-auto-update \
microsoft-excel \
microsoft-powerpoint \
microsoft-word \
miniconda \
moonlight \
music-decoy \
protonvpn \
qbittorrent \
qflipper \
slack \
spotify \
steam \
visual-studio-code \
wechat \
whatsapp \
zoom

## Download Via App Store

Amphetamine
Perplexity
Pure Paste
Xcode

## Download Online

Cold Turkey Blocker
KeyboardCleanTool
SideNotes (I Paid)
Stacher

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
