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
        <p>Fluent API for building SQL in Delphi/Lazarus with an AST, per-dialect drivers, and parameters aligned to the generated SQL (including <code>UNION</code> / <code>INTERSECT</code> since v0.2.0). The stable public factory is <code>CreateFluentSQL</code> (since v1.0.0). Later releases added parametrization (<strong>ESP-009</strong>–<strong>ESP-013</strong>, v1.0.3–v1.0.7), canonical MongoDB JSON/MQL (<strong>ESP-014</strong>, v1.0.8), batch INSERT with <code>AddRow</code> / multi-<code>VALUES</code> / Mongo <code>insertMany</code> (<strong>ESP-015</strong>, v1.0.9), and explicit per-engine extension via <code>ForDialectOnly</code> (<strong>ESP-016</strong> / <strong>ADR-016</strong>). <strong>v1.2.0</strong> (2026-04-13) consolidates the DDL vertical with <strong>Advanced Constraints</strong> (<strong>ESP-034</strong>), <strong>Foreign Keys</strong> (<strong>ESP-035</strong>), and <strong>distributed caching</strong> with Redis (<strong>ESP-032</strong>), plus renaming and truncate support.</p>
      </div>
      <div className="card__footer">
        <a className="button button--primary" href="./fluentsql/">Open documentation →</a>
      </div>
    </div>
  </div>
</div>

## Documented release

This portal matches the published **v1.2.0** tag (2026-04-13), per `CHANGELOG.md`, `boss.json`, and repository tags.

- **[1.0.0]** — public API rename: `CreateFluentSQL`, Boss package **FluentSQL** — issue [#13](https://github.com/ModernDelphiWorks/FluentSQL/issues/13).
- **[1.1.0]** — **ESP-016** ([#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)), **ESP-017** ([#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)), **ESP-018** ([#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29), [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)), **ESP-019** ([#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)).
- **[1.1.1]** — **ESP-020** — `ALTER TABLE DROP COLUMN` ([#34](https://github.com/ModernDelphiWorks/FluentSQL/issues/34)); **ESP-022** — `CREATE [UNIQUE] INDEX` ([#35](https://github.com/ModernDelphiWorks/FluentSQL/issues/35)).
- **[1.2.0]** (today) — **ESP-032** Redis Cache ([#47](https://github.com/ModernDelphiWorks/FluentSQL/issues/47)), **ESP-034** DDL Constraints ([#48](https://github.com/ModernDelphiWorks/FluentSQL/issues/48)), **ESP-035** Foreign Keys ([#49](https://github.com/ModernDelphiWorks/FluentSQL/issues/49)), plus TRUNCATE ([#44](https://github.com/ModernDelphiWorks/FluentSQL/issues/44)) and RENAME ([#45](https://github.com/ModernDelphiWorks/FluentSQL/issues/45), [#46](https://github.com/ModernDelphiWorks/FluentSQL/issues/46)).

Per-engine extension (`ForDialectOnly`, **ADR-016**): [Explicit per-engine extension](./fluentsql/guides/extensao-por-dialeto) and [API reference](./fluentsql/reference/api).

