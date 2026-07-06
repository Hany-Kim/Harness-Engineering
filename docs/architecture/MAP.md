# Repo Map — Harness-Engineering

> 에이전트용 목차. 구조가 바뀌면 같은 커밋에서 이 문서를 갱신한다(문서 가드닝이
> 링크를 검사한다).

## Where things live

| 영역 | 경로 | 비고 |
| ---- | ---- | ----- |
| 계약 | `AGENTS.md` / `CLAUDE.md` | 이 저장소 자신의 계약 |
| **단일 소스 (kit)** | `kit/` | 아래 모든 산출물의 원본 — 수정은 여기서만 |
| ├ 에이전트 정의 | `kit/agents/*.agent.md` | → `.claude/agents/` + `.codex/agents/` |
| ├ 루프 커맨드 | `kit/commands/*.cmd.md` | → `.claude/commands/` |
| ├ 컨벤션 Skill | `kit/skills/<name>/` | → `.claude/skills/` + `docs/conventions/` |
| ├ 훅 / 게이트 | `kit/hooks/` `kit/gates/` | → `harness/hooks/` `harness/gates/` |
| ├ 설정 | `kit/settings/` | → `.claude/settings.json` + `.codex/config.toml` |
| ├ 계약 템플릿 | `kit/contract/*.tmpl` | init.sh가 대상 프로젝트용으로 렌더링 |
| └ 스택 팩 | `kit/stacks/<stack>/` | gate.env · stack.md · skills · exemplar · CI |
| 스크립트 | `scripts/` | render.sh · init.sh · upgrade.sh |
| 렌더 산출물 | `.claude/` `.codex/` `harness/` `docs/conventions/` | **직접 수정 금지** |
| 아키텍처 문서 | `docs/architecture/` | principles, 이 지도 |
| 계획(작업 상태 기계) | `docs/plans/` | frontmatter status가 진실, 머지 후에도 보존 |
| 설계 / 결정 | `docs/specs/` `docs/decisions/` | 템플릿 포함 |
| 세션 간 메모리 | `memory/` | 환경 특이사항, 반복 이슈 |
| 팀 전역 컨벤션 | `team/CLAUDE.global.md` | `~/.claude/CLAUDE.md` · `~/.codex/AGENTS.md`로 설치 |
| 버전 | `VERSION` | 설치본 `.harness/manifest`에 스탬프 |

## Key commands

```bash
scripts/render.sh            # kit → 산출물 (--check: 드리프트 검사, 게이트가 실행)
scripts/init.sh <dir> <stack>   # 대상 프로젝트에 설치 (react-vite|spring-boot|fastapi)
scripts/upgrade.sh <dir>     # 설치본 갱신 (manifest 해시 기반, 로컬 수정 보존)
harness/gates/gate.sh        # 커밋 게이트 (pre-commit/CI가 실행, --ci 모드 지원)
harness/gates/doctor.sh      # 설치 완결성 검진
```
