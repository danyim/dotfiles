#!/bin/bash
# Interactive restore for dotfiles backups.
#
# sync.sh (and load.sh) save a copy of any file they overwrite into
#   ~/.dotfiles.backup/<UTC epoch>/
# This script lists every backed-up file across all those snapshots, lets you
# filter by typing a substring (fzf if available, otherwise a numbered menu),
# and restores the one(s) you pick back to their original location. The file
# currently on disk is itself backed up first, so a restore is reversible.

set -euo pipefail

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"
source "$current_dir/lib/mappings.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BACKUP_ROOT="$HOME/.dotfiles.backup"
DRY_RUN=0
NO_FZF=0

usage() {
  cat <<EOF
restore.sh - interactively restore dotfiles from a backup snapshot

Usage: ./restore.sh [options]

Options:
  -n, --dry-run    Show what would be restored without writing anything
      --no-fzf     Force the plain numbered menu even if fzf is installed
  -h, --help       Show this help

Backups are read from: $BACKUP_ROOT/<UTC epoch>/

Workflow:
  1. Pick a backed-up file (type any substring to filter the list).
  2. Confirm the source snapshot and restore destination.
  3. The current file is backed up, then the chosen version is restored.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    --no-fzf) NO_FZF=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo -e "${RED}Unknown option: $1${NC}" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# ---- Build reverse lookup: backup file name -> restore destination ----------
# sync.sh names backups by the repo path with slashes turned into dashes:
#   system-side backup:  "${repo_path//\//-}"        -> restore to system_path
#   repo-side backup:    "repo-${repo_path//\//-}"   -> restore to repo file
# load.sh uses the original basename / subdir, which equals the dashed key once
# its own slashes are flattened, so the same table covers both.
declare -A DEST_BY_KEY=()       # dashed-key -> system destination
declare -A REPO_DEST_BY_KEY=()  # dashed-key -> repo destination
build_file_mappings
for mapping in "${FILE_MAPPINGS[@]}"; do
  repo_path="${mapping%%:*}"
  system_path="${mapping#*:}"
  key="${repo_path//\//-}"
  DEST_BY_KEY["$key"]="$system_path"
  REPO_DEST_BY_KEY["$key"]="$current_dir/$repo_path"
done

# Resolve a backup file (relative path within a snapshot) to its destination.
# Prints the destination path, or nothing if it can't be mapped.
resolve_dest() {
  local rel="$1"
  local key="${rel//\//-}"
  if [[ "$key" == repo-* ]]; then
    local repo_key="${key#repo-}"
    [ -n "${REPO_DEST_BY_KEY[$repo_key]:-}" ] && echo "${REPO_DEST_BY_KEY[$repo_key]}"
  else
    [ -n "${DEST_BY_KEY[$key]:-}" ] && echo "${DEST_BY_KEY[$key]}"
  fi
}

# Human-readable timestamp from a UTC epoch snapshot dir name.
fmt_epoch() {
  local epoch="$1"
  if date -r "$epoch" '+%Y-%m-%d %H:%M' > /dev/null 2>&1; then
    date -r "$epoch" '+%Y-%m-%d %H:%M'   # BSD/macOS date
  elif date -d "@$epoch" '+%Y-%m-%d %H:%M' > /dev/null 2>&1; then
    date -d "@$epoch" '+%Y-%m-%d %H:%M'  # GNU date
  else
    echo "$epoch"
  fi
}

# ---- Gather every backed-up file across all snapshots -----------------------
# Each row is TAB-separated: epoch \t when \t relpath \t dest \t fullpath
declare -a ROWS=()
if [ ! -d "$BACKUP_ROOT" ]; then
  echo -e "${YELLOW}No backups found — $BACKUP_ROOT does not exist.${NC}"
  exit 0
fi

# Newest snapshots first.
while IFS= read -r snap; do
  epoch="$(basename "$snap")"
  when="$(fmt_epoch "$epoch")"
  while IFS= read -r -d '' f; do
    rel="${f#"$snap"/}"
    dest="$(resolve_dest "$rel")"
    [ -n "$dest" ] || dest="(unknown — choose destination at restore)"
    ROWS+=("$(printf '%s\t%s\t%s\t%s\t%s' "$epoch" "$when" "$rel" "$dest" "$f")")
  done < <(find "$snap" -type f -print0 | sort -z)
done < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort -r)

