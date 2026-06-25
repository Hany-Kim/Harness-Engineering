# Stack: Spring Boot (MyBatis / JPA) + Java

> Template note: copy this file to a module root as a nested `AGENTS.md` when this stack
> lives under a polyglot repository.

Inline the relevant parts of this into the project's root `AGENTS.md` §6.

## Layout & layering

```
src/main/java/<pkg>/
  domain/        # entities, value objects                      (Types)
  dto/           # request/response DTOs                         (Types)
  config/        # @Configuration, properties, beans             (Config)
  repository/    # MyBatis mappers / JPA repositories            (Repository)
  service/       # @Service business logic, @Transactional       (Service)
  controller/    # @RestController endpoints                     (Runtime/API)
```

Direction: `domain/dto → config → repository → service → controller`.
Controllers never touch repositories directly; they go through services. No business
logic in controllers or mappers.

## Mechanical enforcement
- **Layering:** an **ArchUnit** test in `src/test` (`layeredArchitecture()`), e.g.
  controller may access service; service may access repository; repository accessed by
  none above it. Fails the build on violation.
- **Format/lint:** Spotless + Checkstyle.
- Constructor injection only (no field `@Autowired`) — enforce via Checkstyle/ArchUnit.

## Verification commands (AGENTS.md §4)
```bash
./gradlew spotlessApply        # format
./gradlew check                # spotless + checkstyle + tests
./gradlew test                 # unit + ArchUnit + slice tests
# e2e: drive the running app via Playwright or RestAssured integration tests
```

## Conventions
- Transactions live in the service layer, never the controller.
- DTOs cross the controller boundary; entities never leak out of the service layer.
- Repository tests use Testcontainers (Postgres) — not H2 — so behaviour matches prod.
- **Tests (mandatory — AGENTS.md §1b):** JUnit under `src/test/java`. New feature → happy
  path + edge cases; bug fix → failing reproduction test first; refactor → keep existing
  tests green. A failing test blocks the commit.

## Database migrations (Flyway)
- All schema changes go through **Flyway**. Migrations are forward-only and human-reviewed.
- Files live in `src/main/resources/db/migration/`.
- **Naming:** `V{TIMESTAMP}__{reason_or_purpose}.sql`
  (Flyway requires a **double** underscore between version and description), e.g.
  `V20260625103000__add_user_email_index.sql`.
- `{TIMESTAMP}` is `yyyyMMddHHmmss` so versions sort chronologically and never collide
  between branches. Use the description to say *why*, in snake_case.
- Never edit an applied migration — add a new one. (Flyway checksums will fail otherwise.)
