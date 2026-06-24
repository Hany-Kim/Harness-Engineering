---
description: Loop stage 1 — read the codebase and report findings before any planning.
argument-hint: <what you're about to work on>
---

Research the codebase for this task: **$ARGUMENTS**

You are read-only. Do not edit anything. Produce a concise findings note covering:

1. Which files/modules are relevant and how they currently work.
2. Existing patterns and conventions to follow (cite file:line).
3. Which layers (`Types → Config → Repository → Service → Runtime/API → UI`) the change
   will touch.
4. Constraints from `AGENTS.md` and `docs/architecture/principles.md` that apply.
5. Open questions / risks.

Read first, infer second. End by recommending whether this needs a full plan (`/plan`)
or is small enough to execute directly.
