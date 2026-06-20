# FluentSQL Framework for Delphi & Lazarus

[![Delphi XE+](https://img.shields.io/badge/Delphi-XE%20or%20superior-blue.svg)]()
[![Lazarus Compatible](https://img.shields.io/badge/Lazarus-Compatible-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*   [🇬🇧 English](#-english)
*   [🇧🇷 Português](#-português)

---

## 🇬🇧 English

**FluentSQL** is a modern, high-performance database-agnostic SQL/MQL script generation library for Delphi and Lazarus. Its core contract is extremely simple: **it only emits `string`** — standard SQL scripts (or drivers-specific equivalents like MQL/JSON for MongoDB) through a robust, fluent object-oriented API (classes, interfaces, and method chaining). DML (CRUD) and DDL statements translate purely into parameterized text. There is no active database connection, no server-side execution, no database catalog introspection, and no validation inside this package. It remains completely strings-only by design, making it highly modular and ideal as a dependency for advanced Object-Relational Mappers (such as **Janus**).

### 🚀 Key Features

*   **Fluent DML & DDL Builder:** Construct queries (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) and schema scripts (`CREATE TABLE`, `ALTER TABLE`, indices) using method chaining.
*   **Database Engine Independence:** Single interface query layer with serialization drivers for Firebird, MySQL, PostgreSQL, MSSQL, Oracle, SQLite, MongoDB (MQL), and more.
*   **Parameterization Support:** Standardized `:pN` / `?` placeholder mapping utilizing a unified `IFluentSQLParams` interface.
*   **Advanced SQL Construction:** Full support for `UNION`, `UNION ALL`, `INTERSECT` statements, and bulk insert optimization (multi-value `VALUES` / `insertMany`).
*   **Strings-Only by Design:** 100% decoupled from active connection components, ensuring lightweight dependencies and zero database-access overhead.

### 🏛 Compatibility Matrix

| Environment / IDE | Platform / Compiler | Drivers Serializer | Dialects Supported |
| :--- | :--- | :---: | :---: |
| **Delphi XE or superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Yes | Firebird, MySQL, PG, MSSQL, SQLite, Oracle, Mongo... |
| **Lazarus / FreePascal** | LCL, Console (Cross-platform) | ✅ Yes | Firebird, MySQL, PG, MSSQL, SQLite, Oracle, Mongo... |

### 🐧 Cross-Platform Build — Win32 / Win64 / Linux64 (verified)

> **✅ Verified 2026-06-20** in a real production backend: FluentSQL compiles **clean** for **Win32, Win64 and Linux64** (`dcclinux64`) with **no platform guards needed** — it was already platform-neutral. macOS/iOS/Android follow from the Delphi RTL but are **not build-verified** here yet.

**Building a consumer app for Linux64:** install the Linux 64-bit platform (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), provide a Linux SDK (RAD Studio SDK Manager + PAServer, **or** a sysroot assembled from a WSL/Linux toolchain passed to `dcclinux64` via `--syslibroot` / `--libpath`), then compile with `dcclinux64`.

### ⚙️ Installation

To install using the package manager [**Boss**](https://github.com/HashLoad/boss):

```sh
boss install FluentSQL
```

---

### ⚡️ Quick Start

#### 1. DML Query Building (SELECT)
```delphi
uses
  FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID').Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
    
  // SQL = 'SELECT ID, NOME FROM CLIENTES WHERE ATIVO = 1'
end;
```

#### 2. DDL Schema Definition (CREATE TABLE)
```delphi
uses
  FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .AsString;
    
  // SQL = 'CREATE TABLE USUARIOS (ID INTEGER PRIMARY KEY, NOME VARCHAR(100) NOT NULL)'
end;
```

---

## 🇧🇷 Português

**FluentSQL** é uma biblioteca moderna e de alta performance para geração de scripts SQL/MQL agnósticos a banco de dados em Delphi e Lazarus. Seu contrato principal é extremamente simples: **gerar `string`** — scripts SQL padrão (e, onde o driver for outro formato, texto equivalente, p.ex. MQL/JSON para MongoDB) através de uma API fluente orientada a objetos (classes/interfaces e encadeamento de métodos). Instruções CRUD (DML) e DDL traduzem-se estritamente em textos parametrizados. Não há conexão ativa com banco de dados, nem execução ou leitura de catálogo dentro deste pacote. Ele mantém-se apenas gerador de strings por design, sendo uma dependência ideal para Mapeadores Objeto-Relacionais (como o **Janus**).

### 🚀 Recursos Principais

*   **Builder Fluente de DML & DDL:** Construa consultas completas (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) e scripts estruturais de schema (`CREATE TABLE`, `ALTER TABLE`, índices) de forma fluida.
*   **Independência de Dialetos:** Única interface geradora com serializadores nativos para Firebird, MySQL, PostgreSQL, MSSQL, Oracle, SQLite, MongoDB (MQL) e outros.
*   **Suporte a Parametrização:** Mapeamento padronizado de placeholders `:pN` / `?` utilizando a interface unificada `IFluentSQLParams`.
*   **Operações Avançadas:** Suporte completo a blocos `UNION`, `UNION ALL`, `INTERSECT` e otimização de inserts em lote (multi-`VALUES` / `insertMany`).
*   **Geração Apenas de Strings por Design:** 100% desacoplado de componentes de conexão ativa, garantindo leveza e ausência de overhead de acesso de dados direto.

### 🏛 Matriz de Compatibilidade

| Ambiente / IDE | Plataforma / Compilador | Serializador de Drivers | Dialetos Suportados |
| :--- | :--- | :---: | :---: |
| **Delphi XE ou superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Sim | Firebird, MySQL, PG, MSSQL, SQLite, Oracle, Mongo... |
| **Lazarus / FreePascal** | LCL, Console (Multiplataforma) | ✅ Sim | Firebird, MySQL, PG, MSSQL, SQLite, Oracle, Mongo... |

### 🐧 Build Multiplataforma — Win32 / Win64 / Linux64 (verificado)

> **✅ Verificado em 2026-06-20** num backend real em produção: o FluentSQL compila **limpo** em **Win32, Win64 e Linux64** (`dcclinux64`), **sem nenhum guard de plataforma** — já era neutro. macOS/iOS/Android seguem da RTL Delphi, mas **ainda não foram verificados** em build aqui.

**Para buildar um app consumidor no Linux64:** instale a plataforma Linux 64-bit (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), forneça um SDK Linux (SDK Manager do RAD Studio + PAServer, **ou** um sysroot montado de um toolchain WSL/Linux passado ao `dcclinux64` via `--syslibroot` / `--libpath`), e compile com `dcclinux64`.

### ⚙️ Instalação

Para instalar usando o gerenciador de pacotes [**Boss**](https://github.com/HashLoad/boss):

```sh
boss install FluentSQL
```

---

### ⚡️ Início Rápido

#### 1. Construindo Consultas DML (SELECT)
```delphi
uses
  FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID').Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
    
  // SQL = 'SELECT ID, NOME FROM CLIENTES WHERE ATIVO = 1'
end;
```

#### 2. Definindo Schemas DDL (CREATE TABLE)
```delphi
uses
  FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .AsString;
    
  // SQL = 'CREATE TABLE USUARIOS (ID INTEGER PRIMARY KEY, NOME VARCHAR(100) NOT NULL)'
end;
```

---
*Copyright © 2025-2026 Isaque Pinheiro. Licensed under MIT License.*
