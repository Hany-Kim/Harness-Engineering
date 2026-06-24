# 팀 Claude Code 작업 규칙

모든 프로젝트에 공통 적용되는 팀 전역 규칙. 프로젝트별 규칙은 해당 프로젝트의 `./CLAUDE.md`가 우선한다.

## 1. 우선순위

1. 현재 대화의 명시적 요청
2. 프로젝트 `./CLAUDE.md`
3. 프로젝트 기존 코드 컨벤션
4. 이 전역 규칙
5. 일반 프레임워크 권장

프로젝트 규칙과 충돌 시 프로젝트 규칙 우선.
단, 보안 / 인증 / 결제 / DB / 배포 / CI-CD / secret / 운영 데이터 / public API / 파괴적 명령은 항상 보수적으로 판단한다.

## 2. 안전 규칙

### 2.1 기본

- 명시 요청 전까지 commit, push, merge 하지 않는다.
- main / master / develop / release / hotfix 브랜치 등 직접 수정 금지.
- 파일 수정 전 `git status`와 현재 브랜치 확인.
- untracked, 수정 중, 임시 파일 임의 삭제 / 덮어쓰기 금지.
- `--no-verify`, `--no-gpg-sign` 등 검증 우회 금지.
- pre-commit, lint, test, CI 실패를 우회하지 않는다.

### 2.2 되돌릴 수 없는 작업 — 반드시 사전 확인

> 아래 목록에 없더라도 되돌릴 수 없는 작업( 파일 삭제, 히스토리 변경, DB / 외부 시스템 상태 변경 )은 실행 전 반드시 확인받는다.

#### Git

- `git reset --hard`
- `git push --force`, `--force-with-lease`
- `git rebase`( 특히 공유 브랜치 )
- `git clean -fd`, `-fdx`
- `git checkout .`, `git restore .`, `git checkout <파일>`
- `git branch -D`
- `git stash drop`, `git stash clear`
- `git filter-branch`, `git filter-repo`
- `git reflog expire`, `git gc --prune=now`
- `git update-ref -d`
- `git worktree remove --force`
- `git submodule deinit`
- 원격 브랜치 삭제 (`git push origin --delete`, `:<branch>`)

#### 파일 시스템

- `rm -rf`
- `find ... -delete`, `find ... -exec rm`
- `xargs rm`
- `truncate -s 0`, `> 파일명` 비우기
- `chmod -R`, `chown -R` (home/root 대상)
- `dd`

#### 인프라 / DB

- SQL `DROP`, `TRUNCATE`, WHERE 없는 `DELETE` / `UPDATE`
- 마이그레이션 reset( `flyway clean`, `prisma migrate reset` 등 )
- `docker system prune -a --volumes`
- `kubectl delete --all`, `--force --grace-period=0`
- 패키지 매니저 `--force`
- 대량 삭제, 운영 데이터 변경

## 3. Secret / 보안

- 실제 비밀번호, API Key, Token, DB 접속 정보는 Git에 커밋 금지.
- 실제 secret 포함 가능 파일은 요청 없이 읽거나 출력 금지. `.env.example` 등 예시 파일은 분석 가능.
- 출력 시 secret / token / password / private key / 개인정보 원문은 마스킹. 로그에도 동일.
- 내부망이라도 secret 관리와 접근 권한 관리 생략 금지.

## 4. 작업 태도

- 한국어로 응답한다.
- 의도가 불명확하면 먼저 확인한다.
- 추측으로 큰 구조를 만들지 않는다.
- 요청 범위를 벗어난 수정, 대규모 리팩터링, 문서 생성을 하지 않는다.
- 새 패턴 도입 전 이유와 영향 범위를 설명한다.
- 불확실한 내용은 `추정` 또는 `확인 필요`로 표시한다.
- "분석해줘"는 수정 없이 분석만. "수정해줘"는 영향 범위 확인 후 수정. "전체로 제공해줘"는 생략하지 않는다.

## 5. 코드 작성

- 실무 사용 가능 수준으로 작성. 운영, 유지보수, 장애 대응, 보안을 함께 고려한다.
- 임시방편, 하드코딩, 숨겨진 side effect, 불필요한 추상화 회피.
- 기존 public API, 공통 타입/hook/util 시그니처 변경 전 영향 범위 설명.
- 기존 주석, 테스트, 설정 임의 삭제 금지.
- 새 인스턴스 / client / connection / config 만들기 전 기존 Bean / wrapper / util 확인.
- README, docs, convention은 요청 전 만들지 않는다.

## 6. 응답 형식

코드 수정 / 리팩토링 답변은 다음을 포함한다.

1. 변경 파일
2. 변경 포인트
3. 변경 이유
4. 검증 방법
5. 주의할 점

단순 질문은 바로 답하되, 보안 / 장애 / 운영 위험은 생략하지 않는다.
이모지 사용 금지.

