echo "-Welcome, Siming-"

parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1="\[\033[1;36m\](\W)\[\033[1;35m\]\$(parse_git_branch)\[\033[0;33m\]|> \[\e[00m\]" #show current directory before command

# mapping to have up and down arrows search commands in history that match currently typed
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# mapping to have [Tab] and [Shift]+[Tab] to cycle through all the possible completions:
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'
# when on: first tab lists all choices
bind "set show-all-if-ambiguous on"
# when on: first tab fills up to difference instead of selecting first option
bind "set menu-complete-display-prefix on" 
# when on: case insensitive
bind "set completion-ignore-case on"

#setup
dotscp() { #helper function to copy files
    cp ~/Documents/dots/Windows/bash/.bashrc ~/ 
    cp ~/Documents/dots/Windows/bash/.minttyrc ~/
}
alias rs='dotscp && source ~/.bashrc && clear && doc'
alias dots='builtin cd ~/Documents/dots/'

# general aliases
alias e='exit'
alias mkdir='mkdir -pv'                      #makes parent folders and notifies all folders made
alias rm='rm -r'                             #rm removes folders
alias f='start . && exit'                    #open folder in file explorer
alias grep='grep --color=auto --ignore-case' #colorize grep
alias hist='history | grep'                  #grep command history
alias ch='history -c && history -w'          #clear command history

# directory aliases
alias ..='builtin cd ..'
alias doc='builtin cd ~/Documents/'
alias dow='builtin cd ~/Downloads/'
alias des='builtin cd ~/Desktop/'

# cd function
cd() {
    # if no DIR given, go home
    if [[ "$@" == "" ]]; then
        builtin cd $HOME
    # if .., go back
    elif [[ "$@" == ".." ]]; then
        builtin cd ..
    # if contains /, I tabbed it so go directly
    elif [[ "$@" == *"/"* ]]; then
        builtin cd "$@" && ls
    else
        # find exact match
        EXACT=$(find . -maxdepth 1 -type d -iname "$@" -print -quit)
        if [[ $EXACT != "" ]]; then
            builtin cd "${EXACT}" && ls
        else
            # find all dirs that contain string
            DIRS=$(find . -maxdepth 1 -type d -iname "*$@*" -print -quit)
            if [[ $DIRS == "" ]]; then
                echo "no match found" 
            else
                # cd to first match
                DIR=${DIRS%%*"\n"}
                builtin cd "${DIR}" && ls
            fi
        fi
    fi
}

# git function
g() {
    if [[ "$@" == "" ]]; then
        git status
    elif [[ "$1" == "up" ]]; then
        shift #remove first argument
        git add --all
        git commit -a -m "$@"
        git push
    elif [[ "$1" == "commit" ]]; then
        shift #remove first argument
        git commit -m "$@"
    elif [[ "$1" == "clone" ]]; then
        shift
        git clone "$1" && builtin cd "$(basename "$1" .git)" #cd into cloned directory
    elif [[ "$@" == ".gitignore" ]]; then
        git rm -r --cached .
        git add .
        git commit -m "fix: .gitignore"
        git push
    elif [[ "$@" == "diff" ]]; then
        git diff --name-status
    elif [[ "$@" == "branch" ]]; then
        git branch -vv
    else
        git "$@"
    fi
}
alias gup='g up'

# conda function
. /c/Users/Sim/miniconda3/etc/profile.d/conda.sh

c() {
    if [[ "$@" == "" ]]; then
        clear
    elif [[ "$1" == "a" ]]; then
        shift #remove first argument
        conda activate "$@"
    elif [[ "$1" == "d" ]]; then
        conda deactivate
    else
        conda "$@"
    fi
}

# python function
p() {
    if [[ "$@" == "" ]]; then
        echo "python: no file given"
    else
        python "$@"
    fi
}

#competitive programming
cf() { #input: page number
    start firefox https://codeforces.com/problemset/page/$1?order=BY_SOLVED_DESC
    exit
}

#browser
cs() { #input: course id
    if [[ "$1" == "" ]]; then
        start firefox https://bulletin.brown.edu/the-college/concentrations/comp/
    else
        start firefox https://cs.brown.edu/courses/csci$1/
    fi
    exit
}
np() {
    if [[ "$1" == "" ]]; then
        start firefox https://numpy.org/doc/stable/reference/routines.array-manipulation.html
    else
        start firefox https://numpy.org/doc/stable/reference/generated/numpy.$1.html
    fi
    exit
}