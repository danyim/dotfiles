#!/usr/bin/env python3
"""Publish the note standard into the vault so Obsidian documents what the agents enforce.

Renders SKILL.md + rules.json into a vault note. `--check` exits 1 when the vault copy no longer
matches the source, which makes drift visible instead of silent.

  publish_standard.py --vault <vault>            write/refresh the note
  publish_standard.py --vault <vault> --check    compare only
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
SKILL = HERE.parent / "SKILL.md"
RULES = HERE.parent / "rules.json"
NOTE_DIR = "Indices"
NOTE_NAME = "Obsidian Note Standard.md"


def render(now: str) -> str:
    skill = SKILL.read_text(encoding="utf-8")
    body = skill.split("---\n", 2)[-1].strip() if skill.startswith("---") else skill.strip()
    # demote the H1 so the vault note keeps its own title
    body = body.replace("\n# Obsidian Notes — Writing Standard\n", "\n")
    rules = json.loads(RULES.read_text(encoding="utf-8"))
    rules_block = "\n".join(f"- `{k}`: `{json.dumps(v, ensure_ascii=False)}`" for k, v in rules.items())
    return f"""---
created: {now}
updated: {now}
---

<!-- generated: obsidian-standard -->
# Obsidian Note Standard

Generated from `~/dev/dotfiles/skills/obsidian-notes/`: edit the SKILL.md and rules.json there, then run `publish_standard.py --vault <vault>`. Anything changed in this note is overwritten on the next publish, and the agents never read this copy. They read the skill and its linter.

Agents reach the standard three ways, so it applies on every device and in every app: `dotfiles/skills.sh` symlinks the skill into each harness's skills folder, Hermes and Claude Code run a pre-write guard that refuses non-compliant notes, and the always-loaded context file in each harness points at the skill.

{body}

## Enforced rules (rules.json)

{rules_block}

####
---
Status:
#index
Tags:
[[Technology]]
Links:
[[_Index]]
References:
- https://github.com/danyim/dotfiles (skills/obsidian-notes)
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--vault", default=os.environ.get("OBSIDIAN_VAULT_PATH"))
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if not args.vault or not Path(args.vault).is_dir():
        raise SystemExit("need --vault or $OBSIDIAN_VAULT_PATH")
    vault = Path(args.vault).expanduser()
    target = vault / NOTE_DIR / NOTE_NAME
    if args.check:
        if not target.exists():
            print(f"missing: {target}")
            return 1
        existing = target.read_text(encoding="utf-8")
        # compare bodies, ignoring the date lines
        def body(t: str) -> str:
            return "\n".join(l for l in t.splitlines() if not l.startswith(("created:", "updated:")))
        if body(existing) != body(render("X")):
            print(f"stale: {target}")
            return 1
        print(f"current: {target}")
        return 0
    now = datetime.now().strftime("%Y-%m-%dT%H:%M")
    if target.exists():
        old = target.read_text(encoding="utf-8")
        created = next((l for l in old.splitlines() if l.startswith("created: ")), f"created: {now}")
        text = render(now).replace(f"created: {now}", created, 1)
    else:
        text = render(now)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    print(str(target))
    return 0


if __name__ == "__main__":
    sys.exit(main())
