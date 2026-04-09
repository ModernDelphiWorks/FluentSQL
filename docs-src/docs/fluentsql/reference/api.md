---
displayed_sidebar: fluentsqlSidebar
title: Referência de API
---

Documentação alinhada à entrega **v1.0.9** (sexto incremento relevante à DML: **ESP-015** — **INSERT em lote** com **`AddRow`**, **ADR-014**, sobre **ESP-013** … **ESP-009**). A fábrica pública e o pacote **FluentSQL** foram estabilizados na **v1.0.0**; na **v1.0.2** o roadmap foi reconciliado com o repositório (**ESP-008**). Comportamento de parâmetros em operações de conjunto reforçado na **v0.2.0**. Detalhes finos estão nas units em `Source/Core/` e `FluentSQL.Interfaces.pas`.

## Entradas principais

| Item | Descrição |
|------|-----------|
| Factory / ponto de entrada | **`CreateFluentSQL(dbnFirebird)`** (unit `FluentSQL`); o atalho `TCQ(dbn…)` permanece equivalente. |
| DDL (`CREATE TABLE`, ESP-017) | **`CreateFluentDDLTable(dbnFirebird, 'TABELA')`** devolve **`IFluentDDLBuilder`**; **`AsString`** gera só texto SQL. Ver [DDL — CREATE TABLE](../guides/ddl-create-table.md). |
| DDL (`DROP TABLE`, ESP-018) | **`CreateFluentDDLDropTable(dbnFirebird, 'TABELA')`** devolve **`IFluentDDLDropBuilder`**; encadear **`.IfExists`** antes de **`AsString`** quando aplicável. Ver [DDL — DROP TABLE](../guides/ddl-drop-table.md). |
| DDL (`ALTER TABLE ADD COLUMN`, ESP-019) | **`CreateFluentDDLAlterTableAddColumn(ADialect, 'TABELA')`** devolve **`IFluentDDLAlterTableAddBuilder`**; exatamente uma chamada `Column*` antes de **`AsString`**. Ver [DDL — ALTER TABLE ADD COLUMN](../guides/ddl-alter-table-add-column.md). |
| DDL (`ALTER TABLE DROP COLUMN`, ESP-020) | **`CreateFluentDDLAlterTableDropColumn(ADialect, 'TABELA')`** devolve **`IFluentDDLAlterTableDropBuilder`**; exatamente uma **`DropColumn`** antes de **`AsString`**. Ver [DDL — ALTER TABLE DROP COLUMN](../guides/ddl-alter-table-drop-column.md). |
| DDL (`CREATE INDEX`, ESP-022) | **`CreateFluentDDLCreateIndex(ADialect, 'INDICE', 'TABELA')`** devolve **`IFluentDDLCreateIndexBuilder`**; uma ou mais **`Column`**; opcional **`Unique`**. Ver [DDL — CREATE INDEX](../guides/ddl-create-index.md). |
| Métodos fluentes | Encadeamento de construção: `Select`, `From`, `Where`, `Join`, `OrderBy`, `Union`, `UnionAll`, `Intersect`, etc., conforme `IFluentSQL` e interfaces de seção. No contexto **Insert**, **`AddRow`** (v1.0.9) fecha a linha corrente e inicia a próxima para **INSERT em lote** (ver regras abaixo). |
| Subquery em conjunto | `Union`, `UnionAll` e `Intersect` recebem `IFluentSQL` da ramificação secundária; a AST armazena `UnionType` e `UnionQuery`. |

## Saídas principais

| Item | Descrição |
|------|-----------|
| `AsString` | Texto SQL serializado para o dialeto ativo. |
| `Params` / `IFluentSQLParams` | Coleção de parâmetros na ordem de binding esperada. Com conjunto (`UNION` / `INTERSECT`), implementação pode ser **`TFluentSQLMergedParams`**, unindo primário e secundário na ordem da SQL final (`TFluentSQL.Params` + `TFluentSQL.pas`). |

## Regras e contratos

