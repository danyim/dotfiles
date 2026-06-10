#!/bin/sh
# Claude Code status line: mirrors zsh PS1 '%(5~|…/%3~|%~)'
# Shows full path, but truncates to "…/last/3/parts" when depth >= 5.
# Also appends the PR number + title associated with the current branch.

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')

# Replace $HOME with ~
home="$HOME"
display="${cwd/#$home/~}"

# Count path components (split on /)
# For ~ paths, count from ~ as component 1
count=$(echo "$display" | tr '/' '\n' | grep -c '.')

if [ "$count" -ge 5 ]; then
  # Take the last 3 components
  last3=$(echo "$display" | awk -F/ '{print $(NF-2)"/"$(NF-1)"/"$NF}')
  path_str=$(printf "…/%s" "$last3")
else
  path_str=$(printf "%s" "$display")
fi

# ── Associated PR title for the current branch ──────────────────────────────
# Shows only the PR *title*; the PR *number* is already shown by Claude Code's
# native footer badge ("· PR #N"), so emitting it here too would duplicate it.
# Cached to /tmp with a 60s TTL. When stale, refresh in the background so the
# status line renders instantly from the (possibly stale) cache instead of
# blocking on a network call to GitHub.
pr_str=""
if command -v git >/dev/null 2>&1 && command -v gh >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    key=$(printf '%s' "$root#$branch" | { md5 2>/dev/null || md5sum | cut -d' ' -f1; })
    cache="/tmp/claude-sl-pr-$key"

    now=$(date +%s)
    mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
    age=$((now - mtime))

    if [ ! -f "$cache" ] || [ "$age" -ge 60 ]; then
      (
        gh pr view --json title \
          --jq '.title | if length > 50 then .[:49] + "…" else . end' \
          -R "$(git -C "$cwd" remote get-url origin 2>/dev/null)" 2>/dev/null \
          > "$cache.tmp" 2>/dev/null \
          || gh pr view --json title \
               --jq '.title | if length > 50 then .[:49] + "…" else . end' \
               2>/dev/null > "$cache.tmp"
        mv "$cache.tmp" "$cache" 2>/dev/null
      ) >/dev/null 2>&1 &
    fi

    pr_str=$(cat "$cache" 2>/dev/null)
  fi
fi

# ── Context-window usage % ──────────────────────────────────────────────────
# Read from the transcript's most recent assistant `usage` block: the current
# prompt (context) size is input_tokens + cache_read + cache_creation. The
# denominator is the model's context window — 1M for *-[1m] sessions, 200k
# otherwise (auto-bumped to 1M if usage already exceeds 200k).
ctx_str=""
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  used=$(tail -n 500 "$transcript" 2>/dev/null \
    | jq -s '[.[] | .message.usage? // empty] | last
             | if . then
                 (.input_tokens + (.cache_read_input_tokens // 0)
                  + (.cache_creation_input_tokens // 0))
               else empty end' 2>/dev/null)
  if [ -n "$used" ] && [ "$used" -gt 0 ] 2>/dev/null; then
    model_id=$(echo "$input" | jq -r '.model.id // empty')
    case "$model_id" in
      *1m*) window=1000000 ;;
      *) window=200000 ;;
    esac
    [ "$used" -gt "$window" ] && window=1000000
    ctx_str="$(( used * 100 / window ))% ctx"
  fi
fi

# ── Active model + reasoning effort ─────────────────────────────────────────
# `model.display_name` is always present; `effort.level` is emitted only for
# effort-capable models (e.g. Opus 4.8) and `fast_mode` only when fast mode is
# on. Render as "Model · effort effort" with a ⚡ when fast mode is active.
model_str=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
fast=$(echo "$input" | jq -r 'if .fast_mode then "⚡ " else "" end')

info_str=""
[ -n "$model_str" ] && info_str="$fast$model_str"
[ -n "$effort" ] && info_str="$info_str · $effort effort"

out="$path_str"
[ -n "$pr_str" ] && out="$out  ⇡ $pr_str"
[ -n "$info_str" ] && out="$out  · $info_str"
[ -n "$ctx_str" ] && out="$out  · $ctx_str"
printf "%s" "$out"
