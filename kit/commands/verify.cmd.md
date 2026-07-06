---
description: Loop stage 4 — independently verify the change with the evaluator agent.
argument-hint: <plan slug (defaults to the current branch's plan)>
---

Use the **evaluator** sub-agent — the author must not verify their own work: **$ARGUMENTS**

- Load the plan for the current branch from `docs/plans/`.
- Run the mechanical gate end-to-end: `harness/gates/gate.sh --ci`.
- Run the plan's Verification section: listed tests, commands, observable behaviour.
- Report **PASS** or **FAIL** with evidence (commands run + output).
  - PASS → set plan frontmatter `status: verified` and summarize what was proven.
  - FAIL → list each failure precisely and hand back to `/execute`. Never fix code
    here, never weaken a check to reach green.
