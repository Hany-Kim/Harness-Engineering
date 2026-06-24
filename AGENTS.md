# AGENTS.md — Harness Contract

> This file is the **single source of truth** for any agent (Claude Code, Codex, …)
> working in this repository. The repo is the agent's only context — assume no
> external knowledge. `CLAUDE.md` imports this file, so both tools read the same contract.
>
> When copied into a real project, replace every `<…>` placeholder and delete sections
> that don't apply. Keep this file *short and dense* — link out to `docs/` for detail.

---

## Precedence (where rules come from)

Rules are layered. When they conflict, the higher one wins:

1. The explicit request in the current conversation.
2. This project's `AGENTS.md` / `CLAUDE.md` (and project code conventions).
3. **Team global convention** — `team/CLAUDE.global.md` in the harness, installed at
   `~/.claude/CLAUDE.md` (Claude Code) and `~/.codex/AGENTS.md` (Codex). Team-wide working
   style, safety, naming, language-level rules.
4. General framework recommendations.

Exception: security / auth / payments / DB / deploy / CI-CD / secrets / production data /
public API / destructive commands are always judged conservatively, regardless of layer.

---

## 0. Project at a glance

- **Name:** `<project-name>`
- **What it is:** `<one sentence>`
- **Stack:** `<react-vite | spring-boot | fastapi | …>` (see stack notes below)
- **Repo map:** see [`docs/architecture/MAP.md`](docs/architecture/MAP.md)
- **Golden principles:** see [`docs/architecture/principles.md`](docs/architecture/principles.md)

---

## 1. The execution loop (research → plan → execute → verify)

Every non-trivial task follows this loop. **Do not skip stages.** Each stage has a
home in the repo so work survives across sessions (filesystem memory, not chat history).

1. **Research** — Read before writing. Map the relevant code, existing patterns, and
   constraints. Output: a short findings note. (`/research`)
2. **Plan** — Write a plan to `docs/plans/<slug>.md` *before* editing code. Get it
   right on paper. (`/plan`)
3. **Execute** — Implement the plan in small, layer-respecting commits. (`/execute`)
4. **Verify** — A **separate** evaluator runs the checks and tests end-to-end. The
   author does not grade their own work. (`/verify`)

> Rule of thumb: if a change touches more than one file or one layer, it needs a plan.

## 2. The four pillars (how this harness works)

1. **Context architecture** — Information is *tiered*. This file is the index; detail
   lives in `docs/` and is pulled in only when relevant (progressive disclosure). Never
   dump everything into one prompt.
2. **Agent specialization** — Use scoped sub-agents with narrow tools:
   `planner`, `implementer`, `evaluator`, `refactorer` (see [`.claude/agents/`](.claude/agents/)).
3. **Persistent memory** — Durable facts go to the filesystem: `docs/` (specs, plans,
   decisions) and `memory/` (cross-session notes). Chat history is disposable.
4. **Structured execution** — The loop in §1, with gates between stages.

## 3. Golden principles (the rules)

These are enforced **mechanically** wherever possible (lint/CI/tests), not by asking
nicely. If you find yourself wanting to break one, stop and open a plan instead.

1. **Repository is the source of truth.** If it isn't in the repo, it isn't real.
2. **Respect the dependency direction.** Code flows one way:
   `Types → Config → Repository → Service → Runtime/API → UI`.
   A lower layer must never import a higher one. (Details in `docs/architecture/principles.md`.)
3. **Code is agent-readable.** Consistent structure, explicit names, comments that
   explain *why*. Optimize for the next agent that reads cold.
4. **Small, reversible changes.** One concern per PR. Prefer many small PRs.
5. **Constraints are mechanical.** New rule → encode it as a lint rule / test / type,
   not a paragraph nobody enforces.
6. **Tests are the contract.** A feature isn't done until a test proves it and the
   evaluator confirms it.
7. **Two-strike rule.** If an automated fix fails twice on the same problem, stop and
   escalate to a human. Never loop forever.
8. **Tool parity (Claude ↔ Codex).** Shared rules are duplicated across `.claude/*` and
   `.codex/*` because the tools use different formats. When you change one side, update
   its mirror in the **same** change. Drift is caught by `harness/scripts/check-sync.sh`
   (run in CI). Parity map: see `docs/architecture/principles.md`.

**Parity map:** `.claude/agents/*.md` mirrors `.codex/agents/*.toml`;
`.claude/commands/*.md` mirrors Codex prompts (**확인 필요:** Codex prompt directory is not
created until confirmed by official docs); `.claude/settings.json` `permissions.ask`
mirrors `.codex/config.toml` `approval_policy`. Any shared-rule change must update both
tool-specific mirrors in the **same commit**, and every mirror that can be checked must
be wired into pre-commit and CI.

## 4. Mechanical enforcement (run these — they gate every change)

> Replace with this project's real commands. The evaluator (`/verify`) runs all of them.

```bash
# format        <prettier / spotless / ruff format>
# lint          <eslint / checkstyle / ruff>
# typecheck     <tsc --noEmit / mypy>
# unit test     <vitest / junit / pytest>
# e2e test      <playwright>
# arch test     <dependency-direction / layering check>
```

A change is **not done** until: format clean, lint clean, types clean, unit + e2e green,
and the arch/layering check passes.

## 5. Working agreements

- **Read first.** Before editing a file, read it and its neighbours. Match local style.
- **Plan before multi-file changes.** See §1.
- **Never commit secrets.** Use env/`.env` (gitignored). See §7.
- **Don't widen scope.** Out-of-scope issues → note them, don't fix inline.
- **Ask only when blocked on a real decision.** Otherwise pick the sensible default and
  state it.
- **Branch, don't push to main** unless told. Conventional-commit messages.

## 6. Stack notes

Pick the matching template from [`harness/templates/`](harness/templates/) and inline
the relevant rules here when you scaffold a real project:

- **React (Vite + Zustand):** [`harness/templates/react-vite/AGENTS.md`](harness/templates/react-vite/AGENTS.md)
- **Spring Boot (MyBatis/JPA):** [`harness/templates/spring-boot/AGENTS.md`](harness/templates/spring-boot/AGENTS.md)
- **FastAPI (SQLAlchemy):** [`harness/templates/fastapi/AGENTS.md`](harness/templates/fastapi/AGENTS.md)

## 7. Boundaries & safety

- Secrets live in `.env` (gitignored) and the secret manager — never in code or docs.
- Destructive / outward-facing actions (deploys, migrations on prod, mass deletes,
  publishing) require explicit human approval each time.
- Migrations are forward-only and reviewed by a human.
