# For NVM (Node Version Manager)
export NVM_DIR="/Users/danyim/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
source ~/.nvm/nvm.sh

export PATH="$PATH:`yarn global bin`" # Yarn
export PATH=$PATH:/Applications/Genymotion.app/Contents/MacOS/tools # For Android simulation

# Golang
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
