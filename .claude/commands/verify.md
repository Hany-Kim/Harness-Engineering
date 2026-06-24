---
description: Loop stage 4 — independently verify the change with the evaluator agent.
argument-hint: <plan slug, or leave blank for current diff>
---

Use the **evaluator** sub-agent to verify: **$ARGUMENTS**

Run the full mechanical gate from `AGENTS.md` §4 (format, lint, typecheck, unit, e2e,
arch/layering) and capture real output. Then confirm the observable behaviour the plan
promised actually happens — run the app / hit the endpoint / drive the UI, don't just
trust green tests.

Return a verdict: **PASS** or **FAIL** with evidence. For FAIL, list each problem with
file:line and what's expected; hand failures back for fixing — do not fix them in this
step. Be adversarial; default to FAIL when uncertain.
