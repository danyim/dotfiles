---
name: obsidian-notes
description: "Use when writing or editing notes in the Obsidian vault. Enforces the vault's note anatomy, title format, folder routing, wikilinks, footer block, and prose voice."
version: 1.3.0
author: danyim
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [obsidian, notes, vault, standard, lint]
    related_skills: [obsidian, obsidian-spec-notes, product-research-notes, obsidian-maintained-notes]
---

# Obsidian Notes: Writing Standard

The machine-readable half of this standard is `rules.json` next to this file, enforced by `scripts/obsidian_lint.py` and by the pre-write guard. Rules a script can check live there; this file explains them and carries the judgment calls a script cannot make. When the two disagree, `rules.json` wins.

Before writing anything into the vault, run the linter on what you wrote:

```
obsidian-lint <path-to-note>
obsidian-lint --all --vault <vault>          # corpus report, legacy notes lint leniently
obsidian-lint --new "Title" --folder LLMs --tags "AI,LLMs"   # scaffold a note in the required shape
```

## When to Use

- Any write or edit to a note under the Obsidian vault.
- Creating a note, index entry, spec, journal entry, or research note.
- Deciding where a note belongs, how it should be titled, or what the footer should say.

Not for: reading notes (just read them), or discussing note contents in chat.

## Hard rules (enforced)

1. **Vault only, real folders.** Write inside the vault root. Never write into `_Archive/`, `_Templates/`, `_PublishMeta/`, `.obsidian/`, or `.trash/`; those are managed surfaces. A note that belongs in `_Archive` is a note that should not be created.

2. **Start from the vault's Note template**, `_Templates/Note.template.md` (in Obsidian: `obsidian://open?vault=MainVault&file=_Templates%2FNote.template`), or from `obsidian-lint --new`, which builds the same shape. The template is the skeleton: an `# H1`, the body, then the footer block (`####`, a `---` rule, `Status:`, `Tags:`, `Links:`, `References:`). Do not invent a different skeleton; follow the convention of the notes already in the vault.

   ```
   # Title

   ## Section
   - point

   ####
   ---
   Status:

   Tags:
   [[Tag One]] [[Tag Two]]
   Links:

   References:
   ```

3. **Title every note `YYYY-MM Title`, short and to the point.** The filename carries the month stamp, then a plain title: `2026-10 Grok Cost Comparison.md`, not `Grok cost comparison research notes final.md`. Ten words at most. The H1 is the title without the stamp (`# Grok Cost Comparison`). Daily journals keep `YYYY-MM-DD Ddd.md`; index notes and templates keep their existing names.

4. **No frontmatter by default.** 1,108 of the vault's 1,328 notes have none, and the title already carries the month, so do not stamp `created:` or `updated:` on every note. Add a key only when something reads it: a Dataview query, a template that expects it (`source:`, `locations:`, `private:`, `publish:`), or a note type already using it. Never add free-form keys like `status:` or `mood:`; status lives on the footer's `Status:` line.

5. **Headings and bullets over prose.** Structure the note with `##` sections and `-` points, and reach for a paragraph only when a list would lose the reasoning: a decision's cause, a sequence of events, a caveat. Keep any single paragraph under about 120 words; past that a heading and a list read better.

6. **One paragraph per line: never hard-wrap prose.** A paragraph or a list item is a single long physical line, however wide it gets; the editor and Obsidian wrap it for display. Break lines only for real structure: headings, list items, table rows, code fences, block quotes. A mid-sentence newline turns every later edit into a whole-block diff.

7. **The footer closes the note.** `Status:` holds a marker, not prose, from the allowed set: `#index`, `#sapling`, `#evergreen`, `#tree`, `#needs-deduping` (or empty). Tags are wikilinks to index notes, never hashtags. `Links:` is the related-note list, `References:` the external URLs.

8. **Wikilinks resolve.** Every `[[Target]]` matches an existing note basename, or a note you are creating in the same operation. Index notes in `Indices/` carry `#index` in Status and `[[_Index]]` in Links.

9. **Filenames are safe on macOS and Linux.** No `:` `/` `\` `|` `#` `^` `[[` `]]`, no trailing dot or space, under 120 characters.

10. **Do not retrofit legacy notes.** The standard governs what gets written now. If you edit an old note, preserve its shape: add the footer if the edit touches it, but do not restructure the body, rewrap old paragraphs, or invent a creation date.

11. **Embellishing an existing note is additive and marked.** When the task is to embellish, enhance, enrich, or expand a note, the bullets you add carry the `& ` marker described below. Existing lines stay as they are, and a marker already in the note is never removed or rewritten.

