---
displayed_sidebar: fluentsqlSidebar
title: Instalação
---

## Pré-requisitos

- **Delphi** (XE ou superior) ou **Lazarus** (FPC), conforme a matriz de suporte do projeto.
- **[Boss](https://github.com/HashLoad/boss)** para dependências, alinhado ao `boss.json` na raiz do repositório.

## Instalar como dependência (recomendado)

Na pasta do **seu** projeto Delphi/Lazarus que vai consumir a biblioteca:

```bash
boss install FluentSQL
```

O nome do pacote no Boss é **FluentSQL** (substitui referências antigas como `CQuery4D`; ver `CHANGELOG.md` **[1.0.0]**).

## Obter o código-fonte (clonar)

Clone o repositório quando for contribuir ou depurar o próprio FluentSQL:

```bash
git clone https://github.com/ModernDelphiWorks/FluentSQL.git
```

## Dependências

O manifesto na raiz (`boss.json`) descreve o pacote; use o Boss para resolver dependências quando o projeto for consumido como biblioteca:

```bash
boss install
```

(Execute na pasta do seu projeto que referencia o FluentSQL, não necessariamente na raiz deste repositório.)

## Verificação

- Confirme que as units em `Source/Core/` e `Source/Drivers/` estão no **search path** do seu projeto Delphi/Lazarus.
- Compile um dos projetos de teste em `Test Delphi/` (por exemplo `Firebird_tests/PTestFluentSQLFirebird.dpr`), conforme a secção **Tests** do `README.md`, se quiser validar o ambiente local.
