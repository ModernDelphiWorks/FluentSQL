# Visibilidade de execução — FluentSQL

**Última atualização:** 2026-04-10  
**ESP:** ESP-024 (governança / transparência — ver `.claude/pipeline/esp.md`)

Este ficheiro **complementa** o [`ROADMAP.md`](ROADMAP.md). Não substitui o roadmap nem os artefactos finos em `.claude/pipeline/`.  
**Versionamento:** este ficheiro está **na raiz do repositório** e é **rastreável no Git** (ESP-024 / **ADR-024**). A especificação formal da rodada continua em **`.claude/pipeline/esp.md`**; **ADR-024** em `adr.md`.  
**Regra:** não listar aqui recursos ou melhorias que não existam já no roadmap, no `CHANGELOG.md`, nas issues referenciadas ou no pipeline — qualquer linha nova de produto passa primeiro por discussão explícita contigo.

---

## 1. Fontes de verdade (ordem de leitura)

| Fonte | O que cobre |
|--------|-------------|
| [`ROADMAP.md`](ROADMAP.md) | Fases, metas, backlog de produto, histórico de evolução |
| [`CHANGELOG.md`](CHANGELOG.md) | Versões **publicadas** (entradas versionadas; `[Unreleased]` vazio até `/release`) |
| `.claude/pipeline/esp.md`, `plan.md`, `task.md` | Especificação e plano da **rodada** corrente ou mais recente |
| Issues GitHub (ex.: ModernDelphiWorks/FluentSQL) | Rastreio de trabalho e dívidas citadas no changelog/roadmap |

**Nota de consistência (transparente):** o bloco **Estado actual** em `ROADMAP.md` menciona entregas **v1.1.0** (DDL ESP-017 … ESP-019). No `CHANGELOG.md` deste ramo, a secção versionada mais recente é **`[1.0.9]`** (2026-04-08). Até existir entrada versionada que corresponda a **v1.1.0**, considera-se **décalage** entre narrativa do roadmap e o que o changelog já registou — deve ser alinhado em **`/release`** ou actualização explícita do roadmap.

---

## 2. Início e fim da execução (definições)

### Início

- **Início histórico do produto** (rastreável no repositório): primeira versão documentada no `CHANGELOG.md` — secção **`[0.1.0]`** (2026-04-07).
- **Início do quadro de evolução actual** (visão “onde estamos agora”): descrito em **`ROADMAP.md` → Estado actual (foco)** e nas fases com itens em aberto.

### Fim

- **Fim do pacote de trabalho **planeado no roadmap** (âmbito actual):** quando todos os itens de fase com checkbox `[ ]` que constituem **compromisso explícito** no `ROADMAP.md` estiverem concluídos e marcados, **e** as entradas de **Meta — Governança** que aplicas forem satisfeitas (ou explicitamente descontinuadas por decisão tua).
- **Não há data única de “fim absoluto”** fixada neste documento: as **previsões** por trimestre no roadmap (Q2–Q4 2026) são **orientação**, não cronograma contratual aqui.
- **Backlog** e a secção **Propostas e ideias** (abaixo) **não** prolongam automaticamente o “fim”: só entram na esteira de features após **aprovação explícita** (ver secções 6 e 7).

---

## 3. O que já está feito (evidência rastreável)

Resumo derivado do **`ROADMAP.md`** (checkboxes `[x]` e texto **Estado actual**), cruzado com **`CHANGELOG.md`** onde há versão:

