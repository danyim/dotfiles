#!/bin/sh

# Use font smoothing https://github.com/alacritty/alacritty/issues/4616#issuecomment-1236413444
defaults write -g AppleFontSmoothing -int 0

# Disable displaying the accents panel when holding a key (so easier key repeats)
defaults write -g ApplePressAndHoldEnabled -bool false

# Disable special characters when holding down alt 
defaults write -g NSUserKeyEquivalents -dict-add "Special Characters..." nul

# Change the default screenshot location to ~/Screenshots
SCREENSHOT_DIR=$HOME/Screenshots
mkdir -p $SCREENSHOT_DIR
defaults write com.apple.screencapture location $SCREENSHOT_DIR
defaults write com.apple.screencapture name "img"
