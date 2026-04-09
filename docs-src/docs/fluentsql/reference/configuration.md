---
displayed_sidebar: fluentsqlSidebar
title: Configuração e constantes
---

Referência operacional derivada do repositório: manifesto Boss, tipo de driver e condicionais de compilação. Não substitui a leitura do código em `Source/Core/` quando o comportamento for ambíguo.

## Pacote Boss

| Campo | Valor (raiz do repositório) |
|--------|----------------------------|
| Nome do pacote | **FluentSQL** |
| Instalação em projeto consumidor | `boss install FluentSQL` |
| Caminho das units (`mainsrc`) | `./Source` |

Versão publicada no manifesto: ver `boss.json` na raiz do repositório.

## Constante de dialeto (`CreateFluentSQL` / `TCQ`)

O primeiro argumento da fábrica é do tipo `TFluentSQLDriver`, definido em `FluentSQL.Interfaces.pas`:

| Constante | Uso típico |
|-----------|------------|
| `dbnMSSQL` | Microsoft SQL Server |
| `dbnMySQL` | MySQL |
| `dbnFirebird` | Firebird |
| `dbnSQLite` | SQLite |
| `dbnInterbase` | InterBase |
| `dbnDB2` | IBM DB2 |
| `dbnOracle` | Oracle |
| `dbnInformix` | Informix |
| `dbnPostgreSQL` | PostgreSQL |
| `dbnADS` | Advantage Database Server |
| `dbnASA` | SQL Anywhere (ASA) |
| `dbnAbsoluteDB` | Absolute Database |
| `dbnMongoDB` | Serialização orientada a MQL (estado do driver conforme roadmap) |
| `dbnElevateDB` | ElevateDB |
| `dbnNexusDB` | NexusDB |

O registo concreto de serializadores, `Select` e funções por dialeto ocorre em `FluentSQL.Register.pas` (nem todo dialeto da enum precisa estar ativo na sua build).

## Search path (Delphi / Lazarus)

Inclua no path do projeto, no mínimo:

- `Source/Core/`
- `Source/Drivers/` (ou apenas os drivers que você compila)

Quando usar Boss como dependência, o gestor costuma ajustar caminhos conforme a configuração do seu projeto pai.

## Compilação condicional e registo de drivers

Alguns drivers só entram no registo global se o símbolo correto estiver definido **antes** da cadeia de `uses` que carrega o núcleo (por exemplo `{$DEFINE MSSQL}`, `ORACLE`, `DB2`, `INTERBASE`, conforme o seu `.dpr` e `FluentSQL.Register`).

Se em runtime aparecer erro de **select** do dialeto não registrado, veja [Erros comuns](../troubleshooting/common-errors.md) e a issue [#14](https://github.com/ModernDelphiWorks/FluentSQL/issues/14).

## API pública vs nomes legados

| Use | Evite (legado) |
|-----|----------------|
| `CreateFluentSQL(dbn…)` ou `TCQ(dbn…)` | `CQuery`, `TCQL.New` |
| `uses FluentSQL, FluentSQL.Interfaces` | `uses CQL, CQL.Interfaces` |
| Pacote Boss **FluentSQL** | `CQuery4D`, nomes antigos do ecossistema |

Tabela de migração: `CHANGELOG.md`, entrada **[1.0.0]**.

## Variáveis de ambiente

Não há variáveis de ambiente obrigatórias documentadas para o uso da biblioteca em tempo de compilação ou runtime.
