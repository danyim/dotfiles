# tmux-claude-indicator — Design Spec

**Date:** 2026-06-21
**Status:** Approved (pending implementation plan)
**Repo to create:** `danyim/tmux-claude-indicator` (standalone TPM plugin)

## Summary

Extract the existing "Claude Code activity indicator" — currently woven into the
dotfiles (`claude/settings.json` hooks, `.tmux.conf`, and `bin/` scripts) — into a
standalone, shareable **TPM (tmux plugin manager) plugin**.

The plugin owns **only** the Claude activity indicator. The MRU window tracking
(`@last_access`) and the `tmux-jump` fuzzy switcher stay in the dotfiles.

The plugin has two halves:

- **tmux half** — auto-loaded by TPM on every tmux start. Defines the icon
  format option, installs a focus hook that arms the dwell-clear, and ships the
  `tmux-mark-read` dwell-clear script.
- **Claude half** — wired once by an explicit, idempotent `install.sh` that
  merges four hooks into `~/.claude/settings.json`.

### Goals

- Single-purpose, idiomatic TPM plugin, installable by anyone via
  `set -g @plugin 'danyim/tmux-claude-indicator'`.
- Explicit, reversible, idempotent installation of the Claude hooks.
- No regression in the current behavior on the author's machines.
- Configurable glyphs (per-state icon overrides).

### Non-goals

- Packaging the MRU switcher (`tmux-jump`) or `@last_access` tracking — these stay
  in dotfiles.
- Making `load.sh` merge (rather than overwrite) `~/.claude/settings.json` — noted
  as a future option, out of scope here.
- Auto-injecting the icon into arbitrary status-line formats — we use the
  documented-placeholder convention instead.

## Background — the current system

The behavior being extracted (unchanged in spirit by this work):

- **Claude hooks** (`claude/settings.json`) set a per-window tmux option
  `@claude_state` on `$TMUX_PANE`:
  - `UserPromptSubmit` → `working`
  - `Stop` → `ready` **and** arms a dwell-clear of the badge
  - `Notification` → `waiting` (but **skips** the `"waiting for your input"` idle nudge)
  - `SessionEnd` → unsets `@claude_state`
- **tmux** (`.tmux.conf`) maps `@claude_state` → an emoji via the `@claude_state_icon`
  format (🟡 working / 🔴 waiting / 🟢 ready / empty otherwise), referenced from the
  window-status formats via `#{E:@claude_state_icon}`.
- **Focus hooks** (`session-window-changed`, `client-session-changed`) run
  `tmux-window-focus`, which (1) stamps `@last_access` for MRU ordering and (2)
  arms `tmux-mark-read` if the focused window is already 🟢.
- **`tmux-mark-read`** clears a 🟢 badge after a 10s dwell, but only if the window
  is still `ready` **and** still on screen (`window_active` + `session_attached`).

### Invariant to preserve

No emoji literal may appear in a shell-script **`case` pattern** — macOS's bash 3.2
mis-parses multibyte literals there. Emoji live only in tmux option **values**
(passed as plain string arguments, which is safe even under bash 3.2). The plugin's
helper scripts only ever `case`-match word states (`ready`, `working`, `waiting`),
never emoji.

## Architecture

### Repo layout

```
tmux-claude-indicator/
├── claude_indicator.tmux     # TPM entry — sourced on every tmux start
├── scripts/
│   ├── helpers.sh            # shared sh helpers (resolve dir; get/set tmux opts)
│   ├── claude-on-focus       # arms dwell-clear when focusing an already-🟢 window
│   └── tmux-mark-read        # the 10s dwell-clear (logic unchanged)
├── hooks.json                # canonical definition of the 4 Claude hooks
├── install.sh                # idempotent jq merge of hooks → ~/.claude/settings.json
├── uninstall.sh              # removes them, restores
├── test/
│   ├── test-install.sh       # install/idempotency/uninstall/merge-preservation
│   └── test-mark-read.sh     # dwell-clear behavior (TMUX_READ_DELAY=0)
└── README.md
```

## Component design

### 1. tmux entry — `claude_indicator.tmux`

Runs once when TPM sources it. Responsibilities:

1. **Resolve its own dir** (`CURRENT_DIR`) so scripts are referenced by absolute
   path — no dependency on `~/.local/bin` or `PATH`.

2. **Glyph defaults (configurable), set only if unset** so a user can override them
   in `.tmux.conf` before TPM loads:

   ```sh
   [ -z "$(tmux show -gqv @claude_icon_working)" ] && tmux set -g @claude_icon_working '🟡 '
   [ -z "$(tmux show -gqv @claude_icon_waiting)" ] && tmux set -g @claude_icon_waiting '🔴 '
   [ -z "$(tmux show -gqv @claude_icon_ready)"   ] && tmux set -g @claude_icon_ready   '🟢 '
   ```

   The trailing space is part of each glyph value, keeping the format clean and
   preserving column alignment.

