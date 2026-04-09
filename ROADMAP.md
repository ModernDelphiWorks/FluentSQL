# Roadmap — FluentSQL

> **Contrato do produto — só `string` via POO:** o FluentSQL existe para **gerar texto**: scripts **SQL** (e, onde o driver for outro formato, **string** equivalente — ex. MQL/JSON como **saída textual**). **CRUD, DDL e o que a API cobrir** traduzem-se sempre em **uma ou mais strings** obtidas por **API fluente orientada a objetos** (classes/interfaces, encadeamento), com serialização por **driver** (`dbn*`) e núcleo alinhado a **SQL amplamente portável** onde aplicável.
>
> **Isto não é** camada de acesso a dados: **não** há conexão, **não** há execução no SGBD, **não** há leitura de catálogo nem validação “classe vs base” *dentro* do pacote — isso fica na tua aplicação ou noutras bibliotecas. O FluentSQL **entrega `string` + `Params`** (quando aplicável) para tu ligares ao FireDAC, UniDAC, Zeos ou ao que quiseres. Recursos específicos de um motor entram por **extensão explícita opt-in** (**ESP-016**). Segurança no uso dos parâmetros continua no âmbito do projeto consumidor.

**Última atualização:** 2026-04-09

## Como este roadmap evolui

Este arquivo é um **artefato vivo**: descreve a direção do produto e deve **mudar junto** com o trabalho real. Não é um snapshot congelado.

