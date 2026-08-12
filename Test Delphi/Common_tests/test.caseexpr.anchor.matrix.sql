/* =============================================================================
   T34 - ONDE O "CASE" SE ANCORA
   Oraculo de motor real. Transcricao LITERAL das sessoes, nao parafrase.

   ---------------------------------------------------------------------------
   QUANTOS MOTORES, E QUAIS - OS DOIS NUMEROS, COM OS NOMES
   ---------------------------------------------------------------------------

   SUBMETIDOS: 7
     PostgreSQL, MySQL, SQL Server, Firebird, Oracle, SQLite  ... 6 ATIVOS
     DB2 ......................................................  1 SOB DEFINE
                                                                 (desligado no
                                                                  FluentSQL.inc,
                                                                  so compila com
                                                                  -DDB2)
   NAO MEDIDO: 1
     InterBase ... nao existe imagem publica. Nao foi inferido do Firebird.

   Uma versao anterior deste arquivo dizia "SEIS de sete" e listava DB2 mas
   nao SQLite - ou seja, largava um dialeto ATIVO e contava um DESLIGADO. O
   dado estava aqui; a recitacao e que perdia o SQLite. Os dois numeros acima
   sao para nao repetir isso.

   ---------------------------------------------------------------------------
   ⚠️ O QUE FOI SUBMETIDO E O QUE FOI ADAPTADO
   ---------------------------------------------------------------------------

   TODOS os enunciados abaixo foram submetidos EXATAMENTE como o FluentSQL os
   emite - sem apelido acrescentado, sem AS, sem reordenar. Onde um motor
   recusa, a recusa esta transcrita.

   Isto corrige uma versao anterior deste arquivo, em que o enunciado do Oracle
   levava "P.*" com apelido "P" que o FluentSQL NAO emite - e a nota de rodape
   que confessava a adaptacao existia so aqui dentro, enquanto o CHANGELOG e a
   doutrina afirmavam "verbatim" sem qualificar. A adaptacao escondia uma
   RECUSA REAL, que agora esta medida e transcrita (ORA-00923).

   ---------------------------------------------------------------------------
   MASSA, identica nos sete
   ---------------------------------------------------------------------------

     PRODUCTS(ID, PRICE, TIPO) = (1, 5.00, 'X'), (2, 15.00, 'Y'), (3, 25.00, 'Y')
     duas linhas com PRICE > 10  ->  esperado BARATO / CARO / CARO
     contagem ANTES e DEPOIS de cada sessao: 3 e 3, em todos.

   ---------------------------------------------------------------------------
   OS CINCO ENUNCIADOS
   ---------------------------------------------------------------------------

   HEAD  o que a base emitia com o cursor na RELACAO
         SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)

   T1    o que passa a sair de .Select.All.From('PRODUCTS') + CaseExpr
         SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS

   T1b   o que passa a sair de .Select.Column('TIPO').From('PRODUCTS') + CaseExpr
         SELECT TIPO, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS

   T2    o que passa a sair com GroupBy('') e cursor na relacao
         SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)

   T3    o que passa a sair com OrderBy('') e cursor na relacao
         SELECT TIPO FROM PRODUCTS ORDER BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) ASC

   ---------------------------------------------------------------------------
   RESUMO - E ELE NAO E "SEIS ACEITAM"
   ---------------------------------------------------------------------------

   motor                        HEAD    T1      T1b     T2      T3
   ---------------------------  ------  ------  ------  ------  ------
   PostgreSQL 16.14             RECUSA  3 lin   3 lin   RECUSA  3 lin
   MySQL 8.4.11                 RECUSA  3 lin   3 lin   RECUSA  3 lin
   SQL Server 16.0.4265.3       RECUSA  3 lin   3 lin   RECUSA  3 lin
   Firebird 5.0.4               RECUSA  RECUSA  3 lin   RECUSA  3 lin
   Oracle 26ai 23.26.2.0.0      RECUSA  RECUSA  3 lin   RECUSA  3 lin
   DB2 v12.1.5.0                RECUSA  3 lin   3 lin   RECUSA  3 lin
   SQLite 3.53.4                RECUSA  3 lin   3 lin   2 lin   3 lin
   InterBase                    ------------ NAO MEDIDO ------------

   LEITURA HONESTA DAS TRES COLUNAS QUE NAO SAO VERDES INTEIRAS:

   HEAD ... 7 de 7 RECUSAM. E o que justifica a tarefa, e nao tem ressalva.

   T1 ..... RECUSADO por Firebird e Oracle, e a causa NAO E a ancoragem: e a
            virgula depois da ESTRELA. O Firebird aponta a coluna 9, que e
            exatamente a virgula; a Oracle devolve ORA-00923. "SELECT *, <expr>"
            e forma que esses dois nao aceitam, e ela ja saia da base por
            Select.All seguido de Column - defeito PRE-EXISTENTE do All, com
            porta propria, fora do escopo desta tarefa. O que esta tarefa
            mudou foi trocar um texto que 7 de 7 recusam por um que 5 de 7
            aceitam; nos outros 2 a recusa passou a ser de OUTRA causa, ja
            catalogada. NAO se afirma aqui que "os seis aceitam T1".

   T1b .... 7 de 7 ACEITAM, com o dado certo. E o teste limpo da ancoragem,
            porque nao carrega a estrela. E a forma que o consumidor obtem
            projetando colunas nomeadas.

   T2 ..... RECUSADO por 6 de 7, e a causa TAMBEM nao e a ancoragem: e a
            CADEIA DO USUARIO. Projetar TIPO agrupando por outra expressao
            viola a regra de GROUP BY, e os motores dizem isso com todas as
            letras ("must appear in the GROUP BY clause"). O SQLite aceita
            porque nao aplica a regra estrita. O CASE esta no lugar certo -
            quem escreve .Select.Column('TIPO').GroupBy('') e pede um CASE
            searched no GROUP BY montou uma consulta que nao fecha. Recusa
            medida e explicada vale mais que texto nao submetido.

   T3 ..... 7 de 7 ACEITAM.

   ============================================================================= */


