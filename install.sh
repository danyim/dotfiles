#!/bin/sh

current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

INSTALL_ROOT=$HOME

# Install antigen (oh-my-zsh plugin manager)
echo "Installing antigen..."
sudo mkdir -p /usr/local/share/antigen
sudo sh -c "curl -L git.io/antigen > /usr/share/antigen/antigen.zsh"

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install z
echo "Installing z (jump around)..."
git clone  --depth 1 https://github.com/rupa/z ~/z

# Install fzf
echo "Installing fzf..."
git clone  --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install vim-plug
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
