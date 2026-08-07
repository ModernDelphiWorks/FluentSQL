/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - SQLITE  (T10)

  MOTOR MEDIDO
    SQLite 3.50.4 (biblioteca embutida no CPython 3.14, modulo sqlite3)

  COMO REPETIR (nao precisa de container nem do binario sqlite3)
    python - <<'EOF'
    import sqlite3
    db = sqlite3.connect(':memory:'); c = db.cursor()
    print(sqlite3.sqlite_version)
    c.execute("CREATE TABLE T (ID INT, NOME TEXT, ATIVO INT, IDADE INT)")
    c.execute("CREATE TABLE U (ID INT, NOME TEXT, ATIVO INT, IDADE INT)")
    for i in range(1, 61):
        c.execute("INSERT INTO T VALUES (?,?,?,?)", (i, "N%03d" % i, 1, 20))
        c.execute("INSERT INTO U VALUES (?,?,?,?)", (i+1000, "U%03d" % i, 1, 30))
    # ... e entao cada SELECT deste arquivo, via c.execute(sql).fetchall()
    EOF

  MASSA: T com 60 linhas (ID 1..60), U com 60 (ID 1001..1060).
         Pagina certa de First(3)/Skip(20): 21,22,23.
  ------------------------------------------------------------------------------
*/

/*
  ==============================================================================
  PARTE 1 - O DEFEITO: POSICAO ERRADA NA GRAMATICA

  TFluentSQLSelectSQLite.Serialize emitia LIMIT/OFFSET entre o SELECT e a lista
  de colunas, herdando o formato de PREFIXO que so o Firebird tem. No SQLite
  LIMIT/OFFSET sao as ULTIMAS clausulas do SELECT.
  ==============================================================================
*/

-- V1 forma ANTERIOR, First+Skip
SELECT LIMIT 3 OFFSET 20 * FROM T;
/*
  SAIDA BRUTA:
    OperationalError: near "LIMIT": syntax error

  LEITURA: invalido SEMPRE - com ou sem WHERE, com ou sem ORDER BY. Toda
  consulta paginada do driver SQLite era recusada. Nao era um caso de borda.
*/

-- V2 forma ANTERIOR, First sozinho
SELECT LIMIT 3 * FROM T;
/*
  SAIDA BRUTA:
    OperationalError: near "LIMIT": syntax error
*/

-- V3 OFFSET sem LIMIT: por que Skip sozinho precisa de um teto
SELECT ID FROM T OFFSET 20;
/*
  SAIDA BRUTA:
    OperationalError: near "20": syntax error

  LEITURA: "the OFFSET clause ... may only follow a LIMIT clause"
  (https://sqlite.org/lang_select.html). Dai o LIMIT -1 do caso 02.
*/

/*
  ==============================================================================
  PARTE 2 - AS FORMAS QUE O FluentSQL EMITE HOJE
  ==============================================================================
*/

-- 01 First(3)                                    -> [1, 2, 3]
SELECT ID FROM T LIMIT 3;

-- 02 Skip(57)                                    -> [58, 59, 60]
SELECT ID FROM T LIMIT -1 OFFSET 57;
/*
  O -1 nao e truque nosso:
    "If the expression has a negative value, then there is no upper bound on the
     number of rows returned."  https://sqlite.org/lang_select.html
*/

-- 03 First(3)+Skip(20)                           -> [21, 22, 23]
SELECT ID FROM T LIMIT 3 OFFSET 20;

-- 04 Where+First+Skip                            -> [21, 22, 23]
SELECT ID FROM T WHERE (ATIVO = 1) LIMIT 3 OFFSET 20;

-- 05 Where+OrderBy+First+Skip                    -> [21, 22, 23]
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC LIMIT 3 OFFSET 20;

-- 06 Distinct+First+Skip                         -> ['N021', 'N022', 'N023']
SELECT DISTINCT NOME FROM T LIMIT 3 OFFSET 20;

-- 07 Distinct+Skip(57)                           -> ['N058', 'N059', 'N060']
SELECT DISTINCT NOME FROM T LIMIT -1 OFFSET 57;

-- 08 GroupBy+First+Skip                          -> ['N021', 'N022', 'N023']
SELECT NOME FROM T GROUP BY NOME LIMIT 3 OFFSET 20;

-- 09 Union+First+Skip                            -> [21, 22, 23]
SELECT ID FROM T UNION SELECT ID FROM U LIMIT 3 OFFSET 20;

-- 10 WithAlias+First+Skip                        -> [21, 22, 23]
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE LIMIT 3 OFFSET 20;

/*
  ==============================================================================
  PARTE 3 - A FORMA COM VIRGULA, E POR QUE O FluentSQL NUNCA A EMITE

  "LIMIT n, m" existe no SQLite e tem os operandos TROCADOS em relacao a
  "LIMIT m OFFSET n". A propria doc pede para nao usa-la. Medido:
  ==============================================================================
*/

-- 11 LIMIT 3, 20   -> [4, 5, 6, 7, 8, 9, 10, 11, ...]   (20 linhas a partir da 4a)
SELECT ID FROM T LIMIT 3, 20;

-- 12 LIMIT 20 OFFSET 3 -> [4, 5, 6, 7, 8, 9, 10, 11, ...]  (IDENTICO ao 11)
SELECT ID FROM T LIMIT 20 OFFSET 3;

/*
  LEITURA: 11 e 12 devolvem O MESMO conjunto. Ou seja, "LIMIT 3, 20" significa
  "OFFSET 3, LIMIT 20" - o contrario do que a leitura ingenua sugere. Quem
  emitisse a forma com virgula acreditando estar pedindo "3 linhas a partir da
  20a" entregaria 20 linhas a partir da 4a, sem erro nenhum.

  O FluentSQL emite SEMPRE "LIMIT m OFFSET n" (casos 01..10 acima); nao ha
  caminho no driver SQLite que produza a forma com virgula.
*/

/*
  ==============================================================================
  PARTE Z - First(0) e Skip(0)

  LIMIT 0 devolve zero linhas. Repare no contraste com o caso 02: o zero
  literal exprime "nada", e o -1 exprime "sem teto" - sao dois pedidos
  diferentes e o SQLite escreve os dois. Foi por nao haver teste de First(0) que
  a regressao do MSSQL passou.
  ==============================================================================
*/

-- Z1 First(0)                 -> 0 linhas
SELECT ID FROM T LIMIT 0;
-- Z2 Skip(0)                  -> 60 linhas
SELECT ID FROM T LIMIT -1 OFFSET 0;
-- Z3 First(0)+Skip(20)        -> 0 linhas
SELECT ID FROM T LIMIT 0 OFFSET 20;
-- Z4 First(10)+Skip(0)        -> 10 linhas
SELECT ID FROM T LIMIT 10 OFFSET 0;
-- Z5 First(0) nas combinacoes -> 0 linhas nas cinco
SELECT ID FROM T WHERE (ATIVO = 1) LIMIT 0;
SELECT ID FROM T ORDER BY NOME ASC LIMIT 0;
SELECT DISTINCT NOME FROM T LIMIT 0;
SELECT ID FROM T UNION SELECT ID FROM U LIMIT 0;
SELECT NOME FROM T GROUP BY NOME LIMIT 0;
