# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/).
Versionamento segue [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Removed

- **BREAKING CHANGE — `TFluentSQLDriver` perdeu 6 valores.** Foram removidos da enum pública (`FluentSQL.Interfaces.pas`), do `FluentSQL.Register.pas`, do `FluentSQL.Utils.pas` e do `FluentSQL.inc`:
  `dbnInformix`, `dbnADS`, `dbnASA`, `dbnAbsoluteDB`, `dbnElevateDB`, `dbnNexusDB`.
  Nenhum deles jamais teve implementação: as units `FluentSQL.Serialize*`, `FluentSQL.Select*` e `FluentSQL.Functions*` correspondentes não existem no repositório, e o `uses` condicional do `Register` referenciava ficheiros inexistentes. Qualquer chamada com esses valores terminava em `EAccessViolation`.
  **O que fazer:** código que nomeie qualquer um dos 6 deixa de compilar (`E2003 Undeclared identifier`). Não há substituto — migre para um dos 9 dialetos restantes (`dbnMSSQL`, `dbnMySQL`, `dbnFirebird`, `dbnSQLite`, `dbnInterbase`, `dbnDB2`, `dbnOracle`, `dbnPostgreSQL`, `dbnMongoDB`). `dbnInterbase` e `dbnDB2` **permanecem**: têm implementação real, apenas continuam desligados por omissão no `FluentSQL.inc`.
- Removidos overrides mortos e inalcançáveis de `Round`, `Floor` e `Abs` em `FluentSQL.Functions{MSSQL,MySQL,PostgreSQL}.pas`, e os overrides de agregação de `FluentSQL.FunctionsMongoDB.pas`.

### Changed

- **BREAKING CHANGE (SQL emitido) — a paginação mudou de forma em 5 dos 7 dialetos ativos.** O framework anunciava paginação nos sete e ela só estava correta em dois (PostgreSQL e MongoDB). Quem compara o SQL gerado com string fixa **precisa atualizar as expectativas**; quem executa a consulta passa a executar SQL que o motor aceita. Com `Skip(20)` sozinho, antes → depois:

  | Dialeto | Antes | Depois |
  |---|---|---|
  | MSSQL | `...) AS T WHERE (ROWNUMBER > 20)` (subconsulta + `ROW_NUMBER()`) | `... ORDER BY (SELECT NULL) OFFSET 20 ROWS` |
  | Oracle | `...) AND ROWINI > 20` — **`AND` sem `WHERE`**, `ORA-03048` | `... OFFSET 20 ROWS` |
  | SQLite | `SELECT OFFSET 20 * FROM T` — **posição errada na gramática**, inválido sempre | `... LIMIT -1 OFFSET 20` |
  | MySQL | `... OFFSET 20` — **`OFFSET` sem `LIMIT`**, `ERROR 1064` | `... LIMIT 18446744073709551615 OFFSET 20` |
  | Firebird | `SELECT SKIP 20 * FROM T` | inalterado |
  | PostgreSQL | `... OFFSET 20` | inalterado |
  | MongoDB | `"skip":20` | inalterado |

  Os tetos do MySQL (2^64−1) e do SQLite (`LIMIT -1`) não são invenção: são as receitas documentadas em cada manual para "todas as linhas a partir de um deslocamento", e são **necessários** porque nesses dois motores `OFFSET` não é cláusula independente — só no PostgreSQL é. O **Firebird não migrou** para `OFFSET/FETCH` de propósito: `FIRST/SKIP` funciona em toda versão (inclusive 2.5) e aceita expressão, enquanto o `OFFSET/FETCH` do Firebird só aceita literal ou parâmetro.

  No MSSQL, como `<offset_fetch>` só existe dentro de um `ORDER BY`, sem `OrderBy` do usuário é emitido `ORDER BY (SELECT NULL)` — preenchimento **gramatical**, que não promete determinismo e não acrescenta operador `Sort` ao plano. Sob `DISTINCT` ou `UNION` o motor recusa `(SELECT NULL)` (`Msg 145` e `Msg 104`) e é emitido `ORDER BY 1`, o único item que está sempre na lista de seleção. Todas as formas foram medidas em motor real; os `docker run`, versões e saídas brutas estão em `Test Delphi\Common_tests\test.pagination.<dialeto>.sql`.

- **BREAKING CHANGE (SQL emitido) — `First(0)` passou a devolver zero linhas nos 7 dialetos.** `First(0)` é pedido legítimo e distinto de "sem `First`", como o próprio `TFluentSQLPagination` declara. Estava errado em dois dialetos, cada um de um jeito:

  | Dialeto | Antes | Depois |
  |---|---|---|
  | MSSQL | `... OFFSET 0 ROWS FETCH NEXT 0 ROWS ONLY` — **`Msg 10744`**, recusado | `SELECT TOP 0 ...` → 0 linhas |
  | MSSQL, com `UNION`/`UNION ALL`/`EXCEPT`/`INTERSECT` | idem | `... ORDER BY 1 OFFSET 9223372036854775807 ROWS` → 0 linhas |
  | MongoDB (`find`) | `"limit":0` — **devolvia a coleção INTEIRA**, em silêncio | `"skip":9223372036854775807` → 0 documentos |
  | MongoDB (`aggregate`) | `{"$limit":0}` — `the limit must be positive` | `{"$skip":9223372036854775807}` → 0 documentos |
  | Firebird / MySQL / SQLite / PostgreSQL / Oracle | já corretos | inalterados |

  No MongoDB `limit: 0` significa **sem limite** — o usuário pedia nada e recebia tudo, sem erro. Era o único dos sete em que `First(0)` falhava calado, e os dois caminhos do próprio driver (`find` e `aggregate`) discordavam entre si sobre o que `First(0)` queria dizer.

  No SQL Server a restrição é do **literal**, não da semântica: o mesmo `FETCH` com o contador vindo de uma variável `BIGINT` valendo `0` é aceito e devolve zero linhas. A forma usada é `SELECT TOP 0`, e ela **descarta o `Skip(n)`** do usuário — pular *n* linhas de um conjunto vazio dá o mesmo conjunto vazio, e é esse descarte que evita o `Msg 10741` (`TOP` não coexiste com `OFFSET`). De quebra, dispensa a cláusula `ORDER BY` de preenchimento, que só existia para hospedar o `OFFSET/FETCH`.

  A **única** combinação em que `TOP 0` não serve é a operação de conjunto: o `TOP` pertence a uma *query specification* e limita só o ramo em que está escrito — medido, `SELECT TOP 0 * FROM T UNION SELECT * FROM U` devolve as 60 linhas de `U`. Só aí entra a cauda `OFFSET 9223372036854775807 ROWS`, que **custa uma varredura completa da tabela, contra I/O zero do `TOP 0`** — com `ORDER BY`, a forma cara ainda acrescenta uma *Worktable*, ou seja, ordenação. A afirmação é o **contraste**: `TOP 0` não lê a tabela, a cauda lê tudo. O número absoluto de leituras lógicas depende da largura da linha e do tamanho da massa — na medição registrada em `test.pagination.mssql.sql` (200 mil linhas, uma coluna `INT`) deu 767, e uma revisão independente mediu 446 numa tabela mais estreita. **Não trate o número como propriedade da forma; trate o contraste.** O custo ficou confinado a esse caso em vez de valer para todo `First(0)` — `First(pageSize)` com `pageSize` zerado dentro de um laço, numa tabela grande, é incidente de produção.

  Também medido e recusado: `FETCH NEXT (SELECT 0) ROWS ONLY`, aceito e barato, mas só quando o `OFFSET` é o literal `0`. Todas as medições estão em `test.pagination.mssql.sql`, parte Z — **inclusive os caminhos não seguidos**, para que quem pensar em `TOP 0` ou em `(SELECT 0)` encontre a medição pronta em vez de refazê-la.

  No MongoDB o `Skip(n)` também é descartado, pelo mesmo motivo. Os outros cinco dialetos preservam os dois números, porque conseguem exprimir o zero pelo limite.

  **`Skip(0)` foi medido correto nos 7 antes e depois** e não mudou — é "não pule nada", não "sem `Skip`".

- **BREAKING CHANGE (SQL emitido) — Firebird: `FIRST`/`SKIP` passaram a preceder o `DISTINCT`.** Era `SELECT DISTINCT FIRST 3 SKIP 20 ...`, forma que o Firebird 5.0.4 **recusa** com `-104 Token unknown`; a gramática é `SELECT [FIRST m] [SKIP n] [{DISTINCT | ALL}] <colunas>`. Toda consulta `Select.Distinct` com paginação neste driver era rejeitada pelo motor.
- **MSSQL, Oracle e DB2: `DISTINCT` passou a preceder a lista de colunas.** Emitiam `SELECT NOME DISTINCT FROM T`. Não dependia de paginação: `Select.Distinct` sozinho já saía assim.
- **BREAKING CHANGE (comportamento) — `TFluentSQLRegister.Functions` deixou de devolver `nil`.** Passa a levantar `EFluentSQLDriverNotRegistered` (classe nova em `FluentSQL.Interfaces.pas`). Antes, o `nil` era desreferenciado em `FluentSQL.Functions.pas` e chegava ao consumidor como `EAccessViolation` opaca. `Select` e `Serialize` passaram de `Exception` crua para a mesma classe nomeada. **Quem captura esses erros para os traduzir em erro de domínio deve rever o `try..except`.**
- `Ceil` e `Length` deixaram de ser emitidos como SQL ANSI fixo pelo núcleo e passaram a delegar ao driver. Corrige SQL inválido gerado em silêncio: `CEIL(...)` não existe em T-SQL (agora `CEILING`), e `LENGTH(...)` não existe nem em T-SQL (agora `LEN`) nem no núcleo do Firebird (agora `CHAR_LENGTH`).
- **BREAKING CHANGE (API) — `IFluentSQLSelectQualifiers` ganhou o método `RequestsZeroRows`.** Acrescentar método a interface publicada quebra quem a implementa do zero.

  **Impacto real: baixo, e provavelmente não é você.** O único implementador é `TFluentSQLSelectQualifiers`, no core, e os 9 qualificadores de driver **descendem** dela sobrescrevendo apenas `SerializePagination` — herdam o novo método de graça, e o mesmo vale para qualquer subclasse externa. Só quebra quem implementa `IFluentSQLSelectQualifiers` inteira do zero e a injeta com um `IFluentSQLSelect` próprio via `RegisterSelect`. **O que fazer nesse caso:** implementar `function RequestsZeroRows: Boolean` como `HasFirst and (First = 0)` sobre a sua coleção — ou passar a descender de `TFluentSQLSelectQualifiers`.

  Está aqui e não em *Added* porque é a régua que esta própria entrega estabelece: se ela rotula como BREAKING até a troca de classe de exceção que pede revisão de `try..except`, acrescentar método a interface publicada não pode ser rodapé.

  O método responde "o usuário pediu `First(0)`?". É pergunta sobre a coleção de qualificadores, não sobre dialeto: a **forma** de exprimir zero linhas varia (`TOP 0`, `LIMIT 0`, `FIRST 0`, pular tudo), o **pedido** é o mesmo nos sete. E não é `First = 0`, é `HasFirst and (First = 0)` — "não pediu `First`" e "pediu `First(0)`" são coisas diferentes, e só a primeira devolve o conjunto todo.

- **InterBase (`dbnInterbase`, desligado por omissão) — `Length` e `Ceil` passaram a levantar `EFluentSQLFunctionNotSupported`** em vez de emitir `LENGTH(...)` / `CEIL(...)`. O InterBase divergiu do tronco comum antes de o Firebird 2.1 introduzir `CHAR_LENGTH` e `CEIL`/`CEILING`, e a forma correta para esse dialeto não foi verificada — emitir a forma do Firebird seria repetir o defeito do `CEIL` no MSSQL. Se você liga `{$DEFINE INTERBASE}` e precisa dessas duas funções, implemente-as em `FluentSQL.FunctionsInterbase.pas` e remova-as da tabela de suporte em `Test Delphi\Common_tests\test.driver.functions.matrix.pas`.

### Added

- `EFluentSQLDriverNotRegistered` e `EFluentSQLFunctionNotSupported` em `FluentSQL.Interfaces.pas`, para que falhas de dialeto sejam tratáveis pelo consumidor em vez de `EAccessViolation` / `EAbstractError`.
- `EFluentSQLQualifierNotSupported` em `FluentSQL.Interfaces.pas`. Substitui oito cópias de `raise Exception.Create('... Unknown qualifier')` — quatro delas nomeando o driver errado na mensagem.
- Oráculos de paginação em motor real, um por dialeto, em `Test Delphi\Common_tests\`: `test.pagination.{mssql,oracle,firebird,sqlite,mysql,postgresql}.sql` e `test.pagination.mongodb.js`. Trazem o `docker run` exato, a versão do motor e a saída bruta transcrita. Motores medidos: SQL Server 2022 (16.0.4265.3), Oracle Free 23.26.2.0.0, Firebird 5.0.4, MySQL 8.4.11, PostgreSQL 16.14, MongoDB 7.0.39, SQLite 3.50.4.
- Matriz de teste `Test Delphi\Common_tests\test.pagination.filter.pas` foi de **15 para 28 testes**, e a contagem merece o detalhe porque `+13` esconde o que aconteceu: **6 removidos, 19 acrescentados**. Os 6 removidos descreviam a janela `ROW_NUMBER()` que deixou de existir, e cada um tem substituto:

  | Removido | Substituto |
  |---|---|
  | `TestMSSQLPaginacaoComFiltroEmiteWhereNaoAnd` | `TestMSSQLPaginacaoComFiltroPreservaPredicado` |
  | `TestMSSQLPaginacaoSemFiltroContinuaComWhere` | `TestSqlExatoMSSQL` + `TestFirstSozinhoEmTodoDialeto` |
  | `TestMSSQLFirstSozinhoNaoInventaLimiteInferior` | `TestFirstSozinhoEmTodoDialeto` (7 dialetos, não 1) |
  | `TestMSSQLSkipSozinhoNaoInventaLimiteSuperior` | `TestSkipSozinhoEmTodoDialeto` + `TestSqlExatoSkipSozinho` |
  | `TestMSSQLJanelaUsaOrderByDoUsuario` | `TestMSSQLOrderByDoUsuarioPrecedeOffsetFetch` |
  | `TestMSSQLJanelaSemOrderByUsaSelectNull` | `TestMSSQLSemOrderByUsaSelectNull` |

  Nenhuma regra deixou de ser verificada; três delas passaram de 1 para 7 dialetos.
- Implementações em falta de `Trim`, `LTrim`, `RTrim`, `Coalesce`, `Modulus`, `CurrentDate` e `CurrentTimestamp` nos drivers **Firebird**, **SQLite** e **Oracle**.
- Funções escalares do **MongoDB** passam a levantar `EFluentSQLFunctionNotSupported` em vez de `EAbstractError`. As agregações (`Count`, `Sum`, `Min`, `Max`, `Average`) não mudaram.

### Fixed

- **MSSQL — paginar descartava `UNION` e `WITH` (CTE) em silêncio.** `TFluentSQLSerializerMSSQL.AsString` remontava o corpo da consulta por conta própria em vez de delegar a `ComposeSqlCore`, e por isso o ramo do `UNION` e a CTE simplesmente não apareciam no texto emitido — SQL válido e incompleto, sem erro nenhum. Passou a delegar; as duas voltaram.
- **MSSQL — `AsString` deixou de escrever no AST.** A coluna `ROW_NUMBER() OVER(...) AS ROWNUMBER` era **injetada** em `AAST.Select.Columns` durante a serialização, então duas chamadas de `AsString` na mesma `IFluentSQL` acumulavam duas colunas `ROWNUMBER`. Com a migração para `OFFSET/FETCH` a injeção deixou de existir e `AsString` ficou idempotente. *(A não-idempotência de `AsString` por outras causas não foi investigada nesta entrega.)*
- **`Select.Distinct` levantava `Exception` crua em MSSQL, MySQL, PostgreSQL e Oracle, mesmo SEM paginação.** Os quatro tratavam `sqDistinct` como qualificador desconhecido dentro do laço de paginação, que os serializadores chamam incondicionalmente. O laço, que estava duplicado nos nove drivers, virou `TFluentSQLSelectQualifiers._Pagination`.
- **`Skip(n)` sem `First(m)` emitia SQL inválido em MSSQL, Oracle, MySQL e SQLite.** Ver a tabela em *Changed*.
- **Oracle — o embrulho `SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI ...)` acrescentava a coluna `ROWINI` ao resultado.** Uma consulta `Select.All.From('T').First(n)` devolvia uma coluna que o usuário nunca pediu. Medido: cinco valores por linha numa tabela de quatro colunas. Sem embrulho, some.

### Known issues

- **Firebird — `Union` + paginação pagina apenas o primeiro ramo.** O FluentSQL emite `SELECT FIRST 3 SKIP 20 * FROM T UNION SELECT * FROM U`; no Firebird o `FIRST`/`SKIP` escrito num ramo recorta **aquele ramo**, não o resultado do `UNION` — medido, devolve 63 linhas onde os outros seis dialetos devolvem 3. É SQL válido com semântica divergente. Não corrigido: o conserto exige embrulhar o `UNION` numa subconsulta, mudando substancialmente a forma emitida por este driver. Detalhes em `test.pagination.firebird.sql`, parte 3.
- **MSSQL — `WITH` (CTE) e `UNION` combinados com `OrderBy` do usuário geram SQL inválido, com ou sem paginação.** `FluentSQL.Serialize.pas` monta o `ORDER BY` **dentro** de `LBase` e só depois embrulha na CTE ou concatena o `UNION`, produzindo `WITH CTE AS (SELECT ... ORDER BY ...)` (`Msg 1033`) e `SELECT ... ORDER BY ... UNION SELECT ...` (`Msg 156`). É defeito de composição, independente de paginação, e não foi corrigido nesta entrega. Casos I e J de `test.pagination.mssql.sql`.

  **`First(0)` acrescenta um segundo motivo de invalidez ao mesmo caso.** Com operação de conjunto *e* `OrderBy` do usuário, o driver emite a cauda `OFFSET 9223372036854775807 ROWS` **sem** um `ORDER BY` na frente — porque o `ORDER BY` do usuário já foi consumido dentro do primeiro ramo pelo defeito acima — e o resultado é `Msg 156`. Não é regressão: a mesma combinação já era inválida antes desta entrega (pelo motivo do parágrafo anterior), e na base `79450e9` o `UNION` era descartado em silêncio. Vale registrar porque `cPULA_TUDO` (`FluentSQL.SerializeMSSQL.pas`) é **o único ponto do driver que pode sair sem `ORDER BY` na frente**: em todos os outros caminhos a cláusula é garantida por `PaginationOrderBy`. Quando o defeito de composição for corrigido, este segundo motivo desaparece junto — mas quem for mexer ali precisa saber que existem os dois.

  **Fora de escopo, confirmado pré-existente:** `First(0)` com `From(<subconsulta>)` sai como `Msg 102` (*derived table* sem alias). Independe de `First(0)` e já ocorria antes desta entrega.
- **MongoDB — `Union` levanta `EIntfCastError`,** com ou sem paginação. Não é defeito de paginação; o MongoDB não tem `UNION` e deveria recusar com exceção nomeada, como já faz para CTE (`EFluentSQLMongoDBSerialize`).
- **`FluentSQL.Select.pas` — `TFluentSQLSelect.Serialize` é código morto.** Os 9 drivers sobrescrevem `Serialize` e `FluentSQL.Ast.pas` sempre pega a instância do `Register`; reverter a linha corrigida não derruba teste algum. A forma neutra foi corrigida ali por coerência, não por efeito observável.
- **A matriz de paginação vive apenas no projeto Firebird.** `PTestFluentSQLFirebird.dpr` é o único que compila `test.pagination.filter.pas`. Consequência medida: reverter a cauda `LIMIT/OFFSET` do SQLite derruba 4 testes, **todos ali** — `SQLite_tests` não tem teste de paginação nenhum. A cobertura existe, mas mora longe do driver que protege.
- **MongoDB — `Abs`, `Cast`, `Upper`, `Lower`, `Round` e `Floor` geram MQL inválido em silêncio.** Essas seis são do "padrão A" (o núcleo emite SQL ANSI sem consultar o driver), e `FluentSQL.SerializeMongoDB.pas` só reconhece nome de campo e os prefixos de agregação (`AGG:`, `SUM(`, `COUNT(`, `MIN(`, `MAX(`, `AVG(`, `AVERAGE(`). O resultado é que a coluna é **descartada sem exceção**: `.Column(Fun.Round('v',2))` produz `{"find":"t","filter":{},"projection":{}}` — a projeção sai vazia — enquanto `.Column(Fun.Sum('v'))` produz corretamente `{"aggregate":"t","pipeline":[{"$project":{"x":1,"_id":0}}],...}`. É o mesmo modo de falha que foi corrigido para `Ceil` e `Length`, e sobrevive nestas seis. **Não corrigido nesta entrega** — o conserto exige mover as seis para o "padrão B" (implementação por driver nos 9 dialetos) ou ensinar o serializador MongoDB a montar `$project` com expressão, e nenhum dos dois cabia no escopo. Registrado como dívida; até lá, não use funções escalares na projeção com `dbnMongoDB`.

## [1.5.1] — 2026-04-20

### Fixed
- **Pipeline — Documentation Build (Issue #144):** Resolved `tsconfig.json` configuration conflict in `docs-src` related to `baseUrl` and path mapping, ensuring compatibility with Docusaurus 3.
- **Pipeline — Governance Sync (Issue #144):** Restored pipeline synchronization by resolving drift for ESP-077 (Issue #141) and finalizing governance state.

## [1.5.0] — 2026-04-20

### Added
- **DDL — Schema Support (ESP-075, issue [#142]):** `CREATE SCHEMA` and `DROP SCHEMA` support for PostgreSQL, MSSQL, and MySQL (mapped to DATABASE per ADR-075).
- **DML — MERGE Skeleton (ESP-076, issue [#142]):** Fluent API for `MERGE INTO ... USING ... ON ... WHEN MATCHED/NOT MATCHED`. Initial serialization for MSSQL.
- **DDL — Advanced Truncate Support (ESP-074, issue [#136]):**
  - Support for multi-table truncation in a single atomic command across all supported dialects.
  - PostgreSQL: added `RESTART IDENTITY`, `CONTINUE IDENTITY`, and `CASCADE` support.
  - MySQL: added `PARTITION` support for single-table truncation.
  - Consistent validation and `ENotSupportedException` for advanced options in dialects that do not support them.

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
