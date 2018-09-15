#!/bin/bash
# Loads the configuration from the repository

current_dir="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

UTCTIME=`date -u +%s`
BACKUP_DIR=$HOME/.dotfiles.backup/$UTCTIME

echo "Loading dotfile configuration from the repository..."
echo "Re-run with the -b switch to install the Brewfile manifest"
echo "WARNING: All existing files will be backed up to $BACKUP_DIR"
echo ""

read -p "Are you SURE you want to backup and overwrite your settings? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

PARSE_BREWS=0
while getopts "b" opt; do
  case "$opt" in
    b)  PARSE_BREWS=1
    ;;
  esac
done

# Create a backup directory
mkdir -p $BACKUP_DIR

if is_macos && [ $PARSE_BREWS -eq 1 ]; then
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
GIT_USERNAME=$(git config --global user.name)
GIT_EMAIL=$(git config --global user.email)
cp .gitconfig ~/.gitconfig
# Replace username & email
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
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

# Kitty  
echo "Importing Kitty settings..."
mkdir -p ~/.config/kitty
backup_if_exists ~/.config/kitty/kitty.conf $BACKUP_DIR
if is_macos; then
  cp kitty.conf ~/.config/kitty/kitty.conf .
else
  cp kitty-linux.conf ~/.config/kitty/kitty.conf .
fi

# Sublime
echo "Importing Sublime Text settings..."
mkdir -p ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
mkdir -p $BACKUP_DIR/sublime
if is_macos; then
  # Must use double quotes in paths due to the spaces
  SUBLIME_DIR="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  backup_if_exists "$SUBLIME_DIR/Preferences.sublime-settings" $BACKUP_DIR/sublime
  backup_if_exists "$SUBLIME_DIR/Default (OSX).sublime-keymap" $BACKUP_DIR/sublime
  backup_if_exists "$SUBLIME_DIR/*.sublime-snippet" $BACKUP_DIR/sublime
  cp ./sublime/Preferences.sublime-settings "$SUBLIME_DIR"
  cp ./sublime/"Default (OSX)".sublime-keymap "$SUBLIME_DIR"
  cp ./sublime/*.sublime-snippet "$SUBLIME_DIR"
  cp ./sublime/zenburn.tmTheme "$SUBLIME_DIR" 
else
  # TODO: Find out the settings directory on Linux
  SUBLIME_DIR="$HOME/.config/sublime-text-3/Packages/User"
  backup_if_exists "$SUBLIME_DIR/Preferences.sublime-settings" $BACKUP_DIR/sublime
  backup_if_exists "$SUBLIME_DIR/Default\ \(Linux\).sublime-keymap" $BACKUP_DIR/sublime
  backup_if_exists "$SUBLIME_DIR/*.sublime-snippet" $BACKUP_DIR/sublime
  cp sublime/Preferences.sublime-settings $SUBLIME_DIR 
  cp sublime/Default\ \(Linux\).sublime-keymap $SUBLIME_DIR
  cp sublime/*.sublime-snippet $SUBLIME_DIR
  cp sublime/zenburn.tmTheme $SUBLIME_DIR 
fi

# Copy key fonts (-n option prevents overwrites)
if is_macos; then
  FONT_DIR=$HOME/Library/Fonts
else  
  FONT_DIR=$HOME/.fonts
fi
echo "Installing fonts to $FONT_DIR ..."
mkdir -p $FONT_DIR
cp -n fonts/Inconsolata-Regular.ttf $FONT_DIR
cp -n fonts/Inconsolata-Bold.ttf $FONT_DIR
cp -n fonts/Inconsolata\ for\ Powerline.otf $FONT_DIR
cp -n fonts/Inconsolata\ Bold\ for\ Powerline.ttf $FONT_DIR
cp -n fonts/Inconsolata-dz\ for\ Powerline.otf $FONT_DIR
cp -n fonts/Inconsolata-g\ for\ Powerline.otf $FONT_DIR
cp -n fonts/Inconsolata.otf $FONT_DIR

# tmux
echo "Importing tmux settings..."
backup_if_exists ~/.tmux.conf $BACKUP_DIR
cp .tmux.conf ~/.tmux.conf

# vim
echo "Importing vim settings..."
backup_if_exists ~/.vimrc $BACKUP_DIR
cp .vimrc ~/.vimrc
backup_if_exists ~/.vim/colors/zenburn.vim $BACKUP_DIR
mkdir -p ~/.vim/colors
cp zenburn/zenburn.vim ~/.vim/colors/zenburn.vim

if is_macos; then
  echo "Running macOS settings script..."
  ./macos-settings.sh
fi

echo ""
echo "Import complete!"
echo ""
