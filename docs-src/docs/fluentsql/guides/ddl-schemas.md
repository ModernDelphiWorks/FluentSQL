---
displayed_sidebar: fluentsqlSidebar
title: DDL — Schemas
---

# DDL — Schemas (Logical Namespaces)

Introduzido na **v1.5.0**, o suporte a **Schemas** permite a criação e exclusão de namespaces lógicos em bancos de dados relacionais.

## Entry point

O ponto de entrada é através da factory `Schema(Dialect)`:

```pascal
var
  LSchema: string;
begin
  LSchema := Schema(dbnPostgreSQL)
    .Schema('Tenant_1')
    .Create
    .AsString;
end;
```

## Operações suportadas

### CREATE SCHEMA

Gera o comando `CREATE SCHEMA [Nome]`.

```pascal
Schema(dbnPostgreSQL).Schema('MySchema').Create.AsString;
// SQL: CREATE SCHEMA "MySchema"
```

### DROP SCHEMA

Gera o comando `DROP SCHEMA [Nome]`.

```pascal
Schema(dbnPostgreSQL).Schema('MySchema').Drop.AsString;
// SQL: DROP SCHEMA "MySchema"
```

## Suporte por Dialeto

| Dialeto | Comportamento |
|---------|---------------|
| **PostgreSQL** | Suporte nativo (`CREATE/DROP SCHEMA`). |
| **MSSQL** | Suporte nativo (`CREATE/DROP SCHEMA`). |
| **MySQL** | Mapeado para `DATABASE` (Sinônimo no MySQL). |
| **Outros** | Lança `ENotSupportedException` (conforme ADR-075). |

## Observações

- Por padrão, o FluentSQL utiliza identificadores citados (quoted identifiers) para evitar conflitos com palavras reservadas.
- O framework emite apenas a string SQL; a execução deve ser feita pela sua camada de persistência.
