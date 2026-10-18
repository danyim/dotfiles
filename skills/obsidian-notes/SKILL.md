---
name: obsidian-notes
description: "Use when writing or editing notes in the Obsidian vault. Enforces the vault's note anatomy, folder routing, wikilinks, footer block, and prose voice."
version: 1.1.0
author: danyim
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [obsidian, notes, vault, standard, lint]
    related_skills: [obsidian, obsidian-spec-notes, product-research-notes, obsidian-maintained-notes]
---

# Obsidian Notes: Writing Standard

The machine-readable half of this standard is `rules.json` next to this file, enforced by
`scripts/obsidian_lint.py` and by the pre-write guard. Rules a script can check live there; this
file explains them and carries the judgment calls a script cannot make. When the two disagree,
`rules.json` wins.

Before writing anything into the vault, run the linter on what you wrote:

```
obsidian-lint <path-to-note>
obsidian-lint --all --vault <vault>          # report mode over the whole vault
obsidian-lint --new "Title" --folder LLMs --tags "AI,LLMs"   # scaffold a compliant note
```

## When to Use

- Any write or edit to a note under the Obsidian vault.
- Creating a note, index entry, spec, journal entry, or research note.
- Deciding where a note belongs, what the footer should say, or whether to add frontmatter.

Not for: reading notes (just read them), or discussing note contents in chat.

## Hard rules (enforced)

1. **Vault only, real folders.** Write inside the vault root. Never write into `_Archive/`,
   `_Templates/`, `_PublishMeta/`, `.obsidian/`, or `.trash/`; those are managed surfaces. A note
   that belongs in `_Archive` is a note that should not be created.
2. **Frontmatter on every new note.** Exactly two dates, unquoted, `YYYY-MM-DDTHH:MM`:

   ```
   ---
   created: 2026-10-18T14:52
   updated: 2026-10-18T14:52
   ---
   ```

   `created` is set once and never moves; `updated` moves on every content edit. Add other keys
   (`source:`, `locations:`, `private:`) only when the note type calls for them.
3. **An H1 as the first body line**, naming the note's subject. Not the filename repeated blindly,
   but close enough that a search hit and a heading read the same.
4. **The footer block, last thing in the file**, in this shape:

   ```
   ---
   Status:

   Tags:
   [[Tag One]] [[Tag Two]]
   Links:

   References:
   ```

   `Status:` holds a marker, not prose, and only from the allowed set: `#index`, `#sapling`,
   `#evergreen`, `#tree`, `#needs-deduping` (or empty). Tags are wikilinks to index notes, never
   hashtags. `Links:` is the related-note list. `References:` is external URLs, one per line.
5. **Wikilinks resolve.** Every `[[Target]]` matches an existing note basename, or a note you are
   creating in the same operation. Index notes in `Indices/` carry `#index` in Status and
   `[[_Index]]` in Links.
6. **Filenames are safe on macOS and Linux.** No `:` `/` `\` `|` `#` `^` `[[` `]]`, no trailing dot
   or space, under 120 characters. Prefer title case with spaces. Dated notes lead with the date
   (`2026-10-18 Grok Cost Comparison.md`).
7. **Do not retrofit legacy notes.** 1,108 of 1,328 existing notes have no frontmatter, and that is
   fine. The standard governs what gets written now. If you edit a legacy note, preserve its shape:
   add the footer if the edit touches it, but do not restructure the body or invent a creation date.

## Voice (from the global standing orders)

- **No em dashes.** Use commas, colons, parentheses, or separate sentences.
- **No LLM tells.** Do not use "load-bearing". Do not write "delve", "leverage" as a verb,
  "it's worth noting", or a summary paragraph that restates the note.
- **No AI attribution** anywhere in a note: no "generated with", no model names, no session links.
  Record what was decided, not who typed it.
- **Absolute dates**, never "last week", because the note outlives the week.
- **Numbers carry their source.** Any figure that drove a decision gets its query, table, or URL in
  the body or in `References:`.

## Where notes go

| Note type | Folder | Notes |
|---|---|---|
| Ordinary topic note | vault root | 725 current notes live here; this is normal |
| Daily journal | `Daily Journals/` | `YYYY-MM-DD Ddd.md`, tag `[[Daily Journals]]`, Status empty |
| Index / MOC | `Indices/` | Status `#index`, Links `[[_Index]]`, Dataview table body |
| Spec | `Specs/` | reviewed before build; `<!-- TODOCLAUDE: -->` comments are instructions |
| LLM / AI reference | `LLMs/` | research write-ups; reels in `LLMs/Reels/` |
| Weekly review | `Weekly Reviews/` | one per week, tagged with that week's journal |

Templates live in `_Templates/` (20 of them). Read the matching template before writing a note of
that type; `Note.template.md` is only the bare footer, `Product Research.template.md` carries the
research shape. Start from the template, fill it in, delete the placeholder bullets.

## Judgment calls (not enforced)

- **Search before creating.** A near-duplicate note is worse than a section in the existing one.
  Check the topic's index note and the vault for the title first.
- **Write for the reader in six months**: what this is, why it matters, what was decided, what is
  still open. Prose, not bullet confetti. Structure a long note with `##` sections.
- **Wikilinks over URLs** for anything that lives in the vault. URLs belong in `References:`.
- **A note about a task is not a task.** Open work goes to the task system; the note records the
  decision and its reasoning.
- **Do not restructure a note you were asked to append to.** Append, or edit the specific section.
  Reorganizing a note is a separate, asked-for job.

## Procedure

1. Resolve the vault (`OBSIDIAN_VAULT_PATH`, else walk up to the directory holding `.obsidian`).
2. Search for an existing note on the subject; extend it if it exists.
3. Pick folder and template from the table above.
4. Write: frontmatter, `# Title`, body, footer.
5. Run `obsidian-lint <path>`. Fix every error. Warnings on legacy notes can stand.
6. Report the absolute path you wrote.

## Failure modes this standard exists to prevent

- Notes with no footer, so they never appear in the index queries that organize the vault.
- Hashtags where the vault uses wikilink tags, splitting one tag across two systems.
- Retrofit passes that rewrite twenty old notes and bury the real edit.
- A `created` date invented at edit time, sorting the note into the wrong year in `Indices/`.
- Duplicate notes for one subject, because nobody searched first.
