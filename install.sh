#!/bin/bash
#
# Installs software dependencies (oh-my-zsh, antigen, fzf, tmux, TPM, nvm,
# Rust, cargo tools, kubectl, etc.).
#
# Run as your normal user, not root. Individual commands that need root
# invoke `sudo` themselves so user-owned files ($HOME, ~/.cargo, ~/.nvm,
# ~/.fzf, ~/.tmux) don't end up owned by root.
#
# Software only — run `load.sh` afterwards (or pass --load) to install the
# actual dotfile configurations.

set -e

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run install.sh as root. Run it as your normal user; it will"
  echo "invoke sudo for the specific steps that need it."
  exit 1
fi

RUN_LOAD=0
for arg in "$@"; do
  case "$arg" in
    --load) RUN_LOAD=1 ;;
  esac
done

INSTALL_ROOT="$HOME/tmp"
mkdir -p "$INSTALL_ROOT"

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

# Install powerlevel10k theme
echo "Installing Powerlevel10k for oh-my-zsh..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

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
~/.fzf/install --all

# Install diff-so-fancy
echo "Installing diff-so-fancy..."
git clone https://github.com/so-fancy/diff-so-fancy.git "$INSTALL_ROOT/diff-so-fancy"
sudo ln -sf "$INSTALL_ROOT/diff-so-fancy/diff-so-fancy" /usr/local/bin/diff-so-fancy

# Install vim-plug
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install a C toolchain (needed by cargo to link crates with build scripts, e.g. broot, exa)
echo "Installing C toolchain..."
if is_macos; then
  xcode-select --install 2>/dev/null || true
elif is_linux; then
  sudo apt-get update && sudo apt-get install -y build-essential
else
  echo "Unsupported platform for C toolchain installation"
  exit 1
fi

# Install Rust (non-interactive)
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Install broot
echo "Installing broot..."
cargo install broot

# Install Exa
echo "Installing exa..."
cargo install exa

# Install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Install tmux
echo "Installing tmux..."
if is_macos; then
  brew install tmux
elif is_linux; then
  sudo apt-get update && sudo apt-get install -y tmux
else
  echo "Unsupported platform for tmux installation"
  exit 1
fi

# Install TPM
echo "Installing TPM (tmux plugin manager)..."
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install herdr
echo "Installing herdr..."
curl -fsSL https://herdr.dev/install.sh | sh

# Install kubectl
echo "Installing kubectl..."
KUBECTL_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
if is_macos; then
  curl -L "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/darwin/amd64/kubectl" -o "$INSTALL_ROOT/kubectl"
elif is_linux; then
  curl -L "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o "$INSTALL_ROOT/kubectl"
else
  echo "Unsupported platform for kubectl installation"
  exit 1
fi
chmod +x "$INSTALL_ROOT/kubectl"
sudo mv "$INSTALL_ROOT/kubectl" /usr/local/bin/kubectl

if is_macos; then
  if ! is_command_available brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew already installed, skipping..."
  fi

  brew install git vim tmux jq hub ripgrep
  brew install --cask spectacle clipy alfred spotify
fi

# Cleanup temporary install directory
rm -rf "$INSTALL_ROOT"

if [ "$RUN_LOAD" -eq 1 ]; then
  echo ""
  echo "Running load.sh to install dotfile configurations..."
  bash "$current_dir/load.sh"
else
  printf "\n\nSoftware install complete. Run ./load.sh to install dotfile configs, then open a new shell.\n"
fi
