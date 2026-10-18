#!/usr/bin/env python3
"""Obsidian note linter for the vault note standard.

Stdlib only (runs on the Mac's system python and on corlabo). Rules live in
../rules.json; prose lives in ../SKILL.md.

Usage:
  obsidian-lint <note.md>...            lint specific notes
  obsidian-lint --all                   report over the whole vault
  obsidian-lint --new "Title" [--folder LLMs] [--tags "AI,LLMs"] [--type note]
  obsidian-lint --vault /path ...       override vault discovery
  obsidian-lint --json ...              machine-readable output
  obsidian-lint --strict-links ...      wikilink misses are errors, not warnings

Exit: 0 clean (warnings allowed), 1 errors found, 2 usage/environment failure.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
RULES_PATH = HERE.parent / "rules.json"

FM_RE = re.compile(r"\A---\n(.*?)\n---\n?", re.S)
WIKILINK_RE = re.compile(r"\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]")


def load_rules() -> dict:
    with open(RULES_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def discover_vault(explicit: str | None, rules: dict) -> Path:
    candidates = []
    if explicit:
        candidates.append(Path(explicit).expanduser())
    env_key = rules.get("vault", {}).get("env", "OBSIDIAN_VAULT_PATH")
    if os.environ.get(env_key):
        candidates.append(Path(os.environ[env_key]).expanduser())
    candidates.append(Path.home() / "Documents" / "Obsidian Vault")
    markers = rules.get("vault", {}).get("markers", [".obsidian"])
    for cand in candidates:
        if not cand.is_dir():
            continue
        if any((cand / m).exists() for m in markers):
            return cand.resolve()
    raise SystemExit(
        "could not find the vault: pass --vault, or set %s (looked for %s)"
        % (env_key, ", ".join(str(c) for c in candidates))
    )


def vault_for_path(path: Path, rules: dict) -> Path | None:
    for parent in [path] + list(path.parents):
        if any((parent / m).exists() for m in rules.get("vault", {}).get("markers", [".obsidian"])):
            return parent
    return None


def basename_index(vault: Path) -> set[str]:
    names = set()
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if not d.startswith(".") and d != "node_modules"]
        for f in files:
            if f.endswith(".md"):
                names.add(f[:-3])
    return names


def make_link_resolver(vault: Path, names: set[str]):
    def resolves(target: str) -> bool:
        target = target.strip()
        if not target:
            return True
        if target.endswith(".md"):
            target = target[:-3]
        if any(x in target for x in ("{{", "${")):
            return True
        if "/" in target:
            return (vault / f"{target}.md").exists() or (vault / target).exists()
        return target in names

    return resolves



STRUCTURAL_RE = re.compile(r"^\s*(#{1,6}\s|#{1,6}$|-{3,}$|\*{3,}$|[-*+]\s|\d+[.)]\s|>|\||```|#[\w-]+$)")
TERMINAL = ".!?:;`)]}\u201d\"'"


def find_manual_wraps(body: str) -> list[str]:
    """Lines that look like a hand-wrapped paragraph or list item."""
    text = re.sub(r"```.*?```", "", body, flags=re.S)
    footer = re.search(r"(?m)^---\s*$\n(?:\s*\n)*Status:", text)
    if footer:  # the footer block is structured key/value, not prose
        text = text[: footer.start()]
    lines = text.split("\n")
    hits: list[str] = []
    run: list[str] = []

    def flush() -> None:
        for i in range(len(run) - 1):
            a, b = run[i].rstrip(), run[i + 1].lstrip()
            if a and b and a[-1] not in TERMINAL and b[:1].islower():
                hits.append("paragraph wrapped by hand: " + a.strip()[:60])
                return

    prev = ""
    for raw in lines:
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped:
            flush(); run = []; prev = ""; continue
        structural = bool(STRUCTURAL_RE.match(line))
        indented = line.startswith("  ") and not structural
        if structural:
            flush(); run = []
            prev = stripped
            continue
        if indented and prev and prev[-1] not in TERMINAL and stripped[:1].islower():
            hits.append("list item wrapped by hand: " + prev[:60])
            prev = stripped
            continue
        run.append(line)
        prev = stripped
    flush()
    return hits


def check_note(path: Path, vault: Path | None, rules: dict, names: set[str], strict_links: bool,
               text: str | None = None, lenient: bool = False):
    errors: list[str] = []
    warnings: list[str] = []
    if text is None:
        text = path.read_text(encoding="utf-8", errors="replace")

    # --- filename -------------------------------------------------------
    fname_rules = rules.get("filename", {})
    stem = path.stem
    if len(stem) > fname_rules.get("max_length", 120):
        errors.append(f"filename longer than {fname_rules.get('max_length', 120)} chars")
    for ch in fname_rules.get("forbidden_chars", []):
        if ch and ch in path.name:
            shown = ch if ch.isprintable() else repr(ch)
            errors.append(f"filename contains forbidden character {shown!r}")
    if fname_rules.get("forbid_trailing_space_or_dot") and stem and stem[-1] in ". ":
        errors.append("filename ends with a dot or space")
    if fname_rules.get("forbid_leading_space") and path.name.startswith(" "):
        errors.append("filename starts with a space")

    # --- location -------------------------------------------------------
    if vault is not None:
        rel = path.relative_to(vault).as_posix()
        for pref in rules.get("paths", {}).get("forbidden_prefixes", []):
            if rel.startswith(pref):
                msg = f"note written under managed path {pref}"
                (warnings if lenient else errors).append(msg)
        if rel in rules.get("paths", {}).get("forbidden_exact", []):
            msg = f"note written at managed path {rel}"
            (warnings if lenient else errors).append(msg)

    # --- frontmatter ----------------------------------------------------
    fm = FM_RE.match(text)
    if not fm:
        if rules.get("frontmatter", {}).get("required", True):
            msg = "missing frontmatter (--- created/updated ---)"
            (warnings if lenient else errors).append(msg)
        body = text
        fields = {}
    else:
        body = text[fm.end():]
        fields = {}
        for line in fm.group(1).splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if ":" not in line:
                warnings.append(f"unparsed frontmatter line: {line.strip()[:40]}")
                continue
            k, v = line.split(":", 1)
            fields[k.strip()] = v.strip().strip('"').strip("'")
        for key in rules.get("frontmatter", {}).get("required_keys", []):
            if key not in fields:
                errors.append(f"frontmatter missing key {key!r}")
            elif fields[key] == "":
                errors.append(f"frontmatter key {key!r} is empty")
        for key, pat in rules.get("frontmatter", {}).get("patterns", {}).items():
            val = fields.get(key)
            if val and not re.match(pat, val):
                errors.append(f"frontmatter {key}={val!r} does not match {pat}")

    # --- body -----------------------------------------------------------
    lines = body.rstrip("\n").split("\n") if body.strip() else []
    if rules.get("body", {}).get("h1_required", True):
        first = next((ln for ln in lines
                      if ln.strip() and not ln.strip().startswith("<!--")), "")
        if not first.startswith("# "):
            msg = "first body line is not an H1 ('# Title')"
            (warnings if lenient else errors).append(msg)

    # --- footer ---------------------------------------------------------
    footer_rules = rules.get("footer", {})
    ferr: list[str] = []
    if footer_rules.get("required", True):
        labels = footer_rules.get("labels", ["Status:", "Tags:", "Links:", "References:"])
        scan = footer_rules.get("scan_last_lines", 25)
        tail = lines[-scan:] if len(lines) > scan else lines
        start = None
        for i in range(len(tail) - 1, -1, -1):
            if tail[i].strip() == "---":
                start = i
                break
        if start is None:
            ferr.append("missing footer block (--- / Status: / Tags: / Links: / References:)")
        else:
            block = tail[start:]
            found = [ln.strip() for ln in block]
            pos = []
            for label in labels:
                if label in found:
                    pos.append(found.index(label))
                else:
                    ferr.append(f"footer missing {label}")
            if pos != sorted(pos):
                ferr.append("footer labels out of order (Status, Tags, Links, References)")

            # status value check
            if "Status:" in found:
                si = found.index("Status:")
                vals = []
                for ln in found[si + 1:]:
                    if ln in labels or ln in ("####", "---"):
                        break
                    if ln:
                        vals.extend(ln.split())
                allowed = rules.get("status", {}).get("allowed_markers", [])
                if not rules.get("status", {}).get("free_text", False):
                    bad = [v for v in vals if v not in allowed]
                    if bad:
                        ferr.append(
                            f"Status contains non-marker text {bad[:3]} (allowed: {', '.join(allowed)})"
                        )

            # tags style + resolution
            if "Tags:" in found and rules.get("tags", {}).get("style", "wikilink") == "wikilink":
                ti = found.index("Tags:")
                tag_lines = []
                for ln in found[ti + 1:]:
                    if ln in labels or ln in ("####", "---"):
                        break
                    if ln:
                        tag_lines.append(ln)
                for ln in tag_lines:
                    stripped = WIKILINK_RE.sub("", ln).replace(",", " ").strip()
                    if stripped:
                        ferr.append(f"Tags line is not pure wikilinks: {ln.strip()[:60]}")
                if rules.get("tags", {}).get("must_resolve") and vault is not None:
                    resolve = make_link_resolver(vault, names)
                    for ln in tag_lines:
                        for t in WIKILINK_RE.findall(ln):
                            if not resolve(t):
                                ferr.append(f"tag [[{t}]] does not resolve to a note")

    # Footer problems on a note that predates the standard are warnings: the standard governs
    # new notes, and rewriting an old note's shape is a separate, asked-for job.
    (warnings if lenient else errors).extend(ferr)

    # --- wikilinks ------------------------------------------------------
    link_mode = rules.get("wikilinks", {}).get("must_resolve", "warn")
    if link_mode != "off" and vault is not None:
        resolve = make_link_resolver(vault, names)
        seen = set()
        prose = re.sub(r"```.*?```", "", text, flags=re.S)
        prose = re.sub(r"`[^`\n]*`", "", prose)
        for t in WIKILINK_RE.findall(prose):
            t = t.strip()
            if t in seen or not t:
                continue
            seen.add(t)
            if not resolve(t):
                msg = f"wikilink [[{t}]] does not resolve to a note"
                (errors if (link_mode == "error" or strict_links) else warnings).append(msg)

    if prose_cfg_no_wrap := rules.get("prose", {}).get("no_manual_wrap", {}):
        if prose_cfg_no_wrap.get("enabled", True):
            marker_now = rules.get("prose", {}).get("skip_marker")
            if not (marker_now and marker_now in text):
                (warnings if lenient else errors).extend(find_manual_wraps(body))

    # --- prose voice (warnings only) ------------------------------------
    prose_rules = rules.get("prose", {})
    marker = prose_rules.get("skip_marker")
    if not (marker and marker in text):
        prose = re.sub(r"```.*?```", "", text, flags=re.S)
        prose = re.sub(r"`[^`\n]*`", "", prose)
        for phrase in prose_rules.get("warn_phrases", []):
            if phrase in prose:
                warnings.append(f"prose: contains {phrase!r}; the standing orders ban it in prose")

    return errors, warnings


def scaffold(vault: Path, args, rules: dict) -> Path:
    title = args.new.strip()
    if not title:
        raise SystemExit("--new needs a title")
    folder = (args.folder or "").strip("/")
    dest_dir = vault / folder if folder else vault
    if not dest_dir.is_dir():
        raise SystemExit(f"folder does not exist: {dest_dir}")
    rel = (Path(folder) if folder else Path()) / f"{title}.md"
    if rel.as_posix() in rules.get("paths", {}).get("forbidden_exact", []):
        raise SystemExit(f"refusing to write into managed path {rel}")

    now = args.now
    tags = " ".join(f"[[{t.strip()}]]" for t in (args.tags or "").split(",") if t.strip())
    body = f"""---
