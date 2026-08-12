/* =============================================================================
   T34 - ONDE O "CASE" SE ANCORA
   Oraculo de motor real.

   ---------------------------------------------------------------------------
   ESTE ARQUIVO E GERADO A PARTIR DA CAPTURA CRUA, E NAO TRANSCRITO A MAO
   ---------------------------------------------------------------------------

   Cada bloco abaixo e o stdout+stderr do comando declarado nele, gravado em
   arquivo e COPIADO SEM EDICAO. Nenhum apelido, AS, reordenacao, recorte ou
   reindentacao foi acrescentado.

   E o procedimento e conferivel sem confiar em ninguem. Cada captura esta entre
   as sentinelas

       /* >>> INICIO DA CAPTURA CRUA: <motor> */
       /* <<< FIM DA CAPTURA CRUA: <motor> */

   Extraia o que ha entre elas, reexecute o comando declarado no bloco
   redirecionando para um arquivo, e rode diff entre os dois. DIFF VAZIO e o
   criterio. Se diferir, o bloco e que esta errado.

   POR QUE ISTO MUDOU. Duas rodadas de revisao acharam adaptacao silenciosa aqui:
     rodada 2 - o Oracle recebeu "SELECT P.* ... FROM PRODUCTS P", com apelido
       que o FluentSQL nao emite. A adaptacao ESCONDIA a recusa ORA-00923.
     rodada 3 - os blocos T1b do MySQL e do SQL Server mostravam uma coluna "R"
       inexistente no enunciado. Era apelido acrescentado na captura.
   Transcricao a mao falhou duas vezes seguidas; por isso agora e mecanica.

   UMA DIFERENCA DE FERRAMENTA, DECLARADA: o sqlplus recebe
   "SET PAGESIZE 50 LINESIZE 200 TAB OFF". Sem TAB OFF ele alinha com TAB e a
   caixa nao reproduz em editor nenhum. Isso e formatacao de CLIENTE e nao toca
   o enunciado nem o resultado.

   ---------------------------------------------------------------------------
   QUANTOS MOTORES, E QUAIS - OS DOIS NUMEROS, COM OS NOMES
   ---------------------------------------------------------------------------

   SUBMETIDOS: 7
     PostgreSQL, MySQL, SQL Server, Firebird, Oracle, SQLite  ... 6 ATIVOS
     DB2 ......................................................  1 SOB DEFINE
   NAO MEDIDO: 1
     InterBase ... nao existe imagem publica. Nao foi inferido do Firebird.

   ---------------------------------------------------------------------------
   MASSA, identica nos sete
   ---------------------------------------------------------------------------

     PRODUCTS(ID, PRICE, TIPO) = (1, 5.00, 'X'), (2, 15.00, 'Y'), (3, 25.00, 'Y')
     duas linhas com PRICE > 10  ->  esperado BARATO / CARO / CARO
     MASSA_ANTES e MASSA_DEPOIS estao DENTRO de cada bloco, na mesma sessao.

   ---------------------------------------------------------------------------
   OS CINCO ENUNCIADOS, na ordem em que aparecem em cada bloco
   ---------------------------------------------------------------------------

   Entre MASSA_ANTES e MASSA_DEPOIS, cada bloco traz nesta ordem:

   HEAD  SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
   T1    SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS
   T1b   SELECT TIPO, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS
   T2    SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
   T3    SELECT TIPO FROM PRODUCTS ORDER BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) ASC

   HEAD e o que a base emitia com o cursor na RELACAO. T1 e o que passa a sair de
   .Select.All.From('PRODUCTS'); T1b de .Select.Column('TIPO').From('PRODUCTS');
   T2 e T3 das mesmas cadeias com GroupBy('') e OrderBy('').

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

   LEITURA HONESTA:

   HEAD ... 7 de 7 RECUSAM. E o que justifica a tarefa, e nao tem ressalva.

   T1 ..... RECUSADO por Firebird e Oracle - que sao DOIS DOS SEIS ATIVOS, e nao
            dois de sete. A causa NAO e a ancoragem: e a virgula depois da
            ESTRELA. O Firebird aponta a coluna 9, que e exatamente a virgula; a
            Oracle devolve ORA-00923. "SELECT *, <expr>" ja saia da base por
            Select.All seguido de Column - defeito PRE-EXISTENTE do All, porta
            propria, fora do escopo desta tarefa.

   T1b .... 7 de 7 ACEITAM, com o dado certo. E o teste limpo da ancoragem.

   T2 ..... RECUSADO por 6 de 7, e a causa TAMBEM nao e a ancoragem: e a CADEIA
            DO USUARIO. Projetar TIPO agrupando por outra expressao viola a
            regra de GROUP BY, e os motores dizem isso com todas as letras. O
            SQLite aceita porque nao aplica a regra estrita. O CASE esta no
            lugar certo.

   T3 ..... 7 de 7 ACEITAM.

   ============================================================================= */

