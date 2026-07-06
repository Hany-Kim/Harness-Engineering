---
name: new-api-endpoint
description: FastAPI 엔드포인트나 서비스/리포지토리 함수를 추가·수정할 때 반드시 사용. 스키마-우선 생성 순서와 계층·DI 규칙.
---

# 엔드포인트 추가 절차 (FastAPI)

표본: `docs/exemplar/app/`의 note 슬라이스를 그대로 모방한다.

1. **스키마부터.** `app/schemas/<domain>.py`에 요청/응답 Pydantic 모델.
   raw dict를 반환하거나 받지 않는다 — 경계에서 검증하고 이후는 타입을 신뢰.
2. **Repository.** 쿼리/저장소 접근은 `app/repositories/`에만. 단건 조회는
   `T | None` 반환 — 호출부(서비스)가 None을 처리한다.
3. **Service.** 비즈니스 흐름은 `app/services/`. None → 도메인 예외 변환은
   여기서 한다. 라우터에 로직 금지(import-linter가 계층을 강제).
4. **Router.** `APIRouter` + `Depends` 주입. 모듈 전역에서 client/connection을
   직접 만들지 않는다. async 엔드포인트에서 블로킹 I/O 직접 호출 금지.
5. **타입.** 함수 인자/반환 타입 명시. 임시 `Any` 금지 — 불가피하면 이유/범위/제거
   조건을 주석으로.
6. **테스트 동반.** `tests/api/test_<domain>.py` — happy + 404/422 실패 경로.
   기준은 docs/conventions/testing-conventions.md.

## 완료 기준

- `harness/gates/gate.sh` 통과 (ruff format/check / mypy / lint-imports / pytest).
- 표본 슬라이스와 구조 동형 — 다르면 표본이 아니라 새 코드가 틀린 것이다.
