#!/usr/bin/env bash
# 설치본 갱신 — .harness/manifest(버전+해시) 기반.
# 로컬에서 수정하지 않은 하네스 파일만 자동 갱신하고, 수정된 파일은 덮어쓰지 않고
# <file>.harness-new 로 보고한다(안전 우선). 실제 로직은 init.sh --upgrade.
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/init.sh" --upgrade "${1:?usage: upgrade.sh <target-dir>}"
