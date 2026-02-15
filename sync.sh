#!/bin/bash
# Interactive sync script for dotfiles
# Compares repo files with installed files and allows selective synchronization

set -euo pipefail

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Options
DRY_RUN=0
SHOW_ALL=0

# Backup directory
UTCTIME=$(date -u +%s)
BACKUP_DIR="$HOME/.dotfiles.backup/$UTCTIME"
BACKUP_CREATED=0

# .syncignore patterns (loaded at runtime)
declare -a SYNCIGNORE_PATTERNS=()

# Load patterns from .syncignore (one regex per line, # for comments)
load_syncignore() {
  local syncignore_path="$current_dir/.syncignore"
  if [ ! -f "$syncignore_path" ]; then
    return
  fi

  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    SYNCIGNORE_PATTERNS+=("$line")
  done < "$syncignore_path"

  if [ ${#SYNCIGNORE_PATTERNS[@]} -gt 0 ]; then
    echo -e "${CYAN}Loaded ${#SYNCIGNORE_PATTERNS[@]} pattern(s) from .syncignore${NC}"
  fi
}

# Check if a hunk matches any .syncignore pattern
# Returns 0 (true) if matched, 1 (false) if not
# Sets MATCHED_PATTERN to the first matching pattern
hunk_matches_syncignore() {
  local hunk="$1"
  MATCHED_PATTERN=""

  if [ ${#SYNCIGNORE_PATTERNS[@]} -eq 0 ]; then
    return 1
  fi

  # Extract content lines from hunk (strip diff +/- /space prefixes)
  local content=""
  while IFS= read -r line; do
    # Skip @@ headers
    [[ "$line" =~ ^@@ ]] && continue
    # Strip the leading diff character (+, -, or space)
    content+="${line:1}"$'\n'
  done <<< "$hunk"

  for pattern in "${SYNCIGNORE_PATTERNS[@]}"; do
    if printf '%s' "$content" | grep -qE "$pattern" 2>/dev/null; then
      MATCHED_PATTERN="$pattern"
      return 0
    fi
  done

  return 1
}

usage() {
  echo "Usage: sync.sh [OPTIONS]"
  echo ""
  echo "Interactive sync for dotfiles between repo and system."
  echo ""
  echo "Options:"
  echo "  -n, --dry-run    Show what would change without applying"
  echo "  -a, --all        Show all files, including identical ones"
  echo "  -h, --help       Show this help"
  echo ""
  echo "Per-hunk actions (like git add -p):"
  echo "  [y] Apply this hunk (repo → system)"
  echo "  [n] Skip this hunk"
  echo "  [a] Apply this and all remaining hunks"
  echo "  [d] Done with file, skip remaining hunks"
  echo "  [r] Reverse: copy entire system file to repo"
  echo "  [e] Edit: open both files in vimdiff"
  echo "  [q] Quit: exit without further changes"
  echo "  [?] Help: show available actions"
  echo ""
  echo "Syncignore:"
  echo "  Place a .syncignore file in the repo root (one regex per line)."
  echo "  Hunks matching any pattern are automatically skipped."
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -a|--all)
      SHOW_ALL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

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

  # Alacritty (platform-specific)
  if is_macos; then
    FILE_MAPPINGS+=("alacritty.yml:$HOME/.config/alacritty/alacritty.yml")
  else
    FILE_MAPPINGS+=("alacritty-linux.yml:$HOME/.config/alacritty/alacritty.yml")
  fi

  # Kitty
  FILE_MAPPINGS+=("kitty.conf:$HOME/.config/kitty/kitty.conf")

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

# Compare two files and return status
# Returns: "identical", "modified", "missing_system", "missing_repo"
compare_files() {
  local repo_path="$1"
  local system_path="$2"

  local repo_exists=0
  local system_exists=0

  [ -f "$current_dir/$repo_path" ] && repo_exists=1
  [ -f "$system_path" ] && system_exists=1

  if [ $repo_exists -eq 0 ] && [ $system_exists -eq 0 ]; then
    echo "both_missing"
  elif [ $repo_exists -eq 1 ] && [ $system_exists -eq 0 ]; then
    echo "missing_system"
  elif [ $repo_exists -eq 0 ] && [ $system_exists -eq 1 ]; then
    echo "missing_repo"
  else
    if diff -q "$current_dir/$repo_path" "$system_path" > /dev/null 2>&1; then
      echo "identical"
    else
      echo "modified"
    fi
  fi
}

# Print colored status
print_status() {
  local status="$1"
  case "$status" in
    identical)
      echo -e "${GREEN}✓ identical${NC}"
      ;;
    modified)
      echo -e "${YELLOW}● modified${NC}"
      ;;
    missing_system)
      echo -e "${BLUE}+ only in repo${NC}"
      ;;
    missing_repo)
      echo -e "${CYAN}? only on system${NC}"
      ;;
    both_missing)
      echo -e "${RED}✗ both missing${NC}"
      ;;
  esac
}

