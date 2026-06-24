# Stack: React (Vite + Zustand) + TypeScript

Inline the relevant parts of this into the project's root `AGENTS.md` §6.

## Layout & layering

```
src/
  types/        # domain types, API DTOs, zod schemas          (Types)
  config/       # env, constants, theme                        (Config)
  api/          # fetch/axios clients — the only place we talk HTTP   (Repository)
  stores/       # zustand stores — app state + actions          (Service)
  hooks/        # composition over stores + api                 (Service/Runtime)
  features/     # feature-scoped UI (components + local state)   (UI)
  components/   # shared/dumb presentational components          (UI)
  routes/       # route components / pages                       (UI)
```

Direction: `types → config → api → stores → hooks → features/components/routes`.
UI never imports `api` directly — it goes through stores/hooks.

## Mechanical enforcement
- **Layering:** `eslint-plugin-boundaries` or `import/no-restricted-paths` — forbid UI →
  api, and any import that points "right". A violation fails CI.
- **Format:** `prettier --check .`
- **Lint:** `eslint . --max-warnings=0`
- **Types:** `tsc --noEmit`

## Verification commands (AGENTS.md §4)
```bash
pnpm format        # prettier --write .
pnpm lint          # eslint . --max-warnings=0
pnpm typecheck     # tsc --noEmit
pnpm test          # vitest run --coverage
pnpm e2e           # playwright test
```

## Conventions
- Zustand stores expose actions, not raw setters; components dispatch actions only.
- All network calls live in `src/api/`; components never call `fetch` directly.
- Validate external data at the boundary with zod; downstream code trusts the types.
- Co-locate a `*.test.tsx` with each non-trivial component; e2e covers each user flow.
