# .dotfiles

<div align="center">
<img src="https://github.com/danyim/dotfiles/raw/master/screenshot.png" alt="screenshot" />
</div>

My dotfiles, circa 2017.

The theme I'm using for my editor and terminal is the [Zenburn color scheme](http://kippura.org/zenburnpage/). I typically pair that with [Inconsolata](http://levien.com/type/myfonts/inconsolata.html) as my main programming font.

### Install the following manually
  - macOS Package Manager: [Homebrew](https://brew.sh/)
  - Editor: [Sublime Text 3](https://www.sublimetext.com/3) (with Package Control)
  - Terminal: [Alacritty](https://github.com/jwilm/alacritty)
  - Shell: zsh `chsh -s $(which zsh)`
  - Shell Plugin Manager: [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
  - Shell Navigation: [z](https://github.com/rupa/z)
  - Fuzzy File Search: [fzf](https://github.com/junegunn/fzf)
  - `ls` Replacement: [Exa](https://github.com/ogham/exa)

### Loading dotfiles into system
- Run `./load.sh`
    - This will backup any existing dotfiles into a new directory `~/.dotfiles.backup/<UTC epoch>`

### Updating dotfiles
- Run `./read.sh` in the repository's directory to copy all of the system's settings.
