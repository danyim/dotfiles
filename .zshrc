# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/danyim/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel9k/powerlevel9k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

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
# source ~/.bin/tmuxinator.zsh

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Set the username for prompts
prompt_context () { }
DEFAULT_USER=danyim

source /usr/local/share/antigen/antigen.zsh
antigen use oh-my-zsh
antigen theme bhilburn/powerlevel9k
antigen bundle git
# antigen bundle git-extras
# antigen bundle git-flow
antigen bundle tmuxinator
# antigen bundle command-not-found
antigen bundle colorize
antigen bundle brew
antigen bundle node
antigen bundle npm
antigen bundle ssh-agent
antigen bundle sublime
# antigen bundle sudo
antigen bundle supervisor
antigen bundle history
antigen bundle history-substring-search
antigen bundle lukechilds/zsh-better-npm-completion

antigen bundle zsh-users/zsh-syntax-highlighting
#antigen bundle zsh-users/zsh-autosuggestions
#antigen bundle zsh-users/zsh-completions

antigen apply

source $ZSH/oh-my-zsh.sh

# User configuration

###############################################################################
# Environment variables                                                       #
###############################################################################
# Change the prompt styles
PS1='%(5~|…/%3~|%~)'
# PS1='\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;32m\]\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '

# Use a 256-color terminal setting
[[ $TMUX = "" ]] && export TERM="xterm-256color" # Enables 265 colors in tmux
#export TERM=screen-256color
# export LSCOLORS=GxFxCxDxBxegedabagaced
# export TERM="xterm-color"

export GREP_OPTIONS='--color=auto'
export EDITOR='sublime --wait' # Sets the default editor

# Tell ls to be colorful
export CLICOLOR=1

# Set PATH vars
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
export PATH="/usr/local/heroku/bin:$PATH" # Added by the Heroku Toolbelt
#$HOME/.rbenv/bin

# Moved to .zshenv
# # For NVM (Node Version Manager)
# export NVM_DIR="/Users/danyim/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# source ~/.nvm/nvm.sh
# export PATH="$PATH:`yarn global bin`" # Yarn

# For RBENV
export PATH="$HOME/.rbenv/bin:$PATH"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Sets pgp key generated on 1/15/2015 as the default key
export GPGKEY=1988FBC9

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/id_rsa"

# For Python tab completions
export PYTHONSTARTUP=$HOME/.pythonrc.py

# For Python virtual env
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Developer
source /usr/local/bin/virtualenvwrapper.sh

# Autojump (from Homebrew)
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

###############################################################################
# Aliases                                                                     #
###############################################################################

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Displays a tree of files/folders of the current directory
alias t='tree -L 2 -C --dirsfirst --filelimit 20 -F'

# Set helpful ls shortcuts
alias ls='exa'
alias l='ls -al'
alias ll='ls -l'
alias lll='ls -a'

# Helpful commands
mkcd() {
  mkdir $1
  cd $1
}

# Alias more to less--I always say more when I mean less ;)
alias more='less'
# Make sure stuff piped through less retains color
alias less='less -R'

# Always use 256-color tmux sessions
alias tmux='tmux -2'

# git/git-flow aliases
alias gita='git add .'
alias clone='git clone'
alias gitc='git clone'
alias gitl='git lg'
alias gitlg='git log --graph --decorate --oneline'
alias gits='git status'
alias gitr='git recent'
alias gitch='git ch'
alias gs='git stash'
alias gitsl='git sl'
alias gsa='git stash apply'
alias gsl='git stash list'
alias gsc='git stash clear'
alias gft='git fetch --tags'
alias gpt='git push --tags'
alias gcm='git checkout master'
alias gmm='git merge master --no-ff'
alias gcd='git checkout develop'
alias gmd='git merge develop --no-ff'

# Sublime
alias subl='sublime'

# cd into ~/Developer
alias cdd='cd ~/Developer'
alias -- -='cd ~-' # Typing '-' navigates to the previous directory

# NPM
alias npmls='npm ls -g --depth=0' # Prints all root packages installed globally

###############################################################################
# Misc                                                                        #
###############################################################################

# Allow for reverse tab of completion lists
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey "^X\x7f" backward-kill-line

# For Z -- https://github.com/rupa/z
. `brew --prefix`/etc/profile.d/z.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Don't share command history with other tabs
unsetopt share_history

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/danyim/Downloads/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/danyim/Downloads/google-cloud-sdk/path.zsh.inc'; fi

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# For Zippy
alias gobuild="go generate teleopui/teleopui.go && go build ./cmd/teleop-server && ./teleop-server"
