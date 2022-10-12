alias br=broot
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/usr/local/git/bin:/usr/local/sbin:$PATH"
# For Rust
export PATH="$HOME/.cargo/bin:$PATH"
# For Yarn (Node)
export PATH="$PATH:`yarn global bin`" # Yarn
# For Android simulation
export PATH=$PATH:/Applications/Genymotion.app/Contents/MacOS/tools
# For Golang
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GO111MODULE=on # Enable Go module support
