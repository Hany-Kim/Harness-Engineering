---
description: Loop stage 2 — write a plan to docs/plans/ before editing code.
argument-hint: <task title / slug>
---

Use the **planner** sub-agent to produce a plan for: **$ARGUMENTS**

Write the plan to `docs/plans/<slug>.md` from `docs/plans/TEMPLATE.md`. It must:

- State the problem and the affected layers.
- Break work into small, independently reviewable steps that respect the dependency
  direction.
- Specify exactly how `/verify` will confirm success (tests + observable behaviour).
- List risks and a rollback.

Do not edit source code in this step. Stop after the plan and let me skim it before
`/execute`.
