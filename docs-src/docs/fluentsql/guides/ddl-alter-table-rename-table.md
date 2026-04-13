---
displayed_sidebar: fluentsqlSidebar
title: DDL — ALTER TABLE … RENAME TO … (renomear tabela, ESP-031)
---

> **Rastreio:** entrega **ESP-031** / **ADR-031**, issue [#46](https://github.com/ModernDelphiWorks/FluentSQL/issues/46). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

A partir da entrega **ESP-031** / **ADR-031**, o FluentSQL gera **texto SQL** para **renomear uma tabela**, com **uma operação por** `AsString`. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLAlterTableRenameTable(ADialect, 'TABELA_ANTIGA', 'TABELA_NOVA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLAlterTableRenameTableBuilder`** (`FluentSQL.Interfaces`).

Finalize com **`AsString`**. Os dois identificadores são fixados na fábrica; não há encadeamento adicional nesta vertical.

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |
| MySQL / MariaDB | `dbnMySQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-031** até extensão explícita do mapeamento.

## Matriz: dialeto × sintaxe × versão mínima

| Dialeto | Forma emitida | Notas de versão |
|---------|----------------|-----------------|
| PostgreSQL | `ALTER TABLE <antiga> RENAME TO <nova>` | Sintaxe canónica no manual PostgreSQL de referência. |
| MySQL / MariaDB | `ALTER TABLE <antiga> RENAME TO <nova>` | Forma única congelada na matriz **ADR-031**; suportada nas versões mínimas habitualmente alinhadas ao restante do manual FluentSQL (MySQL 5.x+ para esta forma). |
| Firebird | `ALTER TABLE <antiga> TO <nova>` | Forma suportada no manual Firebird de referência do projeto (**Firebird 2.5+** para esta operação). |

## Validação e excepções

- Após **`Trim`**, nomes de tabela antiga e nova são **obrigatórios**; caso contrário **`EArgumentException`** com referência **ESP-031**.
- Tabela antiga e nova **não** podem coincidir após **`Trim`** (incluindo `'X'` vs `'  X  '`); caso contrário **`EArgumentException`** (**ADR-031**).
- Dialecto sem ramo dedicado: **`ENotSupportedException`** com referência **ESP-031**.

## Limitações declaradas

- **Uma tabela** por `AsString`; várias renomeações implicam **várias** cadeias na aplicação.
- Sem **`RENAME TABLE`** multi-objecto num único statement.
- Para **renomear coluna**, ver [ddl-alter-table-rename-column](./ddl-alter-table-rename-column.md) (**ESP-030**).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLAlterTableRenameTable`).
- `FluentSQL.DDL.Serialize.pas` — `DDLAlterTableRenameTableSQL`.
