---
description: Loop stage 1 — read the codebase and report findings before any planning.
argument-hint: <topic / feature / bug>
---

Use the **planner** sub-agent (read-only) to research: **$ARGUMENTS**

- Read `AGENTS.md`, `docs/architecture/principles.md`, `docs/architecture/MAP.md`, and
  the code relevant to the topic. Check `docs/conventions/` and `docs/exemplar/` for
  the patterns this project already uses — findings should say "follow X", not invent.
- Map: which layers are touched, which existing patterns apply, which files matter,
  what constraints (tests, gates, tickets) exist.
- Output a short findings note in chat. If a plan will follow immediately, the note
  becomes §1 of `docs/plans/<slug>.md`.
- Read-only: no source edits, no plan yet.
