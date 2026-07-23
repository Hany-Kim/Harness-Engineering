---
slug: spring-persistence-layered-skill
status: draft
branch: chore/spring-persistence-layered-skill
ticket: none
updated: 2026-07-23
---

# Plan: Spring Boot Persistence 계층형 Skill과 JPA/MyBatis 표본

- **Owner / driver:** human + implementer
- **Related:** current request and attached account package reference;
  [golden principles](../architecture/principles.md);
  [Spring Boot stack rules](../../kit/stacks/spring-boot/stack.md)

## 1. Problem

현재 Spring Boot 팩은 JPA와 MyBatis를 함께 지원한다고 선언하지만, 설치되는 `note`
exemplar는 Service concrete class가 `JpaRepository`를 직접 주입받는 구조이고 MyBatis
Mapper 분리 표본은 없다. 이 상태에서는 ORM을 바꿀 때 Service/Controller까지 수정되거나
MyBatis Mapper 또는 Spring Data Repository가 상위 계층으로 새어 나갈 수 있다.

JPA와 MyBatis 모두 다음 공통 호출 구조를 사용해야 한다.

`Controller → Service interface → ServiceImpl → Repository interface
→ RepositoryImpl → persistence adapter → DB`

영속성 어댑터만 선택한 변형에 따라 바뀐다.

- MyBatis: `AccountMapper` interface + `AccountMapper.xml`
- JPA: `AccountJpaRepository extends JpaRepository<AccountEntity, Long>`

반환 데이터는 `DB row → 선택한 adapter → AccountEntity → AccountRepositoryImpl
→ AccountServiceImpl → AccountResponse DTO → AccountController`로 이동한다.
Controller와 Service는 ORM 종류를 몰라야 하며, Repository interface도 Spring Data나
MyBatis 타입을 import하지 않는 애플리케이션 계약이어야 한다. 이 구조를 조건부 Skill,
JPA/MyBatis 독립 exemplar와 ArchUnit 회귀 테스트로 강제한다.

## 2. Constraints & affected layers

- `kit/`이 단일 소스다. `.claude/skills/`, `docs/conventions/`, `harness/` 등 렌더·설치
  산출물은 직접 수정하지 않고 `scripts/render.sh`와 `scripts/init.sh`로 생성한다.
- 변경은 Spring Boot 스택 팩의 Skill, `stack.md`, JPA/MyBatis exemplar, ArchUnit
  테스트와 gate 설명에 한정한다. 다른 스택과 제품 런타임은 건드리지 않는다.
- 새 `persistence-layered` Skill은 Spring persistence 코드를 추가·수정하거나
  Controller/Service/Repository/Mapper/JpaRepository 경계를 점검할 때 사용한다.
  시작 전에 build dependency, 기존 adapter와 사용자 요청을 조사해 `jpa` 또는
  `mybatis` 중 정확히 하나를 선택한다. 불명확하거나 한 bounded context에 양쪽이
  이미 섞여 있으면 구현하지 않고 사람에게 선택을 요청한다.
- 공통 계층은 `Types(Entity/DTO) → persistence adapter → Repository → Service
  → Runtime/API` 방향만 허용한다. Controller는 Service interface, ServiceImpl은
  Repository interface, RepositoryImpl은 선택된 adapter만 주입받는다. concrete Impl
  또는 ORM adapter를 건너뛴 직접 주입을 금지한다.
- 공통 패키지/네이밍:
  `account/controller/AccountController`,
  `account/dto/AccountCreateRequest·AccountResponse`,
  `account/entity/AccountEntity`,
  `account/repository/AccountRepository·AccountRepositoryImpl`,
  `account/service/AccountService·AccountServiceImpl`.
  interface에 `I` 접두사를 붙이지 않고 구현체만 `Impl` 접미사를 사용한다.
- adapter 패키지만 달라진다. MyBatis는
  `account/mapper/AccountMapper`와
  `src/main/resources/mapper/account/AccountMapper.xml`, JPA는
  `account/jpa/AccountJpaRepository`를 사용한다. RepositoryImpl 바깥에서는 이
  패키지와 `org.apache.ibatis.*`/`org.springframework.data.jpa.*`를 import하지 않는다.
- DTO는 Controller의 요청/응답 경계다. Mapper/JpaRepository/Repository가 DTO를
  사용하지 않고, ServiceImpl이 Entity를 DTO로 변환해 Service interface 밖으로
  Entity/Optional을 노출하지 않는다. Controller endpoint signature에는 DTO만 둔다.
