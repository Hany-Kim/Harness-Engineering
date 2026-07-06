# CLAUDE.md

이 프로젝트의 계약은 `AGENTS.md` 하나다 — Claude Code와 Codex가 같은 원본을 읽는다.

@AGENTS.md

---

Claude Code 전용 (Codex는 이 섹션을 무시한다):

- 서브에이전트: `.claude/agents/` — planner / implementer / evaluator / refactorer.
  **원본은 `kit/agents/`** — 수정은 kit에서, 반영은 `scripts/render.sh`.
- 루프 커맨드: `/research` `/plan` `/execute` `/verify` `/harden`
  (원본: `kit/commands/`)
- 컨벤션 Skill: `.claude/skills/` (원본: `kit/skills/`)
- 훅: `harness/hooks/` — SessionStart가 진행 중 작업을 주입한다. 훅이 차단하면
  우회하지 말고 안내를 따를 것. (원본: `kit/hooks/`)