| Gatilho | O que atualizar aqui |
|--------|----------------------|
| **`/architect`** (nova demanda relevante ao produto) | Itens de fase/backlog quando a direção mudar; **uma linha** no [Histórico de evolução do roadmap](#histórico-de-evolução-do-roadmap) se a mudança for material. |
| **`/sprint`** | [Registro de sprints](#registro-de-sprints): data, escopo, referência à issue; alinhar checkboxes concluídos. |
| **`/release`** | Previsões de fase se necessário; linha no histórico para marcos de versão. |
| **Implementação concluída** | Ticar itens no [checklist](#-checklist-de-execução-acompanhamento) e na fase correspondente; conferir `.claude/pipeline/implement-report.md` e testes. |

**Detalhe operacional** (planos, critérios, fatias): `.claude/pipeline/` — em especial `esp.md`, `plan.md`, `task.md`. O roadmap resume o quadro para humanos; o pipeline mantém o rastro fino para a esteira.

## Estado atual (foco)

- **Fase 0 (identidade / rebranding, âmbito consumidor):** encerrada no roadmap após auditoria **ESP-008** (evidências e matriz em `.claude/pipeline/implement-report.md`). Issue: [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17).
- **Fase 2 — ESP-016 (extensão explícita por motor):** fecho formal verificado em **2026-04-09** (issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)). **Fase 3 — DDL (ESP-017 … ESP-019):** entregues em **v1.1.0** (**2026-04-09**, `CHANGELOG.md`): `CREATE TABLE` (**ESP-017**, [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)), `DROP TABLE` (**ESP-018**, [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29) / [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)), `ALTER TABLE ADD COLUMN` (**ESP-019**, [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)); guias em `docs-src`. **ESP-020** (`ALTER TABLE DROP COLUMN`, **ADR-020**, issue [#34](https://github.com/ModernDelphiWorks/FluentSQL/issues/34)):** implementação e documentação no repositório; `task.md` reconciliado com `review-report.md` / `test-report.md`; **próximo passo:** **`/develop`** e **`/release`** (entrada em `CHANGELOG`/versão — contrato do pipeline). **Retirado do roadmap de núcleo:** CTE genérico, window functions, `RETURNING` / `ON CONFLICT` / `EXCEPT` como promessa universal (ver **ADR-016** em `.claude/pipeline/adr.md`). **Fase 1:** batch INSERT (**ESP-015**) entregue (**CHANGELOG [1.0.9]**, [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24)); **ESP-014** Mongo entregue (**CHANGELOG [1.0.8]**, [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29)).
- **Pipeline:** `.claude/pipeline/task.md`, `esp.md`, `plan.md` e relatórios (`implement-report.md`, etc.) para rastreio fino da esteira.
- **Projeto Kanban:** GitHub Project nº 16 (`gh project item-list 16 --owner ModernDelphiWorks`).

---

## Fases

### Fase 0 — Identidade e rebranding (encerrada no roadmap — âmbito consumidor, 2026-04-08)

**Objetivo:** Refatoração completa de nomenclatura para **FluentSQL** em todo o repositório (fontes públicas, testes, projetos `.dpr`, Boss, README e documentação), eliminando marcas e símbolos legados.

**Previsão:** Q2 2026 (antes ou em paralelo controlado à Fase 1)

- [x] Inventário e matriz de substituição: **CQLBr**, **CQL4D**, **cqlbr.*** (caminhos/unidades), **CQuery**, **TCQL**, uses **CQL** / **CQL.Interfaces**, programas **TestCQLBr_***, **TestCQuery_***, fixtures (**UTestFluent.CQL***, **TTestCQL***), referências em **boss.json** e **README**. *Evidência:* `CHANGELOG.md` **[1.0.0]** (tabela antes/depois); ausência de usos legados em `Source/**/*.pas` e `Test Delphi/**/*.dpr` / `*.pas` (referências legadas apenas em docs de migração e arquivo).
- [x] API pública: substituir fábrica `CQuery` / `TCQL.New` pelo nome acordado no pipeline (ver `.claude/pipeline/adr.md` — ex.: `CreateFluentSQL` / `CreateFluentSQL`). *Evidência:* `Source/Core/FluentSQL.pas` (`CreateFluentSQL`); `CHANGELOG.md` **[1.0.0]**; README exemplo com `CreateFluentSQL`. O atalho **`TCQ`** na mesma unit permanece documentado como equivalente (não é a fábrica legada `CQuery`).
- [x] Corrigir todos os `.dpr` de teste para unidades e caminhos reais `FluentSQL.*` sob `Source/`. *Evidência:* `Test Delphi/**/TestFluentSQL_*.dpr`, `PTestFluentSQLFirebird.dpr`, `PTestFluentSQLSample.dpr` com uses apontando para `..\..\Source\Core\FluentSQL.*` e drivers.
- [x] Atualizar documentação (`docs-src/`, troubleshooting) e comandos de build em `.claude/SKILL.md` após renomes. *Evidência:* `docs-src/docs/fluentsql/introduction.md`, `troubleshooting/common-errors.md`; `.claude/SKILL.md` § comandos com projetos `TestFluentSQL_*`.
- [x] Registar **breaking changes** no CHANGELOG quando a API pública mudar. *Evidência:* `CHANGELOG.md` **[1.0.0]** (secção *Changed (breaking)*).

**Nota (ADR-008):** identificadores **internos** com prefixo `FCQL*` em `Source/Core/FluentSQL.Register.pas` não fazem parte da API pública; permanecem como dívida opcional (rename limitado / backlog), não impedindo o fechamento da Fase 0 no âmbito consumidor.

**Artefatos de planejamento:** `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` (ESP-004); reconciliação checklist: **ESP-008**, **ADR-008**, issue [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17).

---

### Fase 1 — Segurança e Robustez (Core)

**Objetivo:** Implementar parametrização para proteção contra SQL Injection e garantir a estabilidade das operações básicas.
**Previsão:** Q2 2026

- [ ] Prepared Statements (Parametrização): Substituir interpolação direta por parâmetros (`:pN` / `?` por dialeto). *Incrementos entregues:* **ESP-009** … **ESP-012** (issues [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19), [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21), [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23), [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25); CHANGELOG **1.0.3**–**1.0.6**), **ESP-013** (CHANGELOG **1.0.7** — `CaseExpr(array of const)`, **ADR-012**). *Outro eixo Fase 1 entregue:* Mongo **ESP-014** e batch **ESP-015** (itens abaixo).
- [x] Refatoração do Driver MongoDB: Serialização **MQL/JSON** coerente (fim do pseudo-SQL em `FluentSQL.SelectMongoDB.pas`, política de DML sem `{}` silencioso). *Entregue:* **ESP-014** (**ADR-013**; **CHANGELOG [1.0.8]**, [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29)).
- [x] Batch Operations: Inserções múltiplas num único comando (`AddRow`, SQL multi-`VALUES`, Mongo `insertMany`). *Entregue:* **ESP-015** (**ADR-014**; **CHANGELOG [1.0.9]**, [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24)).

---

### Fase 2 — Núcleo portável e extensão explícita por motor

**Objetivo:** Preservar **uma** API fluente que, no núcleo, não obrigue o utilizador a depender de construções que **uns SGBDs têm e outros não** (ou com custo/semântica muito diferentes). Para necessidades “modernas” ou específicas de um só motor, o produto oferece **extensão opt-in** — o desenvolvedor fica **consciente** de que a portabilidade **não** é garantida pelo FluentSQL nesse trecho.

**Previsão:** Q3 2026

- [x] **ESP-016** — Extensão explícita por motor (opt-in por dialeto): API e serialização documentadas; trechos fora do motor alvo podem ser **`''`**; issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27); fecho verificado em **2026-04-09** (`.claude/pipeline/implement-report.md`, `test-report.md`). Ver `.claude/pipeline/esp.md`, `plan.md`, **ADR-016** em `adr.md`.
- [x] **Operações de conjunto (núcleo já existente):** `UNION`, `UNION ALL`, `INTERSECT` na API (`FluentSQL.pas`). *Não* há objetivo de **`EXCEPT`** no núcleo universal nesta direção — apenas via **ESP-016** ou SQL literal na aplicação.
- [ ] **Sem roadmap de núcleo** para: CTE/`WITH` genérico além do que já existir como `WithAlias`, window functions (`OVER`, etc.), `RETURNING`, `ON CONFLICT`/`UPSERT` como contrato “para todos os bancos”. Quem precisar usa **extensão por motor** ou composição na camada da aplicação.

---

### Fase 3 — Ecossistema e DDL

**Objetivo:** Expandir o **gerador de strings** (sintaxe SQL/MQL como texto) para além do DML onde fizer sentido — sempre **só texto via POO**, sem **acesso a dados**, execução ou leitura de catálogo **dentro** do FluentSQL.

**Previsão:** Q4 2026

**Não objetivos (não constam como fases nem backlog de produto):** **API ou camada de acesso a dados**; substituir FireDAC/UniDAC/Zeos; **inspecionar ou validar** metadados reais no motor (catálogo vs catálogo, classe vs BD) — o FluentSQL **só emite strings** que *tu* pediste na fluent API (incluindo DDL: ainda é **texto**, não é “ir buscar” o esquema à base). Executar SQL, abrir conexões ou “serializador REST” como produto — **fora**. Quem fala com o SGBD ou HTTP é sempre o consumidor.

- [x] **ESP-017** — DDL fluente (vertical inicial): fundação + **`CREATE TABLE`** com **ADR-017** — entregue **v1.1.0** **2026-04-09** ([#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)); detalhe histórico em `CHANGELOG.md` / `.claude/pipeline/`.
- [x] **ESP-018** — DDL alargado (1ª vertical): **`DROP TABLE`** com **ADR-018** — entregue **v1.1.0** **2026-04-09** ([#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29) / [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)).
- [x] **ESP-019** — DDL alargado (2ª vertical): **`ALTER TABLE … ADD COLUMN`** com **ADR-019** — entregue **v1.1.0** **2026-04-09** ([#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)).
- [ ] **ESP-020** — DDL alargado (3ª vertical): **`ALTER TABLE … DROP COLUMN`** com **ADR-020**, testes Firebird + PostgreSQL e guia em `docs-src`; detalhe em `.claude/pipeline/esp.md` / `plan.md`.
- [ ] **ESP-022** — DDL alargado (4ª vertical): **`CREATE INDEX`** (API fluente + serialização **Firebird** e **PostgreSQL**, **ADR-022**); testes em `test.ddl.pas` e guia em `docs-src`; *ver `.claude/pipeline/esp.md` / `plan.md`.*
- [ ] DDL Fluente (âmbito alargado): `ALTER TABLE` (além de ADD/DROP column), **DROP INDEX** e restantes índices/alterações (avaliar portabilidade; o que for estritamente específico de um motor → **ESP-016** ou app). *Nota: `DROP TABLE` — **ESP-018**; **ADD COLUMN** — **ESP-019**; **DROP COLUMN** — **ESP-020**; **CREATE INDEX** — **ESP-022**; esta linha cobre o restante alargamento.*

### Meta — Governança do roadmap (contínuo)

**Objetivo:** Manter este documento útil e honesto em relação ao repositório e ao pipeline.

**Previsão:** contínua

- [ ] A cada `/sprint` ou release relevante, atualizar [Registro de sprints](#registro-de-sprints) e checklists conforme o que foi de fato entregue.
- [ ] A cada mudança material de direção (escopo de fase, prioridade), registrar no [Histórico de evolução do roadmap](#histórico-de-evolução-do-roadmap).
- [ ] Revisar trimestralmente (ou por release maior) se as **previsões** por fase ainda fazem sentido.

---

## Backlog

Itens identificados mas não priorizados:

- Política de compatibilidade opcional (alias deprecated) para `CQuery` — só se a comunidade exigir janela de migração; caso contrário, remoção direta conforme Fase 0.
- Suporte a Dialetos NoSQL adicionais.
- Integração nativa com frameworks ORM leves.
- Revisão de **`WithAlias`** legado vs política de núcleo portável (deprecação documentada ou manutenção mínima), após **ESP-016**.

---

## Registro de sprints

Cada sprint documentado pelo `/sprint` é registrado aqui.
O `/sprint` tica o item correspondente ao fechar a rodada.

- [ ] Sprint 1 — Planejamento Inicial e Infra de Parametrização — 2026-04-07

---

## Histórico de evolução do roadmap

| Data | Mudança | Referência |
|------|---------|------------|
| 2026-04-08 | Introduzidas política de artefato vivo, gatilhos de atualização, bloco **Estado atual**, fase **Meta — Governança** e esta tabela de histórico (demanda ESP-007). | GitHub [#15](https://github.com/ModernDelphiWorks/FluentSQL/issues/15), `.claude/pipeline/esp.md`, `adr.md`, `plan.md` |
| 2026-04-08 | Reconciliação **Fase 0** e checklist **R1–R6** com evidências do repositório (CHANGELOG 1.0.x, Boss, testes, docs); **Estado atual** aponta **Fase 1 — parametrização**; dívida interna `FCQL*` documentada (ADR-008). | GitHub [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17), **ESP-008** (`.claude/pipeline/esp.md`), **ADR-008** (`.claude/pipeline/adr.md`), `.claude/pipeline/implement-report.md` |
| 2026-04-08 | Planejada **ESP-009** — baseline de parametrização DML (fixture `test.core.params.pas`, placeholders `:pN` vs `?`, redução de `SqlParamsToStr` em valores); **ADR-009** no pipeline. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` |
| 2026-04-08 | Release **v1.0.3**: primeiro incremento **ESP-009** (`IN` / `NOT IN` com listas parametrizadas, fixture `test.core.params.pas` em Firebird e MySQL). Caveats: [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20). | GitHub [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19), `CHANGELOG.md` **[1.0.3]** |
| 2026-04-08 | Planejada **ESP-010** — segundo incremento de parametrização: redução de `SqlParamsToStr` em `array of const`, Having/Values/CASE (`FluentSQL.pas`, `FluentSQL.Cases.pas`); regressão obrigatória além de Firebird+MySQL em ≥2 projetos `.dpr` (MSSQL/Oracle/DB2/Interbase). ADR-009 mantido; sem novo ADR (secção no `adr.md`). | `.claude/pipeline/esp.md`, `plan.md`, `task-input.md`, `adr.md` |
| 2026-04-08 | Planejada **ESP-011** — terceiro incremento: alinhar `FluentSQL.Expression.pas` ao helper de parametrização; **ADR-011** (política explícita para strings em `array of const`; sem heurística frágil); testes e regressão Firebird+MySQL (+ dialeto extra recomendado). `CaseExpr(array)` fora de escopo. | `.claude/pipeline/esp.md`, `plan.md`, `task-input.md`, `adr.md` |
| 2026-04-08 | Release **v1.0.5**: terceiro incremento **ESP-011** (`TFluentSQLCriteriaExpression`, **ADR-011**, wiring em `FluentSQL.pas` / `FluentSQL.Cases.pas`, testes em `test.core.params.pas`). Caveats: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24). | GitHub [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23), `CHANGELOG.md` **[1.0.5]** |
| 2026-04-08 | Release **v1.0.6**: quarto incremento **ESP-012** — `Column(array of const)` via `SqlArrayOfConstToParameterizedSql` + `FAST.Params` (**ADR-009** / **ADR-011**); `CaseExpr(array)` intocado. Caveats (runners MSSQL/Oracle): [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26). | GitHub [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25), `CHANGELOG.md` **[1.0.6]** |
| 2026-04-08 | Planejada **ESP-013** — quinto incremento de parametrização: `CaseExpr(array of const)` via `SqlArrayOfConstToParameterizedSql` + `FAST.Params`; **ADR-012** (contexto `CASE`, paridade com **ADR-011**); testes em `test.core.params.pas` e regressão Firebird+MySQL (+ extra recomendado). | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` |
| 2026-04-08 | Entregue **ESP-013** no repositório (CHANGELOG **1.0.7**). Planejada **ESP-014** — driver MongoDB: contrato JSON canónico, alinhamento `SelectMongoDB` vs serializer, DML (JSON ou exceção); **ADR-013**. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` |
| 2026-04-08 | Entregue **ESP-014** (CHANGELOG **[1.0.8]**, [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29); caveats [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)). **Arquitetada ESP-015** — batch INSERT multi-`VALUES`, Mongo `insertMany`, **ADR-014**; pipeline atualizado. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, **ESP-015** |
| 2026-04-09 | **Auditoria Kanban** (Project 16): Backlog = dívidas técnicas pós-release + lacuna legado #12; entregas em **Done**. **Arquitetada ESP-016** — CTE fluente (`WITH` / `WITH RECURSIVE`), **ADR-015**; estado do roadmap alinhado a **CHANGELOG [1.0.9]** (**ESP-015** entregue). | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md` |
| 2026-04-09 | **Direção de produto (**ADR-016**):** núcleo sem SQL “moderno” universal; **ESP-016** repensada como **extensão explícita por motor**; **ADR-015** (CTE no núcleo) **revogado**; Fase 2 e backlog atualizados. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md` |
| 2026-04-09 | **Pipeline:** artefatos **ESP-016** renovados para **fecho formal** (auditoria de serializadores, testes, docs); plano em 6 fatias em `plan.md` — implementação núcleo já presente no repo. | `.claude/pipeline/esp.md`, `plan.md`, `task-input.md`, `checklist.md` |
| 2026-04-09 | **Fase 2 — ESP-016:** checklist e roadmap ticados; documentação alinhada (issue **#27** vs rastreio **ESP-013** em `CHANGELOG` **[1.0.7]**); relatórios `implement-report.md` / `test-report.md` prontos para **`/develop`**. | `.claude/pipeline/implement-report.md`, `test-report.md`, `task.md` |
| 2026-04-09 | Planejada **ESP-017** — DDL fluente (fundação + `CREATE TABLE`, **ADR-017**); artefatos `esp.md`, `adr.md`, `plan.md`, `task-input.md` na pasta pipeline. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` |
| 2026-04-09 | Planejada **ESP-018** — DDL alargado (`DROP TABLE`, **ADR-018**); **ESP-017** com QA aprovado, aguardando **`/develop`**; artefatos renovados na pasta pipeline. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md` |
| 2026-04-09 | **`/architect`** — handoff **ESP-018** confirmado; código-fonte já inclui API **`DROP TABLE`**; critérios de aceite e issue GitHub a fechar na esteira (`/task`, testes, **`/release`**). Índice **ADR-018** corrigido (sem associação errada a **#29**). | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md` |
| 2026-04-09 | **`/architect` (renovação)** — **ESP-018**: `esp.md` / `plan.md` / `task-input.md` alinhados ao estado do repositório (implementação + `test.ddl` + `ddl-drop-table.md`); checklist com próximos passos **`/task`** → **`/test`** → **`/develop`**. | `.claude/pipeline/esp.md`, `plan.md`, `task-input.md`, `checklist.md`, `ROADMAP.md` |
| 2026-04-09 | **`/architect`** — **ESP-019** planeada: **`ALTER TABLE ADD COLUMN`** (**ADR-019**); artefactos `esp.md`, `adr.md`, `plan.md`, `task-input.md`; checklist nova rodada; roadmap Fase 3 atualizado. Próximo passo: **`/task`**. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md`, `ROADMAP.md` |
| 2026-04-09 | **`/architect`** — **ESP-017–019** reconciliados como entregues **v1.1.0**; **ESP-020** planeada: **`ALTER TABLE DROP COLUMN`** (**ADR-020**); artefactos `esp.md`, `adr.md`, `plan.md`, `task-input.md`; checklist nova rodada. Próximo passo: **`/task`**. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md`, `ROADMAP.md` |
| 2026-04-09 | **Alinhamento de escopo:** removidos do roadmap itens que sugeriam validação por metadados, “REST API serializer” ou execução via suites (FireDAC/UniDAC/Zeos) como direção de produto; consolidada secção **Não objetivos** na Fase 3. Ajuste pontual em `CHANGELOG.md` **[0.2.0]** (texto histórico). | `ROADMAP.md`, `CHANGELOG.md`, `.claude/pipeline/esp.md` (**ESP-021**) |
| 2026-04-09 | **Identidade e contrato:** produto = **só geração de `string` (scripts) via POO** (CRUD, DDL, etc. — “metadados” no sentido de **texto** gerado pela API, não validação nem I/O ao SGBD); **Não objetivos** e abertura reforçam que **não** há camada de acesso a dados. | `ROADMAP.md` |
| 2026-04-09 | **`/architect`:** renovados artefactos **ESP-020** / **ADR-020** (DROP COLUMN); **Estado atual** alinhado — código no repo, fecho versionado via **`/release`**; **ADR-021** mantido no mesmo `adr.md`. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `ROADMAP.md` |
| 2026-04-09 | **`/architect`:** ficheiros `esp.md`, `adr.md`, `plan.md`, `task-input.md` **materializados** no repositório (ESP-020 / ADR-020 + ADR-021); checklist rodada 7; próximo passo oficial **`/task`** para `task.md` e **#34**. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md` |
| 2026-04-09 | **`/architect` (próxima demanda):** **ESP-020** — artefactos e `task.md` reconciliados (`review-report.md` marcado cumprido); remanescente **`/develop`** + **`/release`** (issue **#34**); checklist rodada 9. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `task.md`, `checklist.md` |
| 2026-04-09 | **`/architect` (próxima demanda de produto):** planeada **ESP-022** — **`CREATE INDEX`** (Firebird + PostgreSQL, **ADR-022**); *nota:* **ESP-021** já usada no pipeline para trabalho documental (non-goals / **ADR-021**). Pendente **`/release`** para fecho versionado de **ESP-020** (**#34**) antes ou em paralelo à esteira de implementação, conforme política. | `.claude/pipeline/esp.md`, `adr.md`, `plan.md`, `task-input.md`, `checklist.md`, `ROADMAP.md` |

---

## 📋 Checklist de Execução (Acompanhamento)

Este checklist detalha as tarefas técnicas necessárias para completar as fases acima.

**Alinhamento:** marque cada item quando o critério correspondente estiver de fato atendido. Use como evidência `.claude/pipeline/implement-report.md`, `review-report.md`, `test-report.md` e a suíte DUnitX quando aplicável — não antecipe tiques só por planejamento em aberto.

### Fase 0 (rebranding) — acompanhamento técnico
- [x] **Slice R1:** Inventário grep + matriz arquivo/símbolo. *Evidência:* matriz pública em `CHANGELOG.md` **[1.0.0]**; grep sem ocorrências produtivas de `CQuery(` / `TCQL.New` / `uses CQL` em `Source/` e suíte `Test Delphi/` (exceto menções em documentação).
- [x] **Slice R2:** `FluentSQL.pas` — nova fábrica e remoção de `CQuery`. *Evidência:* `CreateFluentSQL` em `Source/Core/FluentSQL.pas`; breaking change documentado no CHANGELOG.
- [x] **Slice R3–R4:** Testes Firebird e demais dialetos — uses e `.dpr`. *Evidência:* projetos `PTestFluentSQLFirebird.dpr`, `TestFluentSQL_{MSSQL,MySQL,Oracle,DB2,Interbase}.dpr`, etc., com `FluentSQL.*` e `CreateFluentSQL` nos testes.
- [x] **Slice R5:** Boss, README, docs. *Evidência:* `boss.json` (`name`: FluentSQL, `version` 1.0.2); `README.md`; `docs-src/docs/fluentsql/*`.
- [x] **Slice R6:** SKILL.md (com backup), grep final. *Evidência:* `.claude/SKILL.md` com comandos `TestFluentSQL_*`; backup de SKILL em `.archive/skill-md/` (contrato pipeline). *Ressalva ADR-008:* grep ainda encontra `FCQL*` apenas em campos internos de `FluentSQL.Register.pas` (fora da API pública).

### Sprint 1: Infraestrutura e Segurança
- [ ] **Slice 1: Core de Parametrização**
    - [ ] Definir interface `IFluentSQLParams`.
    - [ ] Implementar coleta de parâmetros no `TFluentSQL`.
    - [ ] Atualizar `TFluentSQLAst` para suporte a parâmetros.
- [ ] **Slice 2: Serializadores DML**
    - [ ] Atualizar Serializer Firebird.
    - [ ] Atualizar Serializer MySQL.
    - [ ] Atualizar Serializer PostgreSQL.
- [ ] **Slice 3: Driver MongoDB**
    - [x] Implementar serialização MQL (JSON). *Evidência:* **ESP-014** / **CHANGELOG [1.0.8]**.

### Sprint 2: Núcleo portável e ESP-016
- [ ] **Slice 4: ESP-016 — Extensão explícita por motor** (opt-in por `dbn`, documentação núcleo vs extensão).
- [x] **Slice 5: Operações de conjunto (já no núcleo)** — `Union`, `UnionAll`, `Intersect` em `FluentSQL.pas`. `EXCEPT` / SQL avançado específico → ESP-016 ou camada app.

### Critérios de Aceite Gerais
- [ ] Testes unitários passando em todos os dialetos.
- [ ] Sem quebras de compatibilidade (Breaking Changes).
- [ ] Documentação atualizada.
