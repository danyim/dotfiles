#!/bin/bash

backup_if_exists() {
  [[ -e $1 ]] && cp $1 $2 
}

is_macos() {
  local platform=$(uname)
  [ "$platform" == "Darwin" ]
}
