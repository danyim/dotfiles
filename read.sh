#!/bin/bash
# Reads the current system's configuration and places the updated files into the
# repository
current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

read -p "Read system config and update repo; continue? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

if is_macos; then # macOS
  # Homebrew config via bundling
  rm BrewFile
  brew bundle dump --force
  mv Brewfile Brewfile.tmp
  cat Brewfile.tmp | sort | uniq > Brewfile # Sort & dedupe the file
  rm Brewfile.tmp
fi

# Copy zsh configs
cp ~/.zshrc .
cp ~/.zshenv .

# Git
cp ~/.gitconfig .
cp ~/.gitignore .gitignore_global

# Alacritty configs
if is_macos; then # macOS
  cp ~/.config/alacritty/alacritty.yml .
else 
  cp ~/.config/alacritty/alacritty.yml alacritty-linux.yml
fi

# Sublime
if is_macos; then # macOS
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings sublime/
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap sublime/
else
  cp ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings sublime/
  cp ~/.config/sublime-text-3/Packages/User/Default\ \(Linux\).sublime-keymap sublime/
fi

# Copy key fonts
if is_macos; then # macOS
  cp /Library/Fonts/Inconsolata-Regular.ttf fonts
  cp /Library/Fonts/Inconsolata-Bold.ttf fonts
  cp ~/Library/Fonts/Inconsolata\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata-dz\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata-g\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata.otf fonts
fi

# Zenburn
cp ~/.vim/colors/zenburn.vim ./zenburn/

# tmux
cp ~/.tmux.conf .

# vim
cp ~/.vimrc .
