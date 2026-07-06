---
description: Loop stage 3 — implement an approved plan in small, layer-respecting commits.
argument-hint: <plan slug, or path to docs/plans/*.md>
---

Use the **implementer** sub-agent to execute the plan: **$ARGUMENTS**

Preconditions — verify before any edit; if unmet, refuse and route to `/plan`:
- The plan file exists, its frontmatter `branch` matches the current git branch, and
  `status` is `approved` (or `executing` when resuming).
- The current branch is not protected.

Then:
- Set `status: executing` (refresh `updated:`). Work the steps in order, one concern
  per commit, reading each file before editing. Tests ship with the code.
- Match `docs/exemplar/` structure and follow `docs/conventions/` for the task type.
- Check off steps in the plan as you go; record deviations in the plan file.
- Stay in scope; note out-of-scope issues rather than fixing them.
- Two-strike rule: if the same fix fails twice, stop and escalate.

Do **not** declare success and do not set `status: verified` — hand off to `/verify`.
