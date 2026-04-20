---
displayed_sidebar: fluentsqlSidebar
title: DDL — CREATE TABLE (ESP-017)
---

A partir da entrega **ESP-017** / **ADR-017**, o FluentSQL expõe uma **superfície DDL dedicada** que gera apenas **texto SQL** (`CREATE TABLE`) para um subconjunto fechado de tipos lógicos. O pacote **não executa** DDL nem consulta catálogo (**RB-DDL-1**, **RB-DDL-3**).

## Ponto de entrada

- **`Schema(ADialect).CreateTable('NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLBuilder`** (`FluentSQL.Interfaces`). Tambem é suportado via o método legado `CreateFluentDDLTable`.

Encadeie colunas com métodos `ColumnInteger`, `ColumnVarChar`, etc., e utilize as **Constraints Avançadas** (**ESP-034**) para definir a integridade:
- **`.PrimaryKey`**: Define a chave primária da tabela.
- **`.NotNull`**: Define a obrigatoriedade do campo.
- **`.DefaultValue(AValue: Variant)`**: Define o valor padrão.
- **`.Identity`**: Suporte para [Auto-incremento e Identidade Nativa](./ddl-advanced-columns.md) (v1.4.0).

Finalize com **`AsString`**.

## Exemplo com Constraints (ESP-034)

```delphi
var
  LSql: string;
begin
  LSql := Schema(dbnPostgreSQL).CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnVarChar('EMAIL', 150).NotNull
    .ColumnBoolean('ATIVO').DefaultValue(True)
    .AsString;
end;
```

## Chaves Estrangeiras (ESP-035)

Para definir chaves estrangeiras que referenciam outras tabelas, utilize o método **`.References`**. Este suporte permite a definição em linha (inline) tanto no `CREATE TABLE` quanto no `ALTER TABLE ADD COLUMN`.

```delphi
  LSql := Schema(dbnPostgreSQL).CreateTable('PEDIDOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID')
    .AsString;
```

Para mais detalhes, consulte o guia de [Chaves Estrangeiras](./ddl-foreign-keys.md).

## Dialetos suportados nesta vertical

Na primeira entrega, a serialização de **`CREATE TABLE`** está implementada para:

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** até extensão explícita do mapeamento.

## Divergência entre motores

O mapeamento **tipo lógico → SQL** é **por dialeto** (**RB-DDL-2**). Por exemplo, texto longo e binário divergem:

- **Texto longo (`ColumnLongText`):** Firebird tende a **`BLOB SUB_TYPE 1`**; PostgreSQL **`TEXT`**.
- **Binário (`ColumnBlob`):** Firebird **`BLOB SUB_TYPE 0`**; PostgreSQL **`BYTEA`**.

Quando precisar de sintaxe **só de um motor**, siga **ESP-016** / **ADR-016** (`ForDialectOnly` na API DML ou composição na aplicação); o núcleo DDL portável não promete um único literal SQL para todos os SGBDs em tipos que não sejam semanticamente alinhados.

## Limitações do subconjunto

- Apenas **`CREATE TABLE`** nesta página; para **`DROP TABLE`** ver [ddl-drop-table](./ddl-drop-table.md) (**ESP-018**); para **`ALTER TABLE ADD COLUMN`** ver [ddl-alter-table-add-column](./ddl-alter-table-add-column.md) (**ESP-019**); para **Chaves Estrangeiras** ver [ddl-foreign-keys](./ddl-foreign-keys.md) (**ESP-035**). Sem `CHECK` complexo, etc.
- Tipos lógicos fechados (`TDDLLogicalType` em `FluentSQL.Interfaces`); extensões proprietárias não entram no contrato portável sem novo ADR ou uso de **ESP-016** na camada DML/aplicação.

## Leitura no código

- `FluentSQL.DDL.pas` — builder.
- `FluentSQL.DDL.Serialize.pas` — `DDLCreateTableSQL` e mapeamentos por dialeto.
