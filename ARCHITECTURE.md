# ARCHITECTURE.md

The architecture index. **Reading order for any change:** `AGENTS.md` → this file →
the linked detail docs. This file stays short; detail lives under `docs/architecture/`.

> When copied into a real project, replace the `<…>` placeholders with the project's
> actual shape. Keep it current — an out-of-date architecture doc misleads every agent.

## System shape
`<one paragraph: what the system is, its main moving parts, and how a request flows
through them>`

## Layers & dependency direction
Code flows in one direction only:

```
Types → Config → Repository → Service → Runtime/API → UI
```

A lower layer must never import a higher one. The rule, the per-stack enforcement
(eslint-plugin-boundaries / ArchUnit / import-linter), and the rationale are in
[`docs/architecture/principles.md`](docs/architecture/principles.md).

## Where things live
The repo map (top-level areas, source layout, key commands):
[`docs/architecture/MAP.md`](docs/architecture/MAP.md).

## Key decisions
Why the system is the way it is: [`docs/decisions/`](docs/decisions/).