# Show diff between files
show_diff() {
  local repo_path="$1"
  local system_path="$2"

  # Use delta if available, otherwise colordiff, otherwise plain diff
  if command_exists delta; then
    delta "$system_path" "$current_dir/$repo_path" 2>/dev/null || true
  elif command_exists colordiff; then
    colordiff -u "$system_path" "$current_dir/$repo_path" 2>/dev/null || true
  else
    diff -u "$system_path" "$current_dir/$repo_path" 2>/dev/null || true
  fi
}

# Ensure backup directory exists
ensure_backup_dir() {
  if [ $BACKUP_CREATED -eq 0 ]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=1
    echo -e "${CYAN}Backup directory: $BACKUP_DIR${NC}"
  fi
}

# Apply repo file to system
apply_to_system() {
  local repo_path="$1"
  local system_path="$2"

  if [ $DRY_RUN -eq 1 ]; then
    echo -e "${YELLOW}[DRY-RUN] Would copy: $repo_path → $system_path${NC}"
    return
  fi

  ensure_backup_dir

  # Create parent directory if needed
  local parent_dir
  parent_dir=$(dirname "$system_path")
  mkdir -p "$parent_dir"

  # Backup existing file
  if [ -f "$system_path" ]; then
    local backup_path="$BACKUP_DIR/$(basename "$system_path")"
    cp "$system_path" "$backup_path"
    echo -e "${CYAN}Backed up: $system_path → $backup_path${NC}"
  fi

  # Copy new file
  cp "$current_dir/$repo_path" "$system_path"
  echo -e "${GREEN}Applied: $repo_path → $system_path${NC}"
}

# Apply system file to repo
apply_to_repo() {
  local repo_path="$1"
  local system_path="$2"

  if [ $DRY_RUN -eq 1 ]; then
    echo -e "${YELLOW}[DRY-RUN] Would copy: $system_path → $repo_path${NC}"
    return
  fi

  ensure_backup_dir

  # Backup existing repo file
  if [ -f "$current_dir/$repo_path" ]; then
    local backup_path="$BACKUP_DIR/repo-$(basename "$repo_path")"
    cp "$current_dir/$repo_path" "$backup_path"
    echo -e "${CYAN}Backed up: $repo_path → $backup_path${NC}"
  fi

  # Copy system file to repo
  cp "$system_path" "$current_dir/$repo_path"
  echo -e "${GREEN}Pulled: $system_path → $repo_path${NC}"
}

# Open files in vimdiff for interactive editing
edit_interactive() {
  local repo_path="$1"
  local system_path="$2"

  if [ $DRY_RUN -eq 1 ]; then
    echo -e "${YELLOW}[DRY-RUN] Would open vimdiff${NC}"
    return
  fi

  # Use nvim if available, otherwise vim
  if command_exists nvim; then
    nvim -d "$current_dir/$repo_path" "$system_path"
  elif command_exists vim; then
    vim -d "$current_dir/$repo_path" "$system_path"
  else
    echo -e "${RED}Neither nvim nor vim found. Cannot open interactive editor.${NC}"
    return 1
  fi
}

