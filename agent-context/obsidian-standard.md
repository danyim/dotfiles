<!-- BEGIN obsidian-standard -->
## Obsidian vault writes

Any write into the Obsidian vault follows the `obsidian-notes` skill (`~/dev/dotfiles/skills/obsidian-notes/SKILL.md`, rules in `rules.json` next to it).

- Load the skill before writing, and scaffold with `obsidian-lint --new "<short title>" --folder <folder> --tags "Tag1,Tag2"` when creating a note.
- New notes start from the vault's `_Templates/Note.template.md` shape: `# H1`, body, then the footer block (`####`, `---`, `Status:`, `Tags:` as wikilinks, `Links:`, `References:`).
- Title every note `YYYY-MM Title`: month stamp, then a short plain title. The H1 is the same title without the stamp.
- No frontmatter by default. Do not stamp `created:`/`updated:`; add a key only when a Dataview query or template reads it.
- Headings (`##`) and bullets instead of prose. A paragraph only when a list would lose the reasoning, and under about 120 words.
- One paragraph or list item per line. Never hard-wrap prose: no mid-sentence newlines, no wrapped bullet continuations.
- Run `obsidian-lint <path>` after writing. A pre-write guard blocks non-compliant new notes in Hermes and Claude Code, so fix what it reports rather than working around it.
- Do not retrofit old notes: missing frontmatter, H1, footer, or existing hand wraps on a note that predates the standard are left alone.
<!-- END obsidian-standard -->
