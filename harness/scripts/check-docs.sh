#!/usr/bin/env bash
# Doc gardening: keep docs in sync with the repo by failing when a Markdown link points
# at a repo path that no longer exists. This is the mechanical half of "code↔doc sync"
# (AGENTS.md §4) — it catches moved/renamed/deleted files that left stale references.
# Wire it into pre-commit / CI next to check-sync.sh.
#
# Scope (deliberately conservative to avoid false positives):
#   - Only Markdown inline links of the form [text](target).
#   - Skips external links (http/https/mailto), pure anchors (#...), and any target
#     containing a placeholder/glob (`<`, `*`, `?`) — those are illustrative, not real paths.
#   - A target is OK if it resolves either relative to the file OR relative to repo root
#     (the harness links paths both ways), with any #anchor/?query stripped.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import re, sys, subprocess, pathlib

root = pathlib.Path(sys.argv[1])
md_files = subprocess.run(
    ["git", "-C", str(root), "ls-files", "*.md"],
    capture_output=True, text=True, check=True,
).stdout.split()

link_re = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
errors = []
checked = 0

comment_re = re.compile(r"<!--.*?-->", re.S)
for rel in md_files:
    f = root / rel
    # drop HTML comment blocks — they hold illustrative, not real, links
    text = comment_re.sub("", f.read_text())
    for m in link_re.finditer(text):
        target = m.group(1).strip()
        # strip optional "title" inside the parens
        target = target.split(" ", 1)[0]
        if not target:
            continue
        if re.match(r"^(https?:|mailto:|#)", target):
            continue
        if any(c in target for c in "<*?"):
            continue
        clean = target.split("#", 1)[0].split("?", 1)[0]
        if not clean:
            continue
        checked += 1
        rel_to_file = (f.parent / clean)
        rel_to_root = (root / clean)
        if not (rel_to_file.exists() or rel_to_root.exists()):
            errors.append(f"{rel}: broken link target '{target}'")

if errors:
    print("DOC GARDENING FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"doc gardening OK: {checked} markdown link target(s) resolve across {len(md_files)} file(s)")
PY
