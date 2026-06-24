# CLAUDE.md

This project's harness contract lives in `AGENTS.md` so that **Claude Code and Codex
read the same source of truth**. The import below pulls it in for Claude Code.

@AGENTS.md

---

Claude-Code-specific notes (Codex ignores this section):

- Specialized sub-agents live in [`.claude/agents/`](.claude/agents/) — prefer the
  `planner` / `implementer` / `evaluator` / `refactorer` split over doing everything in
  one context.
- Loop commands live in [`.claude/commands/`](.claude/commands/): `/research`, `/plan`,
  `/execute`, `/verify`, `/harden`.
- Permissions & hooks (mechanical enforcement) are in
  [`.claude/settings.json`](.claude/settings.json).
