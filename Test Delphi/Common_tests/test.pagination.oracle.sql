/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - ORACLE  (T10)

  MEDICAO em motor real das formas que FluentSQL.QualifierOracle.pas passou a
  emitir, e da razao de o encadeamento ROWNUM/ROWINI ter saido.

  MOTOR MEDIDO
    Oracle AI Database 26ai Free Release 23.26.2.0.0 - Develop, Learn, and Run for Free
    Version 23.26.2.0.0
    (imagem gvenzl/oracle-free:23-slim-faststart, tal como estava em 2026-08-07)

    RESSALVA DE FRONTEIRA: o row_limiting_clause existe desde a 12.1, mas SO
    ESTA VERSAO foi medida. Os codigos ORA transcritos abaixo sao os que ESTE
    motor devolveu; nao se afirma aqui qual codigo a 12c ou a 19c devolveriam nos
    mesmos casos. O que nao foi medido nao esta reportado como medido.

  COMO REPETIR
    docker run -d --name t10ora -e ORACLE_PASSWORD=fluent -p 11521:1521 \
      gvenzl/oracle-free:23-slim-faststart
    docker cp test.pagination.oracle.sql t10ora:/tmp/p.sql
    docker exec t10ora bash -lc \
      "sqlplus -S system/fluent@//localhost:1521/FREEPDB1 @/tmp/p.sql"

  MASSA
    T: 60 linhas, ID 1..60, NOME 'N001'..'N060', ATIVO=1.
    U: 60 linhas, ID 1001..1060.
    Com First(3)/Skip(20) a pagina certa e ID 21,22,23.
  ------------------------------------------------------------------------------
*/

SET FEEDBACK OFF
SET PAGESIZE 0
SET LINESIZE 200

PROMPT === SETUP ===
DROP TABLE T PURGE;
DROP TABLE U PURGE;
CREATE TABLE T (ID NUMBER, NOME VARCHAR2(20), ATIVO NUMBER, IDADE NUMBER);
CREATE TABLE U (ID NUMBER, NOME VARCHAR2(20), ATIVO NUMBER, IDADE NUMBER);
INSERT INTO T SELECT LEVEL, 'N'||LPAD(LEVEL,3,'0'), 1, 20 FROM DUAL CONNECT BY LEVEL <= 60;
INSERT INTO U SELECT LEVEL+1000, 'U'||LPAD(LEVEL,3,'0'), 1, 30 FROM DUAL CONNECT BY LEVEL <= 60;
COMMIT;

/*
  ==============================================================================
  PARTE 1 - O QUE A FORMA ANTERIOR (ROWNUM/ROWINI) FAZIA
  ==============================================================================
*/

PROMPT
PROMPT === V1: Skip sozinho na forma ANTERIOR - "AND" sem "WHERE" ===
SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T) T) AND ROWINI > 20;
/*
  SAIDA BRUTA:
    SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T) T) AND ROWINI > 20
                                                                          *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AND' is not syntactically valid following
    '...FROM (SELECT * FROM T) T) '

  LEITURA: Skip(n) sem First(m) emitia AND sem WHERE. Nao havia caminho em que
  essa consulta rodasse. Causa: FluentSQL.QualifierOracle.pas:53 (antes da T10)
  montava o SKIP ja com a palavra AND colada, e o WHERE so vinha do ramo do
  FIRST.
*/

PROMPT
PROMPT === V2: forma ANTERIOR devolvia uma COLUNA A MAIS (ROWINI) ===
SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T) T) WHERE ROWNUM <= 2;
/*
  SAIDA BRUTA:
      1 N001              1     20        1
      2 N002              1     20        2

  Cinco valores por linha. A tabela T tem QUATRO colunas.

  LEITURA: o embrulho acrescentava ROWINI ao conjunto de resultado, e ela vinha
  junto no SELECT * externo. Ou seja: Select.All.From('T').First(n) devolvia uma
  coluna que o usuario nunca pediu, sem erro nenhum - defeito calado, do tipo que
  so aparece quando alguem itera por indice de campo. Comparar com V3.
*/

PROMPT
PROMPT === V3: forma NOVA, a mesma consulta ===
SELECT * FROM T OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY;
/*
  SAIDA BRUTA:
      1 N001              1     20
      2 N002              1     20

  Quatro valores por linha, que e o que T tem. Sem embrulho nao ha coluna extra.
*/

/*
  ==============================================================================
  PARTE 2 - AS FORMAS QUE O FluentSQL EMITE HOJE
  row_limiting_clause: [OFFSET n ROWS] [FETCH NEXT m ROWS ONLY], os dois membros
  opcionais e independentes.
  ==============================================================================
*/

PROMPT
PROMPT === 01 First(3) -> so FETCH, sem OFFSET (o T-SQL nao permite isto) ===
SELECT ID FROM T FETCH NEXT 3 ROWS ONLY;
/* SAIDA: 1 2 3 */