| Área | Síntese (sem inventar além do roadmap/changelog) |
|------|-----------------------------------------------------|
| Fase 0 — Identidade / rebranding | Encerrada no roadmap; evidências citadas no roadmap (CHANGELOG **[1.0.0]**, testes, docs). |
| Parametrização (eixos ESP-009 … ESP-013) | Múltiplos incrementos com entradas em **CHANGELOG [1.0.3]** … **[1.0.7]**; pormenores nas issues referenciadas no changelog. |
| MongoDB ESP-014 | **CHANGELOG [1.0.8]** |
| Batch INSERT ESP-015 | **CHANGELOG [1.0.9]** |
| ESP-016 — extensão explícita por motor | Fecho formal referido no **ROADMAP** (issue **#27**). |
| ESP-017 … ESP-019 (DDL: CREATE/DROP/ALTER ADD COLUMN) | Marcadas como entregues no **ROADMAP** (v1.1.0 / 2026-04-09); **confirmar** alinhamento com **`CHANGELOG`** quando a versão correspondente existir (ver nota na secção 1). |
| Operações de conjunto no núcleo | `UNION`, `UNION ALL`, `INTERSECT` — conforme **ROADMAP** Fase 2. |

---

## 4. O que falta executar (pendências explícitas)

Lista **apenas** a partir de itens ainda **abertos** no `ROADMAP.md` ou da **esteira** descrita no pipeline / checklist, sem acrescentar desejos não documentados.

### 4.1 Roadmap — checkboxes ainda `[ ]`

| Local no ROADMAP | Item (resumo) |
|------------------|----------------|
| Fase 1 | Linha principal **Prepared Statements (Parametrização)** permanece `[ ]` no roadmap; o texto do mesmo bloco lista incrementos já entregues — **o fecho total da linha** depende de reconciliação explícita contigo (o que falta para marcar a caixa). |
| Fase 3 | **ESP-020** — `ALTER TABLE … DROP COLUMN` (**ADR-020**, issue **#34**) — `[ ]` |
| Fase 3 | **ESP-022** — `CREATE INDEX` (Firebird + PostgreSQL, **ADR-022**, issue **#35**) — `[ ]` |
| Fase 3 | **DDL fluente (âmbito alargado)** — além de ADD/DROP column e CREATE INDEX — `[ ]` (avaliar portabilidade; específico de motor → ESP-016 ou app). |
| Meta — Governança | Atualizar registo de sprints / histórico / rever previsões — itens `[ ]` conforme tabela no roadmap. |
| Registro de sprints | **Sprint 1** — `[ ]` |
| Checklist de execução (final do ROADMAP) | Vários itens em **Sprint 1** (slices de parametrização) e **Slice 4 ESP-016** ainda `[ ]`; critérios gerais (testes todos os dialetos, sem breaking, docs) `[ ]` — **sincronizar** com o estado real da suíte e da CI (pode haver obsolescência parcial face às entregas já listadas no changelog). |

### 4.2 Esteira e versão (pipeline)

| Pendência | Referência |
|-----------|------------|
| Fecho versionado **ESP-020** (**#34**) | **ROADMAP** “Estado actual”; **`/release`** para `CHANGELOG` (política em `pipeline-contract.md`). |
| Fecho **ESP-022** (**#35**) | Especificação em `.claude/pipeline/esp.md` (ESP-022); critérios e **`/release`** como no plano. |
| Trabalho em ramo (ficheiros modificados não integrados) | Ver estado git local; alinhar com **`/develop`** quando aprovado. |

---

## 5. Bugs e defeitos — triagem para aprovação

**Propósito:** concentrar **problemas reais** ou **dívidas técnicas** que possam virar trabalho corretivo, **sem** expandir o âmbito por “melhorias contínuas” não acordadas.

**Regra:** uma linha só entra na esteira de **bugfix** depois de **aprovação tua** (ou política de priorização que definires). Até lá permanecem como **registo**.

**Regras de entrada na esteira (correção):** aprovação explícita → registo em **issue** (etiqueta `bug` quando fizer sentido) → brief em `.claude/pipeline/task.md` via **`/task`** → **`/implement`** → **`/review`** → **`/test`** → **`/develop`** / **`/release`** conforme o caso. Nada nesta tabela antecipa prioridade no Kanban sem decisão humana.

| ID / ref. | Descrição (só o já documentado) | Onde está detalhado |
|-----------|----------------------------------|---------------------|
| *(vazio)* | *Nenhum bug novo foi inventado neste documento.* | *Preencher a partir de issues, QA ou utilizadores.* |

**Dívidas técnicas citadas no `CHANGELOG.md` (para triagem, não assumidas como bugs confirmados):**

- [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32) — pós-caveats **[1.0.9]**
- [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30) — pós-caveats **[1.0.8]**
- [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28) — pós-caveats **[1.0.7]**
- [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26) — pós-caveats **[1.0.6]**
- [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24) — pós-caveats **[1.0.5]**
- [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22) — pós-caveats **[1.0.4]**
- [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20) — pós-caveats **[1.0.3]**
- [#18](https://github.com/ModernDelphiWorks/FluentSQL/issues/18) — pós-caveats **[1.0.2]**

**Caveats da esteira (build/QA/kanban):** ver `.claude/pipeline/checklist.md` — tabela **Caveats log** (MSBuild, DUnitX, IDs Kanban em `SKILL.md` raiz, etc.). São **observações de processo/ambiente**; só viram itens de produto após decisão.

---

## 6. Propostas e ideias — fora da esteira até decisão

**Propósito:** qualquer ideia nova que surja (agente, equipa ou tu) **não** entra no roadmap nem na sprint por omissão. Regista-se aqui (ou numa issue com etiqueta acordada) para **discussão futura**.

**Regras de entrada na esteira (evolução de produto):** enquanto o estado não for **`Aprovada para esteira`**, a ideia **não** gera ESP técnica nem ocupação de sprint. Após aprovação: **`/architect`** (se nova ESP/ADR) → **`/task`** → resto da pipeline; só então o item pode ser copiado para fases/checklists do [`ROADMAP.md`](ROADMAP.md).

| Data | Origem | Proposta | Estado |
|------|--------|----------|--------|
| *(vazio)* | — | — | Em discussão |

**Estados sugeridos:** `Em discussão` | `Aprovada para esteira` | `Rejeitada / arquivada` | `Adiada`

---

## 7. Backlog já identificado no ROADMAP (não priorizado)

Copiado literalmente de **`ROADMAP.md` → Backlog** (para visibilidade; **não** implica compromisso de implementação):

- Política de compatibilidade opcional (alias deprecated) para `CQuery` — só se a comunidade exigir janela de migração; caso contrário, remoção direta conforme Fase 0.
- Suporte a Dialetos NoSQL adicionais.
- Integração nativa com frameworks ORM leves.
- Revisão de **`WithAlias`** legado vs política de núcleo portável (deprecação documentada ou manutenção mínima), após **ESP-016**.

---

## 8. Manutenção deste ficheiro

| Gatilho | Acção |
|---------|--------|
| Nova fase ou fecho de ESP no roadmap | Actualizar secções 3–4 e, se necessário, 1 |
| `/release` | Cruzar versão no `CHANGELOG` com o roadmap; resolver ou anotar **décalage** (secção 1) |
| Nova ideia ou bug candidato | Secções 5 ou 6 — **nunca** promover a “já planeado” sem aprovação explícita |

---

*Documento gerado no âmbito do comando `/architect` (ESP-024). Próximo passo operacional da pipeline: `/task` quando houver tarefa de implementação associada a uma ESP aprovada.*
