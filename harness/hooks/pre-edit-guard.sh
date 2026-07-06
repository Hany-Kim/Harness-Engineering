#!/usr/bin/env bash
# PreToolUse(Edit|Write) 훅 — 편집 계층 가드.
#   하드: 보호 브랜치에서 src/** 편집 차단 (exit 2 → 도구 호출 자체가 거부된다).
#   소프트: 현재 브랜치에 approved 계획이 없는 src/** 편집은 경고만 남긴다.
# WHY: 사소한 수정의 마찰은 줄이되(소프트), 최종선은 커밋 게이트(gate.sh)가 지키는
# "커밋 하드 + 편집 소프트" 설계. 보호 브랜치 편집만은 시작부터 막는 게 싸다.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null)
[ -n "$FILE" ] || exit 0

# 소스 루트 바깥(문서, 설정, 계획)은 이 가드의 대상이 아니다.
# 소스 루트 패턴/보호 브랜치는 스택 팩의 gate.env가 정의한다.
SRC_PATTERN="^src/"
PROTECTED="main master develop"
if [ -f "$ROOT/harness/gate.env" ]; then
  # shellcheck disable=SC1091
  . "$ROOT/harness/gate.env"
  SRC_PATTERN="${GATE_SRC_PATTERN:-$SRC_PATTERN}"
  PROTECTED="${GATE_PROTECTED_BRANCHES:-$PROTECTED}"
fi
REL="${FILE#"$ROOT"/}"
printf '%s' "$REL" | grep -Eq "$SRC_PATTERN" || exit 0

BRANCH=$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null || echo "")
for p in $PROTECTED; do
  if [ "$BRANCH" = "$p" ]; then
    echo "[harness] 차단: 보호 브랜치($BRANCH)에서 소스 편집 금지. AGENTS.md Stage 0에 따라 작업 브랜치를 먼저 만들 것." >&2
    exit 2
  fi
done

# 소프트 계층: 계획 부재는 경고만 — 커밋 게이트가 최종 차단한다.
fm_field() { awk -v key="$2" '/^---$/{c++;next} c==1 && $0 ~ "^"key":"{sub("^"key":[ ]*","");print;exit} c>=2{exit}' "$1"; }
has_plan=0
for f in "$ROOT"/docs/plans/*.md; do
  [ -e "$f" ] || continue
  st=$(fm_field "$f" status)
  br=$(fm_field "$f" branch)
  if [ "$br" = "$BRANCH" ] && { [ "$st" = "approved" ] || [ "$st" = "executing" ]; }; then
    has_plan=1
    break
  fi
done
if [ "$has_plan" = 0 ]; then
  printf '{"systemMessage":"[harness] 경고: 현재 브랜치(%s)에 approved 계획이 없습니다. 커밋 게이트가 src/ 변경을 거부합니다 — /plan을 먼저 실행하세요."}\n' "$BRANCH"
fi
exit 0
