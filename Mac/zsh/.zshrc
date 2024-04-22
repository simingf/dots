# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
export SHELL="zsh"

DISABLE_AUTO_TITLE="true"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(colored-man-pages zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi
alias v='nvim'

# TA alias
alias ta='cd ~/CS166HTA/dev-env/ && ./cs1660-run-docker'

# OS alias
alias os='ssh -Y sfeng22@ssh.cs.brown.edu'
alias rd='xhost +localhost && ./run-docker'

# directory aliases
alias ls='ls -AG'
alias ..='builtin cd .. && clear && ls'
alias app='builtin cd /Applications/ && clear && ls'
alias doc='builtin cd ~/Documents/ && clear && ls'
alias dow='builtin cd ~/Downloads/ && clear && ls'
alias des='builtin cd ~/Desktop/ && clear && ls'
alias ss='builtin cd ~/Screenshots/ && clear && ls'
alias hub='builtin cd ~/Github/ && clear && ls'
alias lab='builtin cd ~/Gitlab/ && clear && ls'
alias euler='builtin cd ~/euler/ && clear && ls'
alias dp='builtin cd ~/atcoder-dp/ && clear && ls'

# general aliases
alias e='exit'
alias f='open . && exit'
alias rm='rm -r'
# print out path and copy the path
alias pwd='pwd && pwd | pbcopy'
# accepts path name
alias mkdir='mkdir -p'
# clears screenshot folder
alias css='rm -f ~/Screenshots/* && echo "screenshots cleared"'
# lists global node modules
alias npmg='npm list -g --depth 0'

# config aliases
alias cf="builtin cd ~/.config && ls"
alias ch="rm -f ~/.zsh_history && clear"
alias zrc="nvim ~/.zshrc"
alias zrs="clear && source ~/.zshrc"
alias nrc="nvim ~/.config/nvim/init.lua"
alias krc="nvim ~/.config/kitty/kitty.conf"
alias ub='builtin cd ~/.config/ubersicht/simple-bar && ls'
urs() {
    osascript -e 'tell application id "tracesOf.Uebersicht" to refresh'
}
alias yrc="nvim ~/.config/yabai/yabairc"
alias yrs="yabai --restart-service && urs"
# call this function if brew updates yabai
yup() {
    TEXT="$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa"
    echo $TEXT | sudo tee /private/etc/sudoers.d/yabai
}
alias src="nvim ~/.config/skhd/skhdrc"
alias srs="skhd --restart-service"
# restarts zshrc, yabai, skhd
alias rs='zrs && yrs && srs'
# updates oh my zsh, homebrew and yabai
alias up='omz update && brew update && brew upgrade && brew cleanup && brew autoremove && yup && yrs'

# enter alias
accept-line() {
    if [[ -z $BUFFER ]]; then
        zle -I
        # command to run when enter pressed
        clear && ls && echo
    else
        zle ".$WIDGET"
    fi
}
zle -N accept-line

# cd function
cd() {
    # if no DIR given, go home
    if [[ "$@" == "" ]]; then
        builtin cd $HOME && clear && ls
    # if the path only contains '.' and '/' (moving up dir tree)
    elif [[ "$@" =~ ^[./-]+$ ]]; then
        builtin cd "$@" && clear && ls
    # if the path contains at least one '/' (i tabbed it)
    elif [[ "$@" == *"/"* ]]; then
        builtin cd "$@" && clear && ls
    else
        # try to find exact match for dirname first
        EXACT=$(find . -maxdepth 1 -type d -iname "$@" -print -quit)
        if [[ $EXACT != "" ]]; then
            builtin cd "${EXACT}" && clear && ls
        else
            # find all dirnames that contain search string
            DIRS=$(find . -maxdepth 1 -type d -iname "*$@*" -print -quit)
            if [[ $DIRS == "" ]]; then
                echo "ERROR: no match found" 
            else
                # cd into first match
                DIR=${DIRS%%*"\n"}
                builtin cd "${DIR}" && clear && ls
            fi
        fi
    fi
}

# git
alias lg='lazygit'

g() {
    if [[ "$@" == "" ]]; then
        git status
    elif [[ "$1" == "up" ]]; then
        # add, commit, push all untracked and modified files
        shift
        git add --all
        git commit -a -m "$@"
        git push
    elif [[ "$1" == "clone" ]]; then
        # cd into cloned directory
        shift
        # check if there is a $2 for new directory name
        if [[ "$2" == "" ]]; then
            git clone "$1" && builtin cd "$(basename "$1" .git)" 
        else
            git clone "$1" "$2" && builtin cd "$2"
        fi
    elif [[ "$@" == "ignore" ]]; then
        # fix .gitignore when files are already tracked
        git rm -r --cached .
        git add --all
        git commit -m "fix: .gitignore"
        git push
    else
        git "$@"
    fi
}
alias gup='g up'

# conda
. "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"

c() {
    if [[ "$@" == "" ]]; then
        clear
    elif [[ "$1" == "a" ]]; then
        shift
        conda activate "$@"
    elif [[ "$@" == "d" ]]; then
        conda deactivate
    else
        conda "$@"
    fi
}

# python
p() {
    if [[ "$@" == "" ]]; then
        echo "python: no file given"
    else
        python "$@"
    fi
}

# vscode
k() {
    if [[ "$@" == "" ]]; then
        code .
    else
        code "$@"
    fi
}

# competitive programming alias
alias rr='make && ./sol'

# image magick function
img() {
    magick "$1" "$2"
    rm "$1"
}

# search notes
n() {
    if [[ "$@" == "" ]]; then
        # list all notes
        ls ~/Documents/Notes/
    elif [[ "$@" == "go" ]]; then
        # go to notes dir
        cd ~/Documents/Notes/
    elif [[ "$1" == "v" ]]; then
        # search for notes that match query and edit all matches w nvim
        shift
        IFS=$'\n'
        INPUT="$@"
        FILES=$(find ~/Documents/Notes/ -type f -iname "*$INPUT*" -print)
        if [[ $FILES == "" ]]; then
            echo "no notes found for '$INPUT'"
        else
            for FILE in $FILES
            do
                nvim $FILE
            done
        fi
        unset IFS
    elif [[ "$1" == "n" ]]; then
        # make a new note and edit w nvim
        shift
        INPUT="$@"
        FILE=~/Documents/Notes/"$INPUT".txt
        touch "$FILE"
        nvim "$FILE"
    elif [[ "$1" == "rm" ]]; then
        # search for exact note name and remove it
        shift
        INPUT="$@"
        FILE=~/Documents/Notes/"$INPUT".txt
        rm -f "$FILE"
    else
        # search for notes that match query and display all matches
        IFS=$'\n'
        INPUT="$@"
        FILES=$(find ~/Documents/Notes -type f -iname "*$INPUT*" -print)
        if [[ $FILES == "" ]]; then
            echo "no notes found for '$INPUT'"
        else
            for FILE in $FILES
            do
                NAME=${FILE##*/}
                NAME=${NAME%".txt"}
                echo -e '\033[1;33m=='$NAME'==\033[0m'
                cat ~/Documents/Notes/"$NAME".txt
                echo ''
            done
        fi
        unset IFS
    fi
}

# go to mac-setup directory
alias mac='builtin cd ~/Github/mac-setup/ && maccp && ls'

# copy configs to mac-setup
maccp() {
    cp ~/.zshrc ~/Github/mac-setup/zsh/
    echo "zsh config copied"

    cp -r ~/.config/skhd/* ~/Github/mac-setup/config/skhd/
    echo "skhd config copied"
    cp -r ~/.config/yabai/* ~/Github/mac-setup/config/yabai/
    echo "yabai config copied"

    cp -r ~/.config/nvim/* ~/Github/mac-setup/config/nvim/
    echo "nvim config copied"
    cp -r ~/.config/kitty/* ~/Github/mac-setup/config/kitty/
    echo "kitty config copied"
    cp -r ~/.config/linearmouse/* ~/Github/mac-setup/config/linearmouse/
    echo "linearmouse config copied"

    cp ~/.gitconfig ~/Github/mac-setup/git/
    cp ~/.gitconfig-github ~/Github/mac-setup/git/
    cp ~/.gitconfig-gitlab ~/Github/mac-setup/git/
    cp ~/.gitignore ~/Github/mac-setup/git/
    echo "git config copied"

    cp ~/.clangd ~/Github/mac-setup/clang/
    cp ~/.clang-format ~/Github/mac-setup/clang/
    echo "clang config copied"

    echo ""
    echo "all configs copied to mac-setup!"
}

# fzf support
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
