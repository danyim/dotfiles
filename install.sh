#!/bin/sh

current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

INSTALL_ROOT=$HOME/tmp

mkdir -p $INSTALL_ROOT

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
git clone --depth 1 https://github.com/rupa/z $INSTALL_ROOT/z
sudo cp $INSTALL_ROOT/z/z.sh /etc/profile.d

# Install fzf
echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install diff-so-fancy
echo "Installing diff-so-fancy..."
git clone git@github.com:so-fancy/diff-so-fancy.git $INSTALL_ROOT/diff-so-fancy
sudo ln -s $INSTALL_ROOT/diff-so-fancy/diff-so-fancy /usr/local/bin/diff-so-fancy

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

# Install broot
echo "Installing broot..."
cargo install broot 

# Install Exa
echo "Installing exa..."
cargo install exa

# Install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# Install TPM
echo "Installing TPM (tmux plugin manager)..."
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install kubectl
echo "Installing kubectl..."
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt` /bin/linux/amd64/kubectl

if is_macos; then
  echo "Installing Homebrew..."
  mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
  brew install git vim tmux jq 
fi

echo "\n\nComplete. Please open a new shell."
