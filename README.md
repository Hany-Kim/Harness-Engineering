# 하네스 엔지니어링 v2 (Harness Engineering)

에이전트(Claude Code 주력 · Codex 보조)가 어느 프로젝트에서든 **일관되고 검증
가능하게** 일하도록 만드는 설치형 하네스. 이 저장소가 원본(kit)이고, 대상
프로젝트에는 `scripts/init.sh`로 렌더링해 설치한다.

> 핵심 철학: 에이전트가 일 잘하게 만드는 건 더 긴 프롬프트가 아니라 **환경**이다.
> 규칙은 산문이 아니라 게이트로 강제하고, 작업 상태는 채팅이 아니라 파일에 남긴다.

## v2가 v1과 다른 점 (왜 재설계했나)

v1을 타 프로젝트에 이식하면 에이전트가 맥락을 잃고 절차를 건너뛰었다. 원인과 해법:

| v1의 문제 | v2의 해법 |
| --- | --- |
| 이식 스크립트가 Codex 설정·게이트를 누락(반쪽 복사) | `init.sh`가 전체를 렌더링 복사 + 마지막에 `doctor.sh` 통과해야 설치 완료 |
| 계약에 자리표시자·깨진 링크 잔존 → 에이전트가 문서를 불신 | 렌더링으로 자리표시자 0개 보장, doctor·check-docs가 기계 검증 |
| 절차 강제가 산문뿐(훅은 주석 상태) | `gate.sh`(pre-commit/CI)가 커밋을 차단 — Codex도 우회 불가 |
| 루프 상태가 파일에 없음 → 세션 바뀌면 맥락 소실 | 계획 frontmatter 상태 기계 + SessionStart 훅이 매 세션 주입 |
| Claude↔Codex 수동 미러링(드리프트) | `kit/` 단일 소스에서 **생성** — 드리프트 클래스 소멸 |

## 4가지 기둥 + 컨벤션 사다리

1. **컨텍스트 아키텍처** — 계약(AGENTS.md)은 짧게, 상세는 docs/에 계층화.
2. **에이전트 전문화** — planner / implementer / evaluator / refactorer (검증은 항상 다른 에이전트).
3. **영속 메모리** — 계획·결정·메모는 파일시스템에. 채팅 기록은 소모품.
4. **구조화된 실행 루프** — research → plan → execute → verify, 단계마다 게이트.

코드 일관성은 **컨벤션 사다리**로: ① 포매터·린터(기계) → ② 표본 코드(exemplar 모방)
→ ③ 작업 유형별 Skill(온디맨드) → ④ 상시 산문(최소). 위에서 해결되는 규칙을
아래에 두지 않는다.

## 구조

```
kit/                       # ★ 단일 소스 — 모든 수정은 여기서
  agents/ commands/ skills/ hooks/ gates/ settings/
  contract/                # 대상 프로젝트용 AGENTS.md/CLAUDE.md 템플릿
  stacks/{react-vite,spring-boot,fastapi}/
                           # gate.env(검증 명령) · stack.md(레이어링/린터 설정)
                           # · skills/(스택 Skill) · exemplar/(표본 슬라이스) · CI
scripts/
  render.sh                # kit → .claude/.codex/harness/docs/conventions 생성
  init.sh                  # 대상 프로젝트 설치 (렌더링 복사 + 버전 스탬프 + doctor)
  upgrade.sh               # 설치본 갱신 (manifest 해시 기반, 로컬 수정 보존)
.claude/ .codex/ harness/ docs/conventions/   # 렌더 산출물 — 직접 수정 금지
docs/  architecture/(원칙·지도) plans/(작업 상태 기계) specs/ decisions/
team/CLAUDE.global.md      # 팀 전역 컨벤션 원본
VERSION                    # 하네스 버전 — 설치본 .harness/manifest에 스탬프
```

## 새 프로젝트에 설치

```bash
scripts/init.sh ../my-app fastapi   my-app develop
#               <target>  <stack>   [이름]  [기본 브랜치]
```

init이 하는 일: 계약 렌더링(자리표시자 치환) → `.claude/ .codex/ harness/ docs/`
전체 복사 → 스택 팩(gate.env·표본·Skill·CI) 설치 → git pre-commit에 게이트 배선 →
`.harness/manifest`(버전+해시) 기록 → **doctor 통과 확인**. 실패하면 설치 미완료다.

이후 하네스 개선분 반영:

```bash
scripts/upgrade.sh ../my-app   # 로컬에서 수정 안 한 파일만 자동 갱신,
                               # 수정한 파일은 <file>.harness-new 로 보고
```

## 설치된 프로젝트에서의 루프

| 단계 | 커맨드 | 강제 장치 |
| --- | --- | --- |
| 0. 브랜치/티켓 | — | 게이트가 보호 브랜치·브랜치명 규칙 차단 |
| 1. 조사 | `/research` | planner(읽기 전용) |
| 2. 계획 | `/plan` | `docs/plans/<slug>.md` — frontmatter `draft` → 사람 승인 → `approved` |
| 3. 실행 | `/execute` | **approved 계획 없으면 src/ 커밋이 게이트에서 거부됨** |
| 4. 검증 | `/verify` | evaluator(별도 에이전트)가 `gate.sh --ci` + 계획 검증 → `verified` |

세션이 바뀌어도 SessionStart 훅이 "진행 중 작업: X (executing, branch: …)"를
주입한다 — 맥락은 저장소가 기억한다.

## 팀 전역 컨벤션 설치 (1회)

```bash
ln -s "$PWD/team/CLAUDE.global.md" ~/.claude/CLAUDE.md   # Claude Code 전역
ln -s "$PWD/team/CLAUDE.global.md" ~/.codex/AGENTS.md    # Codex 전역
```

## 이 저장소에서 하네스를 고칠 때

`kit/`을 고치고 `scripts/render.sh` 실행 — 원본과 산출물을 같은 커밋에.
게이트가 `render.sh --check`·문서 링크·브랜치 규칙을 커밋마다 검사한다.
설치본에 영향을 주는 변경은 `VERSION`을 올린다. 상세: [AGENTS.md](AGENTS.md).
