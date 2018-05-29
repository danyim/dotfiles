#!/bin/bash
# Loads the configuration from the repository

current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

UTCTIME=`date -u +%s`
BACKUP_DIR=$HOME/.dotfiles.backup/$UTCTIME

echo "Loading dotfile configuration from the repository..."
echo "Re-run with the -i switch to ignore Brewfile installs"
echo "WARNING: All existing files will be backed up to $BACKUP_DIR"
echo ""

read -p "Are you SURE you want to backup and overwrite your settings? [Y/n] " -n 1 -r
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
  echo "Parsing Brewfile..."
# Read the Brewfile and invoke Homebrew to install
  brew update
  brew upgrade
  brew bundle
fi

# Make the backup directory
echo "Creating backup directory $BACKUP_DIR ..."
mkdir -p $BACKUP_DIR

# Copy zsh configs
echo "Importing git configuration..."
backup_if_exists ~/.zshrc $BACKUP_DIR
cp .zshrc ~/.zshrc
backup_if_exists ~/.zshenv $BACKUP_DIR
cp .zshenv ~/.zshenv
touch ~/.localrc # Make sure a ~/.localrc exists

# Git
echo "importing git settings..."
backup_if_exists ~/.gitconfig $BACKUP_DIR
cp .gitconfig ~/.gitconfig
backup_if_exists ~/.gitignore $BACKUP_DIR
cp .gitignore ~/.gitignore_global

# Alacritty
echo "Importing alacritty settings..."
mkdir -p ~/.config/alacritty
backup_if_exists ~/.config/alacritty/alacritty.yml $BACKUP_DIR
if is_macos; then
  cp alacritty.yml ~/.config/alacritty/alacritty.yml
else
  cp alacritty-linux.yml ~/.config/alacritty/alacritty.yml
fi

# Sublime
echo "Importing Sublime Text settings..."
mkdir -p ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
mkdir -p $BACKUP_DIR/sublime
if is_macos; then  
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings $BACKUP_DIR/sublime
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap $BACKUP_DIR/sublime
  cp sublime/Preferences.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
  cp sublime/Default\ \(OSX\).sublime-keymap ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
else
  # TODO: Find out the settings directory on Linux
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings $BACKUP_DIR/sublime
  cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap $BACKUP_DIR/sublime
  cp sublime/Preferences.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
  cp sublime/Default\ \(Linux\).sublime-keymap ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
fi

# Copy key fonts (-n option prevents overwrites)
if is_macos; then  
  cp -n fonts/Inconsolata-Regular.ttf /Library/Fonts/
  cp -n fonts/Inconsolata-Bold.ttf /Library/Fonts/
  cp -n fonts/Inconsolata\ for\ Powerline.otf ~/Library/Fonts/
  cp -n fonts/Inconsolata-dz\ for\ Powerline.otf ~/Library/Fonts/
  cp -n fonts/Inconsolata-g\ for\ Powerline.otf ~/Library/Fonts/
  cp -n fonts/Inconsolata.otf ~/Library/Fonts/
fi

# tmux
echo "Importing tmux settings..."
backup_if_exists ~/.tmux.conf $BACKUP_DIR
cp .tmux.conf ~/.tmux.conf

# vim
echo "Importing vim settings..."
backup_if_exists ~/.vimrc $BACKUP_DIR
cp .vimrc ~/.vimrc
backup_if_exists ~/.vim/colors $BACKUP_DIR
mkdir -p ~/.vim/colors
cp zenburn/zenburn.vim ~/.vim/colors
