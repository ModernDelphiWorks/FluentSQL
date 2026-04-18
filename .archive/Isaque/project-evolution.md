# Project Evolution — FluentSQL

> Canal de visibilidade do ciclo para o dono do produto.  
> Actualizado por `/architect` em cada nova rodada.

**Last updated:** 2026-04-18

---

## Cycle overview

- **ESP-077: (open) Repository Encoding Restoration & Governance Finalization** — Correção massiva de encoding (Mojibake) e fecho de pendências do Kanban.
- **ESP-060: (closed) Kanban Hygiene & Governance (Drift Correction)** — Reconciliação em massa de ~40 cards e implementação de script de prevenção de drift.
- **ESP-074: (closed) DDL: Advanced Truncate (Multi-Table & Partitions)** — Expansão do suporte a TRUNCATE com multi-tabela, RESTART IDENTITY e partições.
- **ESP-073: (closed) DDL: Numeric and Decimal Support** — Suporte a colunas de alta precisão (NUMERIC/DECIMAL) com escala e precisão.
- **ESP-072: (closed) DDL: Foreign Key Referential Actions** — Suporte a ON DELETE/UPDATE CASCADE, SET NULL, etc.
- **ESP-070: (closed) DDL: Stored Procedures and Triggers** — Suporte a Create/Drop para SPs e Triggers, com foco em Enable/Disable Triggers.
- **ESP-069: (closed) SQL-to-MQL Translation: Set Operations (UNION)** — Suporte a UNION e UNION ALL no MongoDB via `$unionWith`.
- **ESP-068: (closed) SQL-to-MQL Translation: Joins ($lookup)** — Suporte a junções entre coleções no MongoDB via aggregation pipeline.
- **ESP-067: (closed) SQL-to-MQL Translation: Aggregations (Group By & Having)** — Suporte a agrupamentos e funções agregadas no MongoDB.
- **ESP-066: (closed) DDL MongoDB Support Phase 4 — Capped & TTL** — Suporte a coleções limitadas e índices de expiração (TTL).
- **ESP-065: (closed) DDL MongoDB Support Phase 3 — Rename & Truncate** — Suporte a renomeação e truncagem de coleções no MongoDB.
- **ESP-064: (closed) DDL MongoDB Support Phase 2 — Index Management** — Expansão para suporte a `createIndexes` e `dropIndexes` no MongoDB.
- **ESP-063: (closed) DDL MongoDB Support (CREATE/DROP COLLECTION)** — Suporte inicial a coleções MongoDB entregue.
- **ESP-062: (closed) DDL Fluent API Refactoring & Test Fragmentation** — Migração concluída com sucesso; test.ddl.pas fragmentado por motor.
- **ESP-061: (closed) DDL Advanced Identity Support (BY DEFAULT / ALWAYS)** — Adição de controle explícito para o escopo de colunas Identity concluída.
- **ESP-060: Kanban Hygiene & README Cleanup** — Reconciliação em massa do quadro Kanban e remoção de referências internas dos READMEs.
- **ESP-059:** **Documentation Refresh: Modern API Patterns (Query & Schema)** — Atualização dos arquivos README para refletir o uso de `Query` e `Schema`.
- **ESP-058:** **DDL Advanced Alter Table: Default Value & Rename Column** — Suporte a `SetDefault`, `DropDefault` e `RenameColumn` para todos os dialetos.
- **ESP-057:** **DDL Alter Table: Constraint Management (ADD/DROP CONSTRAINT)** — Suporte unificado para ADD/DROP PK, Unique, FK e Check em 5 dialetos.
- **ESP-056:** **DDL Index Management (CREATE/DROP INDEX)** — Suporte unificado para criação e remoção de índices em 5 dialetos, incluindo concorrência e idempotência.
- **ESP-055:** **DDL Advanced Constraints (Composite Keys & Named Constraints)** — Suporte a chaves primárias e únicas compostas e nomeação de restrições.
- **ESP-054:** **DDL Sequence Support (CREATE/DROP SEQUENCE)** — Suporte nativo a sequências e geradores para PG, FB e MSSQL.
- **ESP-053:** **DDL View Support (CREATE/DROP VIEW)** — Suporte a vistas lógicas integradas com o motor de SELECT.
- **ESP-052:** **DDL Table and Column Comments Support** — Suporte nativo a descrições de tabelas e colunas para PG, FB, MySQL e MSSQL.
- **ESP-051:** **DDL Identity and Auto-Increment Support** — Implementado e validado para 5 dialetos.
- **ESP-050:** **Advanced DDL: Alter Column Support (Re-work)** — Correção e estabilização da alteração de tipo e nulidade para 5 dialetos.
- **ESP-049:** **Advanced DDL: Computed Columns Support** — Suporte a colunas calculadas via `COMPUTED BY`/`GENERATED ALWAYS` para FB, PG, MySQL e MSSQL.
- **ESP-047:** **Advanced DDL: Rename Table Support** — Adicionado suporte a `AlterTableRename` para 5 dialetos (FB, PG, MySQL, MSSQL, SQLite).
- **ESP-046:** **Pipeline Hygiene & Scope Alignment** — Correção de poluição de root (.gitignore), remoção de `Winapi.Windows` (portabilidade) e auditoria de escopo (string-only).
- **ESP-045:** **Estabilização de Literais de Tipo (Date e GUID)** — Suporte a `dltGuid`, `ColumnGuid`, tradução centralizada de literais via `TUtils`.
- **ESP-044:** **Correção de Literais Booleanos MSSQL** — Tradução driver-aware de booleanos implementada via `TUtils.BooleanToSQLFormat`.
- **ESP-043:** **Alinhamento de Expectativas de Teste DDL** — Fixtures e asserts atualizados para refletir quoting mandatório em todos os dialetos.
- **ESP-041:** **Suporte DDL para MS SQL Server** — Serializador MSSQL inicial implementado.
- **ESP-040:** **Suporte DDL para SQLite** — Serializador, registro e testes validados com 100% de cobertura.
- **ESP-039:** **Refatoração de Entrypoints Globais** — Depreciação de `CreateFluentSQL`/`TCQ` e adição de `Func()` concluídas.
- **ESP-038:** **Remoção de Funções Globais DDL** — 24 funções globais removidas; arquitetura purista OOP/Fluent restaurada.
- **ESP-036:** **DDL Unique & Check Constraints** — Suporte a `.Unique` e `.Check()` implementado e validado.
- **ESP-035:** **DDL Foreign Keys** — Suporte a `REFERENCES` concluído e validado.

