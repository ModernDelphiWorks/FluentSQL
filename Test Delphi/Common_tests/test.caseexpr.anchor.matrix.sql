/* =============================================================================
   T34 - ONDE O "CASE" SE ANCORA
   Oraculo de motor real. Transcricao LITERAL das sessoes, nao parafrase.

   O que se mede aqui NAO e "o parser aceitou". E:
     (a) o texto que o HEAD anterior emitia e RECUSADO, e
     (b) o texto que o HEAD novo emite PASSA e DEVOLVE O DADO CERTO,
         com contagem de linhas ANTES e DEPOIS.

   Docker engine 29.6.2. Containers proprios (t34-*), massa identica nos seis.

   MASSA, em todos:
     PRODUCTS(ID, PRICE) = (1, 5.00), (2, 15.00), (3, 25.00)
     duas linhas com PRICE > 10  ->  esperado BARATO / CARO / CARO

   OS DOIS TEXTOS SOB TESTE
     HEAD  SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
     NOVO  SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS

   O texto HEAD nasce de CaseExpr com o cursor sobre a RELACAO: o nome da tabela
   virava operando de um CASE simples, comparado com um booleano, e o CASE
   substituia o proprio FROM.

   ATENCAO AO QUE ESTE ARQUIVO NAO DIZ. Ele mede o texto emitido com o cursor na
   RELACAO. Com o cursor sobre uma COLUNA o texto NAO MUDOU nesta entrega, e por
   isso nao ha o que medir ali: continua sendo o mesmo CASE simples que a suite
   ja fixava antes. As duas situacoes se alcancam com as MESMAS secoes em ordens
   diferentes - ver test.caseexpr.anchor.pas, celulas TestOrdemA_* e TestOrdemB_*.

   RESUMO
     seis motores medidos, SEIS recusam o texto HEAD.
     seis motores medidos, SEIS aceitam o texto NOVO e devolvem 3 linhas certas.
     InterBase: NAO MEDIDO. Nao ha imagem publica. Nao inferido do Firebird.
   ============================================================================= */


/* ---------------------------------------------------------------------------
   PostgreSQL 16          (imagem postgres:16)
   --------------------------------------------------------------------------- */

postgres=# SELECT COUNT(*) AS massa_antes FROM PRODUCTS;
 massa_antes
-------------
           3
(1 row)

-- HEAD
postgres=# SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
ERROR:  syntax error at or near "CASE"
LINE 1: SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELS...
                       ^

-- NOVO
postgres=# SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS;
 id | price |  case
----+-------+--------
  1 |  5.00 | BARATO
  2 | 15.00 | CARO
  3 | 25.00 | CARO
(3 rows)

postgres=# SELECT COUNT(*) AS massa_depois FROM PRODUCTS;
 massa_depois
--------------
            3
(1 row)


/* ---------------------------------------------------------------------------
   MySQL 8.4              (imagem mysql:8.4)
   --------------------------------------------------------------------------- */

+-------------+
| massa_antes |
+-------------+
|           3 |
+-------------+

-- HEAD
ERROR 1064 (42000) at line 6: You have an error in your SQL syntax; check the
manual that corresponds to your MySQL server version for the right syntax to use
near 'CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)' at line 1

-- NOVO
+------+-------+------------------------------------------------------+
| ID   | PRICE | (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) |
+------+-------+------------------------------------------------------+
|    1 |  5.00 | BARATO                                               |
|    2 | 15.00 | CARO                                                 |
|    3 | 25.00 | CARO                                                 |
+------+-------+------------------------------------------------------+

+--------------+
| massa_depois |
+--------------+
|            3 |
+--------------+


/* ---------------------------------------------------------------------------
   SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
   (imagem mcr.microsoft.com/mssql/server:2022-latest)
   --------------------------------------------------------------------------- */

massa_antes
-----------
          3

-- HEAD
Msg 156, Level 15, State 1, Server df83cbfa9c28, Line 1
Incorrect syntax near the keyword 'CASE'.

-- NOVO
ID          PRICE
----------- ------------ ------
          1         5.00 BARATO
          2        15.00 CARO
          3        25.00 CARO

(3 rows affected)

massa_depois
------------
           3


/* ---------------------------------------------------------------------------
   Firebird 5.0.4         (imagem firebirdsql/firebird:5.0.4)
   --------------------------------------------------------------------------- */

          MASSA_ANTES
=====================
                    3

-- HEAD
Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Token unknown - line 1, column 16
-CASE

-- NOVO
          ID                 PRICE R
============ ===================== ======
           1                  5.00 BARATO
           2                 15.00 CARO
           3                 25.00 CARO

         MASSA_DEPOIS
=====================
                    3


/* ---------------------------------------------------------------------------
   Oracle AI Database 26ai Free Release 23.26.2.0.0
   (imagem gvenzl/oracle-free:23-slim-faststart)
   --------------------------------------------------------------------------- */

MASSA_ANTES
-----------
          3

-- HEAD
SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
                             *
ERROR at line 1:
ORA-00907: missing right parenthesis
Help: https://docs.oracle.com/error-help/db/ora-00907/

-- NOVO
-- (a Oracle exige apelido de relacao para expandir "P.*"; a diferenca e de
--  SINTAXE DE ESTRELA e nao do CASE, e nao muda o que se mede aqui)
        ID      PRICE R
---------- ---------- ------
         1          5 BARATO
         2         15 CARO
         3         25 CARO

MASSA_DEPOIS
------------
           3


/* ---------------------------------------------------------------------------
   DB2 v12.1.5.0          (imagem icr.io/db2_community/db2:latest)
   --------------------------------------------------------------------------- */

MASSA_ANTES
-----------
          3
  1 record(s) selected.

-- HEAD
SQL0104N  An unexpected token "CASE PRODUCTS WHEN" was found following "SELECT
* FROM (".  Expected tokens may include:  "<select>".  SQLSTATE=42601

-- NOVO
ID          PRICE        R
----------- ------------ ------
          1         5.00 BARATO
          2        15.00 CARO
          3        25.00 CARO
  3 record(s) selected.

MASSA_DEPOIS
------------
           3
  1 record(s) selected.


/* ---------------------------------------------------------------------------
   SQLite 3               (imagem keinos/sqlite3)
   --------------------------------------------------------------------------- */

massa_antes=3

-- HEAD
Parse error near line 5: near "CASE": syntax error
  SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
                 ^--- error here

-- NOVO
1|5|BARATO
2|15|CARO
3|25|CARO

massa_depois=3


/* ---------------------------------------------------------------------------
   InterBase              NAO MEDIDO
   ---------------------------------------------------------------------------
   Nao existe imagem publica de InterBase, e por isso NAO HA medicao aqui. Nao
   foi inferida do Firebird de proposito - a suite ja trata os dois como
   dialetos distintos em outros pontos (a matriz de CAST, por exemplo). O que se
   afirma sobre InterBase nesta entrega e apenas o que o TESTE cobre, que e o
   texto emitido; o comportamento do motor fica declarado como nao medido.
   --------------------------------------------------------------------------- */
