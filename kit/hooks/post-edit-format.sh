#!/usr/bin/env bash
# PostToolUse(Edit|Write) 훅: 편집 직후 포매터 실행 — 컨벤션 사다리 1층.
# WHY: 스타일 논쟁을 기계적으로 제거한다. 에이전트가 어떤 스타일로 쓰든 저장 시점에
# 프로젝트 포맷으로 수렴하므로, 스타일 규칙을 산문으로 가르칠 필요가 없어진다.
# 어떤 포매터를 어떤 확장자에 쓸지는 스택 팩의 harness/gate.env가 정의한다.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -f "$ROOT/harness/gate.env" ] || exit 0
# shellcheck disable=SC1091
. "$ROOT/harness/gate.env"
[ -n "${GATE_FORMAT_FILE_CMD:-}" ] || exit 0

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null)
[ -f "$FILE" ] || exit 0

ext="${FILE##*.}"
for e in ${GATE_FORMAT_EXTENSIONS:-}; do
  if [ "$e" = "$ext" ]; then
    # 포맷 실패(툴 미설치 등)는 편집을 막을 이유가 아니다 — 게이트가 잡는다.
    (cd "$ROOT" && $GATE_FORMAT_FILE_CMD "$FILE" >/dev/null 2>&1) || true
    break
  fi
done
exit 0
