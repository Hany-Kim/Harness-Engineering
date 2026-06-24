---
description: Background tech-debt sweep — grade the repo against the golden principles and open one small refactor.
argument-hint: <optional: area to focus on>
---

Use the **refactorer** sub-agent to run a hardening sweep${ARGUMENTS:+ focused on: $ARGUMENTS}.

1. Scan for deviations from `docs/architecture/principles.md`: layering violations, lint
   suppressions (`eslint-disable`, `# type: ignore`, `@SuppressWarnings`), dead code,
   untested public functions, duplication.
2. Report the top findings ranked by risk.
3. Pick **one** small, behaviour-preserving improvement, confirm test coverage (add a
   characterization test if missing), apply it, and prepare a small PR with a rationale
   that names the principle it restores.

Behaviour-preserving only — existing tests must stay green. One concern per PR.
