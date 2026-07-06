#!/usr/bin/env bash
# 하네스 설치(렌더링 복사 + 버전 스탬프) / 갱신(--upgrade).
# WHY: v1 이식 실패의 직접 원인은 "반쪽 복사"(Codex 설정·게이트 누락)와 자리표시자
# 잔존이었다. v2 init은 전체를 렌더링해 복사하고, manifest(버전+해시)를 남기며,
# 마지막에 doctor로 설치 완결성을 검증한다 — 통과해야 설치 완료다.
#
# 사용:
#   scripts/init.sh <target-dir> <stack> [project-name] [default-branch]
#     <stack> = react-vite | spring-boot | fastapi
#   scripts/init.sh --upgrade <target-dir>
#     (.harness/manifest의 stack/이름/브랜치로 재렌더링해 갱신.
#      로컬 수정 파일은 덮어쓰지 않고 <file>.harness-new 로 보고한다.)
set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE=init
if [ "${1:-}" = "--upgrade" ]; then
  MODE=upgrade
  shift
fi
TARGET="${1:?usage: init.sh <target-dir> <stack> | init.sh --upgrade <target-dir>}"
STACK="${2:-}"
NAME="${3:-}"
BRANCH="${4:-}"

# 산출물이 kit과 어긋난 상태로 설치하면 드리프트가 전파된다 — 먼저 렌더링.
"$HARNESS_ROOT/scripts/render.sh" >/dev/null

python3 - "$HARNESS_ROOT" "$MODE" "$TARGET" "$STACK" "$NAME" "$BRANCH" <<'PY'
import hashlib, pathlib, re, sys

root = pathlib.Path(sys.argv[1])
mode = sys.argv[2]
target = pathlib.Path(sys.argv[3]).resolve()
stack = sys.argv[4]
name = sys.argv[5]
branch = sys.argv[6]

version = (root / "VERSION").read_text().strip()
manifest_path = target / ".harness" / "manifest"

# --- upgrade 모드: manifest에서 설치 변수 복원
old_hashes = {}
if mode == "upgrade":
    if not manifest_path.is_file():
        sys.exit(f"upgrade 불가: {manifest_path} 없음 — v1 설치본이거나 init.sh로 설치되지 않았다. 신규 init을 권장.")
    meta = {}
    in_files = False
    for ln in manifest_path.read_text().splitlines():
        if ln.strip() == "--":
            in_files = True
            continue
        if not in_files and "=" in ln:
            k, _, v = ln.partition("=")
            meta[k.strip()] = v.strip()
        elif in_files and ln.strip():
            h, _, p = ln.partition("  ")
            old_hashes[p.strip()] = h.strip()
    stack = stack or meta.get("stack", "")
    name = name or meta.get("project_name", "")
    branch = branch or meta.get("default_branch", "")

stack_dir = root / "kit" / "stacks" / stack
if not stack_dir.is_dir():
    known = ", ".join(sorted(p.name for p in (root / "kit" / "stacks").iterdir() if p.is_dir()))
    sys.exit(f"알 수 없는 스택: '{stack}' (가능: {known})")

name = name or target.name
branch = branch or "main"

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

# --- 스택 Skill → 계약 표(§4)에 넣을 행
stack_skills = []
skills_src = stack_dir / "skills"
if skills_src.is_dir():
    for d in sorted(p for p in skills_src.iterdir() if p.is_dir()):
        if (d / "SKILL.md").is_file():
            stack_skills.append(d.name)
guide_rows = "\n".join(
    f"| {n} | [docs/conventions/{n}.md](docs/conventions/{n}.md) |" for n in stack_skills
)

subst = {
    "PROJECT_NAME": name,
    "STACK": stack,
    "DEFAULT_BRANCH": branch,
    "HARNESS_VERSION": version,
    "STACK_GUIDE_ROWS": guide_rows,
}

def render(text):
    for k, v in subst.items():
        text = text.replace("{{" + k + "}}", v)
    return text

# --- 설치 맵 구성: relpath -> (content, executable)
install = {}

def add(rel, content, exe=False):
    install[rel] = (render(content), exe)

def add_tree(src_dir, dst_prefix):
    for p in sorted(src_dir.rglob("*")):
        if p.is_file():
            rel = f"{dst_prefix}/{p.relative_to(src_dir)}"
            add(rel, p.read_text(), exe=p.suffix == ".sh")

# 계약
add("AGENTS.md", (root / "kit/contract/AGENTS.md.tmpl").read_text())
add("CLAUDE.md", (root / "kit/contract/CLAUDE.md.tmpl").read_text())

# 렌더 산출물 (하네스 저장소의 관리 디렉터리에서 그대로)
for d in [".claude/agents", ".claude/commands", ".claude/skills", ".codex/agents",
          "harness/gates", "harness/hooks", "docs/conventions"]:
    src = root / d
    if src.is_dir():
        add_tree(src, d)
add(".claude/settings.json", (root / ".claude/settings.json").read_text())
add(".codex/config.toml", (root / ".codex/config.toml").read_text())

# 스택 팩: gate.env, stack.md, CI, pre-commit, exemplar, 스택 skill(+conventions 렌더)
add("harness/gate.env", (stack_dir / "gate.env").read_text())
add("docs/architecture/stack.md", (stack_dir / "stack.md").read_text())
add(".github/workflows/verify.yml", (stack_dir / "verify.yml").read_text())
add(".pre-commit-config.yaml", (stack_dir / ".pre-commit-config.yaml").read_text())
if (stack_dir / "exemplar").is_dir():
    add_tree(stack_dir / "exemplar", "docs/exemplar")
