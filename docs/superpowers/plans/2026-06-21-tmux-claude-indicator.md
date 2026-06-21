# tmux-claude-indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the Claude Code activity indicator from the dotfiles into a standalone, shareable TPM plugin (`danyim/tmux-claude-indicator`), then migrate the dotfiles to consume it.

**Architecture:** A TPM plugin with two halves. The **tmux half** (`claude_indicator.tmux`, auto-sourced by TPM) defines the icon format option, sets per-state glyph defaults, and arms a window-focus dwell-clear via a guarded `set-hook -ga` append. The **Claude half** is wired once by an idempotent `install.sh` that merges four hooks into `~/.claude/settings.json`, keyed on a `# tmux-claude-indicator` marker comment for clean reinstall/uninstall. The dwell-clear decision is a pure shell predicate, kept separate from its tmux side effects so it is unit-testable.

**Tech Stack:** POSIX `sh` (helper/install scripts), bash (`.tmux` entry), tmux ≥ 3.2, `jq`, TPM.

## Global Constraints

- **Two repos.** Tasks 1–7 operate in the **new plugin repo** `/home/danyim/dev/tmux-claude-indicator`. Task 8 operates in the **dotfiles repo** `/home/danyim/dev/dotfiles`. Each task commits to its own repo.
- **Shells:** helper/install/uninstall scripts use `#!/bin/sh` (POSIX). `claude_indicator.tmux` uses `#!/usr/bin/env bash`.
- **No-emoji invariant:** no emoji literal may appear in any shell `case` pattern. Emoji appear only as plain string arguments to `tmux set`. Helper scripts only `case`/compare word states (`ready`, `working`, `waiting`).
- **Marker (exact):** every installed Claude hook command ends with ` # tmux-claude-indicator`.
- **Backup convention:** scripts that overwrite a file first copy it to `$HOME/.dotfiles.backup/<UTC-epoch>/`.
- **Dependency:** `jq` required by `install.sh`/`uninstall.sh`; fail with a clear message if absent.
- **tmux integration tests:** always run against an isolated server via `export TMUX_TMPDIR=$(mktemp -d)` + `tmux new-session -d`; `tmux kill-server` and remove the tmpdir at the end.
- **Plugin load line (consumers):** `set -g @plugin 'danyim/tmux-claude-indicator'`.
- **State → glyph:** `working`→🟡, `waiting`→🔴, `ready`→🟢, unset→empty. Each glyph value includes one trailing space.

---

### Task 1: Plugin repo scaffold + `helpers.sh` clear-decision predicate

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/scripts/helpers.sh`
- Create: `/home/danyim/dev/tmux-claude-indicator/.gitignore`
- Test: `/home/danyim/dev/tmux-claude-indicator/test/test-helpers.sh`

**Interfaces:**
- Produces: `claude_should_clear "$state" "$active" "$attached"` — a shell function returning exit status 0 (clear) only when `state = ready` AND `active = 1` AND `attached != 0`. Sourced by `tmux-mark-read` (Task 2) and the tests.

- [ ] **Step 1: Initialize the repo**

```bash
mkdir -p /home/danyim/dev/tmux-claude-indicator/scripts /home/danyim/dev/tmux-claude-indicator/test
cd /home/danyim/dev/tmux-claude-indicator
git init
printf '*.swp\n.DS_Store\n' > .gitignore
```

- [ ] **Step 2: Write the failing test**

Create `test/test-helpers.sh`:

```sh
#!/bin/sh
# Unit tests for the pure clear-decision predicate. No tmux involved.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/scripts/helpers.sh"

fail=0
expect_clear()   { if claude_should_clear "$1" "$2" "$3"; then echo "ok: clear $*"; else echo "FAIL: expected clear for $*"; fail=1; fi; }
expect_noclear() { if claude_should_clear "$1" "$2" "$3"; then echo "FAIL: expected no-clear for $*"; fail=1; else echo "ok: no-clear $*"; fi; }

expect_clear   ready 1 1
expect_noclear working 1 1
expect_noclear waiting 1 1
expect_noclear ready 0 1
expect_noclear ready 1 0
expect_noclear "" 1 1