## 7. 주석

- 한국어. WHY 중심. 코드로 명확한 WHAT은 쓰지 않는다.
- 기존 주석 임의 삭제 금지. 코드와 안 맞으면 정확히 수정.
- 복잡한 흐름, 예외, 보안, 인증, 결제, DB 트랜잭션, 비즈니스 규칙, 장애 대응에는 상세 주석.
- TODO / FIXME는 이유, 처리 조건, 제거 기준 포함.
- public API, 공용 함수 / hook, 외부 재사용 타입에는 필요시 JSDoc / Javadoc.

## 8. 네이밍

- Java 패키지 소문자, 클래스 / 타입 / 컴포넌트 PascalCase, 함수 / 변수 camelCase, 상수 UPPER_SNAKE_CASE.
- interface `I` 접두사 금지.
- boolean은 `is / has / can / should`.
- 콜백 prop `on*`, 핸들러 `handle*`, custom hook `use*`.
- 의미 없는 이름 회피: `data`, `item`, `temp`, `result`, `value`.
- Config 클래스 `XxxConfig`/`XxxProperties`, React Props `XxxProps`.
- 프로젝트 기존 네이밍 규칙이 있으면 그쪽 우선.

## 9. Java / Spring

- 생성자 주입 기본. `@RequiredArgsConstructor` + `private final` 우선. 필드 주입 `@Autowired` 금지.
- Config는 정책 연결과 Bean 선언만. 내부에서 핵심 의존성 `new` 직접 생성 금지.
- Handler, Filter, Provider, Service 등 핵심 로직은 별도 Bean으로 분리.
- Controller는 요청 / 응답 매핑, Service는 비즈니스 흐름. Repository / Mapper에 비즈니스 판단 금지.
- DTO / VO / Service / DAO 구조는 프로젝트 기존 컨벤션 우선.

## 10. TypeScript / React

- 객체 구조 `interface` 우선. 유니온 / 인터섹션 / 매핑 / 조건부 / 유틸 타입은 `type`.
- 인프라 / 순수 유틸 / 재사용 로직은 `function` 선언. 컴포넌트 내부 핸들러는 `const` 화살표.
- HTTP는 기존 공용 래퍼로만. 컴포넌트에서 `axios`/`fetch` 직접 import 금지.
- API 응답 타입 명시. 임시 `any` 금지.
- 불가피한 `any`, 타입 단언, `@ts-ignore`는 이유 / 범위 / 제거 조건을 주석으로.
- 가능하면 `unknown`, 타입 가드, 명시적 interface / type으로 대체.

## 11. Python / FastAPI · Flask

- 타입 힌트 기본. 함수 인자 / 반환 타입 명시. 임시 `Any` 금지, 불가피하면 이유 / 범위 / 제거 조건을 주석으로. 가능하면 구체 타입 / Pydantic 모델로 대체.
- 요청 / 응답 스키마는 Pydantic 모델로 정의( FastAPI ). API 응답 타입 명시, raw dict 떠넘기기 지양.
- 계층 분리: 라우터 / 뷰는 요청 / 응답 매핑, 비즈니스 흐름은 service 계층. Repository / DAO에 비즈니스 판단 금지( §9와 동일 원칙 ).
- 의존성은 FastAPI `Depends`로 주입. 모듈 로드 시점에 무거운 client / connection을 전역으로 직접 생성 금지. 새로 만들기 전 기존 공용 객체 확인.
- 외부 HTTP / DB 호출은 공용 클라이언트 / 세션 래퍼로만. `requests` / `httpx` 클라이언트를 모듈 곳곳에서 직접 생성 금지( §10 `axios`/`fetch` 규칙과 대응 ).
- 설정 / secret은 환경변수 / 설정 객체( `pydantic-settings` 등 )로 주입, 하드코딩 금지( §3 ). 포매터 / 린터( black / ruff 등 ) 버전과 설정은 프로젝트 우선.
- 네이밍은 PEP 8: 함수 / 변수 / 모듈 `snake_case`, 클래스 PascalCase, 상수 UPPER_SNAKE_CASE. Python에 한해 §8의 camelCase 규칙보다 우선.
- async 엔드포인트( FastAPI )에서 블로킹 I/O 직접 호출 금지( async 라이브러리 / `run_in_executor` ). Flask는 애플리케이션 팩토리( `create_app` ) + Blueprint로 라우트 분리, extension은 `init_app`으로 연결.

## 12. 프로젝트별 규칙 분리

이 전역 파일에는 팀 공통 작업 스타일만 둔다. 폴더 구조, 빌드 / 실행 / 테스트 명령, 배포, 브랜치 전략, API / Security / 상태관리 구조, 인프라( DB / Redis / Kafka / Flink 등 ) 규칙, 도메인 규칙, 프로젝트 고유 명칭은 프로젝트 `./CLAUDE.md`에 작성한다.
