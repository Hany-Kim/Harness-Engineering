# Golden Principles & Layering

The non-negotiable rules of this codebase. `AGENTS.md` §3 is the short list; this file
is the detail an agent pulls in when it needs to reason about *why* and *how to enforce*.

## Dependency direction (layering)

Code flows in **one direction only**. A module may import from its own layer or any
layer to its left, **never** to its right.

```
Types  →  Config  →  Repository  →  Service  →  Runtime/API  →  UI
```

| Layer          | Owns                                              | May import        |
| -------------- | ------------------------------------------------- | ----------------- |
| **Types**      | DTOs, domain models, schemas, enums               | (nothing)         |
| **Config**     | env parsing, constants, DI wiring                 | Types             |
| **Repository** | DB/Redis access, queries (MyBatis/JPA/SQLAlchemy) | Types, Config     |
| **Service**    | business logic, transactions, orchestration       | ↑ + Repository    |
| **Runtime/API**| controllers, routers, request/response handling   | ↑ + Service       |
| **UI**         | React components, stores, hooks                   | ↑ + API client    |

**Why:** one-way flow makes any change locally reasonable — an agent editing a Service
never has to understand the UI, and a Repository change can't silently depend on a
controller. This is what lets an agent work correctly with partial context.

**How it's enforced (mechanical, not vibes):**
- TS/React: `eslint-plugin-boundaries` or `import/no-restricted-paths`.
- Spring Boot: ArchUnit layered-architecture test in `src/test`.
- FastAPI/Python: `import-linter` contracts (`importlinter` in CI).

If the linter can't yet express a rule, the rule does not exist. Add the linter first.

## Golden principles (expanded)

1. **Repository is the source of truth.** Decisions go in `docs/decisions/`, plans in
   `docs/plans/`, durable cross-session facts in `memory/`. "I remember we agreed…" is
   not a source — the file is.

2. **Agent-readable code.** Names say what; comments say why. No clever one-liners that
   need archaeology. A function should be understandable by an agent that has read only
   that file and its imports.

3. **Small, reversible changes.** One concern per PR. If a plan has independent parts,
   ship them as separate PRs. Reversibility > cleverness.

4. **Constraints are mechanical.** Every recurring "please don't do X" must become a
   lint rule, a type, or a test. Prose rules rot; CI doesn't.

5. **Tests are the contract.** New behaviour ships with a test. Bug fixes ship with a
   regression test that fails before and passes after.

6. **Two-strike rule.** Automated fix fails twice on the same root cause → stop, write
   what you tried to the plan/issue, escalate to a human. No infinite retry loops.

7. **Staged autonomy.** Agents earn scope through gates: research is read-only; planning
   produces a doc a human can skim; execution is small commits; verification is done by
   a *different* agent. Don't collapse the stages.

## Tool parity (Claude ↔ Codex) — 생성으로 보장한다

v2부터 패리티는 "비교 검사"가 아니라 **생성**이다. 단일 소스는 `kit/`이고,
`scripts/render.sh`가 양쪽 도구의 산출물을 만들며, 게이트의 `render.sh --check`가
드리프트를 커밋 시점에 차단한다. 손으로 미러를 맞추는 규칙은 존재하지 않는다 —
산출물을 직접 고치지 말고 kit을 고쳐라.

| 산출물 | 원본 (단일 소스) |
| --- | --- |
| `.claude/agents/*.md` + `.codex/agents/*.toml` | `kit/agents/*.agent.md` |
| `.claude/commands/*.md` | `kit/commands/*.cmd.md` |
| `.claude/skills/*` + `docs/conventions/*.md` | `kit/skills/*` (+ 스택 팩 `skills/`) |
| `.claude/settings.json` + `.codex/config.toml` | `kit/settings/*` |
| `harness/gates/*` + `harness/hooks/*` | `kit/gates/*` + `kit/hooks/*` |
| 계약 / 원칙 | `AGENTS.md` (Codex가 원생으로 읽고 `CLAUDE.md`가 @import) |
| 팀 전역 컨벤션 | `team/CLAUDE.global.md` (양쪽 전역 경로에 동일 설치) |

Codex에는 슬래시 커맨드·Skill·훅의 대응물이 없다. 그 간극은 두 가지로 메운다:
(1) 루프와 컨벤션 표를 `AGENTS.md`에 담아 Codex가 절차를 읽게 하고(커맨드의 대체),
Skill 내용은 `docs/conventions/*.md`로 렌더링해 링크한다. (2) 절차 **강제**는 도구
무관 계층인 pre-commit/CI의 `harness/gates/gate.sh`가 담당한다 — Codex도 커밋
시점에는 같은 게이트를 통과해야 한다. (확인 필요: Codex 프롬프트 디렉터리가 공식
문서로 확인되면 `kit/commands/`에서 해당 포맷도 렌더링하도록 render.sh를 확장.)

**Rule of thumb:** 규칙은 가능하면 `AGENTS.md`(단일 파일)에, 도구별 포맷이 정말
필요할 때만 `kit/`에 — 그리고 그 경우에도 원본은 하나다.

## Tech-debt hygiene (background sweeps)

Run `/harden` (or a scheduled Codex/Claude task) periodically to:
- scan for layering violations and lint suppressions,
- find untested public functions,
- grade modules against these principles and open small, targeted refactor PRs.

Keep each sweep's PRs small enough to review in one sitting — see the two-strike rule.
