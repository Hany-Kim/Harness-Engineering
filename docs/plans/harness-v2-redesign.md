---
slug: harness-v2-redesign
status: executing
branch: claude/priceless-turing-cbdd4f
ticket: none
updated: 2026-07-06
---

# Plan: 하네스 v2 전면 재설계 — 이식 가능하고 기계적으로 강제되는 하네스

> This file is durable memory. 상태는 frontmatter가 진실이다(§3.2 상태 기계 — 본
> 계획이 첫 적용 사례). 사람이 대화에서 승인("진행해") → executing 전환.

- **Owner / driver:** 김주한
- **Related:** docs/plans/codex-parity-harness.md, docs/plans/src-change-workflow.md (v1 설계 — 본 계획이 대체)

## 1. Problem

v1 하네스를 타 프로젝트에 이식했을 때 두 가지 실패가 관찰되었다: (a) 에이전트가
맥락을 잃는다, (b) 의도한 절차(research→plan→execute→verify)를 수행하지 않는다.

조사 결과 원인은 다섯 가지 구조적 결함이다.

1. **이식이 반쪽이다.** `init-project.sh`가 `.codex/`, `harness/scripts/*`,
   `harness/templates/*`를 복사하지 않는다. 이식된 프로젝트에서 Codex는 완전
   무하네스 상태이고, AGENTS.md §4가 지목하는 게이트 스크립트는 존재하지 않는다.
2. **계약이 메타 문서다.** AGENTS.md가 `<…>` 자리표시자, 템플릿 안내문, 하네스
   철학 설명을 담고 있어, 이식 직후 에이전트는 깨진 참조투성이 문서를 읽는다.
   참조가 허탕을 치면 에이전트는 문서 전체를 저신뢰로 취급하고 무시한다.
3. **강제가 0개다.** settings.json 훅은 `_example_hooks` 주석 상태, §4 게이트
   명령은 전부 자리표시자. 절차는 산문 권고뿐이라 컨텍스트가 길어지면 확률적으로
   무시된다. "Constraints are mechanical"(골든 원칙 5)을 하네스 자신이 어긴다.
4. **루프 상태가 파일에 없다.** 어떤 작업이 어느 단계·어느 브랜치·어느 계획에
   매였는지 기록되지 않아, 컴팩션·세션 전환 시 맥락이 소실된다.
5. **항상 로드되는 산문이 과다하다.** 규칙 수가 많을수록 개별 준수율이 떨어진다.

## 2. Constraints & affected layers

- 소스 코드 레이어(`Types→…→UI`)는 해당 없음 — 하네스 저장소 자체의 재구성.
- 골든 원칙 4(Constraints are mechanical), 8(Tool parity)이 이번 설계의 중심.
- 제약: Codex의 프롬프트 디렉터리는 공식 문서로 미확인(기존 "확인 필요" 유지).
  Codex에는 Claude 훅 대응물이 없으므로 도구 무관 계층(pre-commit/CI)이 최종선.
- 팀 전역 컨벤션(team/CLAUDE.global.md)의 내용은 이번 범위에서 변경하지 않는다.

## 3. Approach

무게중심을 두 번 옮긴다: **산문 → 메커니즘**, **채팅 → 파일 상태**. 확정된 설계
결정 세 가지:

- **범위:** 전면 재설계. 기존 문서·스크립트는 참고 자료로만 쓰고 구조를 새로 설계.
- **강제 수준:** 커밋 하드 + 편집 소프트. 커밋 시점 게이트(pre-commit/CI)는 무조건
  차단, 편집 시점 훅은 보호 브랜치만 하드 차단하고 계획 부재는 경고.
- **배포:** 렌더링 복사 + 버전 스탬프. init이 자리표시자를 치환해 렌더링하고
  버전·매니페스트를 기록, upgrade 스크립트가 diff 기반으로 갱신을 전파.

### 3.1 v2 저장소 구조

