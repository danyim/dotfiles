#!/bin/bash
# Reads the current system's configuration and places the updated files into the
# repository

if [[ "$OSTYPE" == "darwin"* ]]; then # macOS
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
cp ~/.gitignore_global .

# Alacritty configs
if [[ "$OSTYPE" == "linux-gnu" ]]; then # Linux
  cp ~/.config/alacritty/alacritty.yml alacritty-linux.yml
elif [[ "$OSTYPE" == "darwin"* ]]; then # macOS
  cp ~/.config/alacritty/alacritty.yml .
fi

# Sublime
if [[ "$OSTYPE" == "linux-gnu" ]]; then # Linux
  cp ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings sublime/
  cp ~/.config/sublime-text-3/Packages/User/Default\ \(Linux\).sublime-keymap sublime/
elif [[ "$OSTYPE" == "darwin"* ]]; then # macOS
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings sublime/
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap sublime/
  # cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/zenburn sublime/zenburn
fi

# Copy key fonts
if [[ "$OSTYPE" == "darwin"* ]]; then # macOS
  cp /Library/Fonts/Inconsolata-Regular.ttf fonts
  cp /Library/Fonts/Inconsolata-Bold.ttf fonts
  cp ~/Library/Fonts/Inconsolata\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata-dz\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata-g\ for\ Powerline.otf fonts
  cp ~/Library/Fonts/Inconsolata.otf fonts
fi

# tmux
cp ~/.tmux.conf .

# vim
cp ~/.vimrc .
