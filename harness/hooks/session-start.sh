#!/usr/bin/env bash
# SessionStart 훅: 저장소가 기억하는 "지금 어디까지 했는지"를 세션 컨텍스트로 주입한다.
# WHY: 컴팩션/세션 교체/작업자 교대 후에도 에이전트가 루프의 현재 단계를 채팅 기록이
# 아니라 파일(계획 frontmatter)에서 복원하게 한다 — 맥락 상실의 직접 해법.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
echo "[harness] 현재 브랜치: $BRANCH"

# 계획 frontmatter(첫 --- 블록)에서 status/branch를 읽어 진행 중 작업을 알린다.
fm_field() { awk -v key="$2" '/^---$/{c++;next} c==1 && $0 ~ "^"key":"{sub("^"key":[ ]*","");print;exit} c>=2{exit}' "$1"; }

if [ -d docs/plans ]; then
  in_flight=0
  for f in docs/plans/*.md; do
    [ -e "$f" ] || continue
    case "$(basename "$f")" in TEMPLATE.md) continue ;; esac
    st=$(fm_field "$f" status); [ -n "$st" ] || continue
    sl=$(fm_field "$f" slug); [ -n "$sl" ] || sl=$(basename "$f" .md)
    br=$(fm_field "$f" branch)
    case "$st" in
      approved|executing)
        echo "[harness] 진행 중 작업: $sl (status: $st, branch: $br) — 계획: $f"
        in_flight=1 ;;
      draft)
        echo "[harness] 승인 대기 계획: $sl (branch: $br) — 계획: $f" ;;
    esac
  done
  if [ "$in_flight" = 0 ]; then
    echo "[harness] 진행 중(approved/executing) 계획 없음 — src/ 변경 전 /plan 필요 (커밋 게이트가 강제)"
  fi
fi

# 설치 상태 요약 — 불완전한 하네스는 세션 첫 턴에 사람에게 보고되어야 한다.
if [ -x harness/gates/doctor.sh ]; then
  if harness/gates/doctor.sh --quiet; then
    echo "[harness] doctor: OK"
  else
    echo "[harness] doctor: 실패 — 'harness/gates/doctor.sh'를 실행해 결과를 확인하고 작업 시작 전에 사람에게 보고할 것"
  fi
fi

exit 0
