# FluentSQL

🇵🇹 [Português](README.md) · Repository: [github.com/ModernDelphiWorks/FluentSQL](https://github.com/ModernDelphiWorks/FluentSQL)

**License:** [MIT](LICENSE)

---

**FluentSQL** is a **Delphi** and **Lazarus** library with one contract: **it only emits `string`** — **SQL** scripts (and, where the driver targets another format, equivalent **text**, e.g. **MQL/JSON**) through a **fluent, object-oriented API** (classes/interfaces, method chaining). **CRUD**, **DDL**, and whatever the API models always become **text** plus **`Params`** when applicable; there is **no** connection, **no** execution on the server, **no** catalog introspection, and **no** “class ↔ database” validation *inside* this package — that stays in your app or in other layers (for example an ORM such as **[Janus](https://github.com/ModernDelphiWorks/Janus)**, which lists FluentSQL as a dependency for SQL construction).

---

## Feature matrix

| Feature | Status |
|---------|--------|
| Fluent DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) | ✅ |
| Fluent DDL (`CREATE TABLE`, `DROP TABLE`, `ALTER` ADD/DROP column — dialect-dependent) | ✅ |
| Multi-dialect serialization (`dbn*`, `Source/Drivers/`) | ✅ |
| Parameterization (`IFluentSQLParams`, `:pN` / `?` placeholders) | ✅ |
| `UNION` / `UNION ALL` / `INTERSECT` with merged `Params` | ✅ |
| Batch INSERT (multi-`VALUES` / Mongo `insertMany`) | ✅ |
| **MongoDB** driver (MQL/JSON as text) | ✅ |
| Per-engine explicit extension (dialect opt-in, **ESP-016** / **ADR-016**) | ✅ |
| **String generation only via OOP** — no data-access layer | ✅ *by design* |

---

## Engines & dialects (reference)

Firebird · InterBase · MySQL · PostgreSQL · Microsoft SQL Server · Oracle · IBM DB2 · SQLite · Informix · Advantage (ADS) · SQL Anywhere (ASA) · Absolute Database · ElevateDB · NexusDB · MongoDB (MQL) — *actual serializer registration depends on your build and `FluentSQL.Register.pas`; see the docs.*

---

## Delphi / Lazarus versions

- **Delphi:** XE or later (or the version used by the test projects).
- **Lazarus / FPC:** wherever the repository is validated for your target.

---

## Install (Boss)

```sh
boss install FluentSQL
```

The Boss package name is **FluentSQL**. Older material may mention `CQuery4D` or `CQLBr`; see the migration table in [CHANGELOG.md](CHANGELOG.md).

## Dependencies

The root Boss manifest does **not** force mandatory transitive packages for the core: add `Source/` and whichever drivers you compile. Test projects under `Test Delphi/` use per-`.dpr` defines to enable dialects (see [configuration](docs-src/docs/fluentsql/reference/configuration.md)).

---

## Quick start (DML)

```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

The `Query(dbnDialect)` method is the primary entry point for **DML** operations (Select, Insert, Update, Delete). The `TCQ(dbnDialect)` shortcut is also available for backward compatibility.

## Quick start (DDL)

```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateTable('PRODUTOS')
      .Column('ID', dltInteger).NotNull.PrimaryKey
      .Column('NOME', dltString, 100).NotNull
      .Column('PRECO', dltNumeric, 12, 2).Default(0)
    .AsString;
end;
```

The `Schema(dbnDialect)` method is the entry point for **DDL** operations (Create, Alter, Drop, Truncate).

---

## Documentation

| Doc | Description |
|-----|-------------|
| [Index / overview](docs-src/docs/fluentsql/index.md) | Main entry |
| [Introduction](docs-src/docs/fluentsql/introduction.md) | Context and scope |
| [Installation](docs-src/docs/fluentsql/getting-started/installation.md) | Boss and search path |
| [Quick start](docs-src/docs/fluentsql/getting-started/quickstart.md) | First end-to-end flow |
| [Architecture](docs-src/docs/fluentsql/architecture/overview.md) | AST, drivers, flow |
| [API reference](docs-src/docs/fluentsql/reference/api.md) | Public contracts |
| [Configuration & `dbn*`](docs-src/docs/fluentsql/reference/configuration.md) | Dialect constants |
| [Tests](docs-src/docs/fluentsql/tests/overview.md) | DUnitX suite |
| [Troubleshooting](docs-src/docs/fluentsql/troubleshooting/common-errors.md) | Common errors |
| [Docs CI](docs-src/docs/fluentsql/getting-started/documentation-ci.md) | Docusaurus / GitHub Actions |

The static site under `docs/` is built and committed in CI when `docs-src/` changes on `main` or `develop` ([`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml)). PRs touching `docs-src/` are validated by [`.github/workflows/docs-build.yml`](.github/workflows/docs-build.yml).

---

## Ecosystem

- **[Janus](https://github.com/ModernDelphiWorks/Janus)** — Delphi ORM bridging OO models and relational databases; uses **FluentSQL** for SQL construction, while persistence, metadata, and model↔DB validation live in Janus and its own dependencies (e.g. MetaDbDiff, DataEngine). FluentSQL stays **strings-only**.

---

## Tests

**DUnitX** projects under `Test Delphi/`:

| Project | Notes |
|---------|--------|
| `Firebird_tests/PTestFluentSQLFirebird.dpr` | Main parameterized / multi-dialect scenarios. |
| `Firebird_tests/PTestFluentSQLSample.dpr` | Minimal sample. |
| `*_tests/TestFluentSQL_<Dialect>.dpr` | MSSQL, MySQL, Oracle, DB2, Interbase, etc. |

**Roadmap:** [ROADMAP.md](ROADMAP.md) · **Dialect extension (ESP-016 closure):** issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), guide [extensao-por-dialeto.md](docs-src/docs/fluentsql/guides/extensao-por-dialeto.md).

---

## Contributing

Issues and pull requests are welcome. For larger changes, open an issue first to align scope — the product rejects proposals that turn the core into a data-access layer or server execution engine (see [ROADMAP.md](ROADMAP.md)).

---

## License

[MIT](LICENSE).
