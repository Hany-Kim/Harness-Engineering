#!/usr/bin/env bash
# 문서 가드닝: Markdown 링크가 저장소에 없는 경로를 가리키면 실패한다.
# WHY: 이동/삭제된 파일이 남긴 깨진 참조는 "code↔doc sync"의 절반이며, 에이전트가
# 문서를 저신뢰로 취급하게 만드는 주범이다. gate.sh와 doctor.sh가 호출한다.
#
# 범위(오탐 방지를 위해 의도적으로 보수적):
#   - Markdown 인라인 링크 [text](target)만 검사.
#   - 외부 링크(http/https/mailto), 앵커(#...), 자리표시자/글롭(<, *, ?) 포함 대상 제외.
#   - 대상은 "파일 기준 상대" 또는 "저장소 루트 기준" 어느 쪽으로든 해석되면 OK
#     (#anchor / ?query 는 제거 후 판정).
#   - HTML 주석 블록 안의 링크는 예시로 간주하고 건너뜀.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

python3 - "$ROOT" <<'PY'
import re, sys, subprocess, pathlib

root = pathlib.Path(sys.argv[1])
md_files = subprocess.run(
    ["git", "-C", str(root), "ls-files", "*.md"],
    capture_output=True, text=True, check=True,
).stdout.split()

link_re = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
comment_re = re.compile(r"<!--.*?-->", re.S)
errors = []
checked = 0

for rel in md_files:
    f = root / rel
    text = comment_re.sub("", f.read_text())
    for m in link_re.finditer(text):
        target = m.group(1).strip().split(" ", 1)[0]
        if not target:
            continue
        if re.match(r"^(https?:|mailto:|#)", target):
            continue
        if any(c in target for c in "<*?{"):
            continue
        clean = target.split("#", 1)[0].split("?", 1)[0]
        if not clean:
            continue
        checked += 1
        if not ((f.parent / clean).exists() or (root / clean).exists()):
            errors.append(f"{rel}: broken link target '{target}'")

if errors:
    print("DOC GARDENING FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"doc gardening OK: {checked} link target(s) resolve across {len(md_files)} file(s)")
PY
