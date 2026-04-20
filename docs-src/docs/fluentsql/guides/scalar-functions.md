---
displayed_sidebar: fluentsqlSidebar
title: Funções Escalares
---

# Funções Escalares (Math & String)

O FluentSQL oferece uma camada de abstração para funções escalares que variam entre os dialetos de banco de dados. Isso garante que você escreva o código uma vez e o framework cuide da tradução para o SQL específico.

## Funções Matemáticas (v1.5.1+)

A partir da versão **v1.5.1**, foram introduzidas funções matemáticas essenciais com paridade entre os principais drivers (PostgreSQL, MySQL, MSSQL).

### Round (Arredondamento)

Arredonda um valor numérico para o número de casas decimais especificado.

```pascal
var
  LResult: string;
begin
  LResult := Query(dbnMSSQL)
    .Select
    .Column(Round('123.456', 2))
    .AsString;
  // SQL: SELECT ROUND(123.456, 2)
end;
```

### Floor (Chão)

Retorna o maior valor inteiro menor ou igual ao número.

```pascal
LResult := Query(dbnPostgreSQL)
  .Select
  .Column(Floor('123.45'))
  .AsString;
// SQL: SELECT FLOOR(123.45)
```

### Ceil (Teto)

Retorna o menor valor inteiro maior ou igual ao número.

```pascal
LResult := Query(dbnMSSQL)
  .Select
  .Column(Ceil('123.45'))
  .AsString;
// SQL: SELECT CEILING(123.45)
```

### Abs (Valor Absoluto)

Retorna o valor absoluto (positivo) de um número.

```pascal
LResult := Query(dbnMySQL)
  .Select
  .Column(Abs('-10'))
  .AsString;
// SQL: SELECT ABS(-10)
```

## Funções de String

### SubString

Extrai uma parte de uma string.

```pascal
Query(dbnFirebird).Select.Column(SubString('NOME', 1, 10)).AsString;
```

### Trim, LTrim e RTrim

Remove espaços em branco das extremidades.

```pascal
Query(dbnMSSQL).Select.Column(Trim(' NOME ')).AsString;
```

### Concat

Concatena múltiplas strings ou colunas.

```pascal
Query(dbnPostgreSQL).Select.Column(Concat(['NOME', ''' ''', 'SOBRENOME'])).AsString;
```

## Funções de Data

### Date / Year / Month / Day

Extracção de partes de uma data.

```pascal
Query(dbnMSSQL).Select.Column(Year('DATA_CADASTRO')).AsString;
// SQL: SELECT YEAR(DATA_CADASTRO)
```

### CurrentDate / CurrentTimestamp

Obtém a data ou data/hora atual do servidor.

```pascal
Query(dbnPostgreSQL).Select.Column(CurrentDate).AsString;
// SQL: SELECT CURRENT_DATE
```

## Outras Funções

### Coalesce

Retorna o primeiro valor não nulo de uma lista.

```pascal
Query(dbnMSSQL).Select.Column(Coalesce(['VALOR_NOVO', 'VALOR_ANTIGO', '0'])).AsString;
```

### Modulus

Operação de resto da divisão.

```pascal
Query(dbnMySQL).Select.Column(Modulus('ID', '2')).AsString;
```

---

> [!TIP]
> Nem todos os dialetos suportam todas as funções. Se você tentar usar uma função não implementada para um dialeto específico, o framework lançará uma exceção de "não suportado".
