# FluentSQL

[![Delphi Supported Versions](https://img.shields.io/badge/Delphi%20Supported%20Versions-XE%2B-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*   [🇬🇧 English](#-english)
*   [🇧🇷 Português](#-português)

---

## 🇬🇧 English

**FluentSQL** is a modern, high-performance database-agnostic SQL/MQL script generation library for **Delphi** and **Lazarus**. 

Its contract is simple: **it only emits `string`** — standard **SQL** scripts (and, where the driver targets another format, equivalent text like **MQL/JSON** for MongoDB) through a **fluent, object-oriented API** (classes/interfaces, method chaining). 

**CRUD** (DML) and **DDL** statements translate purely into **text** + **`Params`** (when applicable). There is **no** database connection, **no** execution on the server, **no** catalog introspection, and **no** "class ↔ database" validation *inside* this package — that stays in your application or in other layers (for example, an ORM such as **[Janus](https://github.com/ModernDelphiWorks/Janus)**, which lists FluentSQL as a dependency for SQL construction). **FluentSQL stays strings-only by design.**

---

### 🚀 Feature Matrix

| Feature | Status |
|---------|--------|
| Fluent DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) | ✅ |
| Fluent DDL (`CREATE TABLE`, `DROP TABLE`, `ALTER` ADD/DROP/RENAME column) | ✅ |
| Multi-dialect serialization (`dbn*`, `Source/Drivers/`) | ✅ |
| Parameterization (`IFluentSQLParams`, `:pN` / `?` placeholders) | ✅ |
| `UNION` / `UNION ALL` / `INTERSECT` with merged `Params` | ✅ |
| Batch INSERT (multi-`VALUES` / Mongo `insertMany`) | ✅ |
| **MongoDB** driver (MQL/JSON as text output) | ✅ |
| Per-engine explicit extension (dialect opt-in, **ESP-016** / **ADR-016**) | ✅ |
| **String generation only via OOP** — no data-access layer | ✅ *by design* |

---

### 🏛 Supported Engines & Dialects
Firebird · InterBase · MySQL · PostgreSQL · Microsoft SQL Server · Oracle · IBM DB2 · SQLite · Informix · Advantage (ADS) · SQL Anywhere (ASA) · Absolute Database · ElevateDB · NexusDB · MongoDB (MQL) — *actual serializer registration depends on your build and `FluentSQL.Register.pas`; see the docs.*

### ⚙️ Installation
To install using [`boss`]:
```sh
boss install FluentSQL
```

---

### ⚡️ Quick Start

#### DML (Queries)
```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID').Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

#### DDL (Data Definition)
```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .AsString;
end;
```

---

### 📚 Documentation

| Doc | Description |
|-----|-------------|
| [Index / overview](docs-src/docs/fluentsql/index.md) | Main entry |
| [Introduction](docs-src/docs/fluentsql/introduction.md) | Context and scope |
| [Installation](docs-src/docs/fluentsql/getting-started/installation.md) | Boss and search path |
| [Quick start](docs-src/docs/fluentsql/getting-started/quickstart.md) | First end-to-end flow |
| [Architecture](docs-src/docs/fluentsql/architecture/overview.md) | AST, drivers, flow |
| [API reference](docs-src/docs/fluentsql/reference/api.md) | Public contracts |
| [Configuration & `dbn*`](docs-src/docs/fluentsql/reference/configuration.md) | Dialect constants |
| [Tests](docs-src/docs/fluentsql/tests/overview.md) | DUnitX suite |
| [Troubleshooting](docs-src/docs/fluentsql/troubleshooting/common-errors.md) | Common errors |
| [Docs CI](docs-src/docs/fluentsql/getting-started/documentation-ci.md) | Docusaurus / GitHub Actions |

---

### ⛏️ Contributing
Issues and pull requests are welcome. For larger changes, open an issue first to align scope — the product rejects proposals that turn the core into a data-access layer or server execution engine (see [ROADMAP.md](ROADMAP.md)).

---

## 🇧🇷 Português

**FluentSQL** é uma biblioteca moderna e de alta performance para **Delphi** e **Lazarus** cujo contrato é simples: **gerar `string`** — scripts **SQL** (e, onde o driver for outro formato, texto equivalente, p.ex. **MQL/JSON** para MongoDB) através de uma **API fluente orientada a objetos** (classes/interfaces, encadeamento).

**CRUD** (DML) e **DDL** traduzem-se estritamente em **texto** + **`Params`** quando aplicável. **Não** há conexão com banco de dados, **não** há execução no motor, **não** há leitura de catálogo nem validação "modelo ↔ base" *dentro* deste pacote — isso fica na sua aplicação ou em camadas à parte (por exemplo, um ORM como o **[Janus](https://github.com/ModernDelphiWorks/Janus)**, que declara o FluentSQL como dependência para construção de SQL). **O FluentSQL mantém-se apenas gerador de strings por design.**

---

### 🚀 Matriz de Funcionalidades

| Funcionalidade | Estado |
|----------------|--------|
| DML fluente (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) | ✅ |
| DDL fluente (`CREATE TABLE`, `DROP TABLE`, `ALTER` ADD/DROP/RENAME) | ✅ |
| Serialização multi-dialeto (`dbn*`, `Source/Drivers/`) | ✅ |
| Parametrização (`IFluentSQLParams`, placeholders `:pN` / `?`) | ✅ |
| `UNION` / `UNION ALL` / `INTERSECT` com `Params` mesclados | ✅ |
| INSERT em lote (SQL multi-`VALUES` / Mongo `insertMany`) | ✅ |
| Driver **MongoDB** (saída MQL/JSON como texto) | ✅ |
| Extensão explícita por motor (opt-in por dialeto, **ESP-016** / **ADR-016**) | ✅ |
| **Apenas geração de string via POO** — sem camada de acesso a dados | ✅ *by design* |

---

### 🏛 Bancos e Dialetos Suportados
Firebird · InterBase · MySQL · PostgreSQL · Microsoft SQL Server · Oracle · IBM DB2 · SQLite · Informix · Advantage (ADS) · SQL Anywhere (ASA) · Absolute Database · ElevateDB · NexusDB · MongoDB (MQL) — *o registo concreto de cada serializador depende da tua build e de `FluentSQL.Register.pas`; ver documentação.*

### ⚙️ Instalação (Boss)
```sh
boss install FluentSQL
```

---

### ⚡️ Início Rápido

#### DML (Consultas)
```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID').Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

#### DDL (Definição de Dados)
```delphi
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .AsString;
end;
```

---

### 📚 Documentação

| Documento | Descrição |
|-----------|-----------|
| [Índice / visão geral](docs-src/docs/fluentsql/index.md) | Entrada principal |
| [Introdução](docs-src/docs/fluentsql/introduction.md) | Contexto e escopo |
| [Instalação](docs-src/docs/fluentsql/getting-started/installation.md) | Boss e path |
| [Início rápido](docs-src/docs/fluentsql/getting-started/quickstart.md) | Primeiro fluxo |
| [Arquitetura](docs-src/docs/fluentsql/architecture/overview.md) | AST, drivers, fluxo |
| [Referência de API](docs-src/docs/fluentsql/reference/api.md) | Contratos públicos |
| [Configuração e `dbn*`](docs-src/docs/fluentsql/reference/configuration.md) | Constantes de dialeto |
| [Testes](docs-src/docs/fluentsql/tests/overview.md) | Suíte DUnitX |
| [Troubleshooting](docs-src/docs/fluentsql/troubleshooting/common-errors.md) | Erros comuns |
| [CI da documentação](docs-src/docs/fluentsql/getting-started/documentation-ci.md) | Build Docusaurus / GitHub Actions |

---

### ⛏️ Contribuição
Issues e pull requests são bem-vindos. Para alterações maiores, abra primeiro uma issue para alinhar escopo — o produto rejeita propostas que transformem o núcleo em camada de acesso a dados ou execução no SGBD (ver [ROADMAP.md](ROADMAP.md)).

---
*Copyright © 2025-2026 Isaque Pinheiro. Licensed under MIT License.*