for n in stack_skills:
    sk = skills_src / n / "SKILL.md"
    text = sk.read_text()
    fm, body = parse_front(text)
    add(f".claude/skills/{n}/SKILL.md", text)
    add(
        f"docs/conventions/{n}.md",
        f"<!-- 자동 생성: 하네스 스택 팩 {stack}/skills/{n} — upgrade로 갱신된다 -->\n\n" + body.lstrip(),
    )

# 문서 스캐폴드
add("docs/architecture/principles.md", (root / "docs/architecture/principles.md").read_text())
add("docs/plans/TEMPLATE.md", (root / "docs/plans/TEMPLATE.md").read_text())
add("docs/specs/TEMPLATE.md", (root / "docs/specs/TEMPLATE.md").read_text())
add("docs/decisions/TEMPLATE.md", (root / "docs/decisions/TEMPLATE.md").read_text())
add("memory/README.md", (root / "memory/README.md").read_text())
add("docs/architecture/MAP.md", f"""# 저장소 지도 — {name}

> 목차 역할. 구조가 바뀌면 이 문서를 같은 커밋에서 갱신한다(문서 가드닝이 링크를 검사).

- 계약: [AGENTS.md](../../AGENTS.md) · 원칙: [principles.md](principles.md) · 스택: [stack.md](stack.md)
- 소스 레이아웃: [stack.md](stack.md)의 Layout을 따른다. 표본: [docs/exemplar/](../exemplar/)
- 계획(작업 상태): [docs/plans/](../plans/) · 결정: [docs/decisions/](../decisions/)
- 하네스: harness/(게이트·훅), .claude/, .codex/ — 직접 수정 금지(upgrade로 갱신)

<!-- 프로젝트 고유 모듈/도메인 지도를 아래에 추가할 것 -->
""")

def sha(content: str) -> str:
    return hashlib.sha256(content.encode()).hexdigest()

# --- 설치 실행
installed, skipped_same, conflicts = [], [], []
for rel, (content, exe) in sorted(install.items()):
    dest = target / rel
    if dest.exists():
        cur = dest.read_text()
        if cur == content:
            skipped_same.append(rel)
            installed.append(rel)  # manifest에는 포함
            continue
        if mode == "upgrade" and old_hashes.get(rel) == sha(cur):
            pass  # 로컬 무수정 → 덮어쓰기
        else:
            side = dest.with_name(dest.name + ".harness-new")
            side.parent.mkdir(parents=True, exist_ok=True)
            side.write_text(content)
            conflicts.append(rel)
            continue
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content)
    if exe:
        dest.chmod(0o755)
    installed.append(rel)

# --- manifest 기록 (충돌 파일은 이전 해시 유지 → 다음 upgrade에서 재감지)
manifest_path.parent.mkdir(parents=True, exist_ok=True)
lines = [
    f"harness_version={version}",
    f"stack={stack}",
    f"project_name={name}",
    f"default_branch={branch}",
    "--",
]
for rel in sorted(set(installed) | set(conflicts)):
    if rel in conflicts and rel in old_hashes:
        lines.append(f"{old_hashes[rel]}  {rel}")
    elif rel in install:
        lines.append(f"{sha(install[rel][0])}  {rel}")
manifest_path.write_text("\n".join(lines) + "\n")

print(f"{mode} 완료: {len(installed)}개 설치/갱신, {len(skipped_same)}개 동일, 충돌 {len(conflicts)}건")
for c in conflicts:
    print(f"  충돌(로컬 수정 보존): {c} — 새 버전은 {c}.harness-new 로 저장됨. 비교 후 수동 병합할 것.")
PY

# --- git pre-commit 심 설치 (pre-commit 프레임워크 없이도 게이트가 걸리게)
if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  HOOK_FILE=$(git -C "$TARGET" rev-parse --git-path hooks/pre-commit)
  # 절대경로화 (rev-parse가 상대경로를 줄 수 있음)
  case "$HOOK_FILE" in /*) ;; *) HOOK_FILE="$TARGET/$HOOK_FILE" ;; esac
  if [ -f "$HOOK_FILE" ] && ! grep -q 'gate\.sh' "$HOOK_FILE"; then
    echo "주의: 기존 pre-commit 훅이 있어 덮어쓰지 않음 — harness/gates/gate.sh 호출을 수동으로 추가할 것: $HOOK_FILE"
  else
    mkdir -p "$(dirname "$HOOK_FILE")"
    printf '#!/bin/sh\n# harness gate — init.sh가 설치. gate.sh가 없으면 통과(브랜치에 아직 없는 경우).\n[ -x harness/gates/gate.sh ] && exec harness/gates/gate.sh\nexit 0\n' > "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    echo "pre-commit → harness/gates/gate.sh 배선 완료"
  fi
else
  echo "주의: $TARGET 는 git 저장소가 아님 — git init 후 scripts/init.sh --upgrade 또는 doctor 안내로 훅을 설치할 것"
fi

# --- 설치 완결성 검증: doctor 통과가 곧 "설치 완료"의 정의다
echo ""
echo "doctor 실행:"
if (cd "$TARGET" && bash harness/gates/doctor.sh); then
  echo ""
  echo "설치 완료. 다음 단계: 프로젝트 툴체인(doctor WARN 항목) 설치 → 첫 /plan 부터 루프 시작."
else
  echo ""
  echo "설치가 불완전하다(위 doctor FAIL 참조). 고친 뒤 다시 doctor를 실행할 것." >&2
  exit 1
fi
