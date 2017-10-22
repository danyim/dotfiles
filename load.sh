#!/bin/bash
# Loads the configuration from the repository

UTCTIME=`date -u +%s`
BACKUP_DIR=$HOME/.dotfiles.backup/$UTCTIME

# Create a backup directory
mkdir -p $BACKUP_DIR

# Homebrew
# brew doctor
# brew update
while read in; do brew install "$in"; done < brews.txt
# Homebrew casks
while read in; do brew cask install "$in"; done < cask.txt

# Copy zsh configs
cp ~/.zshrc $BACKUP_DIR
cp .zshrc ~/.zshrc
cp ~/.zshenv $BACKUP_DIR
cp .zshenv ~/.zshenv

# Git
cp ~/.gitconfig $BACKUP_DIR
cp .gitconfig ~/.gitconfig
cp ~/.gitignore_global $BACKUP_DIR
cp .gitignore_global ~/.gitignore_global

# Alacritty
mkdir -p ~/.config/alacritty
cp ~/.config/alacritty/alacritty.yml $BACKUP_DIR
cp alacritty.yml ~/.config/alacritty/alacritty.yml

# Sublime
mkdir -p ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
mkdir -p $BACKUP_DIR/sublime
cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings $BACKUP_DIR/sublime
cp sublime/Preferences.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

# Copy key fonts (-n option prevents overwrites)
cp -n fonts/Inconsolata-Regular.ttf /Library/Fonts/
cp -n fonts/Inconsolata-Bold.ttf /Library/Fonts/
cp -n fonts/Inconsolata\ for\ Powerline.otf ~/Library/Fonts/
cp -n fonts/Inconsolata-dz\ for\ Powerline.otf ~/Library/Fonts/
cp -n fonts/Inconsolata-g\ for\ Powerline.otf ~/Library/Fonts/
cp -n fonts/Inconsolata.otf ~/Library/Fonts/

# tmux
cp ~/.tmux.conf $BACKUP_DIR
cp .tmux.conf ~/.tmux.conf

# vim
cp ~/.vimrc $BACKUP_DIR
cp .vimrc ~/.vimrc