/* ---------------------------------------------------------------------------
   PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1)
   postgres@sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
   --------------------------------------------------------------------------- */

postgres=# SELECT COUNT(*) AS massa_antes FROM PRODUCTS;
 massa_antes
-------------
           3

-- HEAD
postgres=# SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
ERROR:  syntax error at or near "CASE"
LINE 1: SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELS...
                       ^

-- T1
postgres=# SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS;
 id | price | tipo |  case
----+-------+------+--------
  1 |  5.00 | X    | BARATO
  2 | 15.00 | Y    | CARO
  3 | 25.00 | Y    | CARO
(3 rows)

-- T1b
postgres=# SELECT TIPO, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS;
 tipo |  case
------+--------
 X    | BARATO
 Y    | CARO
 Y    | CARO
(3 rows)

-- T2
postgres=# SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
ERROR:  column "products.tipo" must appear in the GROUP BY clause or be used in an aggregate function
LINE 1: SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THE...
               ^

-- T3
postgres=# SELECT TIPO FROM PRODUCTS ORDER BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) ASC;
 tipo
------
 X
 Y
 Y
(3 rows)

postgres=# SELECT COUNT(*) AS massa_depois FROM PRODUCTS;
 massa_depois
--------------
            3


/* ---------------------------------------------------------------------------
   MySQL 8.4.11
   mysql@sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
   --------------------------------------------------------------------------- */

+-------------+
| massa_antes |
+-------------+
|           3 |
+-------------+

-- HEAD
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the
manual that corresponds to your MySQL server version for the right syntax to use
near 'CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)' at line 1

-- T1
+------+-------+------+------------------------------------------------------+
| ID   | PRICE | TIPO | (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) |
+------+-------+------+------------------------------------------------------+
|    1 |  5.00 | X    | BARATO                                               |
|    2 | 15.00 | Y    | CARO                                                 |
|    3 | 25.00 | Y    | CARO                                                 |
+------+-------+------+------------------------------------------------------+

-- T1b
+------+--------+
| TIPO | R      |
+------+--------+
| X    | BARATO |
| Y    | CARO   |
| Y    | CARO   |
+------+--------+

-- T2
ERROR 1055 (42000) at line 1: Expression #1 of SELECT list is not in GROUP BY
clause and contains nonaggregated column 't34.PRODUCTS.TIPO' which is not
functionally dependent on columns in GROUP BY clause; this is incompatible with
sql_mode=only_full_group_by

-- T3
+------+
| TIPO |
+------+
| X    |
| Y    |
| Y    |
+------+

+--------------+
| massa_depois |
+--------------+
|            3 |
+--------------+


/* ---------------------------------------------------------------------------
   Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
   mcr.microsoft.com/mssql/server@sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
   --------------------------------------------------------------------------- */

massa_antes
-----------
          3

-- HEAD
Msg 156, Level 15, State 1, Server d540df4bd287, Line 1
Incorrect syntax near the keyword 'CASE'.

-- T1
ID          PRICE        TIPO
----------- ------------ ---------- ------
          1         5.00 X          BARATO
          2        15.00 Y          CARO
          3        25.00 Y          CARO
(3 rows affected)

-- T1b
TIPO       R
---------- ------
X          BARATO
Y          CARO
Y          CARO
(3 rows affected)

