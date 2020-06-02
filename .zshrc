# Config order:
# .zshenv → [.zprofile if login] → [.zshrc if interactive] →
# [.zlogin if login] → [.zlogout sometimes]

export TERM="xterm-256color" # Enables 265 colors in tmux
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# How often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# "tt [title]" will title the iTerm2 tab if outside of tmux. If inside of tmux,
# it will rename the tmux window
function () {
  if [ -z $TMUX ] ; then
    echo -e "\033];$@\007"
  else
   printf "\033]2;$@\033\\"
  fi
}

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Set the username for prompts
export DEFAULT_USER=danyim

# The offical Powerline repo suggests running this, but we're seeing script errors
# when loading
#. $HOME/Library/Python/3.6/lib/python/site-packages/powerline/bindings/zsh/powerline.zsh

source /usr/local/share/antigen/antigen.zsh
antigen use oh-my-zsh
antigen bundle git
antigen bundle colorize
antigen bundle node
antigen bundle npm
antigen bundle ssh-agent
antigen bundle supervisor
antigen bundle lukechilds/zsh-better-npm-completion
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zdharma/fast-syntax-highlighting
if ! (( ${+functions[_zsh_highlight]} )); then
    . $HOME/.antigen/bundles/zdharma/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi
antigen bundle history
antigen bundle history-substring-search
# antigen bundle zsh-users/zsh-completions

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir vcs)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(node_version time)
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_with_package_name"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_TIME_FORMAT="%D{%L:%M:%S %p}"
POWERLEVEL9K_DISABLE_RPROMPT=true

antigen theme romkatv/powerlevel10k
antigen apply

source $ZSH/oh-my-zsh.sh

###############################################################################
# Environment variables                                                       #
###############################################################################
# Change the prompt styles
PS1='%(5~|…/%3~|%~)'

export EDITOR='vim'

# Tell ls to be colorful
export CLICOLOR=1

# Set PATH variables are set in .zshenv
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
export PATH="/usr/local/heroku/bin:$PATH" # Added by the Heroku Toolbelt
# More PATH variables set in .zshenv

# Sets pgp key generated on 1/15/2015 as the default key
export GPGKEY=1988FBC9

export LANG=en_US.UTF-8
export SSH_KEY_PATH=$HOME/.ssh/id_rsa

# For Python tab completions
export PYTHONSTARTUP=$HOME/.pythonrc.py

# For Python virtual env
export WORKON_HOME=$HOME/Developer/.virtualenvs
export PROJECT_HOME=$HOME/Developer
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3.6
# source /usr/local/bin/virtualenvwrapper.sh

###############################################################################
# Aliases                                                                     #
###############################################################################

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Load ~/.zshrc configs
alias zshconf="$EDITOR $HOME/.zshrc"
alias zshreload="source $HOME/.zshrc"
alias ohmyzsh="$EDITOR $HOME/.oh-my-zsh"

# Displays a tree of files/folders of the current directory
alias t='tree -L 2 -C --dirsfirst --filelimit 20 -F'

# Set helpful ls shortcuts
alias ls='exa'
alias lsl='exa -l'
alias l='exa -lr'
alias ll='exa -lra'

# Helpful commands
function mkcd {
  mkdir $1
  cd $1
}

alias more='less'
alias less='less -R'

# Attaches to the existing tmux session if it exists; create one if not
alias tm='tmux new -A -s _base -n home'
# Connect to desktop via SSH and immediately open tmux; reuse session if exists 
alias ssh-desktop='ssh -t desktop tmux new -A -s _cruise -n cruise'

# macOS only -- opens Alacritty as a new window (supports multiple)
alias alac='open -nb io.alacritty'

