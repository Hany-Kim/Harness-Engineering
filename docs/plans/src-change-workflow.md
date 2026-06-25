# Plan: src/ change workflow rules

- **Status:** done
- **Owner / driver:** 김주한 (rule author) + Claude
- **Related:** conversation request — 5-step workflow for any change under `src/`

## 1. Problem
Encode the user's mandatory workflow for every `src/` change (feature / bugfix /
refactor) into the harness contract so both Claude Code and Codex enforce it: plan-first,
worktree isolation, mandatory tests, a verification gate, and a confirmed-approver merge.

## 2. Constraints & affected layers
Harness docs/contract only — no product runtime code. Single-source in `AGENTS.md`
(no per-tool duplication, parity-safe). Decisions confirmed:
generalize default branch as `<default-branch>`; create root `ARCHITECTURE.md`;
file-size gate excluded; doc gardening = code↔doc sync (broken-link/path check).

## 3. Approach
Layer the 5 steps onto the existing loop (§1) and §1a rather than inventing a parallel
process. Add a concise `§1b` for `src/` changes, extend the §4 gate, add a root
`ARCHITECTURE.md` index, and make doc gardening mechanical with a `check-docs.sh` wired
into pre-commit/CI templates next to the existing parity check.

## 4. Steps
- [x] `ARCHITECTURE.md` (root) — reading-order index → `docs/architecture/*`.
- [x] `AGENTS.md` — new `§1b Changing src/ code` (5 steps); extend `§4` gate (build,
      doc gardening, parity); cross-ref in `§1a` (worktree).
- [x] `harness/scripts/check-docs.sh` — validate markdown link/path targets exist.
- [x] Stack templates — test-file conventions + `§1b` pointer (react / spring / fastapi).
- [x] Wire `check-docs.sh` into the 3 pre-commit configs and 3 CI workflows.

## 5. Verification
`harness/scripts/check-sync.sh` exits 0; `harness/scripts/check-docs.sh` exits 0;
`bash -n` clean on new scripts; manual diff review; `git grep` shows no leftover
hardcoded `main`/`master` in the new rule text (uses `<default-branch>`).

## 6. Rollback
Single branch `chore/src-change-workflow`; revert the branch / drop the commits. Docs
only — no runtime impact.
