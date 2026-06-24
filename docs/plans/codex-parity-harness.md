# Plan: Codex parity harness

- **Status:** done
- **Owner / driver:** Codex
- **Related:** current request

## 1. Problem

이 하네스는 Claude Code 전용 `.claude/` 접점과 공용 `AGENTS.md`를 이미 갖고 있지만,
Codex가 읽는 `.codex/` 설정과 도구 중립 게이트가 부족하면 같은 보호가 적용되지 않는다.
요청 범위는 Codex 승인 설정, 스택 템플릿의 pre-commit/CI 게이트, nested AGENTS 안내,
Claude/Codex 미러 동기화 검사에 한정한다.

## 2. Constraints & affected layers

코드 런타임 계층은 건드리지 않고 하네스 설정/템플릿만 수정한다. 루트 `AGENTS.md`,
`docs/architecture/principles.md`, 스택별 `harness/templates/*/AGENTS.md`,
`.claude/settings.json`, `.claude/agents/*`, `.codex/agents/*`를 근거로 삼는다.
커밋/푸시는 하지 않는다.

## 3. Approach

Codex는 `.claude/settings.json`의 ask 목록을 직접 읽지 않으므로 `.codex/config.toml`에
보수적 승인 정책과 workspace-write 샌드박스를 둔다. 스택별 검증 명령은 각
`harness/templates/<stack>/AGENTS.md`에 적힌 명령을 그대로 CI/pre-commit 템플릿에
연결하고, 공통 동기화 검사는 `harness/scripts/check-sync.sh`를 호출하게 한다.

## 4. Steps (small, reviewable)

- [x] `.codex/config.toml` 생성 및 패리티 문구 보강
- [x] 스택별 `.pre-commit-config.yaml` 템플릿 추가
- [x] 스택별 `.github/workflows/*.yml` 템플릿 추가
- [x] 스택별 `AGENTS.md` 상단에 nested AGENTS 안내 추가
- [x] `harness/scripts/check-sync.sh`가 agent 미러 불일치를 실패로 처리하는지 확인/보강

## 5. Verification

`bash harness/scripts/check-sync.sh`로 Claude/Codex agent 미러를 확인한다.
`git diff --check`로 공백 오류를 확인한다. 템플릿 자체는 자리표시자를 포함하므로 실제
스택 명령 실행은 대상 프로젝트 적용 후 확인 필요다.

## 6. Rollback

이번 변경 파일만 되돌리면 된다. 커밋/푸시/외부 시스템 변경은 하지 않는다.
