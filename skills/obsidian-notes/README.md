# obsidian-notes: the vault write standard

One skill, one linter, linked into every harness. The prose lives in `SKILL.md`, the checkable rules in `rules.json`, the gate in `scripts/obsidian_lint.py`, and the install in `dotfiles/skills.sh` (which `load.sh` calls).

```
skills/obsidian-notes/
  SKILL.md                     # the standard, loaded by Claude Code, Codex, Cursor, opencode, Hermes
  rules.json                   # machine-checkable half, read by the linter
  scripts/obsidian_lint.py     # lint / --all report / --new scaffold / --stdin guard mode
  scripts/publish_standard.py  # mirror the standard into the vault for humans
```

## What the standard says, in one screen

- New notes start from `_Templates/Note.template.md`: `# H1`, body, then `####` / `---` / `Status:` / `Tags:` / `Links:` / `References:`.
- Title is `YYYY-MM Title`: month stamp, then a short title (`2026-10 Grok Cost Comparison.md`).
- No frontmatter unless a query or template reads it. No `created:`/`updated:` stamps.
- Headings and bullets carry the structure; prose is the exception, under about 120 words per paragraph.
- One paragraph per line, never hard-wrapped.
- Status markers are `#index`, `#sapling`, `#evergreen`, `#tree`, `#needs-deduping`; tags are wikilinks.
- Embellishing an existing note is additive: bullets you add start with `& ` (`- & text`), nested under the bullet they enrich, and existing lines stay untouched.

## Install on a device

Skills only (no prompts, no other dotfile touched, safe to re-run):

```
cd ~/dev/dotfiles && git pull && ./skills.sh
./skills.sh --dry-run      # show what would change
./skills.sh --uninstall    # remove the links, the bin scripts, and the pointer blocks
./skills.sh --no-publish   # skip the vault copy
```

Install also publishes the standard into every configured vault that exists (`vault.publish_targets` in `rules.json`: the personal vault from `OBSIDIAN_VAULT_PATH`, and the Sirona vault from `SIRONA_VAULT_PATH`, defaulting to `~/Obsidian/Sirona`). Missing vaults are skipped.

That links `skills/obsidian-notes` into `~/.claude/skills`, `~/.codex/skills`, `~/.cursor/skills`, `~/.config/opencode/skills` and `~/.hermes/skills`; installs `obsidian-lint` and `obsidian-guard` into `~/.local/bin`; links the Hermes plugin into `~/.hermes/plugins/obsidian-standard`; and syncs the pointer block into `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

A full dotfiles run does the same thing, since `load.sh` calls this script. `./load.sh --skills-only` runs only this part and exits.

Enable the Hermes side once per device:

```
hermes plugins enable obsidian-standard --no-allow-tool-override
```

Claude Code gets its gate from the PreToolUse hook in `claude/settings.json`, which `load.sh` copies. `skills.sh` does not touch settings files, on purpose.

## Daily use

```
obsidian-lint path/to/Note.md                                 # lint one note
obsidian-lint --all --vault "$OBSIDIAN_VAULT_PATH" --quiet    # corpus report, lenient on old notes
obsidian-lint --new "Grok Cost Check" --folder LLMs --tags "AI,LLMs"   # 2026-10 Grok Cost Check.md
```

## Editing the standard

1. Change `SKILL.md` (prose, judgment) and/or `rules.json` (anything a script can check).
2. `python3 scripts/obsidian_lint.py --all --vault "$OBSIDIAN_VAULT_PATH"` to see the blast radius.
3. `python3 scripts/publish_standard.py --vault "$OBSIDIAN_VAULT_PATH"` to refresh the vault copy.
4. Commit and push. Other devices pick it up with `git pull && ./skills.sh`.

## Notes

- Existing notes lint leniently: missing frontmatter, H1, footer, managed-path location, hand wraps, and the title pattern are warnings there, because the standard governs what gets written now.
- `OBSIDIAN_GUARD_DISABLE=1` disables the Hermes gate for a session.
- The guard never rewrites anything. It refuses, and hands the model the list of violations.