---

## Planned / Remaining work

- [x] **ESP-065 Slice 1-3:** Concluído e validado.
- [x] **ESP-066 Slice 1-3:** Concluído e validado.
- [x] **ESP-068 Slice 1-4:** Concluído e validado.

---

## Potential improvements

- `MERGE` (DML) - **ESP-076** (Core skeleton).
- Suporte a `CREATE SCHEMA / DROP SCHEMA` - **ESP-075**.
- Automated Kanban reconciliation script - **ESP-060** (Governance).

---

## Bugs and caveats (new demands)

- **Kanban drift:** ~40 cards accumulated in wrong columns over 30+ rounds. ESP-060 addresses this directly.

---

| 2026-04-18 | ESP-077 | `/architect` — Repository Encoding Restoration & Governance Finalization. Rodada 67. |
| 2026-04-18 | ESP-075/076 | `/architect` — Formalização da Fase 5 do Roadmap: Schemas e MERGE Skeleton. |
| 2026-04-18 | ESP-060 | `/architect` — Kanban Hygiene & Governance (Drift Correction). Rodada 66. |
| 2026-04-18 | ESP-074 | `/architect` — DDL: Advanced Truncate (Multi-Table, Restart Identity e Partições). |
| 2026-04-18 | ESP-073 | `/architect` — DDL Avançado: Suporte a tipos Numeric/Decimal. |
| 2026-04-17 | ESP-072 | `/release` — DDL Avançado: Ações Referenciais em FK (ON DELETE/UPDATE). Entregue e validado. |
| 2026-04-17 | ESP-071 | `/architect` — DDL: Stored Functions (Create/Drop). Entregue e validado na v1.5.0. |
| 2026-04-17 | ESP-070 | `/release` — DDL: Stored Procedures and Triggers. Entregue e validado. |
| 2026-04-17 | ESP-069 | `/architect` — DML MongoDB: Set Operations. Concluído e validado. |
| 2026-04-17 | ESP-068 | `/architect` — DML MongoDB: Joins. Concluído e validado. |
| 2026-04-17 | ESP-067 | `/architect` — DML MongoDB: Aggregations. Concluído e validado. |
| 2026-04-17 | ESP-066 | `/architect` — DDL MongoDB Phase 4. Concluído e validado. |
| 2026-04-17 | ESP-065 | `/architect` — DDL MongoDB Phase 3. Concluído e validado. |
| 2026-04-17 | ESP-064 | `/architect` — DDL MongoDB Index Management. Concluído e validado (createIndexes/dropIndexes). |
| 2026-04-16 | ESP-063 | `/architect` — DDL MongoDB Support. Concluído e validado (Collection Management). |
| 2026-04-16 | ESP-062 | `/architect` — DDL Test Fragmentation Cleanup. Concluído e validado; monolith particionado. |
| 2026-04-16 | ESP-062 | `/architect` — DDL Fluent API Refactoring & Test Fragmentation. Planeada a refatoração para API orientada a contexto (Table.Add.Column) e divisão do `test.ddl.pas` por dialeto. |
| 2026-04-16 | ESP-061 | `/architect` — DDL Advanced Identity Support (BY DEFAULT / ALWAYS). Planeada a expansão da API de Identity para suportar escopos Always e By Default. Rodada 52. |
| 2026-04-15 | ESP-060 | `/architect` — Kanban Hygiene & README Cleanup. Entregue e validado na Rodada 51. |
| 2026-04-15 | ESP-059 | `/implement` — Documentation Refresh: Modern API Patterns (Query & Schema). Entregue na Rodada 50. |
| 2026-04-15 | ESP-058 | `/architect` — DDL Advanced Alter Table: Default Value & Rename Column Completion. |
| 2026-04-15 | ESP-057 | `/architect` — DDL Alter Table: Constraint Management (ADD/DROP CONSTRAINT). Entregue e validado na Rodada 48. |
| 2026-04-15 | ESP-056 | `/architect` — DDL Index Management (CREATE/DROP INDEX). Entregue e validado na Rodada 47. |
| 2026-04-15 | ESP-055 | `/architect` — DDL Advanced Constraints (Composite Keys & Named Constraints). Entregue e validado na Rodada 46. |
| 2026-04-15 | ESP-054 | `/architect` — DDL Sequence Support (CREATE/DROP SEQUENCE). Entregue e validado na Rodada 45. |
| 2026-04-15 | ESP-053 | `/architect` — DDL View Support (CREATE/DROP VIEW). Entregue e validado na Rodada 44. |
| 2026-04-15 | ESP-052 | `/architect` — DDL Table and Column Comments Support. Entregue e validado na Rodada 43. |
| 2026-04-15 | ESP-051 | `/architect` — DDL Identity and Auto-Increment Support. Entregue e validado na Rodada 42. |
| 2026-04-15 | ESP-050 | ESP-050 — Advanced DDL: Alter Column Support (Re-work). Entregue e validado na Rodada 41. |
| 2026-04-14 | ESP-049 | `/architect` — Advanced DDL: Computed Columns Support. Planeada a implementação de campos calculados. |
| 2026-04-14 | ESP-048 | `/architect` — Advanced DDL: Alter Column Support. Planeada a alteração de tipo e nulidade. (Nota: Implementação anterior falhou em teste/compilação, pendente de correção manual ou re-work). |
| 2026-04-14 | ESP-047 | `/architect` — Advanced DDL: Rename Table Support. Planeada a implementação da 11ª vertical de DDL (RENAME TO) para 5 dialetos. |
| 2026-04-14 | ESP-046 | `/architect` — Pipeline Hygiene: Root Pollution Guard & Scope Alignment Audit. Identificados 4 ficheiros residuais + dependência Winapi.Windows. Portabilidade restaurada. |
| 2026-04-14 | ESP-045 | `/architect` — Estabilização de Literais de Tipo (Date e GUID) no DDL. |
| 2026-04-14 | ESP-044 | `/architect` — Correção de Literais Booleanos no Driver MSSQL DDL. |
| 2026-04-14 | ESP-043 | `/architect` — Alinhamento de Expectativas de Teste DDL (Quoting). |
| 2026-04-13 | ESP-042 | `/architect` — Refatoração para Quoting e Estabilização de Conversão DDL. |
| 2026-04-13 | ESP-041 | `/architect` — Planeamento de Suporte DDL para MS SQL Server (Fase 3). |
| 2026-04-13 | ESP-040 | `/architect` — Planeamento de Suporte DDL para SQLite (Fase 3). |
| 2026-04-13 | ESP-039 | `/architect` — Fecho de Refatoração de Entrypoints. |
| 2026-04-13 | ESP-038 | `/architect` — Remoção de funções globais procedurais do DDL. |
| 2026-04-13 | ESP-037 | `/architect` — Refatoração de drivers DDL (Drivers/Registry pattern). |
| 2026-04-13 | ESP-036 | `/architect` — DDL Unique & Check Constraints. |
| 2026-04-13 | ESP-035 | `/architect` — DDL Foreign Keys. |
| 2026-04-13 | ESP-033 | `/architect` — Governança e Root Standardization. |
| 2026-04-13 | ESP-032 | `/architect` — Distributed Cache (Redis). |
| 2026-04-10 | ESP-031 | `/architect` — `ALTER TABLE RENAME TO` (Baseline original). |
