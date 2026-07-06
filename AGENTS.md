# AGENTS.md — Harness-Engineering (하네스 원본 저장소)

> 이 파일은 이 저장소에서 일하는 모든 에이전트(Claude Code, Codex, …)의 계약이다.
> 이 저장소는 다른 프로젝트에 **설치되는 하네스의 원본(kit)** 이다 — 여기서의 작업은
> 대부분 `kit/`과 `docs/`를 고치는 일이고, 그 결과가 모든 대상 프로젝트로 전파된다.

## 0. 사실

- **단일 소스는 `kit/`이다.** `.claude/` `.codex/` `harness/gates/` `harness/hooks/`
  `docs/conventions/`는 `scripts/render.sh`의 산출물 — **직접 수정 금지.**
  `kit/`을 고치고 렌더링한다(게이트가 `render.sh --check`로 강제).
- 설치: `scripts/init.sh <target> <stack>` · 갱신: `scripts/upgrade.sh <target>`
  · 버전: `VERSION` (설치본 `.harness/manifest`에 스탬프됨)
- 저장소 지도: [docs/architecture/MAP.md](docs/architecture/MAP.md)
  · 골든 원칙: [docs/architecture/principles.md](docs/architecture/principles.md)
- 우선순위: 대화의 명시 요청 > 이 파일 > 팀 전역 컨벤션(`team/CLAUDE.global.md` —
  `~/.claude/CLAUDE.md` · `~/.codex/AGENTS.md`로 설치) > 일반 관행.
  보안 / secret / 파괴적 명령은 계층 무관 항상 보수적으로.

## 1. 실행 루프 — 비자명한 변경은 이 순서를 따른다

| 단계 | 커맨드 | 산출물 / 상태 전이 |
| --- | --- | --- |
| 0. Branch | — | 보호 브랜치(main) 금지. `<type>/<slug>` 또는 에이전트 워크트리 브랜치 |
| 1. 조사 | `/research` | 발견 사항 노트 (읽기 전용) |
| 2. 계획 | `/plan` | `docs/plans/<slug>.md` — `status: draft` → **사람 승인 후 approved** |
| 3. 실행 | `/execute` | `status: executing`, 작은 커밋 |
| 4. 검증 | `/verify` | evaluator가 gate --ci 실행 → PASS 시 `status: verified` |

**계획 frontmatter가 작업 상태의 진실이다.** 새 세션은 SessionStart 훅이 주입하는
"진행 중 작업"을 이어서 한다.

## 2. 이 저장소의 규칙

1. **kit 우선.** 에이전트/커맨드/훅/게이트/Skill/설정을 바꾸려면 `kit/`을 고치고
   `scripts/render.sh`를 실행해 산출물을 같은 커밋에 포함한다. 패리티(Claude↔Codex)는
   이 생성 과정이 보장한다 — 손 미러링은 존재하지 않는다.
2. **스택 팩 정합.** `kit/stacks/<stack>/`의 규칙(gate.env, stack.md)을 바꾸면 그
   표본(exemplar)과 Skill도 같은 커밋에서 맞춘다 — 표본이 곧 컨벤션의 정의다.
3. **게이트.** `harness/gates/gate.sh`가 pre-commit/CI에서 실행된다: 렌더 패리티,
   문서 링크, 브랜치 규칙. `--no-verify` 금지. 점검: `harness/gates/doctor.sh`.
4. **문서 가드닝.** 파일을 옮기면 링크도 같은 커밋에서 — check-docs가 차단한다.
5. **버전.** 설치본에 영향 주는 변경은 `VERSION`을 올린다(대상 프로젝트가
   upgrade로 받는다).
6. 골든 원칙(작고 되돌릴 수 있는 변경, two-strike, 테스트가 계약)은
   [principles.md](docs/architecture/principles.md)를 따른다.

## 3. 구조 (요약 — 상세는 MAP.md)

```
kit/            # ★ 단일 소스: agents/ commands/ skills/ hooks/ gates/ settings/
                #   contract/(AGENTS·CLAUDE 템플릿) stacks/(gate.env·stack.md·skills·exemplar)
scripts/        # render.sh(kit→산출물) init.sh(설치) upgrade.sh(갱신)
.claude/ .codex/ harness/ docs/conventions/   # 렌더 산출물 — 직접 수정 금지
docs/           # architecture/ plans/(상태 기계) specs/ decisions/
team/           # 팀 전역 컨벤션 원본
VERSION         # 하네스 버전 (설치 스탬프)
```

## 4. 경계·안전

- secret은 커밋 금지. 파괴적 작업(rm -rf, reset --hard, force push 등)은 사전 확인.
- commit / push / merge는 명시 요청·승인 하에서만. push는 작업 브랜치만.
