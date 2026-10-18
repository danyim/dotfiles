#!/bin/bash
#
# Install (or remove) the agent skills and the Obsidian note gate, without touching
# any other dotfile. Idempotent: safe to re-run any time, no prompts, no backups.
#
#   ./skills.sh              link skills, install the two bin scripts, link the Hermes plugin,
#                            sync the pointer block into CLAUDE.md / AGENTS.md
#   ./skills.sh --dry-run    print what would change, change nothing
#   ./skills.sh --uninstall  remove every link and bin script this script installed
#
# Called by load.sh, so there is exactly one implementation of the linking.

set -euo pipefail

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$current_dir/lib/helpers.sh"

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SKILL_NAME="obsidian-notes"
SKILL_SRC="$current_dir/skills/$SKILL_NAME"
SKILL_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.hermes/skills"
)
BIN_SCRIPTS=(obsidian-lint obsidian-guard)
CONTEXT_FILES=("$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md")
PLUGIN_SRC="$current_dir/hermes/plugins/obsidian-standard"
PLUGIN_DST="$HOME/.hermes/plugins/obsidian-standard"

run() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "  would: $*"; else "$@"; fi
}

remove_context_block() {
  local target="$1"
  python3 - "$target" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
if not p.exists():
    raise SystemExit
text = p.read_text()
new = re.sub(r"\n?<!-- BEGIN obsidian-standard -->.*?<!-- END obsidian-standard -->\n?", "\n", text, flags=re.S)
if new != text:
    p.write_text(new)
    print(f"  removed pointer block from {p}")
PY
}

if [ "$UNINSTALL" -eq 1 ]; then
  echo "Removing the skill links, binaries and pointer blocks..."
  for dir in "${SKILL_DIRS[@]}"; do
    if [ -L "$dir/$SKILL_NAME" ]; then run rm -f "$dir/$SKILL_NAME"; echo "  unlinked $dir/$SKILL_NAME"; fi
  done
  for script in "${BIN_SCRIPTS[@]}"; do
    if [ -f "$HOME/.local/bin/$script" ]; then run rm -f "$HOME/.local/bin/$script"; echo "  removed ~/.local/bin/$script"; fi
  done
  if [ -L "$PLUGIN_DST" ]; then run rm -f "$PLUGIN_DST"; echo "  unlinked $PLUGIN_DST"; fi
  for ctx in "${CONTEXT_FILES[@]}"; do
    if [ "$DRY_RUN" -eq 1 ]; then echo "  would remove pointer block from $ctx"; else remove_context_block "$ctx"; fi
  done
  echo "Done. The plugin stays registered in Hermes until you run: hermes plugins disable obsidian-standard"
  exit 0
fi

if [ ! -d "$SKILL_SRC" ]; then
  echo "missing skill source: $SKILL_SRC" >&2
  exit 1
fi

echo "Linking the $SKILL_NAME skill into every harness..."
for dir in "${SKILL_DIRS[@]}"; do
  run mkdir -p "$dir"
  run ln -sfn "$SKILL_SRC" "$dir/$SKILL_NAME"
  echo "  $dir/$SKILL_NAME -> $SKILL_SRC"
done

echo "Installing the linter and guard..."
run mkdir -p "$HOME/.local/bin"
for script in "${BIN_SCRIPTS[@]}"; do
  if [ -f "$current_dir/bin/$script" ]; then
    run cp "$current_dir/bin/$script" "$HOME/.local/bin/$script"
    run chmod +x "$HOME/.local/bin/$script"
    echo "  ~/.local/bin/$script"
  fi
done

if [ -d "$PLUGIN_SRC" ]; then
  echo "Linking the Hermes gate plugin..."
  run mkdir -p "$HOME/.hermes/plugins"
  run ln -sfn "$PLUGIN_SRC" "$PLUGIN_DST"
  echo "  $PLUGIN_DST -> $PLUGIN_SRC"
  if command_exists hermes; then
    enabled="$(hermes plugins list 2>/dev/null | grep -c "obsidian-standard .*enabled" || true)"
    if [ "${enabled:-0}" -eq 0 ]; then
      echo "  enable it once: hermes plugins enable obsidian-standard --no-allow-tool-override"
    fi
  fi
fi

sync_context_block() {
  # Replace the marked block in place, or append it if absent. Keeps the pointer text current
  # when the standard changes, without duplicating it on every run.
  python3 - "$1" "$current_dir/agent-context/obsidian-standard.md" <<'PY'
import pathlib, re, sys
target, snippet_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
snippet = snippet_path.read_text().strip()
text = target.read_text() if target.exists() else ""
block = re.compile(r"<!-- BEGIN obsidian-standard -->.*?<!-- END obsidian-standard -->", re.S)
if block.search(text):
    new = block.sub(lambda _: snippet, text, count=1)
    if new != text:
        target.write_text(new)
        print(f"  updated pointer block in {target}")
    else:
        print(f"  present in {target}")
elif snippet and snippet not in text:
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("a") as fh:
        fh.write(("\n" if text and not text.endswith("\n\n") else "") + snippet + "\n")
    print(f"  appended to {target}")
PY
}

echo "Syncing the pointer block into always-loaded context files..."
for ctx in "${CONTEXT_FILES[@]}"; do
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  would sync pointer block into $ctx"
  else
    sync_context_block "$ctx"
  fi
done

echo
echo "Verify with: obsidian-lint --new \"Test\" --folder . ; obsidian-lint <that path>"
