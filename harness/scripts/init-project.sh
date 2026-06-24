#!/usr/bin/env bash
# Scaffold this harness into a target project.
#
# Usage:
#   harness/scripts/init-project.sh <target-dir> <stack>
#     <stack> = react-vite | spring-boot | fastapi
#
# Copies the contract, docs scaffold, memory, and .claude config into the target,
# then drops the matching stack template alongside so you can inline it into AGENTS.md.
set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${1:?usage: init-project.sh <target-dir> <stack>}"
STACK="${2:?usage: init-project.sh <target-dir> <stack> (react-vite|spring-boot|fastapi)}"

TEMPLATE="$HARNESS_ROOT/harness/templates/$STACK/AGENTS.md"
[ -f "$TEMPLATE" ] || { echo "unknown stack: $STACK"; exit 1; }

mkdir -p "$TARGET"
echo "scaffolding harness into $TARGET (stack: $STACK)"

# Core contract + Claude Code config
cp "$HARNESS_ROOT/AGENTS.md"  "$TARGET/AGENTS.md"
cp "$HARNESS_ROOT/CLAUDE.md"  "$TARGET/CLAUDE.md"
cp -R "$HARNESS_ROOT/.claude" "$TARGET/.claude"

# Docs + memory scaffold (templates only)
mkdir -p "$TARGET/docs/architecture" "$TARGET/docs/plans" "$TARGET/docs/specs" \
         "$TARGET/docs/decisions" "$TARGET/memory"
cp "$HARNESS_ROOT/docs/architecture/principles.md" "$TARGET/docs/architecture/"
cp "$HARNESS_ROOT/docs/architecture/MAP.md"         "$TARGET/docs/architecture/"
cp "$HARNESS_ROOT/docs/plans/TEMPLATE.md"           "$TARGET/docs/plans/"
cp "$HARNESS_ROOT/docs/specs/TEMPLATE.md"           "$TARGET/docs/specs/"
cp "$HARNESS_ROOT/docs/decisions/TEMPLATE.md"       "$TARGET/docs/decisions/"
cp "$HARNESS_ROOT/memory/README.md"                 "$TARGET/memory/"

# Stack notes — drop next to the contract for you to inline into AGENTS.md §6
cp "$TEMPLATE" "$TARGET/docs/architecture/STACK-$STACK.md"

cat <<EOF

done. Next steps in $TARGET:
  1. Fill in the <…> placeholders in AGENTS.md (name, commands, layout).
  2. Inline docs/architecture/STACK-$STACK.md into AGENTS.md §6, then delete it.
  3. Wire the layering linter + verification commands from the stack notes into CI.
  4. Commit. Your harness is live for both Claude Code and Codex.
EOF
