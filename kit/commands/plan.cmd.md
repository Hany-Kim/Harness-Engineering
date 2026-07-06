---
description: Loop stage 2 — write a plan with state frontmatter to docs/plans/ before editing code.
argument-hint: <task title / slug>
---

Use the **planner** sub-agent to produce a plan for: **$ARGUMENTS**

Write `docs/plans/<slug>.md` from `docs/plans/TEMPLATE.md`. Requirements:

- Fill the YAML frontmatter: `slug`, `status: draft`, `branch` (the work branch — if
  still on a protected branch, decide the branch per AGENTS.md Stage 0 first),
  `ticket` (Jira key or `none`), `updated` (today).
- State the problem and affected layers. Steps must be small, independently
  reviewable, and respect the dependency direction.
- Specify exactly how `/verify` will confirm success: tests + observable behaviour.
- List risks and a rollback path.

Do not edit source code in this stage. Stop after writing: the plan stays
`status: draft` until the human approves it (then set `status: approved`). The commit
gate rejects `src/` changes on this branch until an approved plan exists.