```
README.md                      # 사람용: 철학·사용법. 에이전트 로드 경로가 아님.
AGENTS.md                      # 이 저장소 자신의 계약 (kit에서 렌더링된 결과물)
CLAUDE.md                      # @AGENTS.md 포인터 + Claude 전용 노트 (렌더링 결과물)
kit/                           # ★ 단일 소스. 모든 에이전트 설정의 원본
  contract/
    AGENTS.md.tmpl             # 계약 템플릿 — {{PROJECT_NAME}} 등 명시적 변수만
    CLAUDE.md.tmpl
  agents/                      # 에이전트 정의 단일 소스 (frontmatter + 본문)
    planner.agent.md           #   → .claude/agents/*.md + .codex/agents/*.toml 생성
    implementer.agent.md
    evaluator.agent.md
    refactorer.agent.md
  commands/                    # 루프 커맨드 단일 소스 → .claude/commands/*.md 생성
    research.cmd.md            #   (Codex 프롬프트 디렉터리는 확인 필요 상태 유지)
    plan.cmd.md
    execute.cmd.md
    verify.cmd.md
    harden.cmd.md
  skills/                      # 컨벤션 Skill 단일 소스 (§3.7)
    testing-conventions/       #   → .claude/skills/ + docs/conventions/ 렌더
    commit-and-pr/
    db-migration/
  hooks/                       # Claude Code 훅 스크립트 원본
    session-start.sh           # 진행 중 작업 상태를 컨텍스트로 주입
    pre-edit-guard.sh          # 보호 브랜치 src/ 편집 하드 차단 + 계획 부재 경고
  gates/
    gate.sh                    # 통합 게이트 (도구 무관 — pre-commit/CI가 실행)
    doctor.sh                  # 하네스 건강검진 (설치 완결성 검사)
    check-docs.sh              # 문서 가드닝 (v1에서 이관)
  settings/
    settings.json              # Claude 권한 + "활성" 훅 배선 (예시 주석 아님)
    codex.config.toml          # Codex 안전 경계
  stacks/                      # 스택 팩: 실행 가능한 실제 명령 + 린터 설정
    react-vite/    {gate.env, .pre-commit-config.yaml, verify.yml, NOTES.md,
                    exemplar/, skills/}   # 표본 slice + 스택 전용 Skill (§3.7)
    spring-boot/   {…}
    fastapi/       {…}
scripts/
  render.sh                    # kit → .claude/.codex 렌더링 (패리티는 생성으로 해결)
  init.sh                      # 타 프로젝트 설치: 렌더링 복사 + 버전 스탬프
  upgrade.sh                   # 설치본 갱신: 매니페스트 해시 diff 기반
team/CLAUDE.global.md          # (유지)
docs/                          # (유지: architecture / plans / specs / decisions)
memory/                        # (유지)
.claude/ .codex/               # render.sh 산출물 — 손으로 수정 금지
```

핵심 전환: `.claude/`와 `.codex/`는 **산출물**이다. 규칙 변경은 `kit/`에서만 하고
`render.sh`로 재생성한다. `check-sync.sh`의 휴리스틱 비교는 "재생성 후 diff가
깨끗한가"라는 결정적 검사로 대체된다 — 수동 복제 드리프트라는 문제 클래스 소멸.

### 3.2 상태 기계: 계획 문서 frontmatter (맥락 상실의 직접 해법)

`docs/plans/<slug>.md`에 YAML frontmatter를 도입한다. 계획 문서가 곧 작업 상태다.

```yaml
---
slug: login-page
status: draft | approved | executing | verified | abandoned
branch: feature/PROJ-123-login-page
ticket: PROJ-123        # 없으면 none
updated: 2026-07-06
---
```

- 상태 전이는 루프 커맨드가 수행한다: `/plan`이 draft 생성 → 사람이 approved로
  올림(또는 명시 승인) → `/execute`가 executing → `/verify` PASS가 verified.
- `/execute`는 현재 브랜치와 일치하는 approved/executing 계획이 없으면 **거부하고
  `/plan`으로 보낸다** (전제조건 검사 — 산문이 아니라 커맨드 로직).
- `session-start.sh` 훅이 세션 시작마다 스캔해 주입한다:
  "진행 중 작업: login-page (executing), 브랜치: feature/PROJ-123-login-page,
  계획: docs/plans/login-page.md" — 컴팩션·세션 전환·팀원 교대에도 저장소가
  맥락을 복원한다.

### 3.3 게이트: gate.sh 하나로 통합, 커밋 시점 하드 차단

`kit/gates/gate.sh`가 유일한 게이트 정의이며 pre-commit과 CI가 같은 것을 실행한다.
**Codex는 훅이 없어도 pre-commit을 우회할 수 없다** — Codex 절차 미이행의 실질
해법. 검사 항목:

