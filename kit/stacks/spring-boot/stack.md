# Stack: Spring Boot (MyBatis / JPA) + Java

이 문서는 이 프로젝트의 스택 레이아웃과 기계적 강제 설정의 상세다.
(AGENTS.md §0에서 링크됨 — 규칙 요약은 AGENTS.md가 우선)

## Layout & layering

```
src/main/java/<pkg>/
  domain/        # 엔티티, VO                                   (Types)
  dto/           # 요청/응답 DTO                                 (Types)
  config/        # @Configuration, properties, bean 선언          (Config)
  repository/    # MyBatis 매퍼 / JPA 리포지토리                  (Repository)
  service/       # @Service 비즈니스 로직, @Transactional         (Service)
  controller/    # @RestController — 매핑만                       (Runtime/API)
```

방향: `domain/dto → config → repository → service → controller`.
컨트롤러는 리포지토리를 직접 만지지 않는다. 비즈니스 판단은 컨트롤러/매퍼에 금지.

## 기계적 강제 (컨벤션 사다리 1층)

- **포맷: Spotless** (`./gradlew spotlessCheck`, 수정은 `spotlessApply`).
- **ArchUnit 테스트** (`src/test/java`, test 단계에서 실행 — 위반 시 커밋 차단):
  1. 레이어드 아키텍처(위 방향 강제).
  2. **Repository 단건 조회는 `Optional<T>` 반환** — `findBy*`/`getBy*` 중
     비컬렉션 반환 메서드는 raw return type이 `Optional`이어야 한다. null 반환
     관례를 타입으로 봉쇄한다. 컬렉션 조회는 빈 컬렉션 반환(`Optional<List>` 금지).
  3. 필드 `@Autowired` 금지 — 생성자 주입만.

  표본 구현: `docs/exemplar/src/test/java/com/example/app/arch/LayeringArchTest.java`

## Conventions

- 트랜잭션은 서비스 계층에만. 엔티티는 서비스 밖으로 내보내지 않는다 — DTO 변환.
- 생성자 주입(`@RequiredArgsConstructor` + `private final`).
- MyBatis 매퍼의 Optional 반환은 **MyBatis 3.5+** 필요.
- 리포지토리 통합 테스트는 Testcontainers(Postgres) — H2 금지(운영과 동작 일치).
- 테스트는 JUnit, `src/test/java`. 기준은 docs/conventions/testing-conventions.md.
- 표본: `docs/exemplar/` — dto → repository → service → controller 관통 슬라이스.

## Database migrations (Flyway)

- 스키마 변경은 전부 Flyway, forward-only, 사람 리뷰.
- 파일: `src/main/resources/db/migration/`,
  네이밍 `V{yyyyMMddHHmmss}__{why_snake_case}.sql` (더블 언더스코어).
- 적용된 마이그레이션은 절대 수정하지 않는다 — 새 파일 추가(checksum 불일치 방지).

## 전제 (doctor가 경고로 알려준다)

- JDK 17+, Gradle wrapper, Spotless / ArchUnit / (선택) Checkstyle 의존성.
- 게이트 명령은 `harness/gate.env`에서 조정.
