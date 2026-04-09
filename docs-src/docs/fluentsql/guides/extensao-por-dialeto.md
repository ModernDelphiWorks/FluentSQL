---
displayed_sidebar: fluentsqlSidebar
title: Extensão explícita por motor (ESP-016)
---

# Extensão explícita por motor (ESP-016)

O **núcleo** do FluentSQL continua focado em SQL **amplamente portável** e uma API fluente coerença entre motores. Recursos que **não** são universais (por exemplo `RETURNING`, dicas de otimizador específicas, extensões de um SGBD) entram apenas pela **extensão opt-in** documentada em **ADR-016**. Fecho formal e rastreio: issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27) (**ESP-016**).

## Contrato

| | Núcleo | Extensão (`ForDialectOnly`) |
|---|--------|-----------------------------|
| Portabilidade | Mesma API tende a produzir SQL utilizável em vários motores (com o dialeto escolhido em `CreateFluentSQL`) | **Não** há promessa de portabilidade: o texto é emitido só para o `TFluentSQLDriver` indicado |
| Responsabilidade | Comportamento previsível da biblioteca na serialização | **Quem chama** valida semântica, versão do servidor e integração ao mudar de banco |
| Parâmetros | `IFluentSQLParams` nos fluxos suportados | Sobrecarga com `array of const` usa o mesmo `Params` da consulta; texto livre permanece por conta do consumidor |

## API

- **`ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string)`** — regista um sufixo textual aplicado **apenas** quando o dialeto da instância (`CreateFluentSQL`) é `ADialect`. Noutros motores o trecho é omitido (comportamento vazio, alinhado a **RB-EXT-3**).
- **`ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const)`** — igual ao anterior, com fragmento gerado por **`TUtils.SqlArrayOfConstToParameterizedSql`** e placeholders no AST (`:pN` antes da substituição por `?` no MySQL, etc.).

O nome **ForDialectOnly** deixa explícito que o trecho **não** é SQL “universal”.

## Exemplos

### Núcleo portável (sem extensão)

```delphi
CreateFluentSQL(dbnFirebird)
  .Select.All
  .From('CLIENTES')
  .Where('ATIVO').Equal(1);
```

### Extensão por motor (PostgreSQL `RETURNING`)

```delphi
CreateFluentSQL(dbnPostgreSQL)
  .Insert
  .Into('LOGS')
  .SetValue('MSG', 'ok')
  .ForDialectOnly(dbnPostgreSQL, ' RETURNING ID');
```

Na serialização **Firebird**, o mesmo encadeamento com `.ForDialectOnly(dbnPostgreSQL, …)` **não** acrescenta o `RETURNING` (trecho omitido).

### Dois motores para o mesmo ponto (um vazio)

```delphi
CreateFluentSQL(dbnFirebird)
  .Insert.Into('T').SetValue('A', 1)
  .ForDialectOnly(dbnPostgreSQL, ' RETURNING ID')
  .ForDialectOnly(dbnMySQL, '');
```

Em **Firebird**, apenas o `INSERT` base é emitido; as variantes PostgreSQL e MySQL não aplicam-se ao dialeto atual.

## Leitura no código

- `FluentSQL.Interfaces.pas` — `TDialectOnlyFragment`, `IFluentSQLAST`, métodos em `IFluentSQL`.
- `FluentSQL.Serialize.pas` — `DialectOnlySqlSuffix`, `ComposeSqlCore`.
- `FluentSQL.Ast.pas` — armazenamento e `GetSerializationDialect`.
