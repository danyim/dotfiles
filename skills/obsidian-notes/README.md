# obsidian-notes: the vault write standard

One skill, one linter, linked into every harness. The prose lives in `SKILL.md`, the checkable
rules in `rules.json`, the gate in `scripts/obsidian_lint.py`, and `dotfiles/load.sh` wires it up
on each device.

```
skills/obsidian-notes/
  SKILL.md                     # the standard, loaded by Claude Code, Codex, Cursor, opencode, Hermes
  rules.json                   # machine-checkable half, read by the linter
  scripts/obsidian_lint.py     # lint / --all report / --new scaffold / --stdin guard mode
  scripts/publish_standard.py  # mirror the standard into the vault for humans
```

## Install on a device

```
cd ~/dev/dotfiles && git pull && ./load.sh
```

`load.sh` symlinks `skills/obsidian-notes` into `~/.claude/skills`, `~/.codex/skills`,
`~/.cursor/skills`, `~/.config/opencode/skills`, `~/.hermes/skills`; installs `bin/obsidian-lint`
and `bin/obsidian-guard` into `~/.local/bin`; links the Hermes plugin into
`~/.hermes/plugins/obsidian-standard`; and copies `claude/settings.json`, which carries the
PreToolUse hook that runs the guard on Write and Edit.

Enable the Hermes side once per device:

```
hermes plugins enable obsidian-standard --no-allow-tool-override
```

## Daily use

```
obsidian-lint path/to/Note.md                                 # lint one note
obsidian-lint --all --vault "$OBSIDIAN_VAULT_PATH" --quiet    # whole-vault report
obsidian-lint --new "Title" --folder LLMs --tags "AI,LLMs"    # scaffold a compliant note
```

## Editing the standard

1. Change `SKILL.md` (prose, judgment) and/or `rules.json` (anything a script can check).
2. `python3 scripts/obsidian_lint.py --all --vault "$OBSIDIAN_VAULT_PATH"` to see the blast radius.
3. `python3 scripts/publish_standard.py --vault "$OBSIDIAN_VAULT_PATH"` to refresh the vault copy.
4. Commit and push. Other devices pick it up with `git pull && ./load.sh`.

## Notes

- Legacy notes lint leniently: missing frontmatter, H1, and footer are warnings there, because the
  standard governs what gets written now, not a retrofit of 1,100 old notes.
- `OBSIDIAN_GUARD_DISABLE=1` disables the Hermes gate for a session.
- The guard never rewrites anything. It refuses, and hands the model the list of violations.
