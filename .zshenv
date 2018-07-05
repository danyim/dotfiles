export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
# For Heroku
export PATH="/usr/local/heroku/bin:$PATH" # Added by the Heroku Toolbelt
# For Rust
export PATH="$HOME/.cargo/bin:$PATH"
# For NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[[ -r $NVM_DIR/bash_completion ]] && \. $NVM_DIR/bash_completion
# For Yarn (Node)
export PATH="$PATH:`yarn global bin`" # Yarn
# For Android simulation
export PATH=$PATH:/Applications/Genymotion.app/Contents/MacOS/tools
# For Golang
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
# For RVM (Ruby)
export PATH=$HOME/.rbenv/bin:$PATH
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
