#!/bin/bash

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

INSTALL_ROOT="$HOME/tmp"

mkdir -p "$INSTALL_ROOT"

# Elevate shell script
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install powerline theme
echo "Installing Powerlevel10k for oh-my-zsh..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install antigen (oh-my-zsh plugin manager)
echo "Installing antigen..."
sudo mkdir -p /usr/local/share/antigen
sudo sh -c "curl -L git.io/antigen > /usr/local/share/antigen/antigen.zsh"

# Install z
echo "Installing z (jump around)..."
sudo mkdir -p /etc/profile.d
git clone --depth 1 https://github.com/rupa/z "$INSTALL_ROOT/z"
sudo cp "$INSTALL_ROOT/z/z.sh" /etc/profile.d

# Install fzf
echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install diff-so-fancy
echo "Installing diff-so-fancy..."
git clone https://github.com/so-fancy/diff-so-fancy.git "$INSTALL_ROOT/diff-so-fancy"
sudo ln -s "$INSTALL_ROOT/diff-so-fancy/diff-so-fancy" /usr/local/bin/diff-so-fancy

# Install vim-plug
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install Rust
echo "Installing Rust..."
curl https://sh.rustup.rs -sSf | sh

# Install Alacritty
echo "Installing Alacritty..."
git clone --depth 1 https://github.com/jwilm/alacritty "$INSTALL_ROOT/alacritty"

# Install broot
echo "Installing broot..."
cargo install broot 

# Install Exa
echo "Installing exa..."
cargo install exa

# Install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Install TPM
echo "Installing TPM (tmux plugin manager)..."
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install kubectl
echo "Installing kubectl..."
if is_macos; then
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
elif is_linux; then
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
else
  echo "Unsupported platform for kubectl installation"
  exit 1
fi

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

if is_macos; then
  if ! is_command_available brew; then
    echo "Installing Homebrew..."
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
  else
    echo "Homebrew already installed, skipping..."
  fi
  
  brew install \
    git vim tmux jq hub ripgrep
  brew install --cask \
    spectacle clipy alfred spotify
fi

printf "\n\nComplete. Please open a new shell.\n"

# Cleanup temporary install directory
rm -rf "$INSTALL_ROOT"