3. **Define the icon format**, referencing the per-state options:

   ```
   set -g @claude_state_icon '#{?#{==:#{@claude_state},working},#{@claude_icon_working},#{?#{==:#{@claude_state},waiting},#{@claude_icon_waiting},#{?#{==:#{@claude_state},ready},#{@claude_icon_ready},}}}'
   ```

   Renders empty for non-Claude windows (no `@claude_state` set).

4. **Install the focus hook by composing, not clobbering.** The two focus hooks are
   added together as a pair, behind a single reload-safe guard so they are added at
   most once. The guard greps **all** global hooks (no per-hook-name argument, which
   is not portable across tmux versions) for our script name:

   ```sh
   if ! tmux show-hooks -g 2>/dev/null | grep -q claude-on-focus; then
     for h in session-window-changed client-session-changed; do
       tmux set-hook -ga "$h" \
         'run-shell -b "'"$CURRENT_DIR"'/scripts/claude-on-focus #{session_name}:#{window_index}"'
     done
   fi
   ```

   `$CURRENT_DIR` is expanded by the shell when the `.tmux` entry runs, so the hook
   stores an absolute path.

The entry does **not** touch the status-line format. Users add the placeholder
themselves (see README convention below).

### 2. The focus untangle

The old `tmux-window-focus` did two jobs; they split by owner:

| Job | New owner | Script |
| --- | --- | --- |
| Stamp `@last_access` (MRU) | dotfiles | `bin/tmux-window-focus` (MRU-only after migration) |
| Arm dwell-clear on a 🟢 window | plugin | `scripts/claude-on-focus` |

Both hang off the same two focus hooks and coexist because:

- Dotfiles `.tmux.conf` uses `set-hook -g` (overwrite) at the top — establishes the
  MRU base.
- The plugin uses guarded `set-hook -ga` (append) when TPM loads at the bottom.

On `prefix r` reload, `.tmux.conf` re-runs first (overwrite resets to MRU-only),
then TPM re-sources the plugin (single guarded append) — so no duplication. For a
stranger with no MRU hook at all, the guarded append simply creates the hook. The
guard makes both paths safe.

`claude-on-focus "$session:$window"`:

```sh
W="$1"; [ -n "$W" ] || exit 0
[ "$(tmux show -wqv -t "$W" @claude_state 2>/dev/null)" = ready ] || exit 0
exec "$(dirname "$0")/tmux-mark-read" "$W"
```

### 3. `tmux-mark-read` (moved verbatim, logic unchanged)

Dwell-clear of a 🟢 badge for window target `$1`:

```sh
T="$1"; [ -n "$T" ] || exit 0
sleep "${TMUX_READ_DELAY:-10}"
[ "$(tmux show -wqv -t "$T" @claude_state 2>/dev/null)" = ready ] || exit 0
[ "$(tmux display-message -p -t "$T" '#{window_active}' 2>/dev/null)" = 1 ] || exit 0
[ "$(tmux display-message -p -t "$T" '#{session_attached}' 2>/dev/null)" != 0 ] || exit 0
tmux set -wu -t "$T" @claude_state 2>/dev/null
```

Armed from two places: `claude-on-focus` (focusing an already-🟢 window) and the
Claude `Stop` hook (covers "it went 🟢 while I was already looking at it").
`TMUX_READ_DELAY` is overridable for tests.

### 4. Claude hooks — `hooks.json` + `install.sh` + `uninstall.sh`

`hooks.json` is the canonical definition of all four hooks. The `Stop` hook
references `__PLUGIN_DIR__/scripts/tmux-mark-read`, a placeholder substituted at
install time. **Every installed command ends with a trailing `# tmux-claude-indicator`
comment** — a harmless, unambiguous marker used to find our entries for
idempotent reinstall and uninstall.

Hook commands (functionally identical to today, marker appended):

- `UserPromptSubmit`:
  `[ -n "$TMUX_PANE" ] && tmux set -w -t "$TMUX_PANE" @claude_state working || true # tmux-claude-indicator`
- `Stop`:
  `[ -n "$TMUX_PANE" ] && tmux set -w -t "$TMUX_PANE" @claude_state ready && tmux run-shell -b "__PLUGIN_DIR__/scripts/tmux-mark-read $TMUX_PANE" || true # tmux-claude-indicator`
- `Notification`:
  `input=$(cat); case "$input" in *"waiting for your input"*) ;; *) [ -n "$TMUX_PANE" ] && tmux set -w -t "$TMUX_PANE" @claude_state waiting ;; esac; true # tmux-claude-indicator`
- `SessionEnd`:
  `[ -n "$TMUX_PANE" ] && tmux set -wu -t "$TMUX_PANE" @claude_state || true # tmux-claude-indicator`

`install.sh`:

1. Require `jq`; resolve `PLUGIN_DIR` from the script's own location.
2. Target `~/.claude/settings.json`; if missing, start from `{}`.
3. Back up the existing file to `~/.dotfiles.backup/<UTC-epoch>/settings.json`
   (reusing the dotfiles backup convention).
