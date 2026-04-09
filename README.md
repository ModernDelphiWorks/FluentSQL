# FluentSQL

**FluentSQL** is a Delphi/Lazarus library for building SQL through a fluent interface. You describe *what* you want (select, joins, where, unions, parameters) once; the framework serializes to the dialect you configure (Firebird, MySQL, MSSQL, PostgreSQL, Oracle, DB2, Interbase, MongoDB MQL, and others supported under `Source/Drivers/`).

Repository: [github.com/ModernDelphiWorks/FluentSQL](https://github.com/ModernDelphiWorks/FluentSQL)

## Requirements

- Embarcadero Delphi XE or later (or a compatible FPC/Lazarus setup where the project is validated).

## Install (Boss)

```sh
boss install FluentSQL
```

Package name in `boss.json` is **FluentSQL**. Older tutorials may refer to `CQuery4D` or `CQLBr`; see [CHANGELOG.md](CHANGELOG.md) for the migration table.

## Quick example

```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := CreateFluentSQL(dbnFirebird)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

The shorthand `TCQ(dbnFirebird)` in unit `FluentSQL` is equivalent to `CreateFluentSQL`. Use `IFluentSQL` / `FluentSQL.Interfaces` in consuming code.

## Documentation

- User-oriented docs live under [docs-src/docs/fluentsql/](docs-src/docs/fluentsql/) (Docusaurus).
- The static site under `docs/` is **built and committed on GitHub Actions** (workflow [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml)) when `docs-src/` changes on `main` or `develop`. Pull requests that touch `docs-src/` are validated by [`.github/workflows/docs-build.yml`](.github/workflows/docs-build.yml). A local Node install is **not** required to edit Markdown only; see [documentation-ci.md](docs-src/docs/fluentsql/getting-started/documentation-ci.md).
- Operational notes for agents: [.claude/SKILL.md](.claude/SKILL.md) and [.claude/references/](.claude/references/).

## Tests

DUnitX projects are under `Test Delphi/`:

- `Firebird_tests/PTestFluentSQLFirebird.dpr` — main parameterized / multi-dialect scenarios.
- `Firebird_tests/PTestFluentSQLSample.dpr` — minimal scaffold.
- `*_tests/TestFluentSQL_<Dialect>.dpr` — per-dialect suites (MSSQL, MySQL, Oracle, DB2, Interbase).

Build commands used in automation are listed in `.claude/SKILL.md` (section **Comandos**).

**Release / roadmap:** **ESP-016** (extension opt-in by dialect, **ADR-016**) is tracked as closed on the roadmap as of 2026-04-09 — issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), `TestDialectOnly*` in `Test Delphi/test.core.params.pas`, guide [extensao-por-dialeto.md](docs-src/docs/fluentsql/guides/extensao-por-dialeto.md). Internal pipeline artifacts under `.claude/pipeline/` (if present locally) reference the same closure; that folder may be gitignored on your machine.

## License

Apache-2.0 — see [LICENSE](LICENSE).