# Review file differences hunk by hunk (git add -p style)
review_file_hunks() {
  local repo_path="$1"
  local system_path="$2"

  # Generate unified diff: system (old) → repo (new)
  # Red (-) lines = current system, Green (+) lines = repo version
  local diff_output
  diff_output=$(diff -u "$system_path" "$current_dir/$repo_path" 2>/dev/null) || true

  if [ -z "$diff_output" ]; then
    echo "No differences found."
    return
  fi

  # Split into header and hunks
  local diff_header=""
  local -a hunks=()
  local current_hunk=""
  local in_header=1

  while IFS= read -r line; do
    if [[ "$line" =~ ^@@ ]]; then
      if [ -n "$current_hunk" ]; then
        hunks+=("$current_hunk")
      fi
      current_hunk="$line"
      in_header=0
    elif [ $in_header -eq 1 ]; then
      diff_header+="$line"$'\n'
    else
      current_hunk+=$'\n'"$line"
    fi
  done <<< "$diff_output"

  # Save last hunk
  if [ -n "$current_hunk" ]; then
    hunks+=("$current_hunk")
  fi

  local total=${#hunks[@]}
  local -a selected_indices=()
  local apply_remaining=0
  local i=0

  echo -e "  ${YELLOW}$total hunk(s)${NC}"
  echo ""

  for hunk in "${hunks[@]}"; do
    i=$((i + 1))

    if [ $apply_remaining -eq 1 ]; then
      selected_indices+=($((i - 1)))
      continue
    fi

    # Check .syncignore patterns
    if hunk_matches_syncignore "$hunk"; then
      echo -e "${CYAN}($i/$total) Skipped — matches .syncignore pattern: ${BOLD}$MATCHED_PATTERN${NC}"
      continue
    fi

    # Display the hunk with colors
    while IFS= read -r line; do
      if [[ "$line" =~ ^@@ ]]; then
        echo -e "${CYAN}$line${NC}"
      elif [[ "$line" =~ ^\+ ]]; then
        echo -e "${GREEN}$line${NC}"
      elif [[ "$line" =~ ^- ]]; then
        echo -e "${RED}$line${NC}"
      else
        echo "$line"
      fi
    done <<< "$hunk"

    echo ""

    while true; do
      echo -ne "($i/$total) Apply this hunk? [y,n,a,d,r,e,q,?] "
      read -n 1 -r
      echo ""
      case "$REPLY" in
        y)
          selected_indices+=($((i - 1)))
          break
          ;;
        n)
          break
          ;;
        a)
          selected_indices+=($((i - 1)))
          apply_remaining=1
          break
          ;;
        d)
          break 2
          ;;
        r)
          apply_to_repo "$repo_path" "$system_path"
          return
          ;;
        e)
          edit_interactive "$repo_path" "$system_path"
          return
          ;;
        q)
          echo "Quitting."
          exit 0
          ;;
        '?')
          echo "y - apply this hunk to system (repo → system)"
          echo "n - skip this hunk"
          echo "a - apply this and all remaining hunks"
          echo "d - done with this file, skip remaining hunks"
          echo "r - reverse: copy entire system file to repo"
          echo "e - edit interactively in vimdiff"
          echo "q - quit sync"
          echo "? - show this help"
          ;;
        *)
          echo "Invalid choice. Press ? for help."
          ;;
      esac
    done
  done

  # Apply selected hunks
  if [ ${#selected_indices[@]} -eq 0 ]; then
    echo "No hunks selected, skipping."
    return
  fi

  if [ ${#selected_indices[@]} -eq $total ]; then
    # All hunks selected — just copy the whole file
    apply_to_system "$repo_path" "$system_path"
    return
  fi

  # Build partial patch from selected hunks
  local patch_content="$diff_header"
  for idx in "${selected_indices[@]}"; do
    patch_content+="${hunks[$idx]}"$'\n'
  done

  ensure_backup_dir
  if [ -f "$system_path" ]; then
    local backup_path="$BACKUP_DIR/$(basename "$system_path")"
    cp "$system_path" "$backup_path"
    echo -e "${CYAN}Backed up: $system_path → $backup_path${NC}"
  fi

  if printf '%s' "$patch_content" | patch --no-backup-if-mismatch -s "$system_path" 2>/dev/null; then
    echo -e "${GREEN}Applied ${#selected_indices[@]}/$total hunk(s) to $system_path${NC}"
  else
    echo -e "${RED}Patch failed to apply cleanly. Try using vimdiff [e] instead.${NC}"
  fi
}

# Main sync logic
main() {
  build_file_mappings
  load_syncignore

  echo -e "${BOLD}Dotfiles Sync${NC}"
  echo "Comparing ${#FILE_MAPPINGS[@]} file mappings..."
  echo ""

  # Arrays to store results
  declare -a modified_files=()
  declare -a missing_system=()
  declare -a missing_repo=()
  declare -a identical_files=()

  # Scan all files
  for mapping in "${FILE_MAPPINGS[@]}"; do
    local repo_path="${mapping%%:*}"
    local system_path="${mapping#*:}"
    local status
    status=$(compare_files "$repo_path" "$system_path")

    case "$status" in
      identical)
        identical_files+=("$mapping")
        ;;
      modified)
        modified_files+=("$mapping")
        ;;
      missing_system)
        missing_system+=("$mapping")
        ;;
      missing_repo)
        missing_repo+=("$mapping")
        ;;
    esac
  done

  # Print summary
  echo -e "${BOLD}Summary:${NC}"
  echo -e "  ${GREEN}✓${NC} Identical:      ${#identical_files[@]}"
  echo -e "  ${YELLOW}●${NC} Modified:       ${#modified_files[@]}"
  echo -e "  ${BLUE}+${NC} Only in repo:   ${#missing_system[@]}"
  echo -e "  ${CYAN}?${NC} Only on system: ${#missing_repo[@]}"
  echo ""

  # Show all files if requested
  if [ $SHOW_ALL -eq 1 ]; then
    echo -e "${BOLD}All files:${NC}"
    for mapping in "${FILE_MAPPINGS[@]}"; do
      local repo_path="${mapping%%:*}"
      local system_path="${mapping#*:}"
      local status
      status=$(compare_files "$repo_path" "$system_path")
      printf "  %-45s %s\n" "$repo_path" "$(print_status "$status")"
    done
    echo ""
  fi

  # Exit if nothing to review
  if [ ${#modified_files[@]} -eq 0 ] && [ ${#missing_system[@]} -eq 0 ] && [ ${#missing_repo[@]} -eq 0 ]; then
    echo -e "${GREEN}All files are in sync!${NC}"
    exit 0
  fi

  if [ $DRY_RUN -eq 1 ]; then
    echo -e "${YELLOW}[DRY-RUN MODE]${NC} No changes will be made."
    echo ""
  fi

  # Review modified files hunk by hunk
  if [ ${#modified_files[@]} -gt 0 ]; then
    for mapping in "${modified_files[@]}"; do
      local repo_path="${mapping%%:*}"
      local system_path="${mapping#*:}"

      echo ""
      echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${BOLD}File:${NC}   $repo_path"
      echo -e "${BOLD}System:${NC} $system_path"
      echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

      if [ $DRY_RUN -eq 1 ]; then
        show_diff "$repo_path" "$system_path"
        continue
      fi

      review_file_hunks "$repo_path" "$system_path"
    done
  fi

  # Review files only in repo
  if [ ${#missing_system[@]} -gt 0 ]; then
    echo ""
    echo -e "${BOLD}${BLUE}Files only in repo (not installed):${NC}"
    for mapping in "${missing_system[@]}"; do
      local repo_path="${mapping%%:*}"
      local system_path="${mapping#*:}"

      echo -e "  ${BLUE}$repo_path${NC} → $system_path"

      # In dry-run mode, just list without prompting
      if [ $DRY_RUN -eq 1 ]; then
        continue
      fi

      read -p "  Install to system? [y/N] " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_to_system "$repo_path" "$system_path"
      else
        echo "  Skipped."
      fi
    done
  fi

  # Review files only on system
  if [ ${#missing_repo[@]} -gt 0 ]; then
    echo ""
    echo -e "${BOLD}${CYAN}Files only on system (not in repo):${NC}"
    for mapping in "${missing_repo[@]}"; do
      local repo_path="${mapping%%:*}"
      local system_path="${mapping#*:}"

      echo -e "  ${CYAN}$system_path${NC} → $repo_path"

      # In dry-run mode, just list without prompting
      if [ $DRY_RUN -eq 1 ]; then
        continue
      fi

      read -p "  Add to repo? [y/N] " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_to_repo "$repo_path" "$system_path"
      else
        echo "  Skipped."
      fi
    done
  fi

  echo ""
  echo -e "${GREEN}Sync complete!${NC}"
  if [ $BACKUP_CREATED -eq 1 ]; then
    echo -e "Backups saved to: ${CYAN}$BACKUP_DIR${NC}"
  fi
}

main
