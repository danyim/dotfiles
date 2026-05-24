alias br=broot
export PATH="$HOME/bin:/usr/local/bin:$PATH"
#export PATH=/opt/homebrew/bin:$PATH
# For Apple Silicon
#export PATH="$PATH:/opt/homebrew/sbin:/opt/homebrew/bin"
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
# For Rust
export PATH="$HOME/.cargo/bin:$PATH"
# For Yarn (Node)
# export PATH="$PATH:`yarn global bin`" # Yarn
# For Android simulation
export PATH=$PATH:/Applications/Genymotion.app/Contents/MacOS/tools
# For Golang
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GO111MODULE=on # Enable Go module support
. "$HOME/.cargo/env"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
eval $(/opt/homebrew/bin/brew shellenv)

# nvm is loaded lazily via zsh-nvm antigen bundle in .zshrc

# Put the default nvm node/npm/pnpm on PATH without sourcing nvm.sh.
# Keeps lazy-load for fast shell startup while ensuring arm64 binaries win
# over any x86 leftovers (e.g. $PNPM_HOME standalone). Runs in ~1ms.
if [ -s "$NVM_DIR/alias/default" ]; then
  _nvm_default=$(cat "$NVM_DIR/alias/default")
  if [ -d "$NVM_DIR/versions/node/$_nvm_default" ]; then
    _nvm_bin="$NVM_DIR/versions/node/$_nvm_default/bin"
  else
    # Default is an alias (e.g. lts/*) — pick newest installed version
    _nvm_latest=$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -1)
    [ -n "$_nvm_latest" ] && _nvm_bin="$NVM_DIR/versions/node/$_nvm_latest/bin"
  fi
  [ -d "${_nvm_bin:-}" ] && export PATH="$_nvm_bin:$PATH"
  unset _nvm_default _nvm_bin _nvm_latest
fi