PROMPT
PROMPT === 02 Skip(57) -> so OFFSET, sem teto artificial ===
SELECT ID FROM T OFFSET 57 ROWS;
/* SAIDA: 58 59 60 */

PROMPT
PROMPT === 03 First(3)+Skip(20) ===
SELECT ID FROM T OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
/* SAIDA: 21 22 23 */

PROMPT
PROMPT === 04 Where+First(3)+Skip(20) ===
SELECT ID FROM T WHERE (ATIVO = 1) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
/* SAIDA: 21 22 23 */

PROMPT
PROMPT === 05 Where+OrderBy+First(3)+Skip(20) ===
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
/* SAIDA: 21 22 23 */

PROMPT
PROMPT === 06 Distinct+First(3)+Skip(20) - sem ORDER BY nenhum ===
SELECT DISTINCT NOME FROM T OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
/*
  LEITURA: a Oracle nao exige ORDER BY para paginar, nem sob DISTINCT. E a
  diferenca de gramatica que faz o driver MSSQL precisar de preenchimento e o
  driver Oracle nao.
*/

PROMPT
PROMPT === 07 Distinct+Skip(57) ===
SELECT DISTINCT NOME FROM T OFFSET 57 ROWS;

PROMPT
PROMPT === 08 GroupBy+First(3)+Skip(20) ===
SELECT NOME FROM T GROUP BY NOME OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;

PROMPT
PROMPT === 09 Union+First(3)+Skip(20) ===
SELECT ID FROM T UNION SELECT ID FROM U OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;

PROMPT
PROMPT === 10 WithAlias+First(3)+Skip(20) ===
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;

/*
  ==============================================================================
  PARTE 3 - A ARMADILHA DO ORA-00918, MEDIDA E NAO SUPOSTA

  A pergunta era: "SELECT * com nomes de coluna duplicados + row_limiting_clause
  da ORA-00918? O FluentSQL cai nisso?". A resposta medida e NAO por causa da
  paginacao - a ambiguidade e do join, e existe com ou sem paginacao. O que MUDOU
  foi a QUALIDADE do erro.
  ==============================================================================
*/

PROMPT
PROMPT === 11 SELECT * sobre join com nomes repetidos + paginacao (forma NOVA) ===
SELECT * FROM T JOIN U ON T.ATIVO = U.ATIVO OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
/*
  SAIDA BRUTA:
     21 N021    1   20   1001 U001   1   30
     22 N022    1   20   1001 U001   1   30
     23 N023    1   20   1001 U001   1   30

  LEITURA: SELECT * sobre join NAO da ORA-00918 - o * expande para as colunas
  qualificadas das duas tabelas. A ambiguidade so aparece quando alguem NOMEIA
  uma coluna repetida, e ai independe de paginacao. Ver 12 e 13.
*/

PROMPT
PROMPT === 12 coluna NOMEADA e ambigua, forma ANTERIOR ===
SELECT ID FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T JOIN U ON T.ATIVO = U.ATIVO) T) WHERE ROWNUM <= 2;
/*
  SAIDA BRUTA:
    ERROR at line 1:
    ORA-00904: "ID": invalid identifier

  LEITURA: o embrulho engolia os nomes duplicados e o erro saia como se a coluna
  ID NAO EXISTISSE. Diagnostico enganoso para quem le.
*/

PROMPT
PROMPT === 13 coluna NOMEADA e ambigua, forma NOVA ===
SELECT ID FROM T JOIN U ON T.ATIVO = U.ATIVO OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY;
/*
  SAIDA BRUTA:
    ERROR at line 1:
    ORA-00918: ID: column ambiguously specified - appears in  and

  LEITURA: mesma consulta impossivel, erro HONESTO - a coluna e ambigua, e e
  isso que o motor diz. A T10 nao consertou nem introduziu esta condicao; ela e
  do join. O que mudou e que o erro parou de mentir.
*/

/*
  ==============================================================================
  PARTE 4 - FRONTEIRA: o que NAO foi demonstrado

  A forma anterior "WHERE ROWNUM <= m AND ROWINI > n" e citada na literatura como
  fragil por depender da ordem de avaliacao dos predicados (ROWNUM so e atribuido
  a linhas que ja passaram pelo filtro). MEDIDO AQUI, ela devolveu a pagina
  CERTA:

    SELECT ID FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T) T)
     WHERE ROWNUM <= 3 AND ROWINI > 20;
    -> 21, 22, 23

  Portanto NAO se afirma aqui que a forma anterior devolvia pagina errada. Os
  motivos medidos para troca-la sao os de V1 (Skip sozinho nao compilava), V2
  (coluna extra no resultado) e 12 (erro enganoso), mais o de forma: a doc da
  Oracle diz que o row_limiting_clause da "superior support" em relacao ao ROWNUM.
  ==============================================================================
*/

PROMPT
PROMPT === 14 forma ANTERIOR devolvia a pagina certa neste caso simples ===
SELECT ID FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM T) T) WHERE ROWNUM <= 3 AND ROWINI > 20;
/* SAIDA: 21 22 23 */

EXIT
