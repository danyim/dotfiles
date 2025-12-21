#!/bin/bash

# Checks if the first argument exists, if so, copy to the 2nd arg (backup directory)
backup_if_exists() {
  if [[ -e "$1" ]] && [[ -r "$1" ]]; then
    local dest_dir
    dest_dir="$(dirname "$2")"
    if [[ -d "$dest_dir" ]] && [[ -w "$dest_dir" ]]; then
      cp "$1" "$2"
      return $?
    else
      return 1
    fi
  else
    return 1
  fi
}

# Checks if the current operating system is macOS
is_macos() {
  local platform
  platform="$(uname)"
  [ "$platform" = "Darwin" ]
}

# Checks if the current operating system is Linux
is_linux() {
  local platform
  platform="$(uname)"
  [ "$platform" = "Linux" ]
}

# Checks if a command exists (in PATH and executable)
command_exists() {
  [ -x "$(command -v "$1")" ]
}

# Checks if a command is available (alternative name for command_exists)
is_command_available() {
  command_exists "$1"
}
