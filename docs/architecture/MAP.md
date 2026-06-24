# Repo Map

> The agent's table of contents. Keep it current — an out-of-date map is worse than
> none. Update it in the same PR that moves or adds a top-level area.

## Where things live

| Area | Path | Notes |
| ---- | ---- | ----- |
| Harness contract | `AGENTS.md` / `CLAUDE.md` | single source of truth |
| Architecture & rules | `docs/architecture/` | principles, layering, this map |
| Plans (research→plan output) | `docs/plans/` | one file per task, kept after merge |
| Specs / designs | `docs/specs/` | bigger features |
| Decisions (ADRs) | `docs/decisions/` | why we chose X over Y |
| Cross-session memory | `memory/` | durable notes, gotchas, env quirks |
| Sub-agents | `.claude/agents/` | planner / implementer / evaluator / refactorer |
| Loop commands | `.claude/commands/` | /research /plan /execute /verify /harden |
| Stack templates | `harness/templates/` | react-vite, spring-boot, fastapi |

## Per-project source layout

> Replace this section with the real project layout when you scaffold. Example shapes
> are in the stack templates under `harness/templates/`.

```
<src layout goes here — see the matching template in harness/templates/>
```

## Key commands

```bash
# install   <…>
# dev       <…>
# build     <…>
# test      <…>   (see AGENTS.md §4 for the full verification set)
```
