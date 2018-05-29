# Config order:
# .zshenv → [.zprofile if login] → [.zshrc if interactive] →
# [.zlogin if login] → [.zlogout sometimes]

# Use a 256-color terminal setting
export TERM="xterm-256color" # Enables 265 colors in tmux

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load
ZSH_THEME="powerlevel9k/powerlevel9k"

# Autostart tmux
ZSH_TMUX_AUTOSTART='true'

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# How often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# "tt [title]" will title the iTerm2 tab if outside of tmux. If inside of tmux,
# it will rename the tmux window
tt () {
  if [ -z $TMUX ] ; then
    echo -e "\033];$@\007"
  else
   tmux rename-window $@
  fi
}

# Autocompletion for tmuxinator
# (Disabled because of error "command not found: compdef")
# source ~/.bin/tmuxinator.zsh

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Set the username for prompts
# prompt_context () { }
export DEFAULT_USER=danyim

# The offical Powerline repo suggests running this, but we're seeing script errors
# when loading
#. $HOME/Library/Python/3.6/lib/python/site-packages/powerline/bindings/zsh/powerline.zsh

source /usr/local/share/antigen/antigen.zsh
antigen use oh-my-zsh
antigen bundle git
antigen bundle tmuxinator
antigen bundle colorize
antigen bundle node
antigen bundle npm
antigen bundle ssh-agent
antigen bundle sublime
antigen bundle supervisor
antigen bundle lukechilds/zsh-better-npm-completion
# antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zdharma/fast-syntax-highlighting
if ! (( ${+functions[_zsh_highlight]} )); then
    . $HOME/.antigen/bundles/zdharma/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi
antigen bundle history
antigen bundle history-substring-search
# antigen bundle command-not-found
# antigen bundle sudo
# antigen bundle zsh-users/zsh-completions
#POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(node_version time)
POWERLEVEL9K_NODE_VERSION_BACKGROUND='022'
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_with_package_name"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_TIME_FORMAT="%D{%L:%M:%S %p}"

antigen theme bhilburn/powerlevel9k
antigen apply

source $ZSH/oh-my-zsh.sh


###############################################################################
# Environment variables                                                       #
###############################################################################
# Change the prompt styles
PS1='%(5~|…/%3~|%~)'
# PS1='\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;32m\]\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '

export GREP_OPTIONS='--color=auto'
export EDITOR='subl --wait' # Sets the default editor

# Tell ls to be colorful
export CLICOLOR=1

# Set PATH variables are set in .zshenv
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
export PATH="/usr/local/heroku/bin:$PATH" # Added by the Heroku Toolbelt
# More PATH variables set in .zshenv

# Sets pgp key generated on 1/15/2015 as the default key
export GPGKEY=1988FBC9

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# For SSH
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
mkcd() {
  mkdir $1
  cd $1
}

alias more='less'
alias less='less -R'

# Always use 256-color tmux sessions
alias tmux='tmux -2'
alias tmuxi='tmux new -s _base -n home' # Inits a tmux session
alias tmuxa='tmux attach -t _base' # Reattaches to a tmux session

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
alias gch='git ch'
alias gs='git stash'
alias gitsl='git sl'
alias gaa='git add -A'
alias gsa='git stash apply'
alias gsl='git stash list'
alias gsc='git stash clear'
alias gft='git fetch --tags'
alias gpt='git push --tags'
alias gcm='git checkout master'
alias grm='git rebase master'
alias gmm='git merge master --no-ff'
alias gcd='git checkout develop'
alias gmd='git merge develop --no-ff'
alias gpom='git pull origin master'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
gds() { git diff --stat --color "$@" | cat }
gdsc() { git diff --stat --cached --color "$@" | cat }

# Sublime
# alias subl='sublime'

# cd into ~/Developer
alias cdd='cd $HOME/Developer'
alias -- -='cd ~-' # Typing '-' navigates to the previous directory

# NPM
alias npmls='npm ls -g --depth=0' # Prints all root packages installed globally

# IP
alias ip="ifconfig en0 | grep 'inet ' | cut -d ' ' -f 2" # Grabs local IP
alias ipcopy='ip | pbcopy'

# For Zippy
alias gen="go generate teleopui/teleopui.go"
alias gobuild="gen && go build ./cmd/teleop-server && ./teleop-server"

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

#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load local-only configurations
source "~/.localrc"