[ "$fail" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-helpers.sh`
Expected: FAIL — `helpers.sh` does not exist / `claude_should_clear: not found`.

- [ ] **Step 4: Write the implementation**

Create `scripts/helpers.sh`:

```sh
# scripts/helpers.sh — shared, sourced by scripts and tests. No side effects.

# claude_should_clear STATE ACTIVE ATTACHED
# Pure decision: should a 🟢 (ready) badge be cleared, given the observed facts?
#   STATE    — the window's @claude_state value
#   ACTIVE   — tmux #{window_active} (1 if the window is the active one)
#   ATTACHED — tmux #{session_attached} (client count; "0" when detached)
# Returns exit 0 to clear, non-zero to leave the badge.
claude_should_clear() {
  [ "$1" = ready ] && [ "$2" = 1 ] && [ "$3" != 0 ]
}
```

- [ ] **Step 5: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-helpers.sh`
Expected: `ALL PASS`.

- [ ] **Step 6: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add scripts/helpers.sh test/test-helpers.sh .gitignore
git commit -m "Add clear-decision predicate and repo scaffold"
```

---

### Task 2: `tmux-mark-read` dwell-clear script

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/scripts/tmux-mark-read`
- Test: `/home/danyim/dev/tmux-claude-indicator/test/test-mark-read.sh`

**Interfaces:**
- Consumes: `claude_should_clear` from `scripts/helpers.sh`.
- Produces: `scripts/tmux-mark-read TARGET` — sleeps `${TMUX_READ_DELAY:-10}`s, then clears `@claude_state` on `TARGET` ("session:index" or pane id) only when `claude_should_clear` is satisfied. Referenced by `claude-on-focus` (Task 3) and the `Stop` hook (Task 5).

- [ ] **Step 1: Write the failing test**

Create `test/test-mark-read.sh`:

```sh
#!/bin/sh
# Integration test for the dwell-clear, against an isolated tmux server.
# A test server is always DETACHED, so the positive clear path is covered by
# the Task 1 predicate unit tests; here we verify the script wires tmux state
# into that predicate (detached -> guard prevents clear) and that the clear
# action itself works.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0

export TMUX_TMPDIR=$(mktemp -d)
tmux new-session -d -s t
W="t:1"

# Detached server: claude_should_clear must veto, badge stays.
tmux set -w -t "$W" @claude_state ready
TMUX_READ_DELAY=0 sh "$ROOT/scripts/tmux-mark-read" "$W"
[ "$(tmux show -wqv -t "$W" @claude_state)" = ready ] \
  && echo "ok: detached window keeps badge (guard honored)" \
  || { echo "FAIL: badge cleared while detached"; fail=1; }

# Not ready -> script must no-op (and not error).
tmux set -w -t "$W" @claude_state working
TMUX_READ_DELAY=0 sh "$ROOT/scripts/tmux-mark-read" "$W"
[ "$(tmux show -wqv -t "$W" @claude_state)" = working ] \
  && echo "ok: non-ready state untouched" \
  || { echo "FAIL: non-ready state changed"; fail=1; }

# The clear action itself unsets the option.
tmux set -wu -t "$W" @claude_state
[ -z "$(tmux show -wqv -t "$W" @claude_state)" ] \
  && echo "ok: unset clears state" \
  || { echo "FAIL: state not cleared by unset"; fail=1; }

tmux kill-server 2>/dev/null || true
rm -rf "$TMUX_TMPDIR"
[ "$fail" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-mark-read.sh`
Expected: FAIL — `scripts/tmux-mark-read` does not exist.

- [ ] **Step 3: Write the implementation**

Create `scripts/tmux-mark-read`:

```sh
#!/bin/sh
# Dwell-clear of a Claude "ready" (🟢) badge for tmux target $1.
# After a dwell, clears @claude_state only if the window is still ready AND
# still on screen (active + its session attached) — so a badge clears only
# once you have genuinely lingered, not while cycling past it.
# Dwell seconds default to 10; override with TMUX_READ_DELAY (used by tests).

T="$1"
[ -n "$T" ] || exit 0

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/helpers.sh"

sleep "${TMUX_READ_DELAY:-10}"

state=$(tmux show -wqv -t "$T" @claude_state 2>/dev/null)
active=$(tmux display-message -p -t "$T" '#{window_active}' 2>/dev/null)
attached=$(tmux display-message -p -t "$T" '#{session_attached}' 2>/dev/null)

claude_should_clear "$state" "$active" "$attached" || exit 0
tmux set -wu -t "$T" @claude_state 2>/dev/null
exit 0
```

Make it executable: `chmod +x /home/danyim/dev/tmux-claude-indicator/scripts/tmux-mark-read`

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-mark-read.sh`
Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add scripts/tmux-mark-read test/test-mark-read.sh
git commit -m "Add tmux-mark-read dwell-clear script"
```

---

### Task 3: `claude-on-focus` script

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/scripts/claude-on-focus`
- Test: `/home/danyim/dev/tmux-claude-indicator/test/test-on-focus.sh`

**Interfaces:**
- Consumes: `scripts/tmux-mark-read` (same dir).
- Produces: `scripts/claude-on-focus TARGET` — if `TARGET`'s `@claude_state` is `ready`, execs `tmux-mark-read TARGET` to arm the dwell-clear; otherwise no-ops. Referenced by the focus `set-hook` in Task 4.

- [ ] **Step 1: Write the failing test**

Create `test/test-on-focus.sh`:

```sh
#!/bin/sh
# claude-on-focus should arm the dwell-clear only for a ready window. We verify
# behavior via the observable outcome with TMUX_READ_DELAY=0 on a detached
# server: a ready window stays ready (guard vetoes the clear) and the script
# exits 0; a non-ready window is a fast no-op that also exits 0.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0

export TMUX_TMPDIR=$(mktemp -d)
tmux new-session -d -s t
W="t:1"

# Non-ready: must exit 0 and not touch state.
tmux set -w -t "$W" @claude_state working
TMUX_READ_DELAY=0 sh "$ROOT/scripts/claude-on-focus" "$W"
[ "$(tmux show -wqv -t "$W" @claude_state)" = working ] \
  && echo "ok: non-ready window untouched" || { echo FAIL; fail=1; }

# Ready: arms mark-read; on detached server the badge persists, script exits 0.
tmux set -w -t "$W" @claude_state ready
TMUX_READ_DELAY=0 sh "$ROOT/scripts/claude-on-focus" "$W"
[ "$(tmux show -wqv -t "$W" @claude_state)" = ready ] \
  && echo "ok: ready window armed without erroring" || { echo FAIL; fail=1; }

# Empty target: no-op, exit 0.
sh "$ROOT/scripts/claude-on-focus" "" && echo "ok: empty target no-ops" || { echo FAIL; fail=1; }

tmux kill-server 2>/dev/null || true
rm -rf "$TMUX_TMPDIR"
[ "$fail" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-on-focus.sh`
Expected: FAIL — `scripts/claude-on-focus` does not exist.

- [ ] **Step 3: Write the implementation**

Create `scripts/claude-on-focus`:

```sh
#!/bin/sh
# Invoked (backgrounded) by tmux's session-window-changed / client-session-changed
# hooks with the newly-focused window as $1 ("session:index"). If that window is
# already showing a Claude "ready" (🟢) badge, arm the dwell-clear so the badge
# clears once you've lingered. Fast tab-cycling passes through before the dwell
# elapses, leaving badges intact.

W="$1"
[ -n "$W" ] || exit 0

[ "$(tmux show -wqv -t "$W" @claude_state 2>/dev/null)" = ready ] || exit 0

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$DIR/tmux-mark-read" "$W"
```

Make it executable: `chmod +x /home/danyim/dev/tmux-claude-indicator/scripts/claude-on-focus`

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-on-focus.sh`
Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add scripts/claude-on-focus test/test-on-focus.sh
git commit -m "Add claude-on-focus dwell-clear arming script"
```

---

### Task 4: `claude_indicator.tmux` TPM entry

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/claude_indicator.tmux`
- Test: `/home/danyim/dev/tmux-claude-indicator/test/test-tmux-entry.sh`

**Interfaces:**
- Consumes: `scripts/claude-on-focus` (referenced by absolute path computed at load).
- Produces (tmux server state after sourcing): global options `@claude_icon_working/waiting/ready` (defaults, set only if unset), `@claude_state_icon` (the format), and one `claude-on-focus` entry on each of `session-window-changed` and `client-session-changed`. Idempotent across re-sourcing.

- [ ] **Step 1: Write the failing test**

Create `test/test-tmux-entry.sh`:

```sh
#!/bin/sh
# Sources the TPM entry against an isolated server and asserts the options,
# the rendered icon, the focus hooks, idempotency, and user overrides.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0

export TMUX_TMPDIR=$(mktemp -d)
tmux new-session -d -s t

sh "$ROOT/claude_indicator.tmux"

[ -n "$(tmux show -gqv @claude_state_icon)" ] \
  && echo "ok: @claude_state_icon defined" || { echo FAIL; fail=1; }
[ "$(tmux show -gqv @claude_icon_ready)" = "🟢 " ] \
  && echo "ok: ready glyph default" || { echo FAIL; fail=1; }

# End-to-end: a ready window renders the green glyph through the format.
tmux set -w -t t:1 @claude_state ready
[ "$(tmux display-message -p -t t:1 '#{E:@claude_state_icon}')" = "🟢 " ] \
  && echo "ok: ready window renders 🟢" || { echo FAIL; fail=1; }
tmux set -wu -t t:1 @claude_state
[ -z "$(tmux display-message -p -t t:1 '#{E:@claude_state_icon}')" ] \
  && echo "ok: unset window renders empty" || { echo FAIL; fail=1; }

c=$(tmux show-hooks -g | grep -c claude-on-focus || true)
[ "$c" = 2 ] && echo "ok: focus hooks armed on both events" || { echo "FAIL: got $c hooks"; fail=1; }

# Idempotent re-source: still exactly 2.
sh "$ROOT/claude_indicator.tmux"
c=$(tmux show-hooks -g | grep -c claude-on-focus || true)
[ "$c" = 2 ] && echo "ok: idempotent re-source" || { echo "FAIL: got $c hooks"; fail=1; }

# User override of a glyph is respected.
tmux kill-server 2>/dev/null || true
tmux new-session -d -s t
tmux set -g @claude_icon_ready 'R '
sh "$ROOT/claude_indicator.tmux"
[ "$(tmux show -gqv @claude_icon_ready)" = "R " ] \
  && echo "ok: user glyph override respected" || { echo FAIL; fail=1; }

tmux kill-server 2>/dev/null || true
rm -rf "$TMUX_TMPDIR"
[ "$fail" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-tmux-entry.sh`
Expected: FAIL — `claude_indicator.tmux` does not exist.

- [ ] **Step 3: Write the implementation**

Create `claude_indicator.tmux`:

```bash
#!/usr/bin/env bash
# TPM entry for tmux-claude-indicator. Sourced by TPM on tmux start.
# Defines the state->icon format, sets per-state glyph defaults (overridable),
# and arms the window-focus dwell-clear without clobbering existing hooks.
# NOTE: emoji appear only as string args to `tmux set` (never in case patterns),
# preserving compatibility with macOS bash 3.2.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"

# Per-state glyph defaults — only if the user hasn't set their own first.
[ -z "$(tmux show -gqv @claude_icon_working)" ] && tmux set -g @claude_icon_working '🟡 '
[ -z "$(tmux show -gqv @claude_icon_waiting)" ] && tmux set -g @claude_icon_waiting '🔴 '
[ -z "$(tmux show -gqv @claude_icon_ready)"   ] && tmux set -g @claude_icon_ready   '🟢 '

# State -> icon. Empty for windows with no @claude_state (non-Claude windows).
tmux set -g @claude_state_icon '#{?#{==:#{@claude_state},working},#{@claude_icon_working},#{?#{==:#{@claude_state},waiting},#{@claude_icon_waiting},#{?#{==:#{@claude_state},ready},#{@claude_icon_ready},}}}'

# Arm the dwell-clear on window focus. Append (-ga) so we compose with any
# existing focus hook (e.g. an MRU stamp); guard so re-sourcing adds at most once.
if ! tmux show-hooks -g 2>/dev/null | grep -q claude-on-focus; then
  for h in session-window-changed client-session-changed; do
    tmux set-hook -ga "$h" "run-shell -b \"$CURRENT_DIR/scripts/claude-on-focus #{session_name}:#{window_index}\""
  done
fi
```

Make it executable: `chmod +x /home/danyim/dev/tmux-claude-indicator/claude_indicator.tmux`

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-tmux-entry.sh`
Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add claude_indicator.tmux test/test-tmux-entry.sh
git commit -m "Add TPM entry: icon format, glyph defaults, focus hook"
```

---

### Task 5: `hooks.json` + `install.sh`

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/hooks.json`
- Create: `/home/danyim/dev/tmux-claude-indicator/install.sh`
- Test: `/home/danyim/dev/tmux-claude-indicator/test/test-install.sh`

**Interfaces:**
- Consumes: `hooks.json` (the four hook groups, with `__PLUGIN_DIR__` placeholder); `scripts/tmux-mark-read` path via substitution.
- Produces: `install.sh` — idempotently merges the four hooks into `$HOME/.claude/settings.json`, substituting `__PLUGIN_DIR__` with the plugin's absolute path, after backing the file up. Each event keeps exactly one marker-tagged group; unrelated hooks are preserved. The marker string is ` # tmux-claude-indicator`. Consumed by `uninstall.sh` (Task 6) and the dotfiles migration (Task 8).

- [ ] **Step 1: Write the failing test**

Create `test/test-install.sh`:

```sh
#!/bin/sh
# install.sh merge: fresh install, idempotency, unrelated-hook preservation.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0
check() { if [ "$1" = "$2" ]; then echo "ok: $3"; else echo "FAIL: $3 (got [$1] want [$2])"; fail=1; fi; }

TMPHOME=$(mktemp -d)
export HOME="$TMPHOME"
S="$HOME/.claude/settings.json"

# 1. Fresh install
sh "$ROOT/install.sh" >/dev/null
check "$(jq -r '.hooks | keys | join(",")' "$S")" "Notification,SessionEnd,Stop,UserPromptSubmit" "all 4 events present"
check "$(jq -r '.hooks.Stop[0].hooks[0].command | contains("'"$ROOT"'/scripts/tmux-mark-read")' "$S")" "true" "Stop references absolute plugin path"
check "$(jq '[.hooks[][].hooks[].command | select(contains("# tmux-claude-indicator"))] | length' "$S")" "4" "4 marker-tagged commands"

# 2. Idempotent re-run
sh "$ROOT/install.sh" >/dev/null
check "$(jq '.hooks.Stop | length' "$S")" "1" "Stop still one group after re-run"
check "$(jq '[.hooks[][].hooks[].command | select(contains("# tmux-claude-indicator"))] | length' "$S")" "4" "still 4 marker commands"

# 3. Preserve an unrelated hook on Stop
jq '.hooks.Stop += [{hooks:[{type:"command",command:"echo other"}]}]' "$S" > "$S.t" && mv "$S.t" "$S"
sh "$ROOT/install.sh" >/dev/null
check "$(jq '[.hooks.Stop[].hooks[].command | select(contains("echo other"))] | length' "$S")" "1" "unrelated Stop hook preserved"
check "$(jq '.hooks.Stop | length' "$S")" "2" "Stop has our group + unrelated"

# 4. A backup was written
check "$(ls "$HOME/.dotfiles.backup"/*/settings.json >/dev/null 2>&1 && echo yes)" "yes" "backup created"

rm -rf "$TMPHOME"
[ "$fail" = 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-install.sh`
Expected: FAIL — `install.sh` / `hooks.json` do not exist.

- [ ] **Step 3: Write `hooks.json`**

Create `hooks.json` (note ` # tmux-claude-indicator` at the end of every command, and `__PLUGIN_DIR__` in the `Stop` command):

```json
{
  "UserPromptSubmit": [
    { "hooks": [ { "type": "command", "command": "[ -n \"$TMUX_PANE\" ] && tmux set -w -t \"$TMUX_PANE\" @claude_state working || true # tmux-claude-indicator" } ] }
  ],
  "Stop": [
    { "hooks": [ { "type": "command", "command": "[ -n \"$TMUX_PANE\" ] && tmux set -w -t \"$TMUX_PANE\" @claude_state ready && tmux run-shell -b \"__PLUGIN_DIR__/scripts/tmux-mark-read $TMUX_PANE\" || true # tmux-claude-indicator" } ] }
  ],
  "Notification": [
    { "hooks": [ { "type": "command", "command": "input=$(cat); case \"$input\" in *\"waiting for your input\"*) ;; *) [ -n \"$TMUX_PANE\" ] && tmux set -w -t \"$TMUX_PANE\" @claude_state waiting ;; esac; true # tmux-claude-indicator" } ] }
  ],
  "SessionEnd": [
    { "hooks": [ { "type": "command", "command": "[ -n \"$TMUX_PANE\" ] && tmux set -wu -t \"$TMUX_PANE\" @claude_state || true # tmux-claude-indicator" } ] }
  ]
}
```

- [ ] **Step 4: Write `install.sh`**

Create `install.sh`:

```sh
#!/bin/sh
# Merge the tmux-claude-indicator Claude hooks into ~/.claude/settings.json.
# Idempotent: re-running replaces our (marker-tagged) entries, leaving any
# other hooks untouched. Backs up settings.json first.
set -eu

PLUGIN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SETTINGS="$HOME/.claude/settings.json"
MARKER="# tmux-claude-indicator"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }

mkdir -p "$HOME/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

BACKUP_DIR="$HOME/.dotfiles.backup/$(date -u +%s)"
mkdir -p "$BACKUP_DIR"
cp "$SETTINGS" "$BACKUP_DIR/settings.json"

# Our hook groups, with the real plugin path baked in.
NEW=$(sed "s#__PLUGIN_DIR__#$PLUGIN_DIR#g" "$PLUGIN_DIR/hooks.json")

tmp=$(mktemp)
jq --argjson new "$NEW" --arg marker "$MARKER" '
  def strip: map(select(any(.hooks[]?; .command | contains($marker)) | not));
  .hooks = (.hooks // {})
  | reduce ($new | keys_unsorted[]) as $ev (.;
      .hooks[$ev] = (((.hooks[$ev] // []) | strip) + $new[$ev]))
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Installed tmux-claude-indicator hooks into $SETTINGS"
echo "Backup: $BACKUP_DIR/settings.json"
```

- [ ] **Step 5: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-install.sh`
Expected: `ALL PASS`.

- [ ] **Step 6: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add hooks.json install.sh test/test-install.sh
git commit -m "Add hooks.json and idempotent install.sh"
```

---

### Task 6: `uninstall.sh`

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/uninstall.sh`
- Test: extend `/home/danyim/dev/tmux-claude-indicator/test/test-install.sh`

**Interfaces:**
- Produces: `uninstall.sh` — removes every marker-tagged hook group from all events in `$HOME/.claude/settings.json` (after a backup), drops any event left empty, and preserves unrelated hooks.

- [ ] **Step 1: Add the failing uninstall assertions**

Append to `test/test-install.sh`, immediately before the `rm -rf "$TMPHOME"` line:

```sh
# 5. Uninstall removes ours, keeps unrelated, drops emptied events
sh "$ROOT/uninstall.sh" >/dev/null
check "$(jq '[.hooks[]?[]?.hooks[]?.command // empty | select(contains("# tmux-claude-indicator"))] | length' "$S")" "0" "no marker commands after uninstall"
check "$(jq '[.hooks.Stop[].hooks[].command | select(contains("echo other"))] | length' "$S")" "1" "unrelated hook survives uninstall"
check "$(jq 'has("hooks") and (.hooks | has("UserPromptSubmit"))' "$S")" "false" "emptied event removed"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-install.sh`
Expected: FAIL — `uninstall.sh` does not exist.

- [ ] **Step 3: Write `uninstall.sh`**

Create `uninstall.sh`:

```sh
#!/bin/sh
# Remove the tmux-claude-indicator Claude hooks from ~/.claude/settings.json.
# Removes only our (marker-tagged) entries; other hooks are preserved.
set -eu

SETTINGS="$HOME/.claude/settings.json"
MARKER="# tmux-claude-indicator"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "nothing to do: $SETTINGS not found"; exit 0; }

BACKUP_DIR="$HOME/.dotfiles.backup/$(date -u +%s)"
mkdir -p "$BACKUP_DIR"
cp "$SETTINGS" "$BACKUP_DIR/settings.json"

tmp=$(mktemp)
jq --arg marker "$MARKER" '
  if .hooks then
    .hooks |= ( with_entries(.value |= map(select(any(.hooks[]?; .command | contains($marker)) | not)))
                | with_entries(select(.value | length > 0)) )
  else . end
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Removed tmux-claude-indicator hooks from $SETTINGS"
echo "Backup: $BACKUP_DIR/settings.json"
echo "tmux side: remove the @plugin line and run TPM uninstall (prefix + alt + u)."
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/test-install.sh`
Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add uninstall.sh test/test-install.sh
git commit -m "Add uninstall.sh and round-trip test"
```

---

### Task 7: README + test runner

**Files:**
- Create: `/home/danyim/dev/tmux-claude-indicator/README.md`
- Create: `/home/danyim/dev/tmux-claude-indicator/test/run.sh`

**Interfaces:**
- Produces: `test/run.sh` — runs every `test/test-*.sh` and exits non-zero if any fails. `README.md` — install/usage/config/uninstall docs.

- [ ] **Step 1: Write the test runner**

Create `test/run.sh`:

```sh
#!/bin/sh
# Run all plugin tests; non-zero exit if any fail.
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
rc=0
for t in "$DIR"/test-*.sh; do
  echo "== $t =="
  sh "$t" || rc=1
done
[ "$rc" = 0 ] && echo "=== ALL SUITES PASS ===" || echo "=== FAILURES ==="
exit "$rc"
```

- [ ] **Step 2: Run the whole suite**

Run: `sh /home/danyim/dev/tmux-claude-indicator/test/run.sh`
Expected: every suite prints `ALL PASS`, ending with `=== ALL SUITES PASS ===`.

- [ ] **Step 3: Write the README**

Create `README.md`:

````markdown
# tmux-claude-indicator

Shows, in your tmux window list, when a Claude Code session is 🟡 working,
🔴 waiting on you, or 🟢 finished (unreviewed). The 🟢 badge clears after you
linger on the window for ~10s.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'danyim/tmux-claude-indicator'
```

Then place the icon wherever you want it in your window-status format(s):

```tmux
setw -g window-status-format         '... #{E:@claude_state_icon}#I:#W ...'
setw -g window-status-current-format '... #{E:@claude_state_icon}#I:#W ...'
```

Reload tmux (`prefix + I` to fetch the plugin, then reload your config).

### Wire the Claude Code hooks (one-time)

The tmux half loads automatically. To make Claude set the state, run the
bundled installer once — it merges four hooks into `~/.claude/settings.json`
(idempotent, backs up first, preserves your other hooks):

```sh
~/.tmux/plugins/tmux-claude-indicator/install.sh
```

Requires `jq`.

## Configuration

Override any glyph in `~/.tmux.conf` **before** the `run '.../tpm'` line:

```tmux
set -g @claude_icon_working '⏳ '
set -g @claude_icon_waiting '❓ '
set -g @claude_icon_ready   '✅ '
```

(Keep the trailing space for alignment.)

## Uninstall

```sh
~/.tmux/plugins/tmux-claude-indicator/uninstall.sh   # removes the Claude hooks
```

Then remove the `@plugin` line and run TPM's uninstall (`prefix + alt + u`).

## Note for dotfiles that overwrite settings.json

If your dotfiles wholesale-overwrite `~/.claude/settings.json` (rather than
merge), run `install.sh` again afterward — it is idempotent.

## Tests

```sh
sh test/run.sh
```

Requires `tmux` and `jq`.
````

- [ ] **Step 4: Commit**

```bash
cd /home/danyim/dev/tmux-claude-indicator
git add README.md test/run.sh
git commit -m "Add README and test runner"
```

---

### Task 8: Migrate the dotfiles to consume the plugin

**Files (all in `/home/danyim/dev/dotfiles`):**
- Modify: `claude/settings.json` — remove the 4 `hooks` entries.
- Modify: `.tmux.conf` — remove the `@claude_state_icon` definition and the dwell-clear half of the focus hook; add the `@plugin` line; keep the placeholders + MRU.
- Modify: `bin/tmux-window-focus` — reduce to MRU-only.
- Delete: `bin/tmux-mark-read` (now in the plugin).
- Modify: `lib/mappings.sh` — remove the `bin/tmux-mark-read` mapping.
- Modify: `load.sh` — remove the `tmux-mark-read` copy block.

**Interfaces:**
- Consumes: the published/clonable plugin from Task 7.

- [ ] **Step 1: Remove the four hooks from the tracked settings.json**

In `/home/danyim/dev/dotfiles/claude/settings.json`, delete the entire top-level `"hooks": { ... }` object (the `UserPromptSubmit`, `Stop`, `Notification`, `SessionEnd` block, lines ~201–242). Verify it still parses:

Run: `jq -e . /home/danyim/dev/dotfiles/claude/settings.json >/dev/null && echo OK`
Expected: `OK`, and `jq '.hooks' claude/settings.json` prints `null`.

- [ ] **Step 2: Reduce `bin/tmux-window-focus` to MRU-only**

Replace the body of `/home/danyim/dev/dotfiles/bin/tmux-window-focus` with:

```sh
#!/bin/sh
# Invoked (backgrounded) by tmux's session-window-changed / client-session-changed
# hooks with the newly-focused window as $1 ("session:index"). Stamps @last_access
# so tmux-jump (Cmd+P) can order windows most-recently-used first.
# (The Claude "ready" dwell-clear that used to live here now ships in the
# tmux-claude-indicator plugin as claude-on-focus.)

W="$1"
[ -n "$W" ] || exit 0
tmux set -w -t "$W" @last_access "$(date +%s)" 2>/dev/null
```

- [ ] **Step 3: Delete the moved script and its mapping/copy**

```bash
cd /home/danyim/dev/dotfiles
git rm bin/tmux-mark-read
```

In `lib/mappings.sh`, delete the line:
`FILE_MAPPINGS+=("bin/tmux-mark-read:$HOME/.local/bin/tmux-mark-read")`

In `load.sh`, delete the `if [ -f bin/tmux-mark-read ]; then ... fi` block (the three-line copy + chmod for `tmux-mark-read`).

- [ ] **Step 4: Update `.tmux.conf`**

In `/home/danyim/dev/dotfiles/.tmux.conf`:

a. **Delete** the `@claude_state_icon` definition (the `set -g @claude_state_icon '...'` line and its preceding comment block, ~lines 72–77). The plugin now defines it.

b. **Replace** the two focus-hook lines (the `set-hook -g session-window-changed ...` and `set-hook -g client-session-changed ...` near the bottom) so they call the now-MRU-only script but keep the same names:

```tmux
# MRU window tracking. The Claude "ready" dwell-clear is provided by the
# tmux-claude-indicator plugin (it appends its own claude-on-focus handler).
set-hook -g session-window-changed 'run-shell -b "~/.local/bin/tmux-window-focus #{session_name}:#{window_index}"'
set-hook -g client-session-changed 'run-shell -b "~/.local/bin/tmux-window-focus #{session_name}:#{window_index}"'
```

c. **Add** the plugin to the `@plugin` list (near the other `set -g @plugin` lines at the top):

```tmux
set -g @plugin 'danyim/tmux-claude-indicator'
```

d. **Keep** the `#{E:@claude_state_icon}` references in `window-status-format` / `window-status-current-format` exactly as they are.

- [ ] **Step 5: Verify the migration locally**

```bash
# Scripts still parse:
sh -n /home/danyim/dev/dotfiles/bin/tmux-window-focus && echo "focus OK"
# settings.json has no hooks:
jq '.hooks' /home/danyim/dev/dotfiles/claude/settings.json   # -> null
# No stray references to the moved script remain:
grep -rn "tmux-mark-read" /home/danyim/dev/dotfiles --exclude-dir=.git --exclude-dir=docs || echo "no references"
```

Expected: `focus OK`, `null`, and `no references`.

- [ ] **Step 6: Live smoke test (manual)**

Install the plugin locally so tmux can load it (until it is pushed to GitHub, clone or symlink it into TPM's dir):

```bash
ln -s /home/danyim/dev/tmux-claude-indicator ~/.tmux/plugins/tmux-claude-indicator
cp /home/danyim/dev/dotfiles/.tmux.conf ~/.tmux.conf
cp /home/danyim/dev/dotfiles/bin/tmux-window-focus ~/.local/bin/tmux-window-focus
chmod +x ~/.local/bin/tmux-window-focus
cp /home/danyim/dev/dotfiles/claude/settings.json ~/.claude/settings.json
/home/danyim/dev/tmux-claude-indicator/install.sh
tmux source-file ~/.tmux.conf
```

Then, in a tmux window, run a Claude prompt and confirm: 🟡 appears while working, 🟢 when it finishes, 🟢 clears after ~10s dwell, and a non-Claude window shows no icon. Confirm MRU ordering still works in the `Cmd+P` (`M-p`) switcher.

- [ ] **Step 7: Commit the dotfiles migration**

```bash
cd /home/danyim/dev/dotfiles
git add claude/settings.json .tmux.conf bin/tmux-window-focus lib/mappings.sh load.sh
git commit -m "Migrate Claude tmux indicator to tmux-claude-indicator plugin"
```

---

### Task 9: Publish the plugin repo (with the user)

**Files:** none (remote operation).

- [ ] **Step 1: Create the GitHub repo and push**

> Outward-facing — do this only with the user's explicit go-ahead.

```bash
cd /home/danyim/dev/tmux-claude-indicator
gh repo create danyim/tmux-claude-indicator --public --source=. --remote=origin --description "tmux indicator for Claude Code activity (working/waiting/ready)"
git push -u origin HEAD
```

- [ ] **Step 2: Confirm a clean TPM install**

Remove the local symlink from Task 8 Step 6, let TPM fetch the real repo (`prefix + I`), reload tmux, and re-run the live smoke test from Task 8 Step 6.

---

## Self-Review

**Spec coverage:**
- TPM plugin layout / two halves → Tasks 1–7. ✓
- `@claude_state_icon` format + per-glyph overrides → Task 4. ✓
- Guarded focus-hook composition (`set-hook -ga`) → Task 4 (test asserts idempotent "2 hooks"). ✓
- Focus untangle (plugin `claude-on-focus` vs dotfiles MRU-only `tmux-window-focus`) → Tasks 3 & 8. ✓
- `tmux-mark-read` with active+attached guards, `TMUX_READ_DELAY` → Tasks 1–2. ✓
- `hooks.json` source of truth, `__PLUGIN_DIR__` substitution, marker, idempotent merge, backup → Task 5. ✓
- Uninstall by marker, preserve unrelated, drop empties → Task 6. ✓
- Documented-placeholder status line, install ordering note, config → Task 7 (README). ✓
- Dotfiles migration table (settings.json, .tmux.conf, bin/, mappings.sh, load.sh) → Task 8. ✓
- Dependencies (jq, tmux ≥ 3.2), no-emoji invariant → Global Constraints; enforced in Task 4 (string-arg glyphs) and Task 5 (jq). ✓
- Plain-sh tests for install merge + dwell-clear → Tasks 1, 2, 5, 6; plus entry/focus coverage in 3, 4. ✓
- Standalone repo `danyim/tmux-claude-indicator` → Tasks 1 & 9. ✓

**Placeholder scan:** No TBD/TODO. `__PLUGIN_DIR__` is an intentional substitution token (defined and exercised in Task 5). All code steps show full content.

**Type/name consistency:** `claude_should_clear` (Tasks 1→2), `scripts/tmux-mark-read` (Tasks 2→3, 5), `scripts/claude-on-focus` (Tasks 3→4), marker `# tmux-claude-indicator` (Tasks 5→6→8), option names `@claude_state` / `@claude_state_icon` / `@claude_icon_{working,waiting,ready}` consistent across Tasks 4, 5, 8, README. ✓
