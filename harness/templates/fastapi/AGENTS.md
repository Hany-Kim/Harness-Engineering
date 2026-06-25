# Stack: FastAPI (SQLAlchemy) + Python

> Template note: copy this file to a module root as a nested `AGENTS.md` when this stack
> lives under a polyglot repository.

Inline the relevant parts of this into the project's root `AGENTS.md` §6.

## Layout & layering

```
app/
  schemas/       # pydantic models (request/response)            (Types)
  models/        # SQLAlchemy ORM models                         (Types)
  core/          # settings, config, DI, security                (Config)
  repositories/  # DB/Redis access — all queries live here       (Repository)
  services/      # business logic, transaction orchestration     (Service)
  api/           # routers / endpoints                           (Runtime/API)
  main.py        # app wiring
```

Direction: `schemas/models → core → repositories → services → api`.
Routers depend on services (via `Depends`), never on repositories directly. No SQL in
routers or services — only in `repositories/`.

## Mechanical enforcement
- **Layering:** `import-linter` contracts in `pyproject.toml` (a "layers" contract over
  the packages above). Run `lint-imports` in CI — violations fail the build.
- **Format + lint:** `ruff format` + `ruff check`.
- **Types:** `mypy app`.

## Verification commands (AGENTS.md §4)
```bash
ruff format .                  # format
ruff check . --fix             # lint
mypy app                       # typecheck
lint-imports                   # layering contracts
pytest -q --cov=app            # unit + integration
playwright test                # e2e (if the app serves UI/flows)
```

## Conventions
- Pydantic schemas validate at the boundary; services/repositories trust typed data.
- One `AsyncSession` per request via dependency injection; repositories take the session.
- Redis access is wrapped in a repository, namespaced by tenant/key-prefix.
- Integration tests run against Postgres+Redis via Testcontainers or docker-compose.
- **Tests (mandatory — AGENTS.md §1b):** pytest (`tests/` or `*_test.py`). New feature →
  happy path + edge cases; bug fix → failing reproduction test first; refactor → keep
  existing tests green. A failing test blocks the commit.
- Alembic migrations, forward-only, human-reviewed.
