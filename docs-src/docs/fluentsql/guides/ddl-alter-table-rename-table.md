---
displayed_sidebar: fluentsqlSidebar
title: DDL — ALTER TABLE … RENAME TO … (renomear tabela)
---

Incluído na release **v1.3.0**.

O FluentSQL gera **texto SQL** para **renomear uma tabela**, com **uma operação por** `AsString`. O pacote **não executa** DDL.

## Ponto de entrada

- **`Schema(ADialect).AlterTableRename('TABELA_ANTIGA', 'TABELA_NOVA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLAlterTableRenameTableBuilder`** (`FluentSQL.Interfaces`).

Finalize com **`AsString`**. Os dois identificadores são fixados na fábrica; não há encadeamento adicional nesta vertical.

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |
| MySQL / MariaDB | `dbnMySQL` |
| MSSQL | `dbnMSSQL` |
| SQLite | `dbnSQLite` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-047** até extensão explícita do mapeamento.

## Matriz: dialeto × sintaxe × versão mínima

| Dialeto | Forma emitida | Notas de versão |
|---------|----------------|-----------------|
| PostgreSQL | `ALTER TABLE <antiga> RENAME TO <nova>` | Sintaxe canónica no manual PostgreSQL de referência. |
| MySQL / MariaDB | `ALTER TABLE <antiga> RENAME TO <nova>` | Suportada nas versões mínimas habitualmente alinhadas ao restante do manual FluentSQL (MySQL 5.x+). |
| Firebird | `ALTER TABLE <antiga> TO <nova>` | Suportada desde o **Firebird 2.5+**. |
| MSSQL | `EXEC sp_rename '<antiga>', '<nova>'` | Utiliza a procedure de sistema `sp_rename` padrão do SQL Server. |
| SQLite | `ALTER TABLE <antiga> RENAME TO <nova>` | Suportada no SQLite 3.25+. |

## Validação e excepções

- Após **`Trim`**, nomes de tabela antiga e nova são **obrigatórios**; caso contrário **`EArgumentException`**.
- Tabela antiga e nova **não** podem coincidir após **`Trim`** (incluindo `'X'` vs `'  X  '`); caso contrário **`EArgumentException`**.
- Dialecto sem ramo dedicado: **`ENotSupportedException`**.

## Limitações declaradas

- **Uma tabela** por `AsString`; várias renomeações implicam **várias** cadeias na aplicação.
- Sem **`RENAME TABLE`** multi-objecto num único statement.
- Para **renomear coluna**, ver [ddl-alter-table-rename-column](./ddl-alter-table-rename-column.md).

## Leitura no código

- `FluentSQL.Interfaces.pas` — `IFluentDDLAlterTableRenameTableBuilder`.
- `FluentSQL.DDL.pas` — builder e registro em `TFluentSchema`.
- `FluentSQL.DDL.SerializeAbstract.pas` — implementação padrão.
- `Source/Drivers/` — overrides específicos por dialeto.