## Voice (from the global standing orders)

- **No em dashes.** Use commas, colons, parentheses, or separate sentences.
- **No LLM tells.** Do not use "load-bearing". Do not write "delve", "leverage" as a verb, "it's worth noting", or a closing paragraph that restates the note.
- **No AI attribution** anywhere in a note: no "generated with", no model names, no session links. Record what was decided, not who typed it.
- **Absolute dates**, never "last week", because the note outlives the week.
- **Numbers carry their source.** Any figure that drove a decision gets its query, table, or URL in the body or in `References:`.

## Embellishing an existing note

"Embellish", "enhance", "enrich", "expand", and "flesh out" mean additive editing of a note that already exists. The reader has to be able to tell the note's own content from what the model wrote, so every bullet added in that mode starts with `& `:

```
- Zengjiayan station (曾家岩, Zēngjiāyán) - monorail views (better than Liziba)
    - Line 2 runs along the Jialing here, so the river and skyline come to an ordinary platform, without the Liziba crowds
    - & Line 2 also stops at Niujiaotuo, so this pairs with the Yangtze cable car in one loop
```

- **Add, do not rewrite.** Existing lines stay byte-identical: no reflow, no reordering, no "improving" a bullet that was already there. New sub-bullets slot in under the bullet they enrich, indented one level to match the note.
- **`& ` marks model-written text.** It is a marker, not decoration: no marker on a human line, always a marker on an added one. Writing it as `-& text`, `- &text`, or a bare `- &` is an error the linter reports.
- **Never touch an existing marker.** When you revisit a note that already carries `& ` bullets, leave them where they are, even if you would have phrased them differently.
- Everything else still holds: no frontmatter, headings and bullets, one line per bullet, footer left alone unless the edit is what adds it.

Use plain additive editing, with no markers, when the request is "append this section" or "add a note about X": that content is the note's own going forward. The marker is for the embellish pass.

## Where notes go

| Note type | Folder | Notes |
|---|---|---|
| Ordinary topic note | vault root | 725 current notes live here; this is normal |
| Daily journal | `Daily Journals/` | `YYYY-MM-DD Ddd.md`, tag `[[Daily Journals]]`, Status empty |
| Index / MOC | `Indices/` | Status `#index`, Links `[[_Index]]`, Dataview table body |
| Spec | `Specs/` | reviewed before build; `<!-- TODOCLAUDE: -->` comments are instructions |
| LLM / AI reference | `LLMs/` | research write-ups; reels in `LLMs/Reels/` |
| Weekly review | `Weekly Reviews/` | one per week, tagged with that week's journal |

Templates live in `_Templates/`. Read the matching template before writing a note of that type: `Note.template.md` is the skeleton for anything without a shape of its own, `Product Research.template.md` carries the research shape, `Daily Journals.template.md` the journal shape. Fill it in and delete the placeholder bullets.

## Judgment calls (not enforced)

- **Search before creating.** A near-duplicate note is worse than a section in the existing one. Check the topic's index note and the vault for the title first.
- **Write for the reader in six months**: what this is, why it matters, what was decided, what is still open.
- **Wikilinks over URLs** for anything that lives in the vault. URLs belong in `References:`.
- **A note about a task is not a task.** Open work goes to the task system; the note records the decision and its reasoning.
- **Do not restructure a note you were asked to append to.** Append, or edit the specific section. Reorganizing a note is a separate, asked-for job.

## Procedure

1. Resolve the vault (`OBSIDIAN_VAULT_PATH`, else walk up to the directory holding `.obsidian`).
2. Search for an existing note on the subject; extend it if it exists.
3. Scaffold with `obsidian-lint --new "<short title>" --folder <folder> --tags "Tag1,Tag2"`, which applies the month stamp, the H1, the section bullets, and the template footer.
4. Write the body as headings and bullets. No frontmatter unless something reads it.
5. Run `obsidian-lint <path>`. Fix every error. Warnings on legacy notes can stand.
6. Report the absolute path you wrote.

## Failure modes this standard exists to prevent

- Notes with no footer, so they never appear in the index queries that organize the vault.
- Hashtags where the vault uses wikilink tags, splitting one tag across two systems.
- Frontmatter sprawl: five keys nobody queries, on a note whose title already says when it was made.
- Titles like "notes", "misc", or a whole sentence, so the note is unfindable a month later.
- Walls of prose where three bullets would have done, and hand-wrapped lines that reflow badly on the first edit.
- Retrofit passes that rewrite twenty old notes and bury the real edit.
- Duplicate notes for one subject, because nobody searched first.
