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
        <p>Fluent API for building SQL in Delphi/Lazarus with an AST, per-dialect drivers, and parameters aligned to the generated SQL. The stable public factory is <code>Query(ADialect)</code> for DML and <code>Schema(ADialect)</code> for DDL (since v1.3.0). <strong>v1.5.1</strong> (2026-04-20) includes <strong>Full MERGE DML Support</strong> and <strong>Scalar Math Functions Parity</strong> (<strong>ESP-079</strong>).</p>
      </div>
      <div className="card__footer">
        <a className="button button--primary" href="./fluentsql/">Open documentation →</a>
      </div>
    </div>
  </div>
</div>

## Documented release

This portal matches the published **v1.5.1** tag (2026-04-20), per `CHANGELOG.md`, `boss.json`, and repository tags.

- **[1.5.1]** (today) — **Full MERGE DML Support** (Issue [#146]), **Scalar Math Functions Parity** (Round, Floor, Ceil, Abs), and **Standardization** (Issue [#141]).
- **[1.5.0]** — **DDL Schema Support** (Issue [#142]), **DML MERGE Skeleton** (Issue [#142]), **DDL Advanced Truncate** (Issue [#136]).
- **[1.4.0]** — **MongoDB Aggregations & Joins** (Issues [#86], [#87]), **MongoDB DDL** (Capped Collections, TTL Indexes), **DDL Core Expansion** (Views, Sequences, Identity, Comments).
- **[1.3.0]** — **ESP-047** ([#65](https://github.com/ModernDelphiWorks/FluentSQL/issues/65)) Rename Table, GUID support, and DDL API refactoring.
- **[1.2.0]** — **ESP-032** Redis Cache ([#47](https://github.com/ModernDelphiWorks/FluentSQL/issues/47)), **ESP-034** DDL Constraints ([#48](https://github.com/ModernDelphiWorks/FluentSQL/issues/48)), **ESP-035** Foreign Keys ([#49](https://github.com/ModernDelphiWorks/FluentSQL/issues/49)), plus TRUNCATE and RENAME.

Per-engine extension (`ForDialectOnly`, **ADR-016**): [Explicit per-engine extension](./fluentsql/guides/extensao-por-dialeto) and [API reference](./fluentsql/reference/api).

