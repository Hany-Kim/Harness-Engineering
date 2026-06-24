---
description: Loop stage 3 — implement an approved plan in small, layer-respecting commits.
argument-hint: <plan slug, or path to docs/plans/*.md>
---

Use the **implementer** sub-agent to execute the plan: **$ARGUMENTS**

- Load the plan from `docs/plans/`. If there's no plan and this isn't trivial, stop and
  run `/plan` first.
- Work the steps in order, one concern per commit, reading each file before editing.
- Respect the dependency direction in `docs/architecture/principles.md`.
- Write/extend tests alongside the code. Check off steps in the plan as you go.
- Stay in scope; note out-of-scope issues rather than fixing them.
- Two-strike rule: if the same fix fails twice, stop and escalate.

Do **not** declare success — when done, hand off to `/verify`.
