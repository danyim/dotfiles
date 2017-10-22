#!/bin/bash
# Reads the current system's configuration and places the updated files into the
# repository

# Get all homebrew recipes
brew list > brews.txt
# Homebrew casks
brew cask list > casks.txt

# Copy zsh configs
cp ~/.zshrc .
cp ~/.zshenv .

# Git
cp ~/.gitconfig .
cp ~/.gitignore_global .

# Alacritty
cp ~/.config/alacritty/alacritty.yml .

# Sublime
cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings sublime/
cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap sublime/
# cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/zenburn sublime/zenburn

# Copy key fonts
cp /Library/Fonts/Inconsolata-Regular.ttf fonts
cp /Library/Fonts/Inconsolata-Bold.ttf fonts
cp ~/Library/Fonts/Inconsolata\ for\ Powerline.otf fonts
cp ~/Library/Fonts/Inconsolata-dz\ for\ Powerline.otf fonts
cp ~/Library/Fonts/Inconsolata-g\ for\ Powerline.otf fonts
cp ~/Library/Fonts/Inconsolata.otf fonts

# tmux
cp ~/.tmux.conf .

# vim
cp ~/.vimrc .
