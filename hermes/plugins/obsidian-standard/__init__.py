"""Hermes gate for the Obsidian note standard.

Blocks ``write_file`` / ``patch`` when the resulting note would violate the standard, feeding the
linter's exact violations back to the model as the block message (so the fix happens in the same
turn). Existing notes are linted leniently — missing frontmatter/H1 were legal when they were
written — while new notes must satisfy the full standard.

Source of truth: ``~/dev/dotfiles/skills/obsidian-notes`` (SKILL.md + rules.json + the linter).
Kill switch: ``OBSIDIAN_GUARD_DISABLE=1``.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

_TARGET_TOOLS = {"write_file", "patch"}
_TRUTHY = {"1", "true", "yes", "on"}


def _guard_path() -> str | None:
    for cand in (
        Path.home() / "dev" / "dotfiles" / "bin" / "obsidian-guard",
        Path.home() / ".local" / "bin" / "obsidian-guard",
    ):
        if cand.is_file():
            return str(cand)
    return shutil.which("obsidian-guard")


def _on_pre_tool_call(tool_name: str = "", args=None, **_):
    if os.environ.get("OBSIDIAN_GUARD_DISABLE", "").lower() in _TRUTHY:
        return None
    if tool_name not in _TARGET_TOOLS or not isinstance(args, dict):
        return None
    path = args.get("path") or args.get("file_path") or ""
    if not isinstance(path, str) or not path.endswith(".md"):
        return None
    guard = _guard_path()
    if not guard:
        return None
    try:
        proc = subprocess.run(
            [sys.executable, guard, "--hermes-hook"],
            input=json.dumps({"tool_name": tool_name, "args": args}),
            capture_output=True, text=True, timeout=30,
        )
    except (subprocess.SubprocessError, OSError):
        return None  # a broken guard must not brick writes
    if proc.returncode == 2:
        return {"action": "block", "message": (proc.stderr or "").strip()}
    return None


def register(ctx) -> None:
    ctx.register_hook("pre_tool_call", _on_pre_tool_call)
