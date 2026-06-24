# 나만의 하네스 엔지니어링 (Harness Engineering)

OpenAI의 [Harness Engineering](https://openai.com/index/harness-engineering/) 전략을
참고해 만든 **개인용 하네스 스타터킷**입니다. 프로젝트마다 복사해 쓰면서, 개발 업무와
사이드 프로젝트에서 에이전트(Claude Code 주력 · Codex 보조)가 일관되고 검증 가능하게
일하도록 만드는 게 목표입니다.

## 하네스 엔지니어링이란?

> "에이전트가 코드를 잘 짜게 만들려고 사람이 직접 코드를 쓰는 게 아니라,
> 에이전트가 일할 **환경(harness)** 을 설계한다."

핵심은 **에이전트의 해법 공간을 좁히는 것**입니다. 자유도를 줄이고 성공 경로를 명확히
할수록 에이전트의 생산성과 정확도가 올라갑니다. 4가지 기둥:

1. **컨텍스트 아키텍처** — 저장소가 유일한 진실 공급원. 정보는 계층적으로, 필요할 때만 노출.
2. **에이전트 전문화** — 범위가 좁고 도구가 제한된 전용 에이전트(생성자/평가자 분리).
3. **영속 메모리** — 대화 기록이 아니라 파일시스템에 사실을 남긴다.
4. **구조화된 실행 루프** — research → plan → execute → verify (검증은 *다른* 에이전트가).

여기에 **기계적 제약 강제**(규칙은 글이 아니라 linter/CI/테스트로)와
**골든 원칙 + 백그라운드 정리 작업**이 더해집니다.

## 규칙 계층 (Precedence)

규칙은 계층으로 쌓이고, 충돌 시 위가 이긴다.

1. 현재 대화의 명시적 요청
2. 프로젝트 `AGENTS.md` / `CLAUDE.md` 및 프로젝트 기존 코드 컨벤션
3. **팀 전역 컨벤션** — `team/CLAUDE.global.md` (Claude Code는 `~/.claude/CLAUDE.md`,
   Codex는 `~/.codex/AGENTS.md` 에 설치). 팀 공통 작업 스타일·안전·네이밍·언어별 규칙
4. 일반 프레임워크 권장

예외: 보안 / 인증 / 결제 / DB / 배포 / CI-CD / secret / 운영 데이터 / public API /
파괴적 명령은 계층과 무관하게 항상 보수적으로 판단한다.

## 구조

```
team/CLAUDE.global.md      # 팀 전역 컨벤션 원본(버전 관리) — ~/.claude/CLAUDE.md 로 설치
AGENTS.md                  # 하네스 계약 — 유일한 진실 공급원 (Codex + Claude 공용)
CLAUDE.md                  #   AGENTS.md 를 @import 하는 얇은 포인터
docs/
  architecture/
    principles.md          # 골든 원칙 + 레이어링(의존성 방향) — 기계적 강제 포함
    MAP.md                 # 저장소 지도(목차)
  plans/TEMPLATE.md        # research→plan 산출물 (작업당 1개, 머지 후에도 보존)
  specs/TEMPLATE.md        # 큰 기능 설계서
  decisions/TEMPLATE.md    # ADR — 왜 이렇게 결정했는가
memory/README.md           # 세션을 넘어 남기는 영속 메모리
.claude/
  settings.json            # 권한 + 훅(기계적 강제) 예시
  agents/                  # 전문 서브에이전트: planner / implementer / evaluator / refactorer
  commands/                # 루프 슬래시 커맨드: /research /plan /execute /verify /harden
harness/
  templates/               # 스택별 레이어링·린트·검증 규칙 (react-vite / spring-boot / fastapi)
  scripts/init-project.sh  # 새 프로젝트에 하네스 복사
  scripts/check-sync.sh    # Claude↔Codex 규칙 미러 싱크 검사 (pre-commit/CI용)
```

## Claude Code + Codex를 함께 쓰는 법

- **`AGENTS.md` 가 원본**입니다. Codex가 기본으로 읽고, `CLAUDE.md` 는 `@AGENTS.md` 로
  이를 가져오므로 **두 도구가 같은 계약을 봅니다.** 규칙은 항상 `AGENTS.md` 에만 적습니다.
- Claude Code 전용 기능(서브에이전트, 슬래시 커맨드, 훅)은 `.claude/` 와 `CLAUDE.md` 의
  전용 섹션에 둡니다 — Codex는 이를 무시합니다.

## 실행 루프 (매 작업마다)

| 단계 | 커맨드 | 담당 | 산출물 |
| --- | --- | --- | --- |
| 1. 조사 | `/research` | planner(읽기 전용) | 발견 사항 노트 |
| 2. 계획 | `/plan` | planner | `docs/plans/<slug>.md` |
| 3. 실행 | `/execute` | implementer | 작은 커밋들 + 테스트 |
| 4. 검증 | `/verify` | evaluator(*다른* 에이전트) | PASS/FAIL + 증거 |

> 한 파일·한 레이어를 넘는 변경이면 반드시 계획부터. 검증은 작성자가 셀프로 하지 않습니다.
> 추가로 `/harden` 으로 기술부채를 주기적으로 청소합니다.

## 팀 전역 컨벤션 설치 (1회)

`team/CLAUDE.global.md` 를 두 에이전트의 전역 설정에 연결한다. 저장소를 단일 원본으로
유지하려면 심볼릭 링크를, 이동 가능성이 있으면 복사를 쓴다.

```bash
# 심볼릭 링크 (저장소 수정이 전역에 자동 반영)
ln -s "$PWD/team/CLAUDE.global.md" ~/.claude/CLAUDE.md      # Claude Code 전역
ln -s "$PWD/team/CLAUDE.global.md" ~/.codex/AGENTS.md       # Codex 전역
```

안전 규칙(§2.2 되돌릴 수 없는 작업)은 `.claude/settings.json` 의 `ask` 목록으로
**기계적으로 강제**된다. Codex는 이 파일을 읽지 않으므로, Codex의 승인 정책에도 동일
수준을 설정해야 한다.

## 새 프로젝트에 적용

```bash
harness/scripts/init-project.sh ../my-app fastapi
#   <target-dir>            <stack: react-vite | spring-boot | fastapi>
```

그다음 대상 프로젝트에서:
1. `AGENTS.md` 의 `<…>` 자리표시자(이름, 명령어, 레이아웃)를 채운다.
2. `docs/architecture/STACK-*.md` 내용을 `AGENTS.md` §6에 합치고 파일은 삭제.
3. 스택 노트의 **레이어링 린터 + 검증 명령어**를 CI에 연결.
4. 커밋. 끝.

## 핵심 원칙 (요약)

저장소가 진실 · 의존성은 한 방향(`Types → Config → Repository → Service → Runtime/API → UI`)
· 코드는 에이전트가 읽을 수 있게 · 작고 되돌릴 수 있는 변경 · 제약은 기계적으로 ·
테스트가 계약 · 같은 수정 두 번 실패하면 사람에게(two-strike).
전체는 [`docs/architecture/principles.md`](docs/architecture/principles.md) 참고.