- Entity의 역할은 같지만 mapping 방식은 다르다. JPA 변형은 `@Entity`, `@Table`,
  `@Id`, `@GeneratedValue`와 JPA용 protected no-arg constructor를 사용한다. MyBatis
  변형은 JPA annotation 없는 POJO이며 Mapper XML `resultMap`과 생성/접근자 계약으로
  row를 매핑한다.
- annotation 계약: MyBatis adapter는 `@Mapper`, JPA adapter는 annotation 없는
  Spring Data interface, RepositoryImpl은 `@Repository`, ServiceImpl은 `@Service`,
  Controller는 `@RestController`/`@RequestMapping`을 사용한다. Service/Repository
  interface에는 Spring stereotype을 붙이지 않는다.
- 모든 주입은 `private final` + `@RequiredArgsConstructor` 생성자 주입이며 필드
  `@Autowired`를 금지한다. 트랜잭션은 ServiceImpl에만 두고 조회는
  `@Transactional(readOnly = true)`, 쓰기는 `@Transactional`을 사용한다.
- Service 단위 테스트는 Spring Context를 띄우지 않는 순수 JUnit 테스트다.
  Repository/Cache 등 port interface에는 테스트마다 새로 만든 in-memory
  `FakeAccountRepository`/`FakeAccountCache`를 주입하고 DB/Redis client, Docker,
  네트워크를 사용하지 않는다. fake는 instance-local 상태만 가지며 static/shared
  mutable state를 금지하고 Optional/빈 컬렉션 계약과 instance 간 격리를 테스트한다.
- 시간·ID·난수처럼 결과를 흔드는 값이 비즈니스 로직에 필요하면 `Clock` 또는
  `AccountIdGenerator` 같은 주입 가능한 port로 추상화하고 단위 테스트에는 fixed/fake
  구현을 사용한다. Mockito는 event publisher·메일 등 외부 호출 횟수/인자 검증이
  실제로 필요한 경계에만 제한하며 Repository/Cache의 상태 기반 동작을 mock
  stubbing으로 대신하지 않는다.
- `@SpringBootTest`, `@DataJpaTest`, Testcontainers, H2, embedded Redis는 unit
  source set에서 금지한다. ORM mapping/SQL/Mapper XML/RepositoryImpl/Redis
  serialization은 별도 `integrationTest` source set에서 Postgres/Redis
  Testcontainers로 검증한다. Service production code는 JDBC/JPA/MyBatis/Redis
  client를 직접 import하지 않고 port interface만 본다.
- adapter와 Repository의 단건 `findBy*`/`getBy*`는 `Optional<Entity>`, 다건은
  `List`/`Collection`/`Map`/`Stream` 또는 `Page`/`Slice`를 직접 반환한다.
  `Optional<다건 타입>`을 금지하고 ServiceImpl에서 단건 Optional을 해소한다.
- 같은 bounded context에서 JPA와 MyBatis adapter를 동시에 Bean으로 등록하지 않는다.
  exemplar는 서로 독립적인 대안이며 선택한 한 트리만 복사한다. 두 persistence
  dependency가 전역적으로 필요한 혼합 저장소라면 module/bounded-context 경계를
  먼저 나누고, 불가피하게 같은 context에 코드를 보유할 때는 상호 배타적인
  `@Profile` 또는 `@ConditionalOnProperty`와 context test로 활성 adapter가 정확히
  하나임을 보장한다. `@Primary`로 중복 Bean을 숨기는 방식은 금지한다.
- 기존 JPA `note` exemplar는 Repository/Service interface와 Impl이 분리되지 않아 새
  계약과 충돌한다. JPA 변형의 account exemplar로 정합화하고
  `new-api-endpoint` Skill의 표본 링크/절차도 새 공통 계약으로 맞춘다.
- 설치본에 새 Skill과 두 표본이 추가되므로 `VERSION`은 `2.3.1`에서 `2.4.0`으로 올린다.
- 위험: ORM별 ArchUnit 규칙을 모든 Spring 코드에 무조건 적용하면 다른 변형을
  오탐한다. 공통 규칙과 adapter별 규칙을 분리하고 각 exemplar/test source set에는
  선택한 adapter 규칙만 연결한다.
- 위험: fake가 singleton/static map을 사용하면 테스트 순서에 따라 결과가 달라지고
  실제 port 계약과 어긋날 수 있다. fake contract test와 unit-test dependency
  ArchUnit 규칙으로 상태 격리와 infrastructure import 금지를 함께 고정한다.