# git/git-flow aliases
alias gita='git add .'
alias gitc='git clone'
alias gitd='git d'    # git diff
alias gitdc='git dc'  # git diff --cached
alias gitl='git lg'   # git log
alias gitlg='git log --graph --decorate --oneline'
alias gits='git status'
alias gitr='git recent'
alias gitch='git ch'
#alias gch='git ch'
alias gch='gitr | fzf | xargs git checkout'
alias gs='git stash'
alias gitsl='git sl'
alias gaa='git add -A'
alias gsa='git stash apply'
alias gsl="git --no-pager stash list --format='%C(blue)%gd: %C(bold)%C(green)%gs %C(white)%cd'"
alias gsc='git stash clear'
alias gft='git fetch --tags'
alias gpn='git push --no-verify'
alias gpnf='git push --no-verify -f'
alias gpt='git push --tags'
alias gcd='git checkout develop'
alias gcm='git checkout master'
alias grm='git rebase master'
alias grd='git rebase develop'
alias gmm='git merge master --no-ff'
alias gcd='git checkout develop'
alias gmd='git merge develop --no-ff'
alias grsh='git reset --soft HEAD^'
alias gpom='git pull origin master'
alias gpp='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
alias gcmd='git commend' # Commit amend
alias gcmdnv='git commend --no-verify' # Commit amend and bypass hooks
alias mkpr='hub pull-request --base develop --head $(git rev-parse --abbrev-ref HEAD) -d -o'
alias mkprm='hub pull-request --base master --head $(git rev-parse --abbrev-ref HEAD) -d -o'
# "git diff stats"
function gds { git diff --stat --color "$@" | cat }
function gdsc { git diff --stat --cached --color "$@" | cat }
# Prints orphaned branches (local branches without a remote branch)
function gitOrphans { for branch in `git branch -vv --no-color | grep ': gone]' | awk '{print $1}'`; do echo $branch; done }
# Cleans orphaned local branches with deleted remote tracking branches
function gcln {
  echo -n "Fetching & prune from remote...\n"
  git fetch -p
  echo -n "\n\nLocal orphaned branches:\n"
  gitOrphans
  echo -n "\nDelete local branches above? [Y/n]: "
  read input
  if [[ $input == "Y" || $input == "y" ]]; then
    for branch in `gitOrphans`; do git branch -D $branch; done
  fi
}

# Sublime
# alias subl='sublime'

# cd into ~/Developer
alias cdd='cd $HOME/Developer'
alias -- -='cd ~-' # Typing '-' navigates to the previous directory

# NPM
alias npmls='npm ls -g --depth=0' # Prints all root packages installed globally
# Swaps the NPM repository information with the publish version
function npmrc_swap {
  FILE=~/.npmrc.publish
  if [[ -f "$FILE" ]]; then
    mv ~/.npmrc ~/.npmrc.bak && mv ~/.npmrc.publish ~/.npmrc
  else
    mv ~/.npmrc ~/.npmrc.publish && mv ~/.npmrc.bak ~/.npmrc
  fi
  
  ls ~/.npmrc*
}

# IP
alias ip="ifconfig en0 | grep 'inet ' | cut -d ' ' -f 2" # Grabs local IP
alias ipcopy='ip | pbcopy'

#alias cat=bat
alias preview="fzf --preview 'bat --color \"always\" {}'"
alias top="sudo htop"
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"

# Docker
alias dkrkill="docker kill $(docker ps -q)"

function dkrclean {
  echo -n "Remove all images and reset Docker? [Y/n]: "
  read input
  if [[ $input == "Y" || $input == "y" ]]; then
    echo "Cleaning all Docker images..."
    docker system prune -f
    docker rmi -f $(docker images -q)
    docker rm $(docker ps -aq)
    rm ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.qcow2
  fi
}
alias ld="lazydocker"

# Kubernetes
alias kc=kubectl
alias kcns=kubens
alias kctx=kubectx
alias kce=kubectx exec -it
alias kcp=kc get pods  --sort-by=.metadata.creationTimestamp
alias kclg=kc logs -f $(kc get pods | grep gateway | cut -d' ' -f-1)

# Chrome (load with WebRTC testing profile)
alias chrome-test="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --console --no-first-run --user-data-dir=$HOME/.config/chrome-test --use-fake-device-for-media-stream --enable-logging --v=1 --vmodule=*third_party/libjingle/*=3,*=0"
alias chrome-test-clean="rm -rf $HOME/.config/chrome-test"

# Fuzzy searching tmux panes
function ftpane {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}

###############################################################################
# Misc                                                                        #
###############################################################################

# Allow for reverse tab of completion lists
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey "^X\x7f" backward-kill-line

# For Z -- https://github.com/rupa/z
. /etc/profile.d/z.sh

# For iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Don't share command history with other tabs
unsetopt share_history

# For fuzzy search
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# --files: List files that would be searched but do not search
# --no-ignore: Do not respect .gitignore, etc...
# --hidden: Search hidden files and folders
# --follow: Follow symlinks
# --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*,!node_modules/**/*"'

# Load local-only configurations
source "$HOME/.localrc"


source /Users/dyim/Library/Preferences/org.dystroy.broot/launcher/bash/br

