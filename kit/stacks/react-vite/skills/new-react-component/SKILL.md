---
name: new-react-component
description: React 컴포넌트, hook, store를 추가하거나 수정할 때 반드시 사용. 파일 배치, Props 규칙, 데이터 접근 경로, 테스트 동반 기준.
---

# React 컴포넌트 추가 절차

표본: `docs/exemplar/src/`의 health 슬라이스를 그대로 모방한다
(types → api → store → UI 순서).

1. **배치.** 기능 UI는 `src/features/<feature>/`, 공용 프레젠테이션 컴포넌트는
   `src/components/`, 라우트/페이지는 `src/routes/`.
2. **Props.** `interface XxxProps` (type 아님, `I` 접두사 금지). 콜백 prop은
   `on*`, 내부 핸들러는 `handle*`, boolean은 `is/has/can/should`.
3. **데이터 접근.** 컴포넌트에서 `fetch`/`axios` 직접 import 금지 — `src/api/`의
   공용 래퍼를 store/hook 경유로만 사용한다(eslint boundaries가 강제).
4. **상태.** 전역 상태는 zustand store에 — 액션을 노출하고 raw setter를 주지
   않는다. 컴포넌트 지역 상태는 `useState`.
5. **타입.** API 응답 타입은 `src/types/`에 명시. 임시 `any` 금지 — 불가피하면
   이유/범위/제거 조건을 주석으로.
6. **테스트 동반.** 같은 폴더 `*.test.tsx` — 렌더 + 상호작용 + 실패/엣지 케이스.
   기준은 docs/conventions/testing-conventions.md.

## 완료 기준

- `harness/gates/gate.sh` 통과 (prettier / eslint --max-warnings=0 / tsc / vitest).
- 표본 슬라이스와 구조 동형 — 다르면 표본이 아니라 새 코드가 틀린 것이다.
