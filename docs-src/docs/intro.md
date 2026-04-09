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
        <p>Fluent API para construir SQL em Delphi/Lazarus, com AST, drivers por dialeto e parâmetros alinhados à SQL gerada (incluindo <code>UNION</code> / <code>INTERSECT</code> desde a v0.2.0). A API pública estável usa <code>CreateFluentSQL</code> desde a v1.0.0; na v1.0.1 o <code>ROADMAP.md</code> passou a ser artefato operacional; na <strong>v1.0.2</strong> a <strong>Fase 0</strong> foi fechada no roadmap (<strong>ESP-008</strong>); na <strong>v1.0.3</strong> entrou <strong>ESP-009</strong> (<code>IN</code> / <code>NOT IN</code> com listas); na <strong>v1.0.4</strong> entrou <strong>ESP-010</strong> (<code>array of const</code> em <code>Where</code>, <code>Having</code>, <code>Values</code>, <code>CASE</code>, etc.); na <strong>v1.0.5</strong> entrou <strong>ESP-011</strong> (<code>TFluentSQLCriteriaExpression</code> e <code>Expression</code> no fluente com a mesma coleção <code>Params</code>); na <strong>v1.0.6</strong> entrou <strong>ESP-012</strong> (<code>Column(array of const)</code> parametrizado na projeção); na <strong>v1.0.7</strong> entrou <strong>ESP-013</strong> (<code>CaseExpr(array of const)</code> com o mesmo helper de parametrização). Inclui <strong>manual de uso</strong> além da documentação técnica.</p>
      </div>
      <div className="card__footer">
        <a className="button button--primary" href="./fluentsql/">Abrir documentação →</a>
      </div>
    </div>
  </div>
</div>

## Versão documentada

A documentação do produto reflete o estado publicado em **v1.0.7** (2026-04-08), conforme `CHANGELOG.md`, `boss.json` e o tag `v1.0.7` no repositório. A mudança de API pública (`CreateFluentSQL`, pacote FluentSQL) permanece na entrada **[1.0.0]**; listas em `IN` / `NOT IN` estão em **[1.0.3]** (issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19)); parametrização com **`array of const`** em predicados e DML está em **[1.0.4]** (issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21)); alinhamento de **`Expression`** / critérios em **`FluentSQL.Expression.pas`** ao helper de parametrização está em **[1.0.5]** (issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23)); **`Column(array of const)`** na lista `SELECT` está em **[1.0.6]** (issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25)); **`CaseExpr(array of const)`** na expressão discriminante do `CASE` está em **[1.0.7]** (issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)).
