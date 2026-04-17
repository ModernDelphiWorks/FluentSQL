# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/).
Versionamento segue [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.4.0] — 2026-04-17

### Added
- **MongoDB — Aggregations & Joins (ESP-067, ESP-068, issues [#86], [#87]):** comprehensive SQL-to-MQL mapping for `GROUP BY`, `HAVING`, `INNER JOIN`, and `LEFT JOIN` (using `$lookup`, `$group`, `$unwind`, and `$project` stages).
- **MongoDB — DDL Extensions (ESP-065, ESP-066, issues [#83], [#84], [#85]):** added support for Capped Collections, TTL Indexes, Index Management (Create/Drop), Collection Rename and Truncate.
- **DDL — Procedural Support (ESP-070, ESP-071, issues [#134], [#135]):** added comprehensive support for Stored Procedures, Triggers, and Stored Functions across PostgreSQL, Firebird, MS SQL Server, and MySQL. Includes support for `OR REPLACE`, `IF EXISTS`, and trigger management (Enable/Disable).
- **DDL — Core Expansion (issues [#67], [#68], [#69], [#70], [#71], [#72], [#73], [#74], [#75], [#79], [#82]):**
  - Native Identity / Auto-Increment support and Advanced Identity (`ALWAYS`/`BY DEFAULT`) for PG, FB, and Oracle.
  - Alter Column and Computed Columns support.
  - Native CREATE/DROP VIEW and SEQUENCE support.
  - Table and Column Comments support.
  - Composite/Named Constraints and Alter Table constraint management.
  - Dialect-specific support for MongoDB DDL.

### Changed
- **DDL — API Refactoring (issue [#80]):** transitioned DDL API to a "context-first" pattern to improve readability and consistency across dialects.
- **Repository Strategy:** finalized test suite fragmentation to better handle dialect-specific integration tests.
- **Documentation:** updated DDL guides and README to reflect the expanded feature set and new entry points.

## [1.3.0] — 2026-04-14

### Added
- **DDL — Rename Table Support (ESP-047, issue [#65]):** added `.AlterTableRename(const AOldName, ANewName: string)` to `Schema` API, with dialect-specific serialization for Firebird, PostgreSQL, MySQL, MSSQL (using `sp_rename`), and SQLite.
- **DDL — GUID Type Support (ESP-043, issue [#63]):** centralized GUID literal translation and added support for GUID types in DDL column definitions.
- **DDL — Logic Centralization (ESP-042, issue [#60]):** mandatory identifier quoting and refactored DDL serialization logic into a robust abstract layer.
- **Core — Portability (ESP-046, issue [#64]):** removed `Winapi.Windows` dependency from `FluentSQL.DDL.pas` for better cross-platform support.

### Fixed
- **MSSQL — Boolean Serialization (issue [#62]):** fixed compatibility issues with boolean literal serialization in MSSQL environments.
- **Pipeline — Root Cleanliness (issue [#64]):** enforced "no root pollution" policy, redirecting temporary artifacts to `.local-readonly/`.

### Tests
- DUnitX: `TTestDDLAlterTableRenameTable` coverage for all 5 core dialects.
- Verified 157 passing tests in the Firebird suite.


## [1.2.0] — 2026-04-13

### Added
- **DDL — Foreign Keys (ESP-035, issue [#49]):** added `.References(const ATableName, AColumnName: string)` support for `CREATE TABLE` and `ALTER TABLE ADD COLUMN` (Firebird, PostgreSQL).
- **DDL — Advanced Constraints (ESP-034, issue [#48]):** support for `NOT NULL`, `DEFAULT`, and `PRIMARY KEY` in `CREATE TABLE` and `ALTER TABLE ADD COLUMN`.
- **Cache — Redis Provider (ESP-032, issue [#47]):** distributed SQL string caching with support for Redis as a back-end, including deterministic AST-based hashing (`TFluentSQL.AsString`) to prevent cache collisions.
- **DDL — RENAME COLUMN/TABLE (ESP-030, ESP-031, issues [#45], [#46]):** added `.RenameTo` and `RenameColumn` for PostgreSQL, Firebird, and MySQL.
- **DDL — TRUNCATE TABLE (ESP-029, issue [#44]):** fluent API for `TRUNCATE TABLE` and serialization across multiple dialects.
- **DDL — DROP INDEX improvements (ESP-025, ESP-026, ESP-027, ESP-028, issues [#40], [#41], [#42], [#43]):** added `DROP INDEX`, support for `IF EXISTS`, `CONCURRENTLY` (PostgreSQL), and `ON table` (MySQL/MariaDB).

### Changed
- **Documentation:** updated DDL guides (foreign keys, renaming, create table) and API reference. Root directory cleanup (`VISIBILIDADE-EXECUCAO.md` removed).

## [1.1.1] — 2026-04-10

### Added
- **DDL — ALTER TABLE DROP COLUMN (ESP-020, ADR-020, issue [#34](https://github.com/ModernDelphiWorks/FluentSQL/issues/34)):** `CreateFluentDDLAlterTableDropColumn`, `DDLAlterTableDropColumnSQL` e serialização Firebird/PostgreSQL; guia `ddl-alter-table-drop-column.md`.
- **DDL — CREATE [UNIQUE] INDEX (ESP-022, ADR-022, issue [#35](https://github.com/ModernDelphiWorks/FluentSQL/issues/35)):** `CreateFluentDDLCreateIndex`, `DDLCreateIndexSQL` (Firebird, PostgreSQL); guia `ddl-create-index.md`; testes DUnitX adicionais (incl. multi-coluna Firebird e nomes vazios).

### Changed
- **Documentação:** alinhamento do índice do portal e da referência de API com ESP-020/ESP-022; quadro de visibilidade de execução em `VISIBILIDADE-EXECUCAO.md` (ESP-024).

### Tests
- DUnitX: `TTestDDLAlterTableDropColumn`, `TTestDDLCreateIndex` em `Test Delphi/test.ddl.pas` (suíte Firebird).

## [1.1.0] — 2026-04-09

### Added
- **Extensão explícita por motor (ESP-016, ADR-016, issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)):** API de opt-in por dialeto (`ForDialectOnly` / serialização por motor), alinhada a `FluentSQL.Serialize.pas` e documentação em `docs-src`.
- **DDL — CREATE TABLE (ESP-017, ADR-017, issue [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)):** API fluente e `DDLCreateTableSQL` para Firebird e PostgreSQL com `TDDLLogicalType`.
- **DDL — DROP TABLE (ESP-018, ADR-018, issues [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29) / [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)):** API fluente e serialização de texto SQL para `DROP TABLE`.
- **DDL — ALTER TABLE ADD COLUMN (ESP-019, ADR-019, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)):** uma coluna lógica por `AsString`, reutilização do mapeamento de tipos do CREATE e paridade Firebird/PostgreSQL.
- **Documentação e CI:** portal Docusaurus em `docs-src/`, `ROADMAP.md` operacional, fluxos `.github/workflows/docs-build.yml` e `deploy-docs.yml`, e guias DDL (`ddl-create-table`, `ddl-drop-table`, `ddl-alter-table-add-column`).

### Tests
- DUnitX em `Test Delphi/test.ddl.pas` para CREATE/DROP/ALTER (matriz referida nos relatórios de review/test; execução MSBuild sujeita a caveats).

Dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

## [1.0.9] — 2026-04-08

### Added
- **INSERT em lote (ESP-015, ADR-014, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)):** `AddRow` no fluente (contexto `Insert`) fecha a linha corrente e abre a próxima; `AsString` faz *flush* implícito da linha pendente. SQL: `VALUES (...), (...)` com placeholders na ordem linha a linha (**ADR-009**). MongoDB (`dbnMongoDB`): `insertMany` com `documents` quando há mais de uma linha; uma linha continua com `insertOne`.

### Tests
- DUnitX: `test.core.params` (Firebird + MySQL, batch parametrizado); `UTestFluentSQLFirebird` (`insertMany` Mongo).

Dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

## [1.0.8] — 2026-04-08

### Changed (breaking)
- **MongoDB (`dbnMongoDB`, ESP-014, issue [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29)):** `TFluentSQLSelectMongoDB.Serialize` deixa de emitir pseudo-SQL `colecao.find({...})` e passa a devolver o fragmento JSON **ADR-013** §2b `{"collection":"…","projection":{…}}`, partilhando a mesma lógica de projeção que `TFluentSQLSerializerMongoDB` (**2b** + **2c**). Quem dependia da string antiga deve migrar.

### Added
- **MongoDB — DML (ADR-013 Opção A):** `IFluentSQL.AsString` para `Insert` / `Update` / `Delete` em `dbnMongoDB` emite JSON mínimo e estável: `insertOne`, `updateMany` (com `filter` + `update.$set`) e `deleteMany`, com resolução de placeholders `:pN` nos documentos via `IFluentSQLParams` (sem literais `:pN` no JSON final).
- **`TFluentSQL.MongoSelectFragment`:** fragmento da secção SELECT em JSON para `dbnMongoDB` (vazio noutros dialetos); útil para testes e introspecção.
- **WHERE Mongo:** prefixo `NOT ` a nível de expressão → `{"$nor":[…]}` (um eixo de extensão do parser documentado na ESP-014).
- **Guardas:** `WITH` / `UNION` / `INTERSECT` em `dbnMongoDB` levantam `EFluentSQLMongoDBSerialize` com mensagem estável em vez de SQL inválido.

### Tests
- DUnitX em `UTestFluentSQLFirebird.pas`: DML Mongo (`insertOne` / `updateMany` / `deleteMany`), coerência `MongoSelectFragment` vs `AsString`, e `NOT` → `$nor`.

Dívida técnica pós-caveats: [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30).

## [1.0.7] — 2026-04-08

### Changed
- **Parametrização (ESP-013):** `TFluentSQL.CaseExpr(array of const)` passa a usar `SqlArrayOfConstToParameterizedSql` com `FAST.Params` (**ADR-009**, **ADR-011**, **ADR-012**). Escalares na expressão discriminante do `CASE` passam a placeholders; strings no array continuam fragmentos literais. Rastreio da entrega: esta secção **[1.0.7]** (não confundir com a issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), hoje **ESP-016** / fecho formal). Dívida técnica pós-caveats: [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28).

## [1.0.6] — 2026-04-08

### Changed
- **Parametrização (ESP-012, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25)):** `TFluentSQL.Column(array of const)` passa a usar `SqlArrayOfConstToParameterizedSql` com `FAST.Params`, alinhado a **ADR-009** / **ADR-011**; escalares na projeção viram placeholders em vez de literais concatenados. `CaseExpr(array of const)` foi migrado em **ESP-013** (ver **[1.0.7]** acima). Dívida técnica pós-caveats: [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26).

## [1.0.5] — 2026-04-08

### Changed
- **Parametrização (ESP-011, issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23)):** `TFluentSQLCriteriaExpression` usa `SqlArrayOfConstToParameterizedSql` quando associada a `IFluentSQLParams` (contexto `TFluentSQL` / `TFluentSQLCriteriaCase`); `Expression(array of const)` e `Expression(string)` no fluente recebem a coleção do AST. Sobrecargas `array of const` em joins/having/where herdam o mesmo contrato da ESP-010; **strings** em `TVarRec` continuam sem bind automático (**ADR-011**). `CaseExpr(array of const)` e `Column(array of const)` permanecem com `SqlParamsToStr`.

### Added
- Testes DUnitX em `test.core.params.pas` cobrindo critérios/expressão com `array of const` via `Where`. Dívida técnica pós-caveats: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).

## [1.0.4] — 2026-04-08

### Changed
- **Parametrização (ESP-010, issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21)):** sobrecargas com `array of const` em `Where`, `AndOpe`, `OrOpe`, `Having`, `OnCond`, `SetValue`, `Values` (`FluentSQL.pas`) e `When`, `AndOpe`, `OrOpe` em `TFluentSQLCriteriaCase` (`FluentSQL.Cases.pas`) passam a expandir **valores escalares** (inteiro, int64, extended, currency, boolean, variant numérico/data) via `IFluentSQLParams` e placeholders (`:pN` no AST); entradas **textuais** em `TVarRec` (identificadores, operadores `Char`, strings) continuam literais na expressão, alinhado a **RN-P3**. Helper novo: `TUtils.SqlArrayOfConstToParameterizedSql`. `CaseExpr(array of const)`, `Column(array of const)` e `Expression(array of const)` mantêm `SqlParamsToStr` (expressão mista / nomes).

### Added
- Testes DUnitX em `test.core.params.pas`: `Where`/`Having`/`Values`/`CASE WHEN` com `array of const` e parâmetros. Dívida técnica pós-caveats: [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22).

### Fixed
- `Test Delphi/MSSQL_tests/test.select.mssql.pas`: asserts de `WHERE` com `GreaterEqThan`/`LessEqThan` esperam `:p1`/`:p2`; `ORDER BY` espera sufixo `ASC`, coerente com a serialização atual (runner usa `CreateFluentSQL(dbnFirebird)` nestes casos).

## [1.0.3] — 2026-04-08

### Changed
- **Parametrização (ESP-009):** predicados `IN` / `NOT IN` com listas (`TArray<String>`, `TArray<Double>`) passam a emitir placeholders (`:p1`, `:p2`, …) e a preencher `IFluentSQLParams` por elemento; subconsultas em `InValues(string)` / `NotIn(string)` continuam literais entre parênteses. Operadores SQL normalizados para `IN` e `NOT IN` na concatenação. Ver issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19).
- Testes Firebird `test.operators.isin.firebird` (ligado a `PTestFluentSQLFirebird.dpr`) e suíte MySQL (`test.functions.mysql`, `test.select.mysql`) alinhados a placeholders e `ORDER BY … ASC` onde a serialização atual já produz esse formato.

### Added
- Fixture DUnitX `Test Delphi/test.core.params.pas` integrado em `PTestFluentSQLFirebird.dpr` e `TestFluentSQL_MySQL.dpr` (cenários Firebird, MySQL e PostgreSQL no runner Firebird). Dívida técnica pós-caveats: [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20).

## [1.0.2] — 2026-04-08

### Changed
- `ROADMAP.md`: encerramento da **Fase 0** no âmbito consumidor após auditoria **ESP-008**; checklist **R1–R6** com evidências citáveis; bloco **Estado atual** com próximo foco na **Fase 1** (parametrização / prepared statements). Ver issue [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17). Dívida técnica pós-caveats: [#18](https://github.com/ModernDelphiWorks/FluentSQL/issues/18).

## [1.0.1] — 2026-04-08

### Added
- `ROADMAP.md` como artefato operacional e evolutivo: política de gatilhos (`/architect`, `/sprint`, `/release`, conclusão de implementação), histórico de evolução, estado/foco ligado ao pipeline (`.claude/pipeline/`), fase **Meta — Governança do roadmap** e alinhamento checklist ↔ relatórios. Ver issue [#15](https://github.com/ModernDelphiWorks/FluentSQL/issues/15). Dívida técnica pós-caveats: [#16](https://github.com/ModernDelphiWorks/FluentSQL/issues/16).

## [1.0.0] — 2026-04-08

### Changed (breaking)
- **API:** a fábrica global `CQuery` foi substituída por `CreateFluentSQL` na unit `FluentSQL.pas`. Código que chamava `CQuery(dbn…)` deve usar `CreateFluentSQL(dbn…)`. (O nome `NewFluentSQL` do ADR foi evitado: em Delphi o token `New` pode ser interpretado como o intrínseco `New`, quebrando encadeamentos como `.&As(…)` após a chamada da fábrica.)
- **Testes / Boss / metadados:** projetos DUnitX renomeados para o prefixo `TestFluentSQL_*`; pacote Boss passa a publicar-se como **FluentSQL** (antes `CQuery4D`). Unidades e fixtures de teste deixam de usar `CQL` / `TCQL.New` em favor de `FluentSQL` / `CreateFluentSQL`.

| Antes | Depois |
|--------|--------|
| `CQuery(dbnFirebird)` | `CreateFluentSQL(dbnFirebird)` |
| `TCQL.New(dbnMSSQL)` | `CreateFluentSQL(dbnMSSQL)` |
| `TCQL.SetDatabaseDafault(...)` | `TFluentSQL.SetDatabaseDafault(...)` |
| `uses CQL, CQL.Interfaces` | `uses FluentSQL, FluentSQL.Interfaces` |
| `CQL.Q('x')` (literais em CASE) | `TFluentSQLFunctions.QFunc('x')` com `FluentSQL.Functions` em uses |

Ver issue [#13](https://github.com/ModernDelphiWorks/FluentSQL/issues/13). Dívida técnica pós-caveats: [#14](https://github.com/ModernDelphiWorks/FluentSQL/issues/14).

## [0.2.0] — 2026-04-08

### Added
- Planejamento da evolução do framework para suporte a recursos avançados de SQL (CTE, Window Functions, etc).
- Planejamento de melhorias de segurança através de Prepared Statements (Parametrização).
- Planejamento de novos serializadores (MongoDB MQL, REST API).
- Mescla ordenada de parâmetros em operações de conjunto (`UNION`, `UNION ALL`, `INTERSECT`): coleção `Params` alinhada à ordem dos placeholders na SQL final, com reindexação do ramo secundário e suporte MySQL (`?`). Ver issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11).
- Módulo `FluentSQL.Params.pas` com visão mesclada de parâmetros em queries compostas.
- Testes DUnitX (Firebird e MySQL) cobrindo parâmetros nos dois lados do conjunto.

### Changed
- Serialização de conjuntos e driver MySQL para contagem total de placeholders em `UNION`.
- Ajustes correlatos em AST, operadores, interfaces e registro de drivers (MongoDB, Firebird, SQLite) integrados à entrega revisada.

---

## [0.1.0] — 2026-04-07

### Added
- Versão inicial do projeto documentada no Ecossistema Delphi.
- Suporte básico para SELECT, INSERT, UPDATE, DELETE em múltiplos dialetos.
- Abstração via AST (Abstract Syntax Tree).