## 3. Approach

`kit/stacks/spring-boot/skills/persistence-layered/SKILL.md`를 추가한다. Skill은
variant 선택 → 공통 DTO/Entity/contract → 선택 adapter → RepositoryImpl
→ ServiceImpl → Controller → 테스트/gate 순서로 작업하게 한다. JPA와 MyBatis의
차이는 Entity mapping annotation과 adapter 구현에만 두고, 상위 package와 public
interface signature는 동형으로 유지한다.

테스트는 포트 중심 피라미드로 나눈다. `src/test/java`의 Service unit test는
`FakeAccountRepository` 등 in-memory fake와 fixed Clock/ID generator만 사용하고
`./gradlew test`로 인프라 없이 실행한다. `src/integrationTest/java`는 선택한 ORM
adapter와 SQL/serialization만 Testcontainers로 검증하며 `./gradlew integrationTest`로
실행한다. Gradle source set과 gate 단계를 분리해 unit test가 integration classpath나
Docker를 우연히 끌어오지 못하게 한다.

exemplar는 `kit/stacks/spring-boot/exemplar/jpa/`와
`kit/stacks/spring-boot/exemplar/mybatis/`에 각각 완결된 `account` vertical slice로
둔다. JPA slice의 RepositoryImpl은 `AccountJpaRepository`, MyBatis slice의
RepositoryImpl은 `AccountMapper`만 위임한다. 두 slice의 Controller/DTO/Repository
interface/Service interface 및 Impl API는 비교 가능한 동형이어야 한다.

공통 `PersistenceLayeringRules`는 interface/Impl 구현 관계, concrete-class 직접 주입,
DTO/Entity 노출, constructor injection, transaction 위치와 Optional 계약을 검사한다.
JPA 규칙은 상위 계층의 Spring Data 직접 의존과 JPA adapter 밖 `JpaRepository` 사용을,
MyBatis 규칙은 Mapper 직접 의존/DTO 매핑/상위 계층의 MyBatis import를 차단한다.
각 variant의 ArchUnit regression test가 정상 fixture와 의도적 위반 fixture를
독립적으로 검증한다.

공통 `UnitTestBoundaryRules`는 Service unit test가 Spring test annotation,
Testcontainers, DB/Redis/HTTP client와 adapter 구현에 의존하지 않는지 검사하고,
fake의 static mutable field를 금지한다. Integration test는 별도 source set이므로 이
unit classpath 규칙의 대상이 아니며 Testcontainers 사용을 허용한다. 공통
`testing-conventions` Skill, `persistence-layered` Skill과 `new-api-endpoint` Skill이
같은 경계를 설명하도록 맞춘다.

기존 JPA note exemplar를 그대로 두는 방안은 Skill의 새 구조와 상충하는 모방 대상을
남기므로 제외한다. JPA와 MyBatis adapter를 한 runtime slice에 함께 넣고 `@Primary`로
선택하는 방안도 설정 오류를 숨기므로 제외한다. 공통 RepositoryImpl 내부에서
`if (jpa)`처럼 ORM을 분기하는 방안은 adapter 교체가 비즈니스 코드 변경으로 번지므로
제외한다.

## 4. Steps (small, reviewable)

- [ ] Step 1 — `kit/stacks/spring-boot/skills/persistence-layered/SKILL.md`: persistence
      변경 트리거와 JPA/MyBatis 단일 variant 선택 절차, 공통 호출 방향, package/name,
      DTO/Entity 경계, annotation/constructor injection/transaction/Optional 계약,
      adapter별 작성 순서와 전체 gate 완료 기준을 작성한다. Service unit test는 port
      fake, integration test는 선택 adapter+Testcontainers를 사용한다는 분리와
      Clock/ID/Mockito 제한을 포함한다. 두 adapter가 감지되거나 선택이 불명확하면
      중단하도록 한다.
- [ ] Step 2 — `kit/stacks/spring-boot/stack.md`와
      `kit/stacks/spring-boot/skills/new-api-endpoint/SKILL.md`: 기존 JPA 직접 Repository
      흐름을 공통 interface/Impl 구조로 바꾸고 JPA/MyBatis variant 표, 허용 import,
      호출/반환 흐름, Entity mapping 차이, 단일 adapter 활성화 원칙을 반영한다.
      엔드포인트 작업에서 persistence가 포함되면 `persistence-layered` Skill도
      적용하도록 연결한다. 새 Service 테스트는 fake 기반 unit과 Testcontainers 기반
      integration을 분리하고 단위 테스트에서 Spring Context/infra를 금지한다.
