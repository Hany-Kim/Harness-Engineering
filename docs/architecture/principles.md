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

## Tool parity (Claude ↔ Codex)

The harness drives two agents. `AGENTS.md` and the team global convention are **single
files** (Codex reads `AGENTS.md` natively; `CLAUDE.md` `@import`s it; the global file is
one symlinked source), so they can't drift. But agent specialization, loop commands, and
safety enforcement use **tool-specific formats**, so they are duplicated and *can* drift.

**Parity map — change one side, change its mirror in the same commit:**

| Shared rule          | Claude side                  | Codex side                              | Enforced by |
| -------------------- | ---------------------------- | --------------------------------------- | ----------- |
| Sub-agents           | `.claude/agents/*.md`        | `.codex/agents/*.toml`                  | `check-sync.sh` |
| Loop commands        | `.claude/commands/*.md`      | Codex prompts (TODO — dir unconfirmed)  | TODO |
| Irreversible-op gate | `settings.json` `ask` list   | `.codex/config.toml` `approval_policy`  | TODO |
| Contract / principles| `AGENTS.md`                  | `AGENTS.md` (same file)                 | single source |
| Team convention      | `~/.claude/CLAUDE.md`        | `~/.codex/AGENTS.md` (same symlink)     | single source |

**Mechanical check:** `harness/scripts/check-sync.sh` fails when `.claude/agents/*.md`
and `.codex/agents/*.toml` diverge in name, description, or instruction body. Wire it
into pre-commit and CI. Extend it as the TODO mirrors gain Codex-side files.

**Rule of thumb:** prefer putting a rule in `AGENTS.md` (single source) over duplicating
it into per-tool files. Only duplicate when the format genuinely requires it.

## Tech-debt hygiene (background sweeps)

Run `/harden` (or a scheduled Codex/Claude task) periodically to:
- scan for layering violations and lint suppressions,
- find untested public functions,
- grade modules against these principles and open small, targeted refactor PRs.

Keep each sweep's PRs small enough to review in one sitting — see the two-strike rule.
