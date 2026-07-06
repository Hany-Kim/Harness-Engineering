# 표본 슬라이스 (exemplar) — note

이 폴더는 이 프로젝트의 **모방 대상**이다. 새 엔드포인트를 만들 때 이 슬라이스의
구조를 그대로 복제한다: `dto → repository(Optional 반환) → service → controller`
+ 단위 테스트 + ArchUnit 규칙.

- 새(빈) 프로젝트라면: `src/` 이하를 프로젝트로 복사하고 패키지명을 바꾼다
  (`com.example.app` → 실제 패키지). ArchUnit 테스트의 패키지 상수도 함께.
- 기존 프로젝트라면: 복사하지 말고 구조 표본으로만 참조한다. 단,
  `arch/LayeringArchTest.java`는 규칙 강제를 위해 프로젝트에 반드시 옮겨 넣는다.

필요 의존성: `com.tngtech.archunit:archunit-junit5` (testImplementation),
Spotless 플러그인, (MyBatis 사용 시) MyBatis 3.5+.