- [ ] Step 3 — `kit/skills/testing-conventions/SKILL.md`: Spring Service unit test
      subsection을 추가한다. port별 in-memory fake, per-test 독립 상태,
      Optional/빈 컬렉션, fixed Clock/ID generator, Mockito 제한과 unit 금지 목록을
      명시하고 adapter/SQL/ORM/Redis serialization은 별도 integration source set +
      Testcontainers로 이동한다. `scripts/render.sh`가 공통 Claude Skill과 Codex용
      `docs/conventions/testing-conventions.md`를 함께 생성하게 한다.
- [ ] Step 4 — `kit/stacks/spring-boot/exemplar/jpa/`: account DTO/Entity/Repository
      interface·Impl/Service interface·Impl/Controller와 README를 추가한다.
      `AccountEntity`는 JPA annotation을 사용하고
      `AccountJpaRepository extends JpaRepository<AccountEntity, Long>`만 Spring Data를
      알며, `AccountRepositoryImpl`이 이를 위임한다.
- [ ] Step 5 — `kit/stacks/spring-boot/exemplar/mybatis/`: Step 4와 public 구조가
      동형인 account slice와 README를 추가한다. `AccountEntity`는 annotation 없는
      POJO, adapter는 `@Mapper AccountMapper`와 namespace/resultMap이 일치하는
      `AccountMapper.xml`이며 `AccountRepositoryImpl`이 Mapper만 위임한다.
- [ ] Step 6 — 기존 `kit/stacks/spring-boot/exemplar/src/` note JPA slice와 최상위
      exemplar README: 상충하는 JpaRepository 직접 주입/Service concrete 패턴을
      제거하고 두 canonical variant 경로를 안내하도록 정합화한다. upgrade 시 로컬
      수정된 설치본을 덮어쓰지 않는 기존 manifest/`.harness-new` 정책을 유지하며,
      retired legacy 파일이 남을 수 있으면 명확히 보고하는 안전한 이전 절차를
      `scripts/init.sh` 동작과 대조해 계획 편차로 기록한다.
- [ ] Step 7 — 두 exemplar의 `src/test/java`: `FakeAccountRepository`와 cache가
      필요할 경우 `FakeAccountCache`, fixed Clock/ID generator를 test support에
      둔다. 각 테스트가 새 fake instance를 생성하고 fake contract
      (Optional/빈 목록/instance isolation)를 검증한다. ServiceImpl
      happy/missing/business-rule 테스트는 Spring extension/Mockito Repository 없이
      이 port fake만 주입하며 Controller DTO 경계도 순수 단위 테스트로 확인한다.
- [ ] Step 8 — 두 exemplar의 `src/integrationTest/java`와 Gradle source set 예시:
      JPA/MyBatis RepositoryImpl과 ORM/Mapper XML/SQL을 Postgres Testcontainer로,
      cache adapter가 있으면 Redis serialization을 Redis Testcontainer로 검증한다.
      H2/embedded Redis는 추가하지 않고 unit `test`와 독립된 `integrationTest` task를
      제공한다.
- [ ] Step 9 — 두 exemplar의 `arch/`: 공통 `PersistenceLayeringRules`와 variant별
      adapter 규칙, `JpaPersistenceLayeringArchTest`,
      `MyBatisPersistenceLayeringArchTest` 및 양성/음성 regression test를 추가한다.
      interface/Impl, annotation, final constructor injection, transaction,
      DTO/Entity, Optional/다건 계약과 잘못된 ORM 직접 의존을 기계적으로 검사한다.
- [ ] Step 10 — 같은 unit source set의 `UnitTestBoundaryRules`와 회귀 fixture:
      Service unit test에서 Spring Context/JPA/MyBatis/JDBC/Redis client/Testcontainers/
      Docker/network adapter import와 `@SpringBootTest`/`@DataJpaTest`를 금지하고,
      fake의 static mutable field와 production Service의 adapter/client 직접 의존을
      실패시킨다. 정상 fake 기반 unit fixture와 각 금지 의존을 넣은 음성 fixture로
      PASS→FAIL을 증명한다.
