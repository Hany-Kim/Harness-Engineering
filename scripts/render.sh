#!/usr/bin/env bash
# kit/(단일 소스) → 도구별 산출물 렌더링. 패리티는 "비교"가 아니라 "생성"으로 보장한다.
# WHY: v1은 .claude/*와 .codex/*를 손으로 미러링하고 휴리스틱으로 비교했다(드리프트
# 가능). v2는 kit/에서 양쪽을 생성하므로 드리프트라는 문제 클래스가 사라진다.
#
# 관리 대상(통째로 재생성 — 직접 수정 금지, kit/을 고칠 것):
#   .claude/agents  .claude/commands  .claude/skills  .codex/agents
#   .claude/settings.json  .codex/config.toml
#   harness/gates  harness/hooks  docs/conventions
#
# 사용:
#   scripts/render.sh           # 렌더링해 산출물 갱신
#   scripts/render.sh --check   # 산출물이 kit과 일치하는지 검사만 (gate.sh가 호출)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" "${1:-}" <<'PY'
import re, sys, os, shutil, tempfile, pathlib

root = pathlib.Path(sys.argv[1])
check = (sys.argv[2] == "--check")
kit = root / "kit"
if not kit.is_dir():
    print("render: kit/ 없음 — 설치본(대상 프로젝트)에서는 렌더링하지 않는다")
    sys.exit(0)

def parse_front(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    fm = {}
    body = text
    if m:
        for ln in m.group(1).splitlines():
            k, _, v = ln.partition(":")
            fm[k.strip()] = v.strip()
        body = m.group(2)
    return fm, body

stage = pathlib.Path(tempfile.mkdtemp(prefix="harness-render-"))
outputs = {}  # rel path -> (content, executable)

def out(rel, content, exe=False):
    outputs[rel] = (content, exe)

# --- agents: kit/agents/*.agent.md → .claude/agents/*.md + .codex/agents/*.toml
agents_dir = kit / "agents"
if agents_dir.is_dir():
    for f in sorted(agents_dir.glob("*.agent.md")):
        text = f.read_text()
        fm, body = parse_front(text)
        name = fm.get("name") or f.name[: -len(".agent.md")]
        # Claude 쪽은 원본 포맷 그대로 (frontmatter 포함)
        out(f".claude/agents/{name}.md", text)
        desc = fm.get("description", "").replace('"', '\\"')
        body_toml = body.strip().replace('"""', '\\"\\"\\"')
        toml = (
            f"# 자동 생성: 원본 kit/agents/{f.name} — scripts/render.sh가 갱신한다. 직접 수정 금지.\n"
            f'name = "{name}"\n'
            f'description = "{desc}"\n'
            f'developer_instructions = """\n{body_toml}\n"""\n'
        )
        out(f".codex/agents/{name}.toml", toml)

# --- commands: kit/commands/*.cmd.md → .claude/commands/*.md
cmds_dir = kit / "commands"
if cmds_dir.is_dir():
    for f in sorted(cmds_dir.glob("*.cmd.md")):
        name = f.name[: -len(".cmd.md")]
        out(f".claude/commands/{name}.md", f.read_text())

# --- skills: kit/skills/<name>/ → .claude/skills/<name>/ + docs/conventions/<name>.md
skills_dir = kit / "skills"
if skills_dir.is_dir():
    for d in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
        sk = d / "SKILL.md"
        if not sk.is_file():
            continue
        text = sk.read_text()
        fm, body = parse_front(text)
        out(f".claude/skills/{d.name}/SKILL.md", text)
        for extra in sorted(d.iterdir()):
            if extra.is_file() and extra.name != "SKILL.md":
                out(f".claude/skills/{d.name}/{extra.name}", extra.read_text())
        conv = (
            f"<!-- 자동 생성: 원본 kit/skills/{d.name}/SKILL.md — scripts/render.sh가 갱신한다. "
            f"Claude는 같은 내용을 Skill로 자동 로드하고, Codex는 이 문서를 읽는다. -->\n\n"
            + body.lstrip()
        )
        out(f"docs/conventions/{d.name}.md", conv)

# --- settings
out(".claude/settings.json", (kit / "settings" / "settings.json").read_text())
out(".codex/config.toml", (kit / "settings" / "codex.config.toml").read_text())

# --- gates & hooks → harness/ (설치본과 동일한 경로를 자기 자신에게도 적용)
for src_dir, dst in [(kit / "gates", "harness/gates"), (kit / "hooks", "harness/hooks")]:
    if src_dir.is_dir():
        for f in sorted(src_dir.glob("*.sh")):
            out(f"{dst}/{f.name}", f.read_text(), exe=True)

# --- 스테이징에 쓰기
for rel, (content, exe) in outputs.items():
    p = stage / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    if exe:
        p.chmod(0o755)

# --- 관리 대상 경로의 현재 상태와 비교
managed_dirs = [
    ".claude/agents", ".claude/commands", ".claude/skills", ".codex/agents",
    "harness/gates", "harness/hooks", "docs/conventions",
]
managed_files = [".claude/settings.json", ".codex/config.toml"]

def files_under(base, reldir):
    d = base / reldir
    if not d.is_dir():
        return set()
    return {str(p.relative_to(base)) for p in d.rglob("*") if p.is_file()}

diffs = []
for rel in sorted(outputs):
    cur = root / rel
    if not cur.exists():
        diffs.append(f"missing: {rel}")
    elif cur.read_text() != outputs[rel][0]:
        diffs.append(f"stale:   {rel}")
for d in managed_dirs:
    extras = files_under(root, d) - set(outputs)
    for e in sorted(extras):
        diffs.append(f"extra:   {e} (kit에 원본 없음 — kit으로 옮기거나 삭제)")

if check:
    shutil.rmtree(stage, ignore_errors=True)
    if diffs:
        print("RENDER CHECK FAILED — kit/과 산출물이 어긋남:")
        for d in diffs:
            print(f"  - {d}")
        print("고치기: scripts/render.sh 실행 후 산출물을 같은 커밋에 포함")
        sys.exit(1)
    print(f"render check OK: {len(outputs)}개 산출물이 kit/과 일치")
    sys.exit(0)

# --- 적용: 관리 디렉터리는 통째로 교체, 관리 파일은 덮어쓰기
for d in managed_dirs:
    target = root / d
    if target.is_dir():
        shutil.rmtree(target)
for rel, (content, exe) in outputs.items():
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    if exe:
        p.chmod(0o755)
shutil.rmtree(stage, ignore_errors=True)
print(f"render OK: {len(outputs)}개 산출물 갱신")
PY
