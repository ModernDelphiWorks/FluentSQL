# FluentSQL

🇬🇧 [English](README.en.md) · Repositório: [github.com/ModernDelphiWorks/FluentSQL](https://github.com/ModernDelphiWorks/FluentSQL)

**Licença:** [MIT](LICENSE)

---

**FluentSQL** é uma biblioteca para **Delphi** e **Lazarus** cujo contrato é simples: **gerar `string`** — scripts **SQL** (e, onde o driver for outro formato, texto equivalente, p.ex. **MQL/JSON**) através de uma **API fluente orientada a objetos** (classes/interfaces, encadeamento). **CRUD**, **DDL** e o que a API expuser traduzem-se em **texto** + **`Params`** quando aplicável; **não** há conexão, **não** há execução no motor, **não** há leitura de catálogo nem validação “modelo ↔ base” *dentro* deste pacote — isso fica na tua aplicação ou em camadas à parte (por exemplo um ORM como o **[Janus](https://github.com/ModernDelphiWorks/Janus)**, que declara o FluentSQL como dependência para construção de SQL).

---

## Matriz de funcionalidades

| Funcionalidade | Estado |
|----------------|--------|
| DML fluente (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) | ✅ |
| DDL fluente (`CREATE TABLE`, `DROP TABLE`, `ALTER` ADD/DROP/RENAME — conforme dialeto e entregas) | ✅ |
| Serialização multi-dialeto (`dbn*`, `Source/Drivers/`) | ✅ |
| Parametrização (`IFluentSQLParams`, placeholders `:pN` / `?`) | ✅ |
| `UNION` / `UNION ALL` / `INTERSECT` com `Params` mesclados | ✅ |
| INSERT em lote (SQL multi-`VALUES` / Mongo `insertMany`) | ✅ |
| Driver **MongoDB** (saída MQL/JSON como texto) | ✅ |
| Extensão explícita por motor (opt-in por dialeto) | ✅ |
| **Apenas geração de string via POO** — sem camada de acesso a dados | ✅ *by design* |

---

## Bancos e dialetos (referência)

Firebird · InterBase · MySQL · PostgreSQL · Microsoft SQL Server · Oracle · IBM DB2 · SQLite · Informix · Advantage (ADS) · SQL Anywhere (ASA) · Absolute Database · ElevateDB · NexusDB · MongoDB (MQL) — *o registo concreto de cada serializador depende da tua build e de `FluentSQL.Register.pas`; ver documentação.*

---

## Versões Delphi / Lazarus

- **Delphi:** XE ou superior (ou versão compatível usada nos projetos de teste).
- **Lazarus / FPC:** onde o repositório estiver validado para a tua plataforma.

---

## Instalação (Boss)

```sh
boss install FluentSQL
```

O nome do pacote em `boss.json` é **FluentSQL**. Tutoriais antigos podem referir `CQuery4D` ou `CQLBr`; a tabela de migração está no [CHANGELOG.md](CHANGELOG.md).

## Dependências

O manifesto Boss na raiz **não** impõe dependências transitórias obrigatórias para o núcleo: inclui `Source/` no teu projeto e os drivers que compilares. Projetos de teste em `Test Delphi/` usam defines por `.dpr` para ativar dialetos (ver [configuração](docs-src/docs/fluentsql/reference/configuration.md)).

---

## Início rápido

**DML (Consultas):**

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

**DDL (Definição de dados):**

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

O ponto de entrada principal para consultas DML é **`Query(ADialect)`**. Para operações de definição de dados, utilize **`Schema(ADialect)`**. As fábricas legadas (`CreateFluentSQL`, `TCQ`, `CreateFluentDDLTable`, etc.) encontram-se obsoletas. Em código reutilizável, prefira as interfaces definidas em `FluentSQL.Interfaces`.

---

## Documentação

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

O site estático em `docs/` é gerado e commitado no CI quando `docs-src/` muda nos ramos `main` ou `develop` (workflow [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml)). PRs que alterem `docs-src/` passam por [`.github/workflows/docs-build.yml`](.github/workflows/docs-build.yml).

---

## Ecossistema

- **[Janus](https://github.com/ModernDelphiWorks/Janus)** — ORM Delphi que faz a ponte entre modelo OO e bases relacionais; usa **FluentSQL** para construção de SQL, enquanto responsabilidades de persistência, metadados e validação modelo↔BD ficam no próprio Janus e nas suas dependências (p.ex. MetaDbDiff, DataEngine). O FluentSQL mantém-se **só strings**.

---

## Testes

Projetos **DUnitX** em `Test Delphi/`:

| Projeto | Notas |
|---------|--------|
| `Firebird_tests/PTestFluentSQLFirebird.dpr` | Cenários principais (parametrização, multi-dialeto). |
| `Firebird_tests/PTestFluentSQLSample.dpr` | Exemplo mínimo. |
| `*_tests/TestFluentSQL_<Dialect>.dpr` | MSSQL, MySQL, Oracle, DB2, Interbase, etc. |


**Roadmap:** [ROADMAP.md](ROADMAP.md) · **Extensão por dialeto:** guia [extensao-por-dialeto.md](docs-src/docs/fluentsql/guides/extensao-por-dialeto.md).

---

## Contribuição

Issues e pull requests são bem-vindos. Para alterações maiores, abre primeiro uma issue para alinhar escopo — o produto rejeita propostas que transformem o núcleo em camada de acesso a dados ou execução no SGBD (ver [ROADMAP.md](ROADMAP.md)).

---

## Licença

[MIT](LICENSE).
