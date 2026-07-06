#!/usr/bin/env bash
# 하네스 건강검진 — "반쯤 설정된 하네스"라는 상태를 기계적으로 배제한다.
# WHY: v1 이식 실패의 근본 원인은 불완전 설치(누락 파일, 자리표시자, 깨진 링크)가
# 조용히 통과된 것. doctor는 그 상태를 실패로 만들어 재발을 막는다.
# init.sh 마지막에 자동 실행되고, SessionStart 훅이 요약을 세션에 주입한다.
#
# 사용: harness/gates/doctor.sh [--quiet]
#   종료코드 0 = 정상(경고 허용), 1 = 실패(불완전 설치)
set -uo pipefail

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

ERR=0; WARN=0
err()  { ERR=$((ERR+1));  [ "$QUIET" = 1 ] || echo "doctor FAIL: $*"; }
warn() { WARN=$((WARN+1)); [ "$QUIET" = 1 ] || echo "doctor WARN: $*"; }
ok()   { [ "$QUIET" = 1 ] || echo "doctor ok:   $*"; }

# kit/이 있으면 하네스 원본 저장소, 없으면 설치본(대상 프로젝트)
DEV=0; [ -d kit ] && DEV=1

# 1) 필수 파일
for f in AGENTS.md CLAUDE.md .claude/settings.json .codex/config.toml docs/plans/TEMPLATE.md; do
  if [ -f "$f" ]; then ok "$f"; else err "필수 파일 없음: $f"; fi
done

# 2) 잔여 템플릿 변수 — 렌더링이 끝나지 않은 계약은 존재해서는 안 된다
for f in AGENTS.md CLAUDE.md harness/gate.env harness/integrations.env; do
  [ -f "$f" ] || continue
  if grep -Eq '\{\{[A-Z_]+\}\}' "$f"; then
    err "잔여 템플릿 변수({{...}}): $f — init.sh 렌더링이 완료되지 않았다"
  fi
done

# 3) settings.json이 참조하는 훅 스크립트가 존재하고 실행 가능한가
if [ -f .claude/settings.json ]; then
  for h in $(grep -o 'harness/hooks/[a-z-]*\.sh' .claude/settings.json | sort -u); do
    if [ -x "$h" ]; then ok "hook $h"; else err "훅 스크립트 없음/실행불가: $h"; fi
  done
fi

# 4) pre-commit에 게이트가 배선되어 있는가 (도구 무관 최종선)
HOOK_PATH=$(git rev-parse --git-path hooks/pre-commit 2>/dev/null || echo "")
if [ -n "$HOOK_PATH" ] && [ -f "$HOOK_PATH" ] && grep -q 'gate\.sh' "$HOOK_PATH"; then
  ok "pre-commit → gate.sh"
else
  msg="pre-commit 훅에 gate.sh 미배선 — 설치: printf '#!/bin/sh\\n[ -x harness/gates/gate.sh ] && exec harness/gates/gate.sh\\nexit 0\\n' > \"\$(git rev-parse --git-path hooks/pre-commit)\" && chmod +x \"\$(git rev-parse --git-path hooks/pre-commit)\""
  if [ "$DEV" = 1 ]; then warn "$msg"; else err "$msg"; fi
fi

# 5) gate.env의 검증 명령이 해석 가능한가 (best-effort: 첫 토큰이 PATH/파일로 존재)
if [ -f harness/gate.env ]; then
  # shellcheck disable=SC1091
  . harness/gate.env
  for v in GATE_FORMAT_CMD GATE_LINT_CMD GATE_TYPECHECK_CMD GATE_ARCH_CMD GATE_TEST_CMD GATE_BUILD_CMD; do
    cmd=$(eval "printf '%s' \"\${$v:-}\"")
    [ -n "$cmd" ] || continue
    first=${cmd%% *}
    if command -v "$first" >/dev/null 2>&1 || [ -x "$first" ]; then
      ok "$v ($first)"
    else
      warn "$v: '$first'를 찾을 수 없음 — 프로젝트 툴체인 설치 필요 (게이트 실행 시 실패한다)"
    fi
  done
elif [ "$DEV" = 0 ]; then
  err "harness/gate.env 없음 — 스택 검증 명령이 설치되지 않았다 (init.sh 재실행)"
fi

# 5b) 통합 참조값 파일 (설치본에만 — init이 항상 설치한다)
if [ "$DEV" = 0 ]; then
  if [ -f harness/integrations.env ]; then ok "harness/integrations.env"
  else warn "harness/integrations.env 없음 — init.sh 재실행 또는 kit/contract/integrations.env.tmpl에서 복사"; fi
fi

# 6) 설치 매니페스트 (설치본에만 요구 — upgrade의 전제)
if [ "$DEV" = 0 ]; then
  if [ -f .harness/manifest ]; then ok ".harness/manifest"; else err ".harness/manifest 없음 — init.sh로 설치되지 않았다"; fi
fi

# 7) 문서 내부 링크 — 깨진 참조는 에이전트의 문서 신뢰를 무너뜨린다
if [ -x harness/gates/check-docs.sh ]; then
  if harness/gates/check-docs.sh >/dev/null 2>&1; then
    ok "문서 링크"
  else
    err "문서 가드닝 실패 — 상세: harness/gates/check-docs.sh"
  fi
fi

if [ "$ERR" -gt 0 ]; then
  [ "$QUIET" = 1 ] || echo "doctor: 실패 $ERR건, 경고 $WARN건 — 이 하네스는 불완전하다. 작업 시작 전에 고칠 것."
  exit 1
fi
[ "$QUIET" = 1 ] || echo "doctor: OK (경고 $WARN건)"
exit 0