- **1:1 placeholders × Params:** a string retornada por `AsString` e os itens expostos em `Params` devem permanecer alinhados; a v0.2.0 reforça isso para operações de conjunto com remapeamento no ramo secundário (`FluentSQL.Serialize.pas`).
- **`IN` / `NOT IN` (v1.0.3):** sobrecargas com **`TArray<String>`** ou **`TArray<Double>`** em `InValues` / `NotIn` emitem **um placeholder por elemento** (por exemplo `:p1`, `:p2`, … no Firebird; `?` repetidos no MySQL, na ordem de binding) e registram cada valor em `IFluentSQLParams`. Sobrecargas com **`String`** única tratam o argumento como **subconsulta ou expressão literal entre parênteses** (comportamento anterior preservado), sem expandir para múltiplos parâmetros de lista. Os operadores SQL normalizados na concatenação são **`IN`** e **`NOT IN`**. Ver `CHANGELOG.md` **[1.0.3]** e a issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19); ressalvas pós-review em [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20).
- **`array of const` (v1.0.4, ESP-010):** sobrecargas em `FluentSQL.pas` (`Where`, `AndOpe`, `OrOpe`, `Having`, `OnCond`, `SetValue`, `Values`) e em `TFluentSQLCriteriaCase` em `FluentSQL.Cases.pas` (`When`, `AndOpe`, `OrOpe`) expandem **valores escalares** (inteiro, int64, extended, currency, boolean, variant numérico/data) para placeholders (`:pN` no AST; `?` conforme serializador) e `IFluentSQLParams`. Entradas **textuais** em `TVarRec` (identificadores, operadores `Char`, strings) permanecem **literais** na expressão (**RN-P3**). O overload **`CaseExpr(array of const)`** foi alinhado ao mesmo helper na **v1.0.7** (**ESP-013**); ver bullet seguinte. Ver `CHANGELOG.md` **[1.0.4]**, issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21); helper **`TUtils.SqlArrayOfConstToParameterizedSql`**. Caveats: [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22).
- **`Column(array of const)` (v1.0.6, ESP-012):** `TFluentSQL.Column(const AColumnsName: array of const)` delega a **`SqlArrayOfConstToParameterizedSql`** com **`FAST.Params`**, alinhado a **ADR-009** / **ADR-011**; escalares na **projeção** viram placeholders em vez de literais concatenados. Ver `CHANGELOG.md` **[1.0.6]**, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25); dívida técnica pós-caveats: [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26).
- **`CaseExpr(array of const)` (v1.0.7, ESP-013):** `TFluentSQL.CaseExpr(const AExpression: array of const)` delega a **`SqlArrayOfConstToParameterizedSql`** com **`FAST.Params`** antes de reutilizar o fluxo de **`CaseExpr(string)`**, alinhado a **ADR-009** / **ADR-011** / **ADR-012**; escalares na expressão discriminante do `CASE` viram placeholders; **strings** no array continuam fragmentos literais. Ver `CHANGELOG.md` **[1.0.7]** (rastreio da **ESP-013**; a issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27) no GitHub é **ESP-016**, não a entrega v1.0.7). Dívida técnica pós-caveats: [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28).
- **Critérios e `Expression` (v1.0.5, ESP-011):** em `FluentSQL.Expression.pas`, `TFluentSQLCriteriaExpression` pode receber **`IFluentSQLParams`** (`FSQLParams`); com ela atribuída, sobrecargas `AndOpe` / `OrOpe` / `Ope` / `Fun` com `array of const` usam **`SqlArrayOfConstToParameterizedSql`**; sem coleção, mantêm **`SqlParamsToStr`** (retrocompatível). `TFluentSQL.Expression(string | array of const)` e integrações em Where/Having/Join passam **`FAST.Params`**; ramos de `CASE` instanciam critérios com **`FOwner.Params`**. **Strings** em `TVarRec` não são promovidas a bind (**ADR-011**). Ver `CHANGELOG.md` **[1.0.5]**, issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23); caveats: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).
- **Interfaces sobre tipos concretos:** consumo preferencial via interfaces definidas em `FluentSQL.Interfaces.pas`, conforme convenções do projeto.
- **EXCEPT:** não documentado como operação de conjunto na interface citada nesta página; se for adicionado no futuro, deve seguir o mesmo contrato de parâmetros que `Union`/`Intersect`.
- **INSERT em lote (v1.0.9, ESP-015, ADR-014):** em **`IFluentSQLInsert`** / **`TFluentSQLInsert`** (`FluentSQL.Insert.pas`), **`AddRow`** grava a linha corrente (pares em `Values` / `SetValue`) e abre uma linha vazia; exige **linha corrente não vazia** (caso contrário `EFluentSQLInsertBatch`). Ao serializar, a **última** linha pendente entra no resultado sem precisar de **`AddRow`** extra (*flush* implícito em **`AsString`**). SQL: `INSERT INTO … (colunas) VALUES (…), (…), …` com placeholders **na ordem linha a linha** (**ADR-009**), por exemplo `:p1,:p2` depois `:p3,:p4` no Firebird; `?,?,?,?` no MySQL. Colunas explícitas (`.Columns`) ou inferidas pela **primeira** linha serializada devem bater em **contagem e nomes** em todas as linhas (`EFluentSQLInsertBatch` em inconsistência). **`Clear`** na secção Insert zera tabela, colunas, linhas acumuladas e a linha corrente.
- **Extensão por motor (ESP-016, ADR-016):** **`ForDialectOnly`** acrescenta fragmentos **opt-in** associados a um **`TFluentSQLDriver`**; só entram na string final quando o dialeto da instância coincide. Não substitui o núcleo portável por recursos “modernos” universais. Issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27). Ver o guia [Extensão explícita por motor](../guides/extensao-por-dialeto.md).
- **MongoDB — INSERT em lote (v1.0.9):** com **`dbnMongoDB`**, uma linha lógica continua com **`insertOne`**; **mais de uma** linha produz **`insertMany`** com array **`documents`**, alinhado a **ADR-014** / **ADR-013**. Ver `CHANGELOG.md` **[1.0.9]**, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31); dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).
- **DDL (v1.1.0, ESP-017–ESP-019; ESP-020 DROP COLUMN em código/docs — changelog via `/release`):** builders em `FluentSQL.DDL.pas` e serializers em `FluentSQL.DDL.Serialize.pas` emitem **apenas strings**; o FluentSQL não executa DDL. Dialetos não suportados levantam **`ENotSupportedException`** com mensagem estável referindo o âmbito da entrega (**ESP-017**–**ESP-020**).

