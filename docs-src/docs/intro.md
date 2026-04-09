---
displayed_sidebar: docsSidebar
title: Portal de documentação
slug: /
sidebar_position: 0
---

Bem-vindo ao portal técnico do ecossistema **FluentSQL**. Aqui você encontra a documentação derivada do código-fonte, dos testes e dos artefatos do pipeline.

## Projetos

<div className="row">
  <div className="col col--6 margin-bottom--lg">
    <div className="card">
      <div className="card__header">
        <h3>FluentSQL</h3>
      </div>
      <div className="card__body">
        <p>Fluent API para construir SQL em Delphi/Lazarus, com AST, drivers por dialeto e parâmetros alinhados à SQL gerada (incluindo <code>UNION</code> / <code>INTERSECT</code> desde a v0.2.0). A API pública estável usa <code>CreateFluentSQL</code> desde a v1.0.0; na v1.0.1 o <code>ROADMAP.md</code> passou a ser artefato operacional; na <strong>v1.0.2</strong> a <strong>Fase 0</strong> foi fechada no roadmap (<strong>ESP-008</strong>); nas <strong>v1.0.3</strong>–<strong>v1.0.7</strong> entraram os incrementos de parametrização (<strong>ESP-009</strong> … <strong>ESP-013</strong>); na <strong>v1.0.8</strong> o driver <strong>MongoDB</strong> passou a serialização <strong>JSON/MQL</strong> canónica (<strong>ESP-014</strong>); na <strong>v1.0.9</strong> há <strong>INSERT em lote</strong> com <code>AddRow</code> e Mongo <code>insertMany</code> quando N &gt; 1 (<strong>ESP-015</strong>); <strong>ESP-016</strong> documenta <strong>extensão explícita por motor</strong> via <code>ForDialectOnly</code> (<strong>ADR-016</strong>). Inclui <strong>manual de uso</strong> além da documentação técnica.</p>
      </div>
      <div className="card__footer">
        <a className="button button--primary" href="./fluentsql/">Abrir documentação →</a>
      </div>
    </div>
  </div>
</div>

## Versão documentada

A documentação do produto reflete o estado publicado em **v1.0.9** (2026-04-08), conforme `CHANGELOG.md`, `boss.json` e as tags no repositório. A mudança de API pública (`CreateFluentSQL`, pacote FluentSQL) permanece na entrada **[1.0.0]**; listas em `IN` / `NOT IN` estão em **[1.0.3]** (issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19)); parametrização com **`array of const`** em predicados e DML está em **[1.0.4]** (issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21)); alinhamento de **`Expression`** / critérios em **`FluentSQL.Expression.pas`** ao helper de parametrização está em **[1.0.5]** (issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23)); **`Column(array of const)`** na lista `SELECT` está em **[1.0.6]** (issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25)); **`CaseExpr(array of const)`** na expressão discriminante do `CASE` está em **[1.0.7]** (**ESP-013**; rastreio no `CHANGELOG`, não confundir com a issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27) — **ESP-016**). **MongoDB** (JSON/MQL, DML mínimo) está em **[1.0.8]** ([#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29)); **INSERT em lote** (`AddRow`, multi-`VALUES`, Mongo `insertMany`) está em **[1.0.9]** ([#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)). **Extensão por motor** (`ForDialectOnly`, **ADR-016**) está descrita no guia [Extensão explícita por motor](./fluentsql/guides/extensao-por-dialeto.md) e na [referência de API](./fluentsql/reference/api.md).
