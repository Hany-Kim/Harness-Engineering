---
name: commit-and-pr
description: 커밋 메시지 작성, 커밋 분할, PR/MR 생성 시 반드시 사용. conventional commit 규칙과 머지 절차.
---

# 커밋 / PR 컨벤션

## 커밋

- Conventional Commits: `<type>(scope?): 요약` — type ∈
  feat | fix | refactor | test | docs | chore | perf. 요약은 한국어.
- 커밋 하나 = 관심사 하나. 계획 문서의 Step 단위로 나눈다.
- 본문에는 WHY(무엇은 diff가 말해준다). 관련 계획/티켓을 언급한다.
- 게이트 우회 금지: `--no-verify`, `--no-gpg-sign`을 절대 쓰지 않는다. 게이트가
  실패하면 원인을 고친다 — 검사를 끄지 않는다.
- commit / push는 명시 요청·승인 하에서만. push는 작업 브랜치만.

## PR / MR

- 제목은 커밋 규칙과 동일. 본문에 반드시 포함:
  1. 계획 문서 링크(`docs/plans/<slug>.md`)와 티켓 키
  2. 변경 요약(파일이 아니라 행동 기준)
  3. `/verify` 결과 증거(실행한 명령 + 결과)
  4. 주의할 점(마이그레이션, 설정 변경, 롤백 방법)
- 머지 전 승인자가 누구인지 사람에게 확인한다. 셀프 머지 금지.
- 머지 후 계획 frontmatter가 `verified`인지 확인하고 작업을 종료한다.