1. 보호 브랜치(main/master/develop/release/*/hotfix/*) 직접 커밋 차단.
2. 브랜치명 규칙: `^(feature|bugfix|hotfix|release|chore)/([A-Z][A-Z0-9]+-[0-9]+-)?[a-z0-9._-]+$`
3. 스테이징에 `src/**` 변경 포함 시: 현재 브랜치와 frontmatter `branch`가 일치하고
   status가 approved 이상인 계획 문서 존재 필수. 없으면 커밋 실패.
4. 스택별 검증: `gate.env`(스택 팩이 제공, init 시 렌더링)가 정의하는 실제 명령
   실행 — lint / typecheck / unit test. 자리표시자 명령은 doctor가 사전 검출.
5. 렌더 패리티: `render.sh --check` (kit ↔ .claude/.codex diff 없음).
6. 문서 가드닝: `check-docs.sh`.

편집 시점(소프트 계층, Claude 전용): `pre-edit-guard.sh`가 PreToolUse(Edit|Write)로
(a) 보호 브랜치에서 `src/**` 편집이면 **차단**(하드 — 유일한 편집 하드 규칙),
(b) 계획 없는 `src/**` 편집이면 경고 메시지만 주입(소프트). 사소한 수정의 마찰을
피하면서 최종선(커밋)은 지킨다.

### 3.4 doctor.sh: "반쯤 설정된 하네스"의 기계적 배제

이식 실패의 재발 방지 장치. 검사 항목 — 하나라도 실패하면 비정상 종료:

- 잔여 `{{…}}` 템플릿 변수 또는 `<…>` 자리표시자 (AGENTS.md, gate.env, settings).
- AGENTS.md 안의 저장소 내부 링크가 실제 파일로 해석되는가.
- `.codex/config.toml`·`.claude/settings.json` 존재 및 훅 배선 여부.
- pre-commit 설치 여부(`.git/hooks/pre-commit`), gate.env의 명령이 실행 가능한가.
- `.harness/manifest` 존재 및 버전 스탬프 유효성.

session-start 훅이 doctor 요약을 함께 주입해, 에이전트가 스스로 "이 하네스는
불완전하다"를 세션 첫 턴에 인지하고 사람에게 보고하게 한다.

### 3.5 배포: init.sh(렌더링 복사) + upgrade.sh(버전 스탬프 diff)

- `init.sh <target> <stack>`:
  1. 프로젝트명·기본 브랜치·게이트 명령(스택 기본값)을 치환해 계약·설정을 렌더링.
  2. `.claude/ .codex/ harness/(gates+hooks) docs/ 스캐폴드`를 **전부** 복사.
  3. `.harness/manifest`에 하네스 버전 + 설치 파일별 해시 기록.
  4. 마지막에 `doctor.sh` 자동 실행 — 통과해야 "설치 완료".
  결과물에는 메타 안내문·자리표시자가 0개다. 남은 수동 작업이 있으면 doctor가
  실패 상태로 명시한다.
- `upgrade.sh`: 설치본의 manifest 해시와 새 버전 비교. 로컬 무수정 파일은 자동
  갱신, 로컬 수정 파일은 3-way 충돌로 보고만 하고 덮어쓰지 않는다(안전 우선).

### 3.6 계약 다이어트

렌더링된 AGENTS.md는 **150줄 이내, 명령형, 프로젝트 고유 정보만**:

0. 프로젝트 사실(이름·스택·기본 브랜치·저장소 지도 링크)
1. 실행 루프 + Stage 0(브랜치/Jira) — 표 1개로 압축
2. 골든 원칙 단축 목록(상세는 principles.md 링크)
3. 게이트 명령(실행 가능한 실제 명령 — gate.sh가 실행하는 것과 동일 목록)
4. 경계·안전(secret, 파괴적 작업, 승인)

제거 대상: 4-pillar 철학 설명, 패리티 지도 상세, 템플릿 사용 안내, "When copied…"
류 메타 텍스트 → 전부 README.md(사람용)로 이동. 패리티는 §3.1의 생성 방식으로
해결되므로 에이전트에게 설명할 필요 자체가 줄어든다.

### 3.7 코드 컨벤션 계층 (일관성 사다리)

여러 작업자·에이전트 간 코드 불일치와 신규 프로젝트의 "모방할 맥락 없음" 문제를
효과 순서대로 4계층으로 해결한다. **위 계층에서 해결 가능한 규칙을 아래 계층
(산문)에 두지 않는다.**

1. **기계적 강제.** formatter(PostToolUse 훅 + gate)로 스타일 논쟁 제거. 린터로
   표현 가능한 규칙은 전부 린터로: 네이밍(naming-convention/checkstyle), 금지
   패턴(no-restricted-imports), 계층(boundaries/ArchUnit/import-linter). 스택
   팩이 설정을 제공한다.
2. **표본 코드(exemplar).** 스택 팩에 완성된 vertical slice 1개(도메인 하나를
   schema→repository→service→API(+UI)+테스트로 관통)를 포함해 init 시 함께
   설치. 에이전트는 기존 코드 모방 성향이 가장 강하므로, 빈 저장소에서 훈련
   데이터 평균 스타일로 회귀하는 문제(신규 프로젝트 맥락 부재)의 직접 해법.
3. **온디맨드 Skill.** 작업 유형별 절차 지식(new-api-endpoint,
   new-react-component, db-migration, testing-conventions 등)을 Skill로 정의 —
   해당 작업에서만 로드되어 계약 다이어트(§3.6)와 정합. 각 Skill은 표본 파일
   링크와 완료 기준(게이트 통과 조건)을 포함한다.
   - 단일 소스: `kit/skills/<name>/SKILL.md` (스택 공통) +
     `kit/stacks/<stack>/skills/` (스택 전용).
   - 렌더링: Claude → `.claude/skills/`, Codex(스킬 미지원) →
     `docs/conventions/*.md`로 렌더 + AGENTS.md에 "작업 유형 → 가이드" 표 1개로
     연결. 패리티는 §3.1과 동일하게 생성으로 보장.
4. **상시 산문.** AGENTS.md에는 린터로 못 잡고 모든 작업에 적용되는 규칙만
   남긴다(예: 주석은 WHY, 에러는 공용 예외 계층).

**확정된 스택별 컨벤션 (1층 배치):**

- **react-vite 팩 — prettier + eslint 확정.**
  - prettier: PostToolUse 훅으로 편집 즉시 포맷 + gate.sh에서 `prettier --check`.
  - eslint: `@typescript-eslint/naming-convention`, `no-restricted-imports`
    (공용 래퍼 우회한 axios/fetch 직접 import 금지), `eslint-plugin-boundaries`
    (레이어링) 설정을 팩에 포함. gate.sh의 lint 단계에서 실행.
- **spring-boot 팩 — Repository 레이어 단건 조회는 `Optional<T>` 반환 강제.**
  - ArchUnit 테스트로 기계적 강제: repository 패키지의 단건 조회 메서드
    (`findBy*`/`getBy*` 중 비컬렉션 반환)는 raw return type이 `Optional`이어야
    한다. null 반환 관례를 타입으로 봉쇄해 호출부의 null 처리 누락을 방지.
  - 컬렉션 조회는 Optional로 감싸지 않고 빈 컬렉션을 반환한다(`Optional<List>`
    금지) — 표준 관례를 기본값으로 채택. (확인 필요: 팀 의도가 컬렉션까지
    포함이면 규칙 조정.)
  - exemplar slice와 new-api-endpoint Skill이 동일 패턴을 표본으로 제시(2·3층),
    MyBatis 매퍼도 3.5+의 Optional 반환을 사용.

### 3.8 기각한 대안

- **전 구간 하드 블로킹(계획 없으면 편집 차단):** 한 줄 수정에도 계획을 강제해
  마찰 과다. 커밋 게이트가 최종선을 지키므로 기각.
- **git subtree/서브모듈 배포:** 전파는 확실하나 팀원 온보딩·프로젝트별 커스텀
  난이도 상승. 버전 스탬프 + upgrade 스크립트로 충분.
- **별도 상태 파일(.harness/state.json):** 계획 문서 frontmatter와 이중 진실이
  된다. 저장소가 진실(원칙 1)이므로 계획 문서 단일화.

## 4. Steps (small, reviewable)

각 단계는 독립 커밋. 순서는 의존 방향(단일 소스 → 렌더러 → 게이트 → 배포).

- [x] **Step 1 — kit/ 골격 + 단일 소스 이관.** `kit/agents/*.agent.md`,
      `kit/commands/*.cmd.md`(상태 전이 로직 포함해 재작성), `kit/settings/*`.
      기존 `.claude/.codex` 내용을 참고해 작성하되 복사가 아니라 재설계.
- [x] **Step 2 — scripts/render.sh.** kit → `.claude/agents|commands`,
      `.codex/agents`, settings 렌더링. `--check` 모드(diff 검사) 포함.
      하네스 저장소 자신의 `.claude/.codex`를 렌더 산출물로 교체.
- [x] **Step 3 — 게이트/훅.** `kit/gates/gate.sh`, `doctor.sh`,
      `check-docs.sh`(이관), `kit/hooks/session-start.sh`, `pre-edit-guard.sh`.
      settings.json에 훅을 **활성 상태로** 배선.
- [x] **Step 4 — 상태 기계.** `docs/plans/TEMPLATE.md`에 frontmatter 도입,
      루프 커맨드가 상태를 검사·전이하도록 커맨드 본문 확정(Step 1과 정합).
      기존 계획 문서 2건에 frontmatter 소급 추가.
- [x] **Step 5 — 계약 템플릿 + 스택 팩.** `kit/contract/AGENTS.md.tmpl`(≤150줄),
      `CLAUDE.md.tmpl`, `kit/stacks/{react-vite,spring-boot,fastapi}/`
      (gate.env 실제 명령, pre-commit, verify.yml, 레이어링·네이밍 린터 설정).
      react-vite: prettier+eslint 설정 확정본. spring-boot: ArchUnit 규칙
      (레이어링 + Repository 단건 조회 Optional 반환, §3.7). v1
      `harness/templates/*` 내용을 이관·정리.
- [x] **Step 5b — 컨벤션 계층(§3.7).** `kit/skills/` 공통 Skill 3종
      (testing-conventions, commit-and-pr, db-migration) + 스택별 Skill
      (new-api-endpoint 또는 new-react-component) 작성, render.sh에
      skills → `.claude/skills/` + `docs/conventions/` 렌더 추가,
      스택 팩별 exemplar vertical slice 1개(테스트 포함, 실제 통과하는 코드).
- [x] **Step 6 — 배포 스크립트.** `scripts/init.sh`(렌더링 복사 + manifest +
      doctor 자동 실행), `scripts/upgrade.sh`(해시 diff 갱신).
- [x] **Step 7 — 하네스 자신을 v2로 전환.** 자기 계약(AGENTS.md/CLAUDE.md)을
      템플릿에서 렌더링, README 재작성(철학·사용법 이동), v1 잔재
      (`harness/scripts/check-sync.sh`, `init-project.sh`, `harness/templates/`) 제거.
      pre-commit에 gate.sh 배선.
- [x] **Step 8 — 종단 검증 리허설.** fastapi 스택으로 스크래치 init 실행 — §5
      시나리오 통과. 편차 기록: (a) exemplar 테스트의 실제 실행은 대상 프로젝트
      툴체인(pytest/vitest/gradle) 의존이라 이 머신에서 미실행(doctor WARN이
      알려줌 — 확인 필요), (b) 소스 루트가 스택별로 달라(GATE_SRC_PATTERN)
      gate/가드에 설정화 반영, (c) 게이트 스택 명령은 리허설에서 비워 배관만 검증.

## 5. Verification

evaluator(별도 에이전트)가 다음을 실행·확인한다. 작성자는 셀프 인증하지 않는다.

1. **렌더 패리티:** `scripts/render.sh --check` 통과. kit의 에이전트 하나를 임의
   수정하면 실패로 전환되는지 확인(음성 테스트).
2. **doctor:** 하네스 저장소 자체에서 `doctor.sh` 통과. 자리표시자를 하나 심으면
   실패하는지 확인.
3. **이식 리허설:** 스크래치에 `init.sh /tmp/target fastapi` →
   (a) doctor 통과, (b) `.codex/`·게이트·훅 전부 존재, (c) AGENTS.md에 `{{`/`<…>`
   0건, (d) 내부 링크 전부 해석됨(check-docs).
4. **게이트 동작:** 이식 대상에서 (a) main 직접 커밋 시도 → 차단,
   (b) 계획 없이 `src/` 파일 커밋 시도 → 차단, (c) frontmatter approved 계획 +
   규칙 맞는 브랜치에서 커밋 → 통과.
5. **상태 주입:** session-start.sh 출력에 진행 중 계획·단계·브랜치가 포함되는지.
6. **문서 가드닝:** `check-docs.sh` 전체 통과.
7. **컨벤션 계층:** init된 프로젝트에 (a) `.claude/skills/`와 `docs/conventions/`가
   같은 내용으로 렌더되어 존재, (b) exemplar slice의 테스트가 실제로 통과,
   (c) Skill 본문의 표본 파일 링크가 해석됨(check-docs에 포함).

## 6. Rollback

- 전 작업이 워크트리 브랜치에서 진행되며 머지 전까지 main에 영향 없음.
- v1 구조는 git 히스토리에 보존 — 문제가 크면 브랜치 폐기로 즉시 복귀.
- 이식된 타 프로젝트는 upgrade.sh 적용 전까지 v1 설치본 그대로 동작(스탬프가
  없는 v1 설치본은 upgrade.sh가 "수동 재설치 필요"로 안내).
