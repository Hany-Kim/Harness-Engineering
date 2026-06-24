#!/usr/bin/env bash
# Tool-parity check: the harness duplicates shared rules across Claude (.claude/*) and
# Codex (.codex/*) because the two tools use different file formats. This script fails
# when those mirrors drift, so the parity rule (AGENTS.md §3) is enforced mechanically
# rather than by hope. Wire it into pre-commit / CI.
#
# Currently checks: .claude/agents/<name>.md  <->  .codex/agents/<name>.toml
#   - same set of agent names
#   - matching description
#   - matching instruction body (markdown body == developer_instructions)
#
# Other mirrors that cannot yet be checked precisely are reported as "확인 필요" so
# they stay visible without inventing unsupported Codex files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
claude_dir = root / ".claude" / "agents"
codex_dir = root / ".codex" / "agents"
claude_settings = root / ".claude" / "settings.json"
codex_config = root / ".codex" / "config.toml"

def norm(s: str) -> str:
    # compare on trimmed content with normalised trailing whitespace per line
    lines = [ln.rstrip() for ln in s.strip().splitlines()]
    return "\n".join(lines)

def parse_md(p: pathlib.Path):
    text = p.read_text()
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return None, None, None
    fm, body = m.group(1), m.group(2)
    name = re.search(r"^name:\s*(.+)$", fm, re.M)
    desc = re.search(r"^description:\s*(.+)$", fm, re.M)
    return (name.group(1).strip() if name else None,
            desc.group(1).strip() if desc else None,
            norm(body))

def parse_toml(p: pathlib.Path):
    text = p.read_text()
    name = re.search(r'^name\s*=\s*"(.*)"\s*$', text, re.M)
    desc = re.search(r'^description\s*=\s*"(.*)"\s*$', text, re.M)
    instr = re.search(r'developer_instructions\s*=\s*"""(.*?)"""', text, re.S)
    return (name.group(1).strip() if name else None,
            desc.group(1).strip() if desc else None,
            norm(instr.group(1)) if instr else None)

errors = []

claude = {p.stem: parse_md(p) for p in sorted(claude_dir.glob("*.md"))} if claude_dir.is_dir() else {}
codex = {p.stem: parse_toml(p) for p in sorted(codex_dir.glob("*.toml"))} if codex_dir.is_dir() else {}

only_claude = set(claude) - set(codex)
only_codex = set(codex) - set(claude)
for n in sorted(only_claude):
    errors.append(f"agent '{n}': exists in .claude/agents but missing .codex/agents/{n}.toml")
for n in sorted(only_codex):
    errors.append(f"agent '{n}': exists in .codex/agents but missing .claude/agents/{n}.md")

for n in sorted(set(claude) & set(codex)):
    cn, cd, cb = claude[n]
    tn, td, tb = codex[n]
    if cn != tn:
        errors.append(f"agent '{n}': name mismatch ('{cn}' vs '{tn}')")
    if cd != td:
        errors.append(f"agent '{n}': description out of sync")
    if cb != tb:
        errors.append(f"agent '{n}': instruction body out of sync")

if claude_settings.exists():
    if not codex_config.exists():
        errors.append(".claude/settings.json exists but .codex/config.toml is missing")
    else:
        config_text = codex_config.read_text()
        sandbox = re.search(r'^sandbox_mode\s*=\s*"([^"]+)"\s*$', config_text, re.M)
        policy = re.search(r'^approval_policy\s*=\s*"([^"]+)"\s*$', config_text, re.M)
        if not sandbox or sandbox.group(1) != "workspace-write":
            errors.append(".codex/config.toml: sandbox_mode must mirror the safe workspace-write boundary")
        if not policy or policy.group(1) not in {"on-request", "untrusted"}:
            errors.append(".codex/config.toml: approval_policy must be conservative (on-request or untrusted)")

if not claude and not codex:
    print("parity: no agents found to compare")

if errors:
    print("PARITY CHECK FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"parity OK: {len(set(claude) & set(codex))} agent mirror(s) in sync")

# Informational: other mirrors not yet checkable.
if claude_settings.exists() and codex_config.exists():
    print("확인 필요: settings.json permissions.ask <-> .codex/config.toml approval_policy is checked only at policy level")
if (root / ".claude" / "commands").exists() and not (root / ".codex" / "prompts").exists():
    print("확인 필요: .claude/commands/*.md <-> Codex prompts mirror is not checked; Codex prompt directory is unconfirmed")
PY
