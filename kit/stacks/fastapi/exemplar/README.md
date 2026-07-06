# 표본 슬라이스 (exemplar) — note

이 폴더는 이 프로젝트의 **모방 대상**이다. 새 엔드포인트를 만들 때 이 슬라이스의
구조를 그대로 복제한다: `schemas → repositories → services → api` + 테스트.

- 새(빈) 프로젝트라면: `app/`·`tests/`를 프로젝트로 복사해 첫 표본으로 삼는다.
- 기존 프로젝트라면: 복사하지 말고 구조 표본으로만 참조한다.

단순화: 이 표본의 리포지토리는 인메모리 저장이다 — 실제 프로젝트에서는
`AsyncSession`(SQLAlchemy)을 주입받는 구현으로 바꾸되 **시그니처(단건 조회
`T | None`)와 계층 구조는 유지**한다. 레이어링은 import-linter가 강제한다
(docs/architecture/stack.md의 pyproject 계약 참조).
