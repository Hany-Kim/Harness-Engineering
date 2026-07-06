# Stack: React (Vite + Zustand) + TypeScript

이 문서는 이 프로젝트의 스택 레이아웃과 기계적 강제 설정의 상세다.
(AGENTS.md §0에서 링크됨 — 규칙 요약은 AGENTS.md가 우선)

## Layout & layering

```
src/
  types/        # 도메인 타입, API DTO, zod 스키마               (Types)
  config/       # env, 상수, 테마                                (Config)
  api/          # HTTP는 여기서만 — 공용 래퍼 + 도메인별 클라이언트 (Repository)
  stores/       # zustand 스토어 — 앱 상태 + 액션                 (Service)
  hooks/        # 스토어 + api 조합                               (Service/Runtime)
  features/     # 기능 단위 UI (컴포넌트 + 지역 상태)              (UI)
  components/   # 공용 프레젠테이션 컴포넌트                        (UI)
  routes/       # 라우트/페이지                                   (UI)
```

방향: `types → config → api → stores → hooks → features/components/routes`.
UI는 `api`를 직접 import하지 않는다 — stores/hooks를 경유한다.

## 기계적 강제 (컨벤션 사다리 1층)

- **포맷: prettier.** 편집 즉시 훅(post-edit-format)이 실행하고, 게이트가
  `prettier --check .`로 재확인한다. 스타일 논쟁은 도구가 끝낸다.
- **린트: eslint** (`--max-warnings=0`). 팀 규칙을 린트로 인코딩한다:
  - `eslint-plugin-boundaries`: 위 레이어링을 import 규칙으로 강제.
  - `@typescript-eslint/naming-convention`: interface `I` 접두사 금지, boolean
    `is/has/can/should`, 상수 UPPER_SNAKE_CASE 등.
  - `no-restricted-imports`: 컴포넌트에서 `axios`/`fetch` 직접 import 금지 —
    `src/api/`의 공용 래퍼만 허용.
- **타입: `tsc --noEmit`.** `any`·`@ts-ignore`는 이유/범위/제거 조건 주석 필수.

boundaries 설정 예시(`eslint.config.js`):

```js
settings: {
  'boundaries/elements': [
    { type: 'types',      pattern: 'src/types/**' },
    { type: 'config',     pattern: 'src/config/**' },
    { type: 'api',        pattern: 'src/api/**' },
    { type: 'stores',     pattern: 'src/stores/**' },
    { type: 'hooks',      pattern: 'src/hooks/**' },
    { type: 'ui',         pattern: 'src/{features,components,routes}/**' },
  ],
},
rules: {
  'boundaries/element-types': ['error', {
    default: 'disallow',
    rules: [
      { from: 'config', allow: ['types'] },
      { from: 'api',    allow: ['types', 'config'] },
      { from: 'stores', allow: ['types', 'config', 'api'] },
      { from: 'hooks',  allow: ['types', 'config', 'api', 'stores'] },
      { from: 'ui',     allow: ['types', 'config', 'stores', 'hooks'] },
    ],
  }],
}
```

## Conventions

- zustand 스토어는 액션을 노출한다 — 컴포넌트에 raw setter를 주지 않는다.
- 외부 데이터는 경계(zod)에서 검증하고, 이후 코드는 타입을 신뢰한다.
- 테스트는 vitest, 같은 폴더 `*.test.{tsx,ts}`. 기준은
  docs/conventions/testing-conventions.md.
- 표본: `docs/exemplar/` — types → api → store → UI 관통 슬라이스.

## 전제 (doctor가 경고로 알려준다)

- Node 20+, 프로젝트에 prettier / eslint(+plugins) / vitest / typescript 설치.
- 게이트 명령은 `harness/gate.env`에서 조정.
