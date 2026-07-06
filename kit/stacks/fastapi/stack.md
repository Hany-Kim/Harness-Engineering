# Stack: FastAPI (SQLAlchemy) + Python

이 문서는 이 프로젝트의 스택 레이아웃과 기계적 강제 설정의 상세다.
(AGENTS.md §0에서 링크됨 — 규칙 요약은 AGENTS.md가 우선)

## Layout & layering

```
app/
  schemas/       # Pydantic 모델 (요청/응답)                     (Types)
  models/        # SQLAlchemy ORM 모델                           (Types)
  core/          # settings, DI, security                        (Config)
  repositories/  # DB/Redis 접근 — 쿼리는 여기서만                (Repository)
  services/      # 비즈니스 로직, 트랜잭션 오케스트레이션           (Service)
  api/           # 라우터/엔드포인트                              (Runtime/API)
  main.py        # 앱 배선
```

방향: `schemas/models → core → repositories → services → api`.
라우터는 서비스에 의존(`Depends`)하고 리포지토리를 직접 만지지 않는다.
SQL은 `repositories/`에만 존재한다.

## 기계적 강제 (컨벤션 사다리 1층)

- **포맷+린트: ruff** (`ruff format --check .`, `ruff check .`).
  편집 즉시 훅(post-edit-format)이 `ruff format`을 실행한다.
- **타입: mypy** (`mypy app`). 함수 인자/반환 타입 명시, 임시 `Any` 금지.
- **레이어링: import-linter** (`lint-imports`) — `pyproject.toml` 계약:

```toml
[tool.importlinter]
root_package = "app"

[[tool.importlinter.contracts]]
name = "layered architecture"
type = "layers"
layers = [
    "app.api",
    "app.services",
    "app.repositories",
    "app.core",
    "app.schemas | app.models",
]
```

## Conventions

- Pydantic 스키마가 경계에서 검증하고, 이후 코드는 타입을 신뢰한다. raw dict 반환 금지.
- 요청당 `AsyncSession` 하나를 DI로 — 리포지토리가 세션을 주입받는다. 모듈 로드
  시점의 전역 client/connection 생성 금지.
- 단건 조회는 `T | None` 반환 — 호출부(서비스)가 None을 처리해 404 등으로 변환.
- async 엔드포인트에서 블로킹 I/O 직접 호출 금지.
- Alembic 마이그레이션, forward-only, 사람 리뷰.
- 테스트는 pytest(`tests/`). 기준은 docs/conventions/testing-conventions.md.
- 표본: `docs/exemplar/` — schemas → repository → service → api 관통 슬라이스.

## 전제 (doctor가 경고로 알려준다)

- Python 3.11+, ruff / mypy / import-linter / pytest 설치.
- 게이트 명령은 `harness/gate.env`에서 조정.
