#!/bin/bash
# Loads the configuration from the repository
UTCTIME=`date -u +%s`
BACKUP_DIR=$HOME/.dotfiles.backup/$UTCTIME

echo "Loading dotfile configuration from the repository..."
echo "Re-run with the -i switch to ignore Brewfile installs"
echo "WARNING: All existing files will be backed up to $BACKUP_DIR"
echo ""

read -p "Are you SURE you want to backup and overwrite your settings? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

PARSE_BREWS=1
while getopts "i" opt; do
  case "$opt" in
    i)  PARSE_BREWS=0
    ;;
  esac
done

# Create a backup directory
mkdir -p $BACKUP_DIR

if [ $PARSE_BREWS -eq 1 ]
then
  # Read the Brewfile and invoke Homebrew to install
  brew update
  brew upgrade
  brew bundle
fi

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
cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap $BACKUP_DIR/sublime
cp sublime/Preferences.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
cp sublime/Default\ \(OSX\).sublime-keymap ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

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
