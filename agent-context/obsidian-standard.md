<!-- BEGIN obsidian-standard -->
## Obsidian vault writes

Any write into the Obsidian vault follows the `obsidian-notes` skill (`~/dev/dotfiles/skills/obsidian-notes/SKILL.md`, rules in `rules.json` next to it).

- Load the skill before writing, and scaffold with `obsidian-lint --new "Title" --folder <folder> --tags "Tag1,Tag2"` when creating a note.
- Every new note: `created`/`updated` frontmatter, an `# H1`, and the footer block (`Status:`, `Tags:` as wikilinks, `Links:`, `References:`).
- One paragraph or list item per line. Never hard-wrap prose: no mid-sentence newlines, no wrapped bullet continuations. The editor wraps for you, and hand wraps turn every later edit into a block diff.
- Run `obsidian-lint <path>` after writing. A pre-write guard blocks non-compliant new notes in Hermes and Claude Code, so fix what it reports rather than working around it.
- Do not retrofit old notes: missing frontmatter, H1, footer, or existing hand wraps on a note that predates the standard are left alone.
<!-- END obsidian-standard -->