if [ ${#ROWS[@]} -eq 0 ]; then
  echo -e "${YELLOW}No backed-up files found under $BACKUP_ROOT.${NC}"
  exit 0
fi

# ---- Pretty display line for a row ------------------------------------------
display_line() {
  # epoch \t when \t rel \t dest \t full
  local when rel dest
  when="$(printf '%s' "$1" | cut -f2)"
  rel="$(printf '%s' "$1" | cut -f3)"
  dest="$(printf '%s' "$1" | cut -f4)"
  printf '%s  %-28s  →  %s' "$when" "$rel" "${dest/#$HOME/~}"
}

# ---- Selection: fzf if available, else a numbered substring menu ------------
declare -a SELECTED=()

select_with_fzf() {
  local menu choice
  menu="$(
    for i in "${!ROWS[@]}"; do
      printf '%s\t%s\n' "$i" "$(display_line "${ROWS[$i]}")"
    done
  )"
  # --with-nth hides the leading index column; we read it back from the choice.
  choice="$(printf '%s\n' "$menu" | fzf \
    --multi \
    --with-nth=2.. \
    --delimiter='\t' \
    --prompt='restore> ' \
    --header='Type to filter · TAB to multi-select · ENTER to restore · ESC to cancel' \
    --height=80% --reverse)" || return 1
  [ -n "$choice" ] || return 1
  while IFS= read -r line; do
    SELECTED+=("${line%%$'\t'*}")
  done <<< "$choice"
}

select_with_menu() {
  local filter="" idx
  while true; do
    echo ""
    echo -e "${BOLD}Dotfiles backups${NC} (${#ROWS[@]} files)"
    [ -n "$filter" ] && echo -e "Filter: ${CYAN}$filter${NC}  (blank to clear)"
    echo ""
    local -a shown=()
    local n=0
    for i in "${!ROWS[@]}"; do
      local line; line="$(display_line "${ROWS[$i]}")"
      if [ -z "$filter" ] || [[ "$line" == *"$filter"* ]]; then
        n=$((n + 1))
        shown+=("$i")
        printf '  %2d) %s\n' "$n" "$line"
      fi
    done
    [ "$n" -eq 0 ] && echo -e "  ${YELLOW}(no matches)${NC}"
    echo ""
    read -r -p "Number to restore, /text to filter, or q to quit: " input
    case "$input" in
      q|Q|"") return 1 ;;
      /*) filter="${input#/}" ;;
      *[!0-9]*|"") echo -e "${YELLOW}Enter a number, /filter, or q.${NC}" ;;
      *)
        if [ "$input" -ge 1 ] && [ "$input" -le "$n" ]; then
          SELECTED+=("${shown[$((input - 1))]}")
          return 0
        fi
        echo -e "${YELLOW}Out of range.${NC}"
        ;;
    esac
  done
}

if [ "$NO_FZF" -eq 0 ] && command_exists fzf; then
  select_with_fzf || { echo "Cancelled."; exit 0; }
else
  select_with_menu || { echo "Cancelled."; exit 0; }
fi

[ ${#SELECTED[@]} -gt 0 ] || { echo "Nothing selected."; exit 0; }

# ---- Restore each selected file ---------------------------------------------
# Back up whatever is currently on disk into a fresh snapshot before clobbering,
# so this restore can itself be undone.
restore_backup_dir="$BACKUP_ROOT/$(date -u +%s)"
pre_backup_made=0

restored=0
for i in "${SELECTED[@]}"; do
  row="${ROWS[$i]}"
  when="$(printf '%s' "$row" | cut -f2)"
  rel="$(printf '%s' "$row" | cut -f3)"
  dest="$(printf '%s' "$row" | cut -f4)"
  full="$(printf '%s' "$row" | cut -f5)"

  echo ""
  echo -e "${BOLD}Restore:${NC} $rel  ${CYAN}($when)${NC}"

  if [[ "$dest" == "(unknown"* ]]; then
    echo -e "  ${YELLOW}Destination unknown for this file.${NC}"
    read -r -p "  Enter full destination path (blank to skip): " dest
    dest="${dest/#\~/$HOME}"
    [ -n "$dest" ] || { echo "  Skipped."; continue; }
  fi

  echo -e "  from: ${full/#$HOME/~}"
  echo -e "  to:   ${dest/#$HOME/~}"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${YELLOW}[dry-run] would restore${NC}"
    continue
  fi

  read -r -p "  Proceed? [y/N] " -n 1 reply; echo ""
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "  Skipped."; continue; }

  # Back up the current file (if any) before overwriting it.
  if [ -e "$dest" ]; then
    [ "$pre_backup_made" -eq 0 ] && { mkdir -p "$restore_backup_dir"; pre_backup_made=1; }
    cp "$dest" "$restore_backup_dir/${rel//\//-}"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$full" "$dest"
  echo -e "  ${GREEN}Restored.${NC}"
  restored=$((restored + 1))
done

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
  echo -e "${YELLOW}Dry-run complete — no files changed.${NC}"
else
  echo -e "${GREEN}Done — restored $restored file(s).${NC}"
  [ "$pre_backup_made" -eq 1 ] && \
    echo -e "Previous versions backed up to: ${CYAN}${restore_backup_dir/#$HOME/~}${NC}"
fi
