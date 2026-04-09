---
displayed_sidebar: fluentsqlSidebar
title: Site de documentação (CI)
---

## Visão geral

O portal Docusaurus vive em `docs-src/`. A pasta de saída estática configurada no build é `docs/` na raiz do repositório (`outDir` em `docs-src/docusaurus.config.ts`), para publicação em GitHub Pages.

## Node local não é obrigatório

- Para **editar apenas Markdown** em `docs-src/docs/`, não é necessário instalar Node no seu máquina.
- O **build oficial** e a **geração** da pasta `docs/` são feitos no **GitHub Actions** quando alterações em `docs-src/` são integradas no ramo configurado no workflow.

## Workflows

| Workflow | Função |
|----------|--------|
| [`.github/workflows/deploy-docs.yml`](https://github.com/ModernDelphiWorks/FluentSQL/blob/main/.github/workflows/deploy-docs.yml) | Em push aos ramos `main` ou `develop` (com alterações em `docs-src/`), instala dependências com `npm ci`, executa `npm run build` em `docs-src/` e faz **commit** da pasta `docs/` gerada (mensagem `ci: rebuild docs [skip ci]`). |
| [`.github/workflows/docs-build.yml`](https://github.com/ModernDelphiWorks/FluentSQL/blob/main/.github/workflows/docs-build.yml) | Em **pull requests** que alterem `docs-src/` ou o próprio workflow, compila o Docusaurus para **validar** o build sem gravar `docs/` no repositório. |

## Preview opcional

Se quiser pré-visualizar o site localmente, use Node 20+ na pasta `docs-src/`:

```bash
cd docs-src
npm ci
npm run start
```

Artefatos gerados localmente (`node_modules/`, `build/`, `.docusaurus/`) não devem ser commitados; estão listados no `.gitignore` na raiz do repositório.