created: {now}
updated: {now}
---

# {title}

{args.body or 'TODO: what this is, why it matters, what was decided, what is still open.'}

---
Status:
{args.status or ''}
Tags:
{tags}
Links:

References:
"""
    path = dest_dir / f"{title}.md"
    if path.exists() and not args.force:
        raise SystemExit(f"refusing to overwrite existing note: {path}")
    path.write_text(body, encoding="utf-8")
    return path


def main() -> int:
    ap = argparse.ArgumentParser(description="Lint Obsidian notes against the vault standard.")
    ap.add_argument("paths", nargs="*", help="notes to lint")
    ap.add_argument("--all", action="store_true", help="report over the whole vault")
    ap.add_argument("--new", metavar="TITLE", help="scaffold a compliant note")
    ap.add_argument("--folder", help="folder for --new (relative to vault)")
    ap.add_argument("--tags", help="comma-separated tag notes for --new")
    ap.add_argument("--status", help="status marker for --new")
    ap.add_argument("--body", help="body text for --new")
    ap.add_argument("--now", default=None, help="override created/updated timestamp")
    ap.add_argument("--force", action="store_true", help="allow --new to overwrite")
    ap.add_argument("--vault", help="vault root (else $OBSIDIAN_VAULT_PATH or discovery)")
    ap.add_argument("--json", action="store_true", help="JSON output")
    ap.add_argument("--strict-links", action="store_true", help="unresolved wikilinks are errors")
    ap.add_argument("--quiet", action="store_true", help="only failures (for --all)")
    ap.add_argument("--stdin", action="store_true", help="lint content from stdin (with --path-as)")
    ap.add_argument("--path-as", help="vault-relative path the stdin content would be written to")
    ap.add_argument("--lenient", action="store_true",
                    help="existing note: missing frontmatter/H1 are warnings, not errors")
    args = ap.parse_args()

    rules = load_rules()
    if args.all and not args.lenient:
        args.lenient = True  # a corpus report is always a legacy report
    if args.now is None:
        from datetime import datetime
        args.now = datetime.now().strftime("%Y-%m-%dT%H:%M")

    vault = discover_vault(args.vault, rules)

    if args.new:
        path = scaffold(vault, args, rules)
        print(str(path))
        return 0

    if args.stdin:
        if not args.path_as:
            raise SystemExit("--stdin needs --path-as <vault-relative path>")
        rel = args.path_as.lstrip("/")
        target = vault / rel
        payload = sys.stdin.read()
        errs, warns = check_note(target, vault, rules, basename_index(vault),
                                 args.strict_links, text=payload, lenient=args.lenient)
        if args.json:
            print(json.dumps({"path": str(target), "errors": errs, "warnings": warns}, indent=2))
        else:
            for e in errs:
                print(f"ERROR {rel}: {e}", file=sys.stderr)
            for w in warns:
                print(f"warn  {rel}: {w}", file=sys.stderr)
        return 1 if errs else 0

    if not args.paths and not args.all:
        ap.print_help()
        return 2

    if args.all:
        targets = []
        for root, dirs, files in os.walk(vault):
            dirs[:] = [d for d in dirs if not d.startswith(".") and d != "node_modules"]
            for f in files:
                if f.endswith(".md"):
                    targets.append(Path(root) / f)
        targets.sort()
    else:
        targets = [Path(p).expanduser().resolve() for p in args.paths]

    names = basename_index(vault)
    results = []
    err_count = warn_count = 0
    for path in targets:
        if not path.exists():
            results.append({"path": str(path), "errors": ["file not found"], "warnings": []})
            err_count += 1
            continue
        v = vault_for_path(path, rules) or vault
        errs, warns = check_note(path, v, rules, names, args.strict_links, lenient=args.lenient)
        err_count += len(errs)
        warn_count += len(warns)
        results.append({"path": str(path), "errors": errs, "warnings": warns})

    if args.json:
        print(json.dumps({"vault": str(vault), "notes": len(targets), "errors": err_count,
                          "warnings": warn_count, "results": results}, indent=2))
    else:
        failing = [r for r in results if r["errors"]]
        for r in results:
            if args.quiet and not r["errors"]:
                continue
            p = Path(r["path"])
            rel = p.relative_to(vault) if p.is_relative_to(vault) else p
            if not r["errors"] and not r["warnings"] and not args.all:
                print(f"ok    {rel}")
            for e in r["errors"]:
                print(f"ERROR {rel}: {e}")
            if not args.quiet:
                for w in r["warnings"]:
                    print(f"warn  {rel}: {w}")
        if args.all:
            print(f"\n{len(targets)} notes, {len(failing)} with errors, "
                  f"{err_count} errors, {warn_count} warnings (vault: {vault})")
        elif len(targets) > 1:
            print(f"\n{len(targets)} notes, {len(failing)} with errors, "
                  f"{err_count} errors, {warn_count} warnings")

    return 1 if err_count else 0


if __name__ == "__main__":
    sys.exit(main())
