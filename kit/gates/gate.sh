#!/usr/bin/env bash
# 통합 커밋 게이트 — pre-commit과 CI가 "같은 것"을 실행한다.
# WHY: 절차(브랜치 규칙, 계획 선행, 검증)를 산문이 아니라 커밋 차단으로 강제한다.
# Claude 훅이 없는 도구(Codex 등)도 이 게이트는 우회할 수 없다 — 도구 무관 최종선.
#
# 사용:
#   harness/gates/gate.sh          # pre-commit 모드: 스테이징 기준, 빠른 검사
#   harness/gates/gate.sh --ci     # CI 모드: 기본 브랜치와의 diff 기준 + build 포함
#
# 스택별 검증 명령은 harness/gate.env가 정의한다(스택 팩에서 init이 설치).
set -uo pipefail

MODE=precommit
[ "${1:-}" = "--ci" ] && MODE=ci

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

FAIL=0
fail() { echo "gate FAIL: $*" >&2; FAIL=1; }
run()  { # run <라벨> <명령문자열> — 빈 명령은 건너뛴다
  local label="$1" cmd="$2"
  [ -n "$cmd" ] || return 0
  echo "gate: $label — $cmd"
  if ! bash -c "$cmd"; then fail "$label ($cmd)"; fi
}

# shellcheck disable=SC1091
[ -f harness/gate.env ] && . harness/gate.env

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
PROTECTED="${GATE_PROTECTED_BRANCHES:-main master develop}"
DEFAULT_BRANCH="${GATE_DEFAULT_BRANCH:-main}"
# claude/, codex/는 에이전트 워크트리 브랜치 — 게이트가 에이전트 자신의 작업을 막지 않도록 허용
BRANCH_REGEX="${GATE_BRANCH_REGEX:-^(feature|bugfix|hotfix|release|chore|claude|codex)/([A-Z][A-Z0-9]+-[0-9]+-)?[A-Za-z0-9._-]+$}"

is_protected() { local b; for b in $PROTECTED; do [ "$1" = "$b" ] && return 0; done; return 1; }

# 1) 보호 브랜치 직접 커밋 차단 + 2) 브랜치명 규칙 (CI는 머지 결과 검증이므로 생략)
if [ "$MODE" = precommit ] && [ -n "$BRANCH" ]; then
  if is_protected "$BRANCH"; then
    fail "보호 브랜치($BRANCH)에는 직접 커밋할 수 없다 — 작업 브랜치를 만들 것 (AGENTS.md Stage 0)"
  elif ! printf '%s' "$BRANCH" | grep -Eq "$BRANCH_REGEX"; then
    fail "브랜치명 규칙 위반: '$BRANCH' — 규칙: $BRANCH_REGEX"
  fi
fi

# 3) src/ 변경에는 현재 브랜치용 approved 계획 필수 (계획 frontmatter가 상태의 진실)
if [ "$MODE" = precommit ]; then
  CHANGED=$(git diff --cached --name-only)
else
  BASE=$(git merge-base "origin/$DEFAULT_BRANCH" HEAD 2>/dev/null \
      || git merge-base "$DEFAULT_BRANCH" HEAD 2>/dev/null || echo "")
  if [ -n "$BASE" ]; then CHANGED=$(git diff --name-only "$BASE"...HEAD); else CHANGED=""; fi
fi

fm_field() { awk -v key="$2" '/^---$/{c++;next} c==1 && $0 ~ "^"key":"{sub("^"key":[ ]*","");print;exit} c>=2{exit}' "$1"; }

if printf '%s\n' "$CHANGED" | grep -q '^src/'; then
  has_plan=0
  for f in docs/plans/*.md; do
    [ -e "$f" ] || continue
    st=$(fm_field "$f" status)
    br=$(fm_field "$f" branch)
    if [ "$br" = "$BRANCH" ]; then
      case "$st" in approved|executing|verified) has_plan=1; break ;; esac
    fi
  done
  if [ "$has_plan" = 0 ]; then
    fail "src/ 변경에는 현재 브랜치용 계획이 필요하다 — docs/plans/*.md frontmatter에 branch: $BRANCH, status: approved 인 계획을 만들 것 (/plan 후 사람 승인)"
  fi
fi

# 4) 스택 검증 명령 (harness/gate.env — 없거나 비어 있으면 건너뜀)
run "format"    "${GATE_FORMAT_CMD:-}"
run "lint"      "${GATE_LINT_CMD:-}"
run "typecheck" "${GATE_TYPECHECK_CMD:-}"
run "arch"      "${GATE_ARCH_CMD:-}"
run "test"      "${GATE_TEST_CMD:-}"
[ "$MODE" = ci ] && run "build" "${GATE_BUILD_CMD:-}"

# 5) 렌더 패리티 — 하네스 원본 저장소에서만 (대상 프로젝트에는 kit/ 없음)
if [ -d kit ] && [ -x scripts/render.sh ]; then
  if ! scripts/render.sh --check; then
    fail "렌더 패리티: kit/과 산출물(.claude/.codex/harness)이 어긋남 — scripts/render.sh 실행 후 같은 커밋에 포함할 것"
  fi
fi

# 6) 문서 가드닝 — 깨진 내부 링크는 에이전트의 문서 신뢰를 무너뜨린다
if [ -x harness/gates/check-docs.sh ]; then
  harness/gates/check-docs.sh || fail "문서 가드닝 (harness/gates/check-docs.sh)"
fi

if [ "$FAIL" != 0 ]; then
  echo "gate FAILED ($MODE) — 위 항목을 고치기 전에는 커밋할 수 없다. --no-verify 우회 금지." >&2
  exit 1
fi
echo "gate OK ($MODE)"