- [ ] Step 11 — variant 선택 회귀 fixture/context test: JPA-only와 MyBatis-only
      context는 각각 `AccountRepository` Bean과 persistence adapter Bean이 하나씩
      존재해야 한다. 두 adapter를 한 context에 무조건 등록한 fixture는 실패해야 하며,
      명시적 profile/property 선택 fixture는 선택된 adapter만 활성화됨을 증명한다.
- [ ] Step 12 — `kit/gates/gate.sh`, `kit/gates/doctor.sh`,
      `kit/stacks/spring-boot/gate.env`와 exemplar README: unit
      `GATE_TEST_CMD="./gradlew test"` 뒤 선택적
      `GATE_INTEGRATION_TEST_CMD="./gradlew integrationTest"`를 별도 gate 단계로
      실행하고 doctor가 두 명령의 도구를 점검하게 한다. Spring 팩에는 integration
      명령을 필수로 설정해 pre-commit/CI에서 빠지지 않게 하되 unit smoke는 `test`
      task만 독립 실행할 수 있어야 한다.
- [ ] Step 13 — `scripts/init.sh` upgrade 경로: 이전 manifest에는 있으나 새 install
      map에서 retired된 legacy exemplar 파일이 대상 프로젝트에 남아 있으면 자동
      삭제하지 않고 경로를 명시적으로 경고한다. 로컬 수정 여부와 무관하게 파괴적
      정리는 사람에게 맡기고, 새 canonical JPA/MyBatis 표본 설치와 충돌 보존 정책은
      유지한다.
- [ ] Step 14 — `VERSION`: 설치본에 새 Skill과 표본을 전달하도록 `2.4.0`으로 올린다.
- [ ] Step 15 — `scripts/render.sh`를 실행해 kit 기반 관리 산출물을 동기화하고
      `scripts/render.sh --check`로 드리프트가 없음을 확인한다. 스택 Skill/exemplar는
      `scripts/init.sh`가 `.claude/skills/`, `docs/conventions/`, `docs/exemplar/`에
      설치하므로 산출물을 손으로 편집하지 않는다.

## 5. Verification

작성자가 아닌 evaluator가 다음을 독립적으로 수행한다.

1. `scripts/render.sh`, `scripts/render.sh --check`,
   `harness/gates/check-docs.sh`, `git diff --check`를 실행한다. 관리 산출물에 수동
   편집이 없고 계획에 명시한 kit/VERSION/legacy 정합화만 diff에 있는지 확인한다.
2. 임시 git 저장소에
   `scripts/init.sh <temp-dir> spring-boot persistence-layered-smoke main`을 실행한다.
   init/doctor 성공과 다음 설치 결과를 확인한다.
   - `.claude/skills/persistence-layered/SKILL.md`가 kit 원본과 일치한다.
   - `docs/conventions/persistence-layered.md`와 설치본 `AGENTS.md`의 Skill 표에
     `persistence-layered`가 노출된다.
   - 공통 `.claude/skills/testing-conventions/SKILL.md`와
     `docs/conventions/testing-conventions.md`에 Spring fake unit/integration
     source-set 경계가 동일하게 렌더된다.
   - `docs/exemplar/jpa/`와 `docs/exemplar/mybatis/`에 독립 account Java/XML/test
     slice가 설치되고 legacy note를 authoritative 표본으로 가리키는 링크가 없다.
   - `.harness/manifest`와 계약의 하네스 버전이 `2.4.0`이다.
3. 설치된 두 exemplar를 각각 독립 Java 21/Gradle fixture로 실행한다. JPA fixture는
   Spring Data JPA만, MyBatis fixture는 MyBatis 3.5+만 persistence adapter로
   활성화한다. 먼저 의존성을 준비한 뒤 Docker socket, DB/Redis URL과 외부 네트워크를
   사용할 수 없는 환경에서 `./gradlew test --offline`을 실행해 Service unit/fake
   contract/UnitTestBoundary 테스트가 PASS하는지 확인한다.
   `./gradlew test --dry-run`에는 `integrationTest`가 포함되지 않아야 하고,
   UnitTestBoundary 검사상 Service unit test의 Spring test annotation/context 및
   Testcontainers import는 0건이어야 한다.
4. 같은 fixture에서 Docker를 사용할 수 있게 한 뒤 `./gradlew integrationTest`를
   실행한다. JPA ORM mapping/RepositoryImpl과 MyBatis Mapper XML/SQL/RepositoryImpl은
   Postgres Testcontainer, cache가 있으면 Redis serialization은 Redis Testcontainer로
   검증하고 H2/embedded Redis 사용은 0건이어야 한다. 두 fixture의
   `./gradlew spotlessCheck`도 PASS해야 한다.