/* ---------------------------------------------------------------------------
   PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1)
   papel na suite: ATIVO
   imagem: postgres@sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
   comando: docker exec -i t34-pg psql -U postgres -c "<enunciado>"
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: pg */
 massa_antes 
-------------
           3
(1 row)

ERROR:  syntax error at or near "CASE"
LINE 1: SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELS...
                       ^
 id | price | tipo |  case  
----+-------+------+--------
  1 |  5.00 | X    | BARATO
  2 | 15.00 | Y    | CARO
  3 | 25.00 | Y    | CARO
(3 rows)

 tipo |  case  
------+--------
 X    | BARATO
 Y    | CARO
 Y    | CARO
(3 rows)

ERROR:  column "products.tipo" must appear in the GROUP BY clause or be used in an aggregate function
LINE 1: SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THE...
               ^
 tipo 
------
 X
 Y
 Y
(3 rows)

 massa_depois 
--------------
            3
(1 row)
/* <<< FIM DA CAPTURA CRUA: pg */

/* ---------------------------------------------------------------------------
   MySQL 8.4.11
   papel na suite: ATIVO
   imagem: mysql@sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
   comando: docker exec -i t34-mysql mysql -uroot -pp t34 --table -e "<enunciado>"
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: mysql */
+-------------+
| MASSA_ANTES |
+-------------+
|           3 |
+-------------+
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)' at line 1
+------+-------+------+------------------------------------------------------+
| ID   | PRICE | TIPO | (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) |
+------+-------+------+------------------------------------------------------+
|    1 |  5.00 | X    | BARATO                                               |
|    2 | 15.00 | Y    | CARO                                                 |
|    3 | 25.00 | Y    | CARO                                                 |
+------+-------+------+------------------------------------------------------+
+------+------------------------------------------------------+
| TIPO | (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) |
+------+------------------------------------------------------+
| X    | BARATO                                               |
| Y    | CARO                                                 |
| Y    | CARO                                                 |
+------+------------------------------------------------------+
ERROR 1055 (42000) at line 1: Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 't34.PRODUCTS.TIPO' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
+------+
| TIPO |
+------+
| X    |
| Y    |
| Y    |
+------+
+--------------+
| MASSA_DEPOIS |
+--------------+
|            3 |
+--------------+
/* <<< FIM DA CAPTURA CRUA: mysql */

/* ---------------------------------------------------------------------------
   Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
   papel na suite: ATIVO
   imagem: mcr.microsoft.com/mssql/server@sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
   comando: docker exec t34-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P ... -C -Q "<enunciado>"
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: mssql */
MASSA_ANTES
-----------
          3

(1 rows affected)
Msg 156, Level 15, State 1, Server a5a7d3a9cd9c, Line 1
Incorrect syntax near the keyword 'CASE'.
ID          PRICE        TIPO             
----------- ------------ ---------- ------
          1         5.00 X          BARATO
          2        15.00 Y          CARO  
          3        25.00 Y          CARO  

(3 rows affected)
TIPO             
---------- ------
X          BARATO
Y          CARO  
Y          CARO  

(3 rows affected)
Msg 8120, Level 16, State 1, Server a5a7d3a9cd9c, Line 1
Column 'PRODUCTS.TIPO' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.
TIPO      
----------
X         
Y         
Y         

(3 rows affected)
MASSA_DEPOIS
------------
           3

(1 rows affected)
/* <<< FIM DA CAPTURA CRUA: mssql */

/* ---------------------------------------------------------------------------
   Firebird 5.0.4
   papel na suite: ATIVO
   imagem: firebirdsql/firebird@sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
   comando: docker exec -i t34-fb isql -u SYSDBA -p p /var/lib/firebird/data/t34.fdb  (enunciados por stdin)
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: firebird */

          MASSA_ANTES 
===================== 
                    3 

Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Token unknown - line 1, column 16
-CASE
Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Token unknown - line 1, column 9
-,

