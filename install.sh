#!/bin/sh

cd $HOME

# Install antigen (oh-my-zsh plugin manager)
sudo mkdir -p /usr/local/share/antigen
sudo sh -c "curl -L git.io/antigen > /usr/share/antigen/antigen.zsh"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