## Leitura recomendada no código

- `FluentSQL.Insert.pas` — `AddRow`, `Serialize`, `SerializedRowCount`, validações de lote (`EFluentSQLInsertBatch`).
- `FluentSQL.pas` — `Union` / `UnionAll` / `Intersect`, resolução de `Params` mesclados, sobrecargas `InValues` / `NotIn`, `Column(array of const)`, `CaseExpr(array of const)`, ramos com `array of const` e `Expression` com `Params`, delegação de **`AddRow`** ao Insert.
- `FluentSQL.Expression.pas` — `TFluentSQLCriteriaExpression`, `FSQLParams`, `_SqlFromArrayOfConst` (ESP-011).
- `FluentSQL.Cases.pas` — `When` / critérios de `CASE` com `array of const` e passagem de `Params` às expressões.
- `FluentSQL.Operators.pas` — `IsIn` / `IsNotIn` (arrays vs string).
- `FluentSQL.Params.pas` — `TFluentSQLMergedParams.Count` / `GetItem`.
- `FluentSQL.Serialize.pas` — `UnionRemapBranchSQL`, `ComposeSqlCore`, `DialectOnlySqlSuffix` (ESP-016).
- `FluentSQL.Utils.pas` — `TUtils.SqlArrayOfConstToParameterizedSql` (ESP-010).