5. Service unit test와 fake를 정적·행동 검토한다.
   - Repository와, cache를 사용하는 경우 Cache 의존은
     `FakeAccountRepository`/`FakeAccountCache`처럼 port interface를 구현한 in-memory
     fake이며 각 test setup이 새 instance를 만든다.
   - 새 fake 두 개 사이에 저장 상태가 전파되지 않고, 초기 조회는
     `Optional.empty()`/빈 컬렉션이며 static/shared mutable field가 없다.
   - Clock/ID가 필요한 로직은 fixed/fake port로 재현 가능하고 sleep/현재시각/랜덤
     global 호출이 없다.
   - Mockito는 event/mail 등 외부 호출 횟수·인자 경계에만 쓰이며 Repository/Cache,
     DB/Redis client mocking은 0건이다.
6. 두 정상 slice의 public 구조를 대조한다. Controller, DTO, Repository interface/Impl,
   Service interface/Impl signature가 동형이고 차이는 아래에만 있어야 한다.
   - JPA: `@Entity AccountEntity` +
     `AccountJpaRepository extends JpaRepository`.
   - MyBatis: annotation 없는 `AccountEntity` + `@Mapper AccountMapper`/Mapper XML.
7. ArchUnit regression test 또는 evaluator의 임시 mutation fixture로 다음 위반이
   각각 FAIL하는지 확인한다.
   - Controller가 ServiceImpl/Repository/adapter/Entity를 직접 사용한다.
   - ServiceImpl이 RepositoryImpl, `AccountJpaRepository` 또는 `AccountMapper`를
     직접 사용하고 ORM package를 import한다.
   - Repository interface가 Spring Data/MyBatis 타입에 의존하거나 RepositoryImpl이
     선택하지 않은 adapter 또는 두 adapter를 함께 주입받는다.
   - JPA 변형이 Mapper/MyBatis를, MyBatis 변형이 JpaRepository/JPA annotation을
     사용한다.
   - endpoint/Service interface가 Entity·Optional을 노출하거나 adapter/Repository가
     DTO를 사용하고, 단건 raw Entity 또는 `Optional<다건>`을 반환한다.
   - interface/Impl 관계, stereotype, final constructor injection 또는 ServiceImpl
     transaction 규칙을 위반한다.
   - Service unit test가 Spring test annotation/context, JPA/MyBatis/JDBC/Redis
     client, Testcontainers/Docker/network adapter 또는 production adapter에
     의존하거나 fake가 static mutable state를 사용한다.
8. variant 선택 context test로 JPA-only/MyBatis-only에서 `AccountRepository` 구현
   Bean이 정확히 하나인지 확인한다. 무조건 두 adapter를 등록한 설정은 startup/검사
   FAIL, profile/property를 명시한 설정은 선택 adapter만 활성화되어야 한다.
9. 기존 JPA note 정합화와 upgrade 경로를 검토한다. clean legacy 설치본은 새 canonical
   문서로 안내되고, 로컬 수정된 관리 파일은 덮어쓰지 않고 `.harness-new`로 보존되며,
   stale 파일이 남으면 init/upgrade 출력에서 수동 정리 대상으로 식별되어야 한다.
10. `kit/stacks/spring-boot/gate.env`와 설치본 `harness/gate.env`에 unit과 integration
    명령이 분리돼 있고 `harness/gates/gate.sh --ci`가 `test` 다음
    `integration-test`를 실행하는지 확인한다. `harness/gates/doctor.sh`와 전체 gate가
    PASS해야 하며 evaluator만 plan frontmatter를 `verified`로 전환한다.

## 6. Rollback

`kit/stacks/spring-boot/skills/persistence-layered/`, JPA/MyBatis account exemplar,
공통/variant ArchUnit·UnitTestBoundary 규칙과
`kit/skills/testing-conventions/SKILL.md`, `stack.md`, `gate.env`,
`new-api-endpoint`, 공통 gate/doctor 변경을 되돌리고 legacy note exemplar를 복원한다.
`VERSION`을 `2.3.1`로 되돌린 뒤
`scripts/render.sh`를 다시 실행한다. upgrade된 대상 프로젝트의 로컬 수정은 기존
`.harness-new` 충돌 보존 정책에 따라 유지하고, 두 adapter가 동시에 활성화된 상태로
롤백하지 않았는지 context test로 확인한다.
