#!/bin/bash
# Reads the current system's configuration and places the updated files into the
# repository

set -euo pipefail

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

# Parse command line arguments first
PARSE_BREWS=0
while getopts "b" opt; do
  case "$opt" in
    b)  PARSE_BREWS=1
    ;;
  esac
done

echo "Re-run with the -b switch to parse the Brewfile"
read -p "Read system config and update repo; continue? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

if is_macos && [ $PARSE_BREWS -eq 1 ]; then
  echo "Creating Brewfile..."
  rm -f Brewfile
  brew bundle dump --force
  mv Brewfile Brewfile.tmp
  sort Brewfile.tmp | uniq > Brewfile
  rm Brewfile.tmp
fi

# Copy zsh configs
echo "Reading zsh configuration..."
[ -f ~/.zshrc ] && cp ~/.zshrc .
[ -f ~/.zshenv ] && cp ~/.zshenv .

# Git
echo "Reading git settings..."
[ -f ~/.gitconfig ] && cp ~/.gitconfig .
[ -f ~/.gitignore ] && cp ~/.gitignore .gitignore_global

# Alacritty config
echo "Reading alacritty settings..."
[ -f ~/.config/alacritty/alacritty.toml ] && cp ~/.config/alacritty/alacritty.toml .

# Sublime Text
echo "Reading Sublime Text settings..."
if is_macos; then
  if [ -d "$HOME/Library/Application Support/Sublime Text/Packages/User" ]; then
    SUBLIME_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
  else
    SUBLIME_DIR="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  fi
  SUBLIME_KEYMAP="Default (OSX).sublime-keymap"
else
  if [ -d "$HOME/.config/sublime-text/Packages/User" ]; then
    SUBLIME_DIR="$HOME/.config/sublime-text/Packages/User"
  else
    SUBLIME_DIR="$HOME/.config/sublime-text-3/Packages/User"
  fi
  SUBLIME_KEYMAP="Default (Linux).sublime-keymap"
fi

if [ -d "$SUBLIME_DIR" ]; then
  [ -f "$SUBLIME_DIR/Preferences.sublime-settings" ] && cp "$SUBLIME_DIR/Preferences.sublime-settings" sublime/
  [ -f "$SUBLIME_DIR/$SUBLIME_KEYMAP" ] && cp "$SUBLIME_DIR/$SUBLIME_KEYMAP" sublime/
  for snippet in "$SUBLIME_DIR"/*.sublime-snippet; do
    [ -f "$snippet" ] && cp "$snippet" sublime/
  done
fi

# VSCode
echo "Reading VSCode settings..."
if is_macos; then
  VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
  VSCODE_DIR="$HOME/.config/Code/User"
fi

if [ -d "$VSCODE_DIR" ]; then
  for json_file in "$VSCODE_DIR"/*.json; do
    [ -f "$json_file" ] && cp "$json_file" vscode/
  done
fi

# Fonts
echo "Reading fonts..."
if is_macos; then
  FONT_DIR="$HOME/Library/Fonts"
else
  FONT_DIR="$HOME/.fonts"
fi

if [ -d "$FONT_DIR" ]; then
  [ -f "$FONT_DIR/Inconsolata-Regular.ttf" ] && cp "$FONT_DIR/Inconsolata-Regular.ttf" fonts/
  [ -f "$FONT_DIR/Inconsolata-Bold.ttf" ] && cp "$FONT_DIR/Inconsolata-Bold.ttf" fonts/
  [ -f "$FONT_DIR/Inconsolata Bold for Powerline.ttf" ] && cp "$FONT_DIR/Inconsolata Bold for Powerline.ttf" fonts/
  [ -f "$FONT_DIR/Inconsolata for Powerline.otf" ] && cp "$FONT_DIR/Inconsolata for Powerline.otf" fonts/
  [ -f "$FONT_DIR/Inconsolata-dz for Powerline.otf" ] && cp "$FONT_DIR/Inconsolata-dz for Powerline.otf" fonts/
  [ -f "$FONT_DIR/Inconsolata-g for Powerline.otf" ] && cp "$FONT_DIR/Inconsolata-g for Powerline.otf" fonts/
  [ -f "$FONT_DIR/Inconsolata.otf" ] && cp "$FONT_DIR/Inconsolata.otf" fonts/
fi

# Zenburn
echo "Reading vim colorscheme..."
[ -f ~/.vim/colors/zenburn.vim ] && cp ~/.vim/colors/zenburn.vim ./zenburn/

# tmux
echo "Reading tmux settings..."
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf .

# vim
echo "Reading vim settings..."
[ -f ~/.vimrc ] && cp ~/.vimrc .

echo "Read complete!"
