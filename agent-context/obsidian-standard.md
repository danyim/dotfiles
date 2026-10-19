<!-- BEGIN obsidian-standard -->
## Obsidian vault writes

Any write into the Obsidian vault follows the `obsidian-notes` skill (`~/dev/dotfiles/skills/obsidian-notes/SKILL.md`, rules in `rules.json` next to it).

- Load the skill before writing, and scaffold with `obsidian-lint --new "<short title>" --folder <folder> --tags "Tag1,Tag2"` when creating a note.
- New notes start from the vault's `_Templates/Note.template.md` shape: `# H1`, body, then the footer block (`####`, `---`, `Status:`, `Tags:` as wikilinks, `Links:`, `References:`).
- Title every note `YYYY-MM Title`: month stamp, then a short plain title. The H1 is the same title without the stamp.
- No frontmatter by default. Do not stamp `created:`/`updated:`; add a key only when a Dataview query or template reads it.
- Headings (`##`) and bullets instead of prose. A paragraph only when a list would lose the reasoning, and under about 120 words.
- Model-written text is marked: `- & text` for content added to the note (and to that bullet), `- ^ text` for meta feedback and status such as "could not find images for this item". Never delete either marker.
- The owner writes both too. A `&` bullet from them is feedback or a command for the next pass: act on it, leave the line untouched, put the result underneath. A `^` bullet is a note addressed to the model.
- Embellishing a note (`embellish`, `enhance`, `expand`) is additive: new bullets carry `& `, existing lines are never rewritten, and no marker is ever stripped.
- Photos: save into the vault with a short meaningful name, then embed on its own line at the sub-bullet indent with no bullet marker (`    ![[Chongqing Hongyadong.jpg|600]]`), never wider than 600. Not a bullet, not at column zero.
- One paragraph or list item per line. Never hard-wrap prose: no mid-sentence newlines, no wrapped bullet continuations.
- Run `obsidian-lint <path>` after writing. A pre-write guard blocks non-compliant new notes in Hermes and Claude Code, so fix what it reports rather than working around it.
- Do not retrofit old notes: missing frontmatter, H1, footer, or existing hand wraps on a note that predates the standard are left alone.
<!-- END obsidian-standard -->