-- T2
Msg 8120, Level 16, State 1, Server d540df4bd287, Line 1
Column 'PRODUCTS.TIPO' is invalid in the select list because it is not contained
in either an aggregate function or the GROUP BY clause.

-- T3
TIPO
----------
X
Y
Y
(3 rows affected)


/* ---------------------------------------------------------------------------
   Firebird 5.0.4
   firebirdsql/firebird@sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
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

-- T1   <<< RECUSADO, e a causa e a VIRGULA depois da ESTRELA (coluna 9),
--           nao o CASE. Ver a leitura honesta no cabecalho.
Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Token unknown - line 1, column 9
-,

-- T1b
TIPO       CASE
========== ======
X          BARATO
Y          CARO
Y          CARO

-- T2
Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Invalid expression in the select list (not contained in either an aggregate
 function or the GROUP BY clause)

-- T3
TIPO
==========
X
Y
Y

         MASSA_DEPOIS
=====================
                    3


/* ---------------------------------------------------------------------------
   Oracle AI Database 26ai Free Release 23.26.2.0.0
   gvenzl/oracle-free@sha256:d8913e4e4769b6e60197949bef30a4391713afe662b4b4e71a2665c881bdac8b
   --------------------------------------------------------------------------- */

MASSA_ANTES
-----------
          3

-- HEAD
SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
                             *
ERROR at line 1:
ORA-00907: missing right parenthesis

-- T1   <<< RECUSADO. Esta e a recusa que a versao anterior deste arquivo
--           ESCONDIA, ao submeter "SELECT P.*, ... FROM PRODUCTS P" - um texto
--           com apelido que o FluentSQL nao emite.
SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS
        *
ERROR at line 1:
ORA-00923: FROM keyword not found where expected

-- T1b
TIPO       (CASEW
---------- ------
X          BARATO
Y          CARO
Y          CARO

-- T2
SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
       *
ERROR at line 1:
ORA-00979: "TIPO": must appear in the GROUP BY clause or be used in an aggregate function

-- T3
TIPO
----------
X
Y
Y


/* ---------------------------------------------------------------------------
   DB2 v12.1.5.0            << SOB DEFINE: desligado no FluentSQL.inc >>
   icr.io/db2_community/db2@sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
   --------------------------------------------------------------------------- */

MASSA_ANTES
-----------
          3
  1 record(s) selected.

-- HEAD
SQL0104N  An unexpected token "CASE PRODUCTS WHEN" was found following "SELECT
* FROM (".  Expected tokens may include:  "<select>".  SQLSTATE=42601

-- T1
ID          PRICE        TIPO       4
----------- ------------ ---------- ------
          1         5.00 X          BARATO
          2        15.00 Y          CARO
          3        25.00 Y          CARO
  3 record(s) selected.

-- T1b
TIPO       2
---------- ------
X          BARATO
Y          CARO
Y          CARO
  3 record(s) selected.

-- T2
SQL0119N  An expression starting with "TIPO" specified in a SELECT clause,
HAVING clause, or ORDER BY clause is not specified in the GROUP BY clause or
it is in a SELECT clause, HAVING clause, or ORDER BY clause with a column
function and no GROUP BY clause is specified.  SQLSTATE=42803

-- T3
TIPO
----------
X
Y
Y
  3 record(s) selected.

MASSA_DEPOIS
------------
           3
  1 record(s) selected.


/* ---------------------------------------------------------------------------
   SQLite 3.53.4            << ATIVO, e faltava na recitacao anterior >>
   keinos/sqlite3@sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
   --------------------------------------------------------------------------- */

sqlite 3.53.4
massa_antes=3

-- HEAD
Parse error near line 6: near "CASE": syntax error
  SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
                 ^--- error here

-- T1
1|5|X|BARATO
2|15|Y|CARO
3|25|Y|CARO

-- T1b
X|BARATO
Y|CARO
Y|CARO

-- T2   << o SQLite NAO aplica a regra estrita de GROUP BY, entao ele e o unico
--         que aceita: agrupa em 2 grupos (BARATO, CARO) e devolve um TIPO
--         arbitrario de cada. E dado de dialeto, nao aval a cadeia.
X
Y

-- T3
X
Y
Y

massa_depois=3


/* ---------------------------------------------------------------------------
   InterBase                NAO MEDIDO
   ---------------------------------------------------------------------------
   Nao existe imagem publica de InterBase, e por isso NAO HA medicao aqui. Nao
   foi inferida do Firebird de proposito - a suite ja trata os dois como
   dialetos distintos em outros pontos (a matriz de CAST, por exemplo). O que se
   afirma sobre InterBase nesta entrega e apenas o que o TESTE cobre, que e o
   texto emitido; o comportamento do motor fica declarado como nao medido.
   --------------------------------------------------------------------------- */
