---
description: Background tech-debt sweep — grade the repo against the golden principles and land one small, behaviour-preserving refactor.
argument-hint: [area or path to focus on]
---

Use the **refactorer** sub-agent for a hygiene sweep: **$ARGUMENTS**

- Scan for layering violations, lint/type suppressions, untested public code, dead
  code, and drift from `docs/conventions/` and `docs/exemplar/`.
- Pick the single smallest, most valuable, behaviour-preserving fix; keep tests green
  (add characterization tests first where coverage is missing).
- Anything larger than a mechanical cleanup: write it up as a candidate plan in
  `docs/plans/` (status: draft) instead of fixing inline.
- Finish with a ranked list of what remains.
