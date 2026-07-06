---
name: new-api-endpoint
description: Spring Boot API 엔드포인트나 서비스/리포지토리 메서드를 추가·수정할 때 반드시 사용. 계층 생성 순서, Optional 반환 규칙, 트랜잭션·주입 규칙.
---

# 엔드포인트 추가 절차 (Spring Boot)

표본: `docs/exemplar/src/main/java/com/example/app/note/`를 그대로 모방한다.

1. **DTO부터.** `dto/`에 요청/응답 record. 엔티티를 컨트롤러 밖으로 내보내지
   않는다 — 항상 DTO로 변환해 반환.
2. **Repository.** 쿼리는 `repository/`에만. **단건 조회(findBy*/getBy*)는 반드시
   `Optional<T>` 반환** — null 반환 금지(ArchUnit이 강제). 컬렉션 조회는 빈
   컬렉션을 반환하고 `Optional<List>`로 감싸지 않는다.
3. **Service.** 비즈니스 흐름과 `@Transactional`은 서비스 계층에만.
   `Optional`은 서비스에서 해소한다(`orElseThrow` 등) — 컨트롤러로 넘기지 않는다.
4. **Controller.** 요청/응답 매핑만. 비즈니스 판단 금지. 리포지토리 직접 접근
   금지(ArchUnit이 강제).
5. **주입.** 생성자 주입만: `@RequiredArgsConstructor` + `private final`.
   필드 `@Autowired` 금지(ArchUnit이 강제).
6. **테스트 동반.** `src/test/java`에 서비스 단위 테스트(happy + 실패 경로).
   기준은 docs/conventions/testing-conventions.md.

## 완료 기준

- `harness/gates/gate.sh` 통과 — `./gradlew test`에 ArchUnit(레이어링 + Optional +
  주입 규칙)이 포함된다.
- 표본 슬라이스와 구조 동형 — 다르면 표본이 아니라 새 코드가 틀린 것이다.
