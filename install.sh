#!/bin/sh

current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

INSTALL_ROOT=$HOME/tmp

mkdir -p $INSTALL_ROOT

# Install antigen (oh-my-zsh plugin manager)
echo "Installing antigen..."
sudo mkdir -p /usr/local/share/antigen
sudo sh -c "curl -L git.io/antigen > /usr/local/share/antigen/antigen.zsh"

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install z
echo "Installing z (jump around)..."
sudo mkdir -p /etc/profile.d
git clone --depth 1 https://github.com/rupa/z $INSTALL_ROOT/z
cp $INSTALL_ROOT/z.sh /etc/profile.d

# Install fzf
echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install vim-plug
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install Rust
echo "Installing Rust..."
curl https://sh.rustup.rs -sSf | sh

# Install Alacritty
echo "Installing Alacritty..."
git clone --depth 1 https://github.com/jwilm/alacritty $INSTALL_ROOT/alacritty

# Install Exa
echo "Installing exa..."
cargo install exa

# Install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

echo "\n\nComplete. Please open a new shell."
