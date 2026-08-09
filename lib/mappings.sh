#!/bin/bash

# Canonical dotfiles <-> system file mapping, shared by sync.sh and restore.sh.
# This is the single source of truth for "which repo file maps to which system
# path". Backups written by sync.sh are named from these mappings, so restore.sh
# reuses this table to map a backed-up file back to where it belongs.

# Depend on helpers.sh (is_macos). Source it if not already loaded.
if ! declare -f is_macos > /dev/null 2>&1; then
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
fi

# Determine paths based on platform
get_sublime_dir() {
  if is_macos; then
    if [ -d "$HOME/Library/Application Support/Sublime Text/Packages/User" ]; then
      echo "$HOME/Library/Application Support/Sublime Text/Packages/User"
    else
      echo "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
    fi
  else
    if [ -d "$HOME/.config/sublime-text/Packages/User" ]; then
      echo "$HOME/.config/sublime-text/Packages/User"
    else
      echo "$HOME/.config/sublime-text-3/Packages/User"
    fi
  fi
}

get_vscode_dir() {
  if is_macos; then
    echo "$HOME/Library/Application Support/Code/User"
  else
    echo "$HOME/.config/Code/User"
  fi
}

get_font_dir() {
  if is_macos; then
    echo "$HOME/Library/Fonts"
  else
    echo "$HOME/.fonts"
  fi
}

# Build file mapping array: "repo_path:system_path"
declare -a FILE_MAPPINGS=()

build_file_mappings() {
  local sublime_dir vscode_dir
  sublime_dir=$(get_sublime_dir)
  vscode_dir=$(get_vscode_dir)

  # Core dotfiles
  FILE_MAPPINGS+=(
    ".zshrc:$HOME/.zshrc"
    ".zshenv:$HOME/.zshenv"
    ".gitconfig:$HOME/.gitconfig"
    ".gitignore_global:$HOME/.gitignore_global"
    ".tmux.conf:$HOME/.tmux.conf"
    ".vimrc:$HOME/.vimrc"
  )

  # Alacritty
  FILE_MAPPINGS+=("alacritty.toml:$HOME/.config/alacritty/alacritty.toml")

  # Kitty
  FILE_MAPPINGS+=("kitty.conf:$HOME/.config/kitty/kitty.conf")

  # tmux helper scripts
  FILE_MAPPINGS+=("bin/tmux-jump:$HOME/.local/bin/tmux-jump")
  FILE_MAPPINGS+=("bin/tmux-window-focus:$HOME/.local/bin/tmux-window-focus")
  FILE_MAPPINGS+=("bin/tmux-mark-read:$HOME/.local/bin/tmux-mark-read")

  # Claude Code
  FILE_MAPPINGS+=("claude/statusline-command.sh:$HOME/.claude/statusline-command.sh")
  FILE_MAPPINGS+=("claude/settings.json:$HOME/.claude/settings.json")

  # VSCode
  FILE_MAPPINGS+=(
    "vscode/settings.json:$vscode_dir/settings.json"
    "vscode/keybindings.json:$vscode_dir/keybindings.json"
  )

  # Sublime
  FILE_MAPPINGS+=(
    "sublime/Preferences.sublime-settings:$sublime_dir/Preferences.sublime-settings"
  )
  if is_macos; then
    FILE_MAPPINGS+=("sublime/Default (OSX).sublime-keymap:$sublime_dir/Default (OSX).sublime-keymap")
  else
    FILE_MAPPINGS+=("sublime/Default (Linux).sublime-keymap:$sublime_dir/Default (Linux).sublime-keymap")
  fi

  # Vim colorscheme
  FILE_MAPPINGS+=("zenburn/zenburn.vim:$HOME/.vim/colors/zenburn.vim")
}