TIPO       CASE   
========== ====== 
X          BARATO 
Y          CARO   
Y          CARO   

Statement failed, SQLSTATE = 42000
Dynamic SQL Error
-SQL error code = -104
-Invalid expression in the select list (not contained in either an aggregate function or the GROUP BY clause)

TIPO       
========== 
X          
Y          
Y          


         MASSA_DEPOIS 
===================== 
                    3 
/* <<< FIM DA CAPTURA CRUA: firebird */

/* ---------------------------------------------------------------------------
   Oracle AI Database 26ai Free Release 23.26.2.0.0
   papel na suite: ATIVO
   imagem: gvenzl/oracle-free@sha256:d8913e4e4769b6e60197949bef30a4391713afe662b4b4e71a2665c881bdac8b
   comando: docker exec -i t34-ora sqlplus -S system/p@localhost/FREEPDB1  com "SET PAGESIZE 50 LINESIZE 200 TAB OFF"
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: oracle */

MASSA_ANTES
-----------
          3

SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
                             *
ERROR at line 1:
ORA-00907: missing right parenthesis
Help: https://docs.oracle.com/error-help/db/ora-00907/


SELECT *, (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END) FROM PRODUCTS
        *
ERROR at line 1:
ORA-00923: FROM keyword not found where expected
Help: https://docs.oracle.com/error-help/db/ora-00923/



TIPO       (CASEW
---------- ------
X          BARATO
Y          CARO
Y          CARO

SELECT TIPO FROM PRODUCTS GROUP BY (CASE WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
       *
ERROR at line 1:
ORA-00979: "TIPO": must appear in the GROUP BY clause or be used in an aggregate function
Help: https://docs.oracle.com/error-help/db/ora-00979/



TIPO
----------
X
Y
Y


MASSA_DEPOIS
------------
           3
/* <<< FIM DA CAPTURA CRUA: oracle */

/* ---------------------------------------------------------------------------
   SQLite 3.53.4
   papel na suite: ATIVO
   imagem: keinos/sqlite3@sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
   comando: docker run --rm -i keinos/sqlite3 sqlite3  (enunciados por stdin)
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: sqlite */
massa_antes=3
1|5|X|BARATO
2|15|Y|CARO
3|25|Y|CARO
X|BARATO
Y|CARO
Y|CARO
X
Y
X
Y
Y
massa_depois=3
Parse error near line 4: near "CASE": syntax error
  SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END);
                 ^--- error here
/* <<< FIM DA CAPTURA CRUA: sqlite */

/* ---------------------------------------------------------------------------
   DB2 v12.1.5.0
   papel na suite: SOB DEFINE (desligado no FluentSQL.inc)
   imagem: icr.io/db2_community/db2@sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
   comando: docker exec -i t34-db2 su - db2inst1 -c "db2 \"<enunciado>\""
   --------------------------------------------------------------------------- */

/* >>> INICIO DA CAPTURA CRUA: db2 */

MASSA_ANTES
-----------
          3

  1 record(s) selected.

SQL0104N  An unexpected token "CASE PRODUCTS WHEN" was found following "SELECT 
* FROM (".  Expected tokens may include:  "<select>".  SQLSTATE=42601

ID          PRICE        TIPO       4     
----------- ------------ ---------- ------
          1         5.00 X          BARATO
          2        15.00 Y          CARO  
          3        25.00 Y          CARO  

  3 record(s) selected.


TIPO       2     
---------- ------
X          BARATO
Y          CARO  
Y          CARO  

  3 record(s) selected.

SQL0119N  An expression starting with "TIPO" specified in a SELECT clause, 
HAVING clause, or ORDER BY clause is not specified in the GROUP BY clause or 
it is in a SELECT clause, HAVING clause, or ORDER BY clause with a column 
function and no GROUP BY clause is specified.  SQLSTATE=42803

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
/* <<< FIM DA CAPTURA CRUA: db2 */

/* ---------------------------------------------------------------------------
   InterBase                NAO MEDIDO
   ---------------------------------------------------------------------------
   Nao existe imagem publica de InterBase, e por isso NAO HA medicao aqui. Nao
   foi inferida do Firebird de proposito - a suite ja trata os dois como
   dialetos distintos em outros pontos (a matriz de CAST, por exemplo). O que se
   afirma sobre InterBase nesta entrega e apenas o que o TESTE cobre, que e o
   texto emitido; o comportamento do motor fica declarado como nao medido.
   --------------------------------------------------------------------------- */
