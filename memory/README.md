# memory/

**Persistent, filesystem-backed memory** — the third pillar of the harness. Chat history
is disposable; anything that must survive across sessions lives here as a file.

## What goes here
- Environment quirks ("Postgres runs on 5433 locally, not 5432").
- Hard-won gotchas ("Redis keys are namespaced by tenant; forgetting this leaks data").
- Conventions discovered mid-project that aren't yet a lint rule.
- Pointers to external resources (dashboards, tickets) — URL + one line of context.

## What does NOT go here
- Anything the repo already records (code structure, git history, CLAUDE.md).
- Decisions → `docs/decisions/`. Plans → `docs/plans/`. Designs → `docs/specs/`.
- Secrets. Ever.

## Format
One fact per file, kebab-case name, e.g. `local-postgres-port.md`. Keep an index in
this README so an agent can scan it cheaply (progressive disclosure).

## Index
<!-- - [local-postgres-port](local-postgres-port.md) — DB listens on 5433 in dev -->
_(empty — add entries as you learn things worth keeping)_
