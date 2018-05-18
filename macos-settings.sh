#!/bin/sh

# Disable displaying the accents panel when holding a key (so easier key repeats)
defaults write -g ApplePressAndHoldEnabled -bool false

# Change the default screenshot location to ~/Screenshots
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location
defaults write com.apple.screencapture name "img"
