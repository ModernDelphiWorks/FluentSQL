/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - POSTGRESQL  (T10)

  MOTOR MEDIDO
    PostgreSQL 16.14 on x86_64-pc-linux-musl (imagem postgres:16-alpine)

  COMO REPETIR
    docker run -d --name t10pg -e POSTGRES_PASSWORD=fluent -p 15432:5432 postgres:16-alpine
    docker cp test.pagination.postgresql.sql t10pg:/tmp/p.sql
    docker exec t10pg psql -U postgres -q -f /tmp/p.sql

  MASSA: T com 60 linhas (ID 1..60), U com 60 (ID 1001..1060).

  O PostgreSQL JA ESTAVA CORRETO antes da T10 - e um dos dois dialetos que
  estavam. Este arquivo existe para travar isso: e a linha de base contra a qual
  as outras seis formas foram desenhadas, e o unico motor em que LIMIT e OFFSET
  sao clausulas de fato INDEPENDENTES.
  ------------------------------------------------------------------------------
*/

DROP TABLE IF EXISTS T; DROP TABLE IF EXISTS U;
CREATE TABLE T (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
CREATE TABLE U (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
INSERT INTO T SELECT g, 'N'||LPAD(g::text,3,'0'), 1, 20 FROM generate_series(1,60) g;
INSERT INTO U SELECT g+1000, 'U'||LPAD(g::text,3,'0'), 1, 30 FROM generate_series(1,60) g;

-- 01 First(3)                        -> 1, 2, 3
SELECT ID FROM T LIMIT 3;

-- 02 Skip(57): OFFSET SOZINHO, sem teto artificial   -> 58, 59, 60
SELECT ID FROM T OFFSET 57;
/*
  ESTE E O CASO QUE SEPARA O POSTGRESQL DOS OUTROS. No MySQL e no SQLite a mesma
  consulta e erro de sintaxe (OFFSET so existe como sub-clausula do LIMIT), e por
  isso aqueles dois drivers emitem um teto - 2^64-1 e -1, respectivamente. Aqui
  nao ha teto porque nao ha necessidade dele.
*/

-- 03 First(3)+Skip(20)               -> 21, 22, 23
SELECT ID FROM T LIMIT 3 OFFSET 20;

-- 04 Where+First+Skip                -> 21, 22, 23
SELECT ID FROM T WHERE (ATIVO = 1) LIMIT 3 OFFSET 20;

-- 05 Where+OrderBy+First+Skip        -> 21, 22, 23
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC LIMIT 3 OFFSET 20;

-- 06 Distinct+First+Skip
SELECT DISTINCT NOME FROM T LIMIT 3 OFFSET 20;
/*
  SAIDA BRUTA MEDIDA: N043, N060, N009

  NAO e N021/N022/N023, e NAO e defeito. Sem ORDER BY, paginar devolve um
  subconjunto arbitrario - aqui a ordem e a do hash do DISTINCT. E a semantica
  do SQL, e o proprio manual do PostgreSQL a enuncia:

    "This is not a bug; it is an inherent consequence of the fact that SQL does
     not promise to deliver the results of a query in any particular order unless
     ORDER BY is used."
    https://www.postgresql.org/docs/current/queries-limit.html

  O FluentSQL NAO exige OrderBy para paginar, por decisao de projeto, e tambem
  nao impoe unicidade da chave de ordenacao. Quem precisa de pagina estavel
  ordena por chave unica. Comparar com o caso 05, que TEM ORDER BY e devolve
  21,22,23 de forma reprodutivel.
*/

-- 07 Distinct+Skip(57)  -> N048, N022, N053 (idem: sem ORDER BY, subconjunto arbitrario)
SELECT DISTINCT NOME FROM T OFFSET 57;

-- 08 GroupBy+First+Skip -> N043, N060, N009 (idem)
SELECT NOME FROM T GROUP BY NOME LIMIT 3 OFFSET 20;

-- 09 Union+First+Skip   -> 1008, 18, 27 (idem; e pagina o UNION inteiro, nao um ramo)
SELECT ID FROM T UNION SELECT ID FROM U LIMIT 3 OFFSET 20;

-- 10 WithAlias+First+Skip            -> 21, 22, 23
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE LIMIT 3 OFFSET 20;
