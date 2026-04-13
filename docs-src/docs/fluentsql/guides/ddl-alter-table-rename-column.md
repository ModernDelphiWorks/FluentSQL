---
displayed_sidebar: fluentsqlSidebar
title: DDL — ALTER TABLE RENAME COLUMN (ESP-030)
---

> **Rastreio:** entrega **ESP-030** / **ADR-030**, issue [#45](https://github.com/ModernDelphiWorks/FluentSQL/issues/45). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

A partir da entrega **ESP-030** / **ADR-030**, o FluentSQL gera **texto SQL** para **`ALTER TABLE …`** que **renomeia uma coluna**, com **uma operação por** `AsString`. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLAlterTableRenameColumn(ADialect, 'NOME_TABELA', 'COLUNA_ANTIGA', 'COLUNA_NOVA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLAlterTableRenameColumnBuilder`** (`FluentSQL.Interfaces`).

Finalize com **`AsString`**. Os três identificadores são fixados na fábrica; não há encadeamento adicional nesta vertical.

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |
| MySQL / MariaDB | `dbnMySQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-030** até extensão explícita do mapeamento.

## Matriz: dialeto × sintaxe × versão mínima

| Dialeto | Forma emitida | Notas de versão |
|---------|----------------|-----------------|
| PostgreSQL | `ALTER TABLE <tabela> RENAME COLUMN <antiga> TO <nova>` | Sintaxe canónica documentada no manual PostgreSQL de referência. |
| MySQL / MariaDB | `ALTER TABLE <tabela> RENAME COLUMN <antiga> TO <nova>` | **`RENAME COLUMN`** em **`ALTER TABLE`** está disponível a partir de **MySQL 8.0.2** (e versões MariaDB alinhadas); motores mais antigos **não** estão cobertos por esta vertical — use SQL manual ou outra ESP. |
| Firebird | `ALTER TABLE <tabela> ALTER <antiga> TO <nova>` | Forma suportada no manual Firebird de referência do projeto (**Firebird 4+** para esta cláusula). |

## Validação e excepções

- Após **`Trim`**, nomes de tabela, coluna antiga e coluna nova são **obrigatórios**; caso contrário **`EArgumentException`** com referência **ESP-030**.
- Coluna antiga e nova **não** podem coincidir após **`Trim`** (incluindo `'X'` vs `'  X  '`); caso contrário **`EArgumentException`** (**ADR-030**).
- Dialecto sem ramo dedicado: **`ENotSupportedException`** com referência **ESP-030**.

## Limitações declaradas

- **Uma coluna** por `AsString`; várias renomeações implicam **várias** cadeias na aplicação.
- Sem **`CHANGE COLUMN`** com tipo (fora de âmbito; **ADR-030**).
- Sem renomear **tabela** nesta entrega — para isso ver [ddl-alter-table-rename-table](./ddl-alter-table-rename-table.md) (**ESP-031**).
- Para **`ALTER TABLE DROP COLUMN`**, ver [ddl-alter-table-drop-column](./ddl-alter-table-drop-column.md) (**ESP-020**).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLAlterTableRenameColumn`).
- `FluentSQL.DDL.Serialize.pas` — `DDLAlterTableRenameColumnSQL`.
