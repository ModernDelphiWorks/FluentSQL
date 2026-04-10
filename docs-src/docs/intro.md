---
displayed_sidebar: docsSidebar
title: Documentation portal
slug: /
sidebar_position: 0
---

Welcome to the **FluentSQL** technical documentation portal. Content is derived from source code, tests, and pipeline artifacts.

## Projects

<div className="row">
  <div className="col col--6 margin-bottom--lg">
    <div className="card">
      <div className="card__header">
        <h3>FluentSQL</h3>
      </div>
      <div className="card__body">
        <p>Fluent API for building SQL in Delphi/Lazarus with an AST, per-dialect drivers, and parameters aligned to the generated SQL (including <code>UNION</code> / <code>INTERSECT</code> since v0.2.0). The stable public factory is <code>CreateFluentSQL</code> (since v1.0.0). Later releases added parametrization (<strong>ESP-009</strong>–<strong>ESP-013</strong>, v1.0.3–v1.0.7), canonical MongoDB JSON/MQL (<strong>ESP-014</strong>, v1.0.8), batch INSERT with <code>AddRow</code> / multi-<code>VALUES</code> / Mongo <code>insertMany</code> (<strong>ESP-015</strong>, v1.0.9), explicit per-engine extension via <code>ForDialectOnly</code> (<strong>ESP-016</strong> / <strong>ADR-016</strong>), and in <strong>v1.1.0</strong> shipped DDL helpers for <strong>CREATE TABLE</strong>, <strong>DROP TABLE</strong>, and <strong>ALTER TABLE ADD COLUMN</strong> (Firebird + PostgreSQL for DDL verticals), plus the Docusaurus portal and docs CI workflows.</p>
      </div>
      <div className="card__footer">
        <a className="button button--primary" href="./fluentsql/">Open documentation →</a>
      </div>
    </div>
  </div>
</div>

## Documented release

This portal matches the published **v1.1.0** tag (2026-04-09), per `CHANGELOG.md`, `boss.json`, and repository tags.

- **[1.0.0]** — public API rename: `CreateFluentSQL`, Boss package **FluentSQL** — issue [#13](https://github.com/ModernDelphiWorks/FluentSQL/issues/13).
- **[1.0.3]** — `IN` / `NOT IN` list parametrization — [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19).
- **[1.0.4]** — `array of const` in predicates/DML — [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21).
- **[1.0.5]** — criteria `Expression` + `IFluentSQLParams` — [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23).
- **[1.0.6]** — `Column(array of const)` — [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25).
- **[1.0.7]** — `CaseExpr(array of const)` (**ESP-013**; do not confuse with issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), which tracks **ESP-016** on GitHub).
- **[1.0.8]** — MongoDB JSON/MQL + DML — [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29).
- **[1.0.9]** — batch INSERT (**ESP-015**) — issue [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24) (traceability for this slice; see `CHANGELOG.md` **[1.0.9]**).
- **[1.1.0]** — **ESP-016** ([#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)), **ESP-017** ([#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)), **ESP-018** ([#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29), [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)), **ESP-019** ([#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)); technical debt follow-ups: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

Per-engine extension (`ForDialectOnly`, **ADR-016**): [Explicit per-engine extension](./fluentsql/guides/extensao-por-dialeto) and [API reference](./fluentsql/reference/api).
