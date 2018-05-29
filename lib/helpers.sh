#!/bin/bash

# Checks if the first argument exists, if so, copy to the 2nd arg (backup directory)
backup_if_exists() {
  [[ -e $1 ]] && cp $1 $2 
}

# Checks if the current operating system is macOS
is_macos() {
  local platform=$(uname)
  [ "$platform" == "Darwin" ]
}

# Checks if a command exists (in PATH and executable)
command_exists() {
  [ -x "$(command -v $1)" ]
}
