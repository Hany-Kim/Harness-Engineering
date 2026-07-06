---
slug: <slug>
status: draft
branch: <type>/<JIRA-KEY>-<slug>
ticket: <JIRA-KEY | none>
updated: <YYYY-MM-DD>
---

# Plan: <task title>

> Copy to `docs/plans/<slug>.md`. Fill this out **before** editing code (loop stage 2).
> This file is durable memory — keep it after the PR merges.
>
> **frontmatter가 작업 상태의 진실이다.** 전이 규칙:
> `draft`(planner 작성) → `approved`(사람 승인 후에만) → `executing`(/execute 시작)
> → `verified`(/verify PASS 시 evaluator가 설정). 중단 시 `abandoned`.
> 커밋 게이트는 `branch:`가 현재 브랜치와 일치하고 status가 approved 이상인 계획이
> 없으면 `src/` 변경 커밋을 거부한다. SessionStart 훅이 이 상태를 매 세션 주입한다.

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
