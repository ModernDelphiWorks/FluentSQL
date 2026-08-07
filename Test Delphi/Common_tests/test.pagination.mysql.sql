/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - MYSQL  (T10)

  MOTOR MEDIDO
    MySQL 8.4.11 (imagem mysql:8.4)

  COMO REPETIR
    docker run -d --name t10mysql -e MYSQL_ROOT_PASSWORD=fluent \
      -e MYSQL_DATABASE=t10 -p 13306:3306 mysql:8.4
    docker exec -i t10mysql mysql -uroot -pfluent t10 < test.pagination.mysql.sql

  MASSA: T com 60 linhas (ID 1..60), U com 60 (ID 1001..1060).
         Pagina certa de First(3)/Skip(20): 21,22,23.
  ------------------------------------------------------------------------------
*/

DROP TABLE IF EXISTS T; DROP TABLE IF EXISTS U;
CREATE TABLE T (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
CREATE TABLE U (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
INSERT INTO T WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n<60)
  SELECT n, CONCAT('N',LPAD(n,3,'0')), 1, 20 FROM s;
INSERT INTO U SELECT ID+1000, CONCAT('U',LPAD(ID,3,'0')), 1, 30 FROM T;

/*
  ==============================================================================
  PARTE 1 - POR QUE Skip SOZINHO PRECISA DE UM TETO

  A gramatica do MySQL e
    LIMIT {[offset,] row_count | row_count OFFSET offset}
  O OFFSET e sub-clausula do LIMIT, nao clausula independente. O driver emitia
  "OFFSET n" solto para Skip(n) sem First(m).
  ==============================================================================
*/

-- V1 forma ANTERIOR do driver: OFFSET sem LIMIT
SELECT ID FROM T OFFSET 20;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the
    manual that corresponds to your MySQL server version for the right syntax to
    use near '20' at line 1

  LEITURA: Skip(n) sem First(m) nunca rodou no driver MySQL.
*/

-- 02 forma NOVA: teto do manual, 2^64-1
SELECT ID FROM T LIMIT 18446744073709551615 OFFSET 57;
/*
  SAIDA: 58, 59, 60

  O numero e a receita do proprio manual:
    "To retrieve all rows from a certain offset up to the end of the result set,
     you can use some large number for the second parameter."
    https://dev.mysql.com/doc/refman/8.4/en/select.html
*/

-- 02b prova de que 2^64-1 e mesmo o teto: 2^64 e recusado
SELECT ID FROM T LIMIT 18446744073709551616 OFFSET 57;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 1: ... right syntax to use near
    '18446744073709551616 OFFSET 57' at line 1

  LEITURA: o valor emitido e o maior BIGINT UNSIGNED aceito, nao um numero
  grande escolhido a esmo. Um a mais e erro de sintaxe.
  ATENCAO ao repetir: o cliente mysql aborta o lote nesta linha. Rode-a separada.
*/

/*
  ==============================================================================
  PARTE 2 - AS FORMAS QUE O FluentSQL EMITE HOJE
  ==============================================================================
*/

-- 01 First(3)                        -> 1, 2, 3
SELECT ID FROM T LIMIT 3;

-- 03 First(3)+Skip(20)               -> 21, 22, 23
SELECT ID FROM T LIMIT 3 OFFSET 20;

-- 04 Where+First+Skip                -> 21, 22, 23
SELECT ID FROM T WHERE (ATIVO = 1) LIMIT 3 OFFSET 20;

-- 05 Where+OrderBy+First+Skip        -> 21, 22, 23
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC LIMIT 3 OFFSET 20;

-- 06 Distinct+First+Skip             -> N021, N022, N023
SELECT DISTINCT NOME FROM T LIMIT 3 OFFSET 20;

-- 07 Distinct+Skip(57)               -> N058, N059, N060
SELECT DISTINCT NOME FROM T LIMIT 18446744073709551615 OFFSET 57;

-- 08 GroupBy+First+Skip              -> N021, N022, N023
SELECT NOME FROM T GROUP BY NOME LIMIT 3 OFFSET 20;

-- 09 Union+First+Skip                -> 21, 22, 23  (pagina o UNION inteiro)
SELECT ID FROM T UNION SELECT ID FROM U LIMIT 3 OFFSET 20;

-- 10 WithAlias+First+Skip            -> 21, 22, 23
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE LIMIT 3 OFFSET 20;