4. Substitute `__PLUGIN_DIR__` → absolute `PLUGIN_DIR` in the hook commands.
5. **Idempotent merge**, per event: drop any existing hook entry whose command
   carries the `# tmux-claude-indicator` marker, then append the fresh entry.
   Entries belonging to other tools are preserved. Re-running is a clean upgrade,
   never a duplicate.
6. Print a summary of what changed.

`uninstall.sh`: filter out every marker-tagged hook entry across all four events,
write back (after a backup), and remind the user to remove the `@plugin` line
and/or run TPM's uninstall (`prefix + alt + u`) for the tmux half.

Because both install and uninstall key on the same marker, install / upgrade /
uninstall are all the same "filter out ours, then optionally add fresh" operation.

## Status-line integration (convention)

The plugin defines `@claude_state_icon` but never edits the user's status format.
README instructs users to place the placeholder where they want the icon, e.g.:

```tmux
setw -g window-status-format         '... #{E:@claude_state_icon}#I:#W ...'
setw -g window-status-current-format '... #{E:@claude_state_icon}#I:#W ...'
```

The author's dotfiles already have this placed, so nothing changes there.

## Dotfiles migration

Extracting the plugin requires the dotfiles to stop owning the indicator bits:

| File | Change |
| --- | --- |
| `claude/settings.json` | Remove the 4 hooks (plugin owns them now). |
| `.tmux.conf` | Remove the `@claude_state_icon` definition and the dwell-clear half of the focus hook. **Keep** the `#{E:@claude_state_icon}` placeholders, the MRU `@last_access` hook, and `tmux-jump`. Add `set -g @plugin 'danyim/tmux-claude-indicator'`. |
| `bin/tmux-window-focus` | Drop the dwell-clear half; becomes MRU-only. |
| `bin/tmux-mark-read` | Delete (moved into the plugin). |
| `lib/mappings.sh` | Remove the `bin/tmux-mark-read` mapping. |
| `load.sh` | Remove the `tmux-mark-read` copy block. |

### `load.sh` / `settings.json` interaction (documented, not fixed here)

`load.sh` wholesale-overwrites `~/.claude/settings.json`. So on any machine the
order is:

1. `load.sh` writes the hookless `settings.json`.
2. Run the plugin's `install.sh` to merge the hooks back.

Re-running `load.sh` later wipes the hooks, so re-run `install.sh` — safe because
it is idempotent. This ordering is documented in both READMEs. (A future
enhancement could make `load.sh` merge instead of overwrite; out of scope.)

## Dependencies

- `jq` — required by `install.sh` (already in the author's Brewfile).
- tmux ≥ 3.2 — already required by the dotfiles (`tmux-jump` uses `display-popup`;
  `show-hooks` is available).
- No new tmux-runtime dependencies. `fzf` / `git` remain with `tmux-jump` in
  dotfiles, not the plugin.

## Testing (plain `sh`, no framework)

- `test/test-install.sh`:
  - Fresh install into a temp `HOME` with no `settings.json` → 4 hooks present,
    `__PLUGIN_DIR__` substituted to an absolute path.
  - Idempotent re-run → still exactly one entry per event (no duplicates).
  - Merge preservation → a pre-existing unrelated hook on, say, `Stop` survives.
  - Uninstall round-trip → all marker-tagged entries removed, unrelated entries
    intact.
- `test/test-mark-read.sh`:
  - With `TMUX_READ_DELAY=0`, a `ready` + active + attached window gets cleared.
  - A window that is no longer `ready` (or not active / not attached) is left
    alone.

Tests assert on JSON via `jq` and on tmux option state in a throwaway tmux server.

## Acceptance criteria

1. `set -g @plugin 'danyim/tmux-claude-indicator'` + TPM install yields working
   🟡/🔴/🟢 badges with no manual tmux edits beyond the documented placeholder.
2. `./install.sh` merges the 4 hooks idempotently, backs up first, preserves
   unrelated hooks; `./uninstall.sh` cleanly removes only ours.
3. Per-state glyphs are overridable via `@claude_icon_working/waiting/ready`.
4. Focus dwell-clear and the MRU stamp coexist on the focus hooks without
   duplication across `prefix r` reloads.
5. The author's dotfiles, after migration, reproduce the current behavior with the
   indicator now sourced from the plugin.
6. No emoji literal appears in any shell-script `case` pattern.
7. All tests pass on both Linux and macOS.

## Open questions

None outstanding. Decisions settled during brainstorming:

- TPM plugin (not a Claude Code plugin or dotfiles module).
- Indicator-only scope; MRU + `tmux-jump` stay in dotfiles.
- Explicit `install.sh` (jq merge + backup + idempotent) for the Claude hooks.
- Documented-placeholder status-line integration.
- New standalone repo `danyim/tmux-claude-indicator`.
- Per-glyph overrides included in v1.
- Plain `sh` tests.
