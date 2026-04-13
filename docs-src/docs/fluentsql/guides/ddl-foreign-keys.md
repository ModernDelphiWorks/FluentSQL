---
displayed_sidebar: fluentsqlSidebar
title: DDL — Foreign Keys (ESP-035)
---

A partir da entrega **ESP-035** / **ADR-035**, o FluentSQL suporta a definição de **chaves estrangeiras** (`FOREIGN KEY`) em linha através do método **`.References`**. Esta funcionalidade está disponível tanto no builder de **`CREATE TABLE`** quanto no de **`ALTER TABLE ADD COLUMN`**.

## API

O método **`.References`** deve ser chamado imediatamente após a definição da coluna (ou após outras restrições como `NotNull`, `Default` ou `PrimaryKey`):

- **`.References(const ATableName, AColumnName: string)`**

### Exemplo: CREATE TABLE

```delphi
var
  LSql: string;
begin
  LSql := CreateFluentDDLTable(dbnPostgreSQL, 'PRODUTOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnInteger('CATEGORIA_ID').NotNull
      .References('CATEGORIAS', 'ID') // <--- ESP-035
    .AsString;
end;
```

SQL Gerado:
```sql
CREATE TABLE PRODUTOS (
  ID INTEGER NOT NULL PRIMARY KEY,
  NOME VARCHAR(100) NOT NULL,
  CATEGORIA_ID INTEGER NOT NULL REFERENCES CATEGORIAS(ID)
)
```

### Exemplo: ALTER TABLE

```delphi
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableAddColumn(dbnFirebird, 'PEDIDOS')
    .ColumnInteger('CLIENTE_ID')
    .References('CLIENTES', 'ID')
    .AsString;
end;
```

SQL Gerado:
```sql
ALTER TABLE PEDIDOS ADD CLIENTE_ID INTEGER REFERENCES CLIENTES(ID)
```

## Ordem das Cláusulas

O FluentSQL garante a ordem semântica correta das restrições para Firebird e PostgreSQL:
1. **Tipo** (`INTEGER`, `VARCHAR`, etc.)
2. **DEFAULT**
3. **NOT NULL**
4. **PRIMARY KEY**
5. **REFERENCES** (Foreign Key)

## Dialetos suportados

A serialização de **`REFERENCES`** segue o padrão SQL ANSI e está validada para:

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

## Limitações

- **Chaves Compostas:** Atualmente, o builder suporta apenas Foreign Keys de uma única coluna definidas em linha.
- **Nomes de Constraints:** A sintaxe gera restrições anônimas (`inline`). Para nomes customizados, o builder precisará de expansão futura.
- **Delete/Update Rules:** Cláusulas `ON DELETE CASCADE` ou `ON UPDATE` ainda não estão mapeadas nesta entrega.

## Leitura no código

- `FluentSQL.DDL.pas` — `TFluentDDLColumn` e setters de metadados.
- `FluentSQL.DDL.Serialize.pas` — `MapConstraints` integrando o `REFERENCES`.
