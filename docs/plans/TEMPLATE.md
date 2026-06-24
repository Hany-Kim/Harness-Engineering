# Plan: <task title>

> Copy to `docs/plans/<slug>.md`. Fill this out **before** editing code (loop stage 2).
> This file is durable memory — keep it after the PR merges.

- **Status:** draft | approved | in-progress | done
- **Owner / driver:** <human>
- **Related:** <issue / spec / decision links>

## 1. Problem
What are we changing and why? One paragraph. Link the research findings.

## 2. Constraints & affected layers
Which layers does this touch (`Types → … → UI`)? Any golden principle at risk?

## 3. Approach
The chosen approach in a few sentences. Note alternatives rejected (and why).

## 4. Steps (small, reviewable)
- [ ] Step 1 — <file(s)>, one concern
- [ ] Step 2 — …
- [ ] Step N — tests for the above

## 5. Verification
How `/verify` will confirm this: which tests, which commands, expected observable
behaviour. (Author does not self-certify — the evaluator runs these.)

## 6. Rollback
How to revert safely if it goes wrong.
