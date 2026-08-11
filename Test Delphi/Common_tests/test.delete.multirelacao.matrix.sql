/*
  ------------------------------------------------------------------------------
  ORACULO DO DELETE COM MAIS DE UMA RELACAO - SETE DIALETOS  (T26)

  MEDICAO em motor real da fronteira que a T18 declarou e nao mediu (secao 8,
  item 5 de test.delete.alias.matrix.sql): com From chamado duas vezes, o
  FluentSQL emitia

      DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)      seis dialetos
      DELETE FROM A X, B Y WHERE (X.ID = :p1)            Oracle
      DELETE FROM A, B WHERE (A.ID = :p1)                sem apelido, nos oito

  OS SETE MOTORES RECUSAM AS TRES, POR PARSE.

  ------------------------------------------------------------------------------
  A MATRIZ, EM UMA TELA

    forma emitida ->  | DELETE FROM A AS X, B AS Y | DELETE FROM A, B | DELETE FROM A X, B Y
    ------------------+----------------------------+------------------+---------------------
    SQL Server 2022   |  Msg 156  RECUSA           |  Msg 102 RECUSA  |  Msg 102 RECUSA
    Oracle 23.26      |  ORA-03048 RECUSA          |  ORA-03048 RECUSA|  ORA-03048 RECUSA
    PostgreSQL 16.14  |  syntax error RECUSA       |  syntax RECUSA   |  syntax RECUSA
    MySQL 8.4.11      |  ERROR 1064 RECUSA         |  ERROR 1064      |  ERROR 1064 RECUSA
    Firebird 5.0.4    |  SQL -104 RECUSA           |  SQL -104 RECUSA |  SQL -104 RECUSA
    SQLite 3.53.4     |  syntax error RECUSA       |  syntax RECUSA   |  syntax RECUSA
    DB2 12.1.5.0      |  SQL0104N RECUSA           |  SQL0104N RECUSA |  SQL0104N RECUSA
    InterBase         |  NAO MEDIDO - nao existe imagem publica

  LEITURA: nao e "a interseccao e vazia". E mais forte que isso - a UNIAO e
  vazia. Nao ha UM motor em que a forma emitida executasse. Nenhum usuario do
  FluentSQL jamais conseguiu rodar essa consulta em banco nenhum, e portanto nao
  ha comportamento em producao a preservar.

  ------------------------------------------------------------------------------
  E A FORMA NATIVA DE CADA UM? MEDIDA TAMBEM - E ELAS NAO SIGNIFICAM O MESMO

  Esta e a parte que decide a tarefa. Existe SIM forma multi-relacao nativa em
  varios dos sete. So que ha DUAS construcoes diferentes escondidas debaixo do
  mesmo nome, e elas apagam coisas diferentes. Medido com contagem ANTES e
  DEPOIS, tabelas A(2 linhas) e B(2 linhas):

    SEMANTICA 1 - "apaga de UMA relacao, filtrando pela outra"
      T-SQL       DELETE X FROM A AS X INNER JOIN B AS Y ON Y.BID=X.ID WHERE X.ID=1
                  -> A: 2 -> 1     B: 2 -> 2     (so A)
      PostgreSQL  DELETE FROM A AS X USING B AS Y WHERE Y.BID=X.ID AND X.ID=1
                  -> A: 2 -> 1     B: 2 -> 2     (so A)
      Oracle 23ai DELETE FROM A X USING B Y WHERE Y.BID=X.ID
                  -> A: 3 -> 1     B: 2 -> 2     (so A)
      MySQL       DELETE X FROM A AS X, B AS Y WHERE Y.BID=X.ID AND X.ID=999  -> aceita

    SEMANTICA 2 - "apaga das DUAS relacoes"
      MySQL       DELETE X, Y FROM A AS X INNER JOIN B AS Y ON Y.BID=X.ID WHERE X.ID=1
                  -> A: 2 -> 1     B: 2 -> 1     (as DUAS)
      T-SQL       DELETE X, Y FROM A AS X INNER JOIN B AS Y ON Y.BID=X.ID WHERE X.ID=999
                  -> Msg 102, Incorrect syntax near ','.        RECUSA
      PostgreSQL  nao tem forma equivalente
      Firebird, SQLite, DB2  nao tem forma multi-relacao nenhuma (medido abaixo)

  A SEMANTICA 2 existe em UM dos sete. A SEMANTICA 1 existe em quatro, com tres
  gramaticas diferentes, e NAO existe em Firebird, SQLite nem DB2.

  E POR ISSO A OPCAO "EMITIR A FORMA VALIDA DE CADA DIALETO" ESTA MORTA. Nao por
  ser trabalhosa - por ser INCORRETA. Traduzir uma unica chamada do builder para
  formas de semantica diferente conforme o dialeto trocaria "SQL que nao executa
  em lugar nenhum" por "SQL que executa apagando COISAS DIFERENTES conforme o
  banco". O primeiro defeito grita na primeira execucao; o segundo e silencioso
  e destrutivo. Nao e uma troca aceitavel.

  ------------------------------------------------------------------------------
  E A PERGUNTA QUE FECHA O ASSUNTO: O QUE O USUARIO PEDIU?

    Delete.From('A','X').From('B','Y').Where('X.ID').Equal(1)

  Nao ha, nesta chamada, nem designador de ALVO (qual das duas relacoes se
  apaga), nem condicao de JUNCAO propria da secao, nem marcador de relacao
  AUXILIAR. Ela nao distingue a semantica 1 da 2, e nao distingue "A e alvo, B e
  filtro" de "B e alvo, A e filtro". Nem o framework nem quem escreveu a linha
  sabem dizer o que ela significa.

  Uma construcao cujo significado ninguem sabe declarar nao pode ter traducao
  correta. Por isso a T26 RECUSA: TFluentSQL.From levanta
  EFluentSQLConstructNotSupported na segunda relacao de um DELETE.

  ------------------------------------------------------------------------------
  MOTORES MEDIDOS - versao perguntada AO MOTOR, nao lida do nome da imagem

    SQL Server  Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
                mcr.microsoft.com/mssql/server:2022-latest
                sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
    PostgreSQL  PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
                postgres:16
                sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
    MySQL       8.4.11
                mysql:8.4
                sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
    Firebird    5.0.4  (rdb$get_context ENGINE_VERSION)
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0 / Version 23.26.2.0.0
                gvenzl/oracle-free:23-slim
                sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8
    DB2         DB2 v12.1.5.0  (SYSPROC.ENV_GET_INST_INFO SERVICE_LEVEL)
                icr.io/db2_community/db2:latest
                sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
    SQLite      3.53.4  (sqlite_version())
                keinos/sqlite3
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1

    RESSALVA DE FRONTEIRA: os codigos de erro transcritos sao os que ESTAS
    versoes devolveram. Nao se afirma aqui que versoes anteriores devolvam os
    MESMOS codigos - so o que foi medido esta reportado como medido.

    INTERBASE NAO FOI MEDIDO. Nao existe imagem Docker publica de InterBase, e a
    convencao da casa e declarar nao medido em vez de deduzir. O que se sabe do
    InterBase aqui e estrutural, nao empirico: TFluentSQLSerializerInterbase
    (Source\Drivers\FluentSQL.SerializeInterbase.pas:29, registrada em
    FluentSQL.Register.pas:178) descende de TFluentSQLSerialize e nao sobrescreve
    DeleteClause - emitia o texto da base, "DELETE FROM A AS X, B AS Y".
    A guarda da T26 nao depende de dialeto: mora em TFluentSQL.From, no nucleo,
    e alcanca o dbnInterbase pelo mesmo caminho que os outros. Isso e verificado
    por TESTE (test.delete.multirelacao.pas percorre todo dialeto REGISTRADO,
    incluindo dbnInterbase quando o build liga -DINTERBASE), nao por medicao em
    motor - e a distincao esta escrita aqui de proposito.

  ------------------------------------------------------------------------------
  COMO REPETIR - os sete docker run usados nesta medicao

    docker run -d --name t26-mssql -e ACCEPT_EULA=Y \
      -e MSSQL_SA_PASSWORD='Fluent!Passw0rd' mcr.microsoft.com/mssql/server:2022-latest
    docker exec t26-mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'Fluent!Passw0rd' -C -i /tmp/mssql.sql

    docker run -d --name t26-pg -e POSTGRES_PASSWORD=fluent postgres:16
    docker exec t26-pg psql -U postgres -f /tmp/pg.sql

    docker run -d --name t26-mysql -e MYSQL_ROOT_PASSWORD=fluent mysql:8.4
    docker exec t26-mysql sh -c "mysql -uroot -pfluent --force -vvv < /tmp/mysql.sql"

    docker run -d --name t26-fb -e FIREBIRD_ROOT_PASSWORD=masterkey \
      -e FIREBIRD_DATABASE=test.fdb firebirdsql/firebird:5.0.4
    docker exec t26-fb isql -u SYSDBA -p masterkey -i /tmp/fb.sql \
      /var/lib/firebird/data/test.fdb

    docker run -d --name t26-ora -e ORACLE_PASSWORD=fluent gvenzl/oracle-free:23-slim
    docker exec t26-ora bash -lc \
      "sqlplus -S system/fluent@//localhost:1521/FREEPDB1 @/tmp/ora.sql"

    docker run -d --name t26-db2 --privileged -e LICENSE=accept \
      -e DB2INST1_PASSWORD=fluentDB2pw -e DBNAME=testdb icr.io/db2_community/db2:latest
    docker exec t26-db2 su - db2inst1 -c "db2 connect to testdb && db2 -tvf /tmp/db2.sql"

    docker run -d --name t26-sqlite --entrypoint sh keinos/sqlite3 -c "sleep 7200"
    docker exec t26-sqlite sh -c "cd /tmp && sqlite3 t.db < /tmp/sqlite.sql"

  ------------------------------------------------------------------------------
  O QUE O FluentSQL EMITIA E O QUE PASSOU A FAZER

    Delete.From('A','X').From('B','Y').Where('X.ID').Equal(1)

      dbnMSSQL      antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnMySQL      antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = ?)
      dbnFirebird   antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnSQLite     antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnInterbase  antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnDB2        antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnOracle     antes: DELETE FROM A X, B Y WHERE (X.ID = :p1)
      dbnPostgreSQL antes: DELETE FROM A AS X, B AS Y WHERE (X.ID = :p1)
      dbnMongoDB    antes: {"deleteMany":{"collection":"A","filter":{"ID":1}}}
                           - a relacao B era DESCARTADA em silencio

      AGORA, nos NOVE: EFluentSQLConstructNotSupported, levantada na segunda
      chamada de From.

    Delete.From('A')          (UMA relacao, sem apelido) -> inalterado nos nove
    Delete.From('A','AP')     (UMA relacao, com apelido) -> inalterado nos nove
    Select.All.From('A').From('B')  -> inalterado: "SELECT * FROM A, B"

  ------------------------------------------------------------------------------
*/


/*
  ==============================================================================
  PARTE 1 - SQL SERVER
  ==============================================================================
*/

-- SETUP
SELECT @@VERSION;
GO
/*
  SAIDA BRUTA:
    Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
      Jul  7 2026 14:37:25
      Copyright (C) 2022 Microsoft Corporation
      Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>
*/
IF OBJECT_ID('A') IS NOT NULL DROP TABLE A;
IF OBJECT_ID('B') IS NOT NULL DROP TABLE B;
CREATE TABLE A (ID INT, NOME VARCHAR(30));
CREATE TABLE B (BID INT, NOME VARCHAR(30));
INSERT INTO A VALUES (1,'a1'),(2,'a2');
INSERT INTO B VALUES (1,'b1'),(2,'b2');
GO

-- === 01 DELETE FROM A AS X, B AS Y  (o que o FluentSQL emitia) ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 156, Level 15, State 1, Server 69b6d1f507fd, Line 1
    Incorrect syntax near the keyword 'AS'.
*/

-- === 02 DELETE FROM A, B  (multi SEM apelido - tambem emitido) ===
DELETE FROM A, B WHERE A.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Server 69b6d1f507fd, Line 1
    Incorrect syntax near ','.

  LEITURA: o defeito NUNCA foi do apelido. Sem apelido nenhum a virgula ja
  derruba o parse. Por isso a guarda nao olha Alias.
*/

-- === 03 DELETE FROM A X, B Y  (a forma que o FluentSQL emitia para Oracle) ===
DELETE FROM A X, B Y WHERE X.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Server 69b6d1f507fd, Line 1
    Incorrect syntax near 'X'.
*/

-- === 04 CONTROLE: DELETE FROM A  (UMA relacao - nao pode mudar) ===
DELETE FROM A WHERE ID = 999;
GO
/* SAIDA BRUTA:  (0 rows affected) */

-- === 05 T-SQL proprio: DELETE X FROM A AS X JOIN B AS Y ON ... ===
DELETE X FROM A AS X INNER JOIN B AS Y ON Y.BID = X.ID WHERE X.ID = 999;
GO
/*
  SAIDA BRUTA:  (0 rows affected)

  LEITURA: EXISTE forma multi-relacao no T-SQL. Ela apaga de UMA - ver caso 08.
*/

-- === 06 T-SQL apaga das DUAS? DELETE X, Y FROM ... ===
DELETE X, Y FROM A AS X INNER JOIN B AS Y ON Y.BID = X.ID WHERE X.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Server 69b6d1f507fd, Line 1
    Incorrect syntax near ','.

  LEITURA: E ESTA CELULA QUE MATA A OPCAO DE TRADUZIR. O MySQL ACEITA
  exatamente esta sentenca e apaga das duas tabelas (Parte 4, caso 07). O
  T-SQL a RECUSA. Ou seja: a semantica "apagar das duas" nao existe no T-SQL,
  e nao ha para onde traduzi-la.
*/

-- === 07 CONTROLE NEGATIVO: sentenca sabidamente invalida ===
DELETE FRUM A WHERE ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Server 69b6d1f507fd, Line 1
    Incorrect syntax near 'A'.

  LEITURA: prova que os "(0 rows affected)" acima sao aceitacao MEDIDA, e nao
  ausencia de relatorio de erro.
*/

-- === 08 SEMANTICA: DELETE X FROM A JOIN B apaga de qual? ===
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
GO
DELETE X FROM A AS X INNER JOIN B AS Y ON Y.BID = X.ID WHERE X.ID = 1;
GO
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
GO
/*
  SAIDA BRUTA:
    === ANTES ===
    T N
    - -----------
    A           2
    B           2

    (1 rows affected)

    === DEPOIS ===
    T N
    - -----------
    A           1
    B           2

  LEITURA: apagou SO de A. "DELETE X FROM A JOIN B" e "apaga de A filtrando por
  B" - NAO e "apaga de A e de B".
*/


/*
  ==============================================================================
  PARTE 2 - ORACLE
  ==============================================================================
*/

SELECT banner_full FROM v$version;
/*
  SAIDA BRUTA:
    Oracle AI Database 26ai Free Release 23.26.2.0.0 - Develop, Learn, and Run for Free
    Version 23.26.2.0.0
*/

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    DELETE FROM A AS X, B AS Y WHERE X.ID = 999
                  *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    'DELETE FROM A '
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    DELETE FROM A, B WHERE A.ID = 999
                 *
    ERROR at line 1:
    ORA-03048: SQL reserved word ',' is not syntactically valid following
    'DELETE FROM A'
*/

-- === 03 DELETE FROM A X, B Y  (o que o FluentSQL emitia para dbnOracle) ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    DELETE FROM A X, B Y WHERE X.ID = 999
                   *
    ERROR at line 1:
    ORA-03048: SQL reserved word ',' is not syntactically valid following
    'DELETE FROM A X'

  LEITURA: a Oracle era o unico dialeto cuja forma de UMA relacao com apelido a
  T18 tinha corrigido. Com DUAS relacoes ela recusa igual aos outros seis.
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  0 rows deleted. */

-- === 05 Oracle 23ai: DELETE FROM A X USING B Y  (semantica 1) ===
--     tabelas A(3 linhas: ID 1,2,7) e B(2 linhas: BID 1,2)
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
DELETE FROM A X USING B Y WHERE Y.BID = X.ID;
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
SELECT * FROM A;
/*
  SAIDA BRUTA:
    === antes ===
    T          N
    - ----------
    A          3
    B          2

    === DELETE FROM A X USING B Y WHERE Y.BID = X.ID ===
    2 rows deleted.

    === depois ===
    T          N
    - ----------
    A          1
    B          2

            ID NOME
    ---------- ------------------------------
             7 a7

  LEITURA: a Oracle 23ai ACEITA USING no DELETE, e apaga SO de A - a linha que
  sobrou e a que nao tinha par em B. Semantica 1, igual a do PostgreSQL, e
  DIFERENTE da semantica 2 do MySQL.

  RESSALVA: isto foi medido nesta versao (23.26.2.0.0). Nao se afirma aqui nada
  sobre versoes anteriores da Oracle, onde a forma classica de multi-relacao e a
  subconsulta (caso 06).
*/

-- === 06 Oracle: subconsulta ===
DELETE FROM A X WHERE X.ID IN (SELECT Y.BID FROM B Y) AND X.ID = 999;
/* SAIDA BRUTA:  0 rows deleted. */

-- === 07 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    DELETE FRUM A WHERE ID = 999
           *
    ERROR at line 1:
    ORA-00942: table or view "SYSTEM"."FRUM" does not exist

  LEITURA: a Oracle le "FRUM" como nome de tabela (o FROM e opcional na
  gramatica dela) e devolve ORA-00942 em vez de erro de sintaxe. Registrado
  porque o codigo devolvido NAO e o esperado por quem le rapido - e ainda assim
  e recusa, que era o que este controle precisava provar.
*/


/*
  ==============================================================================
  PARTE 3 - POSTGRESQL
  ==============================================================================
*/

SELECT version();
/*
  SAIDA BRUTA:
    PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled
    by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
*/

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    ERROR:  syntax error at or near ","
    LINE 1: DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
                              ^
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    ERROR:  syntax error at or near ","
    LINE 1: DELETE FROM A, B WHERE A.ID = 999;
                         ^
*/

-- === 03 DELETE FROM A X, B Y ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    ERROR:  syntax error at or near ","
    LINE 1: DELETE FROM A X, B Y WHERE X.ID = 999;
                           ^
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  DELETE 0 */

-- === 05 PG proprio: DELETE FROM A AS X USING B AS Y  (semantica 1) ===
DELETE FROM A AS X USING B AS Y WHERE Y.BID = X.ID AND X.ID = 999;
/* SAIDA BRUTA:  DELETE 0 */

-- === 06 SEMANTICA: USING apaga de qual? ===
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
DELETE FROM A AS X USING B AS Y WHERE Y.BID = X.ID AND X.ID = 1;
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
/*
  SAIDA BRUTA:
    === antes ===
     t | n
    ---+---
     A | 2
     B | 2

    DELETE 1

    === depois ===
     t | n
    ---+---
     A | 1
     B | 2

  LEITURA: apagou SO de A. Semantica 1. O PostgreSQL NAO tem forma que apague
  das duas.
*/

-- === 07 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    ERROR:  syntax error at or near "FRUM"
    LINE 1: DELETE FRUM A WHERE ID = 999;
                   ^
*/


/*
  ==============================================================================
  PARTE 4 - MYSQL  (o unico com a semantica 2)
  ==============================================================================
*/

SELECT version();
/* SAIDA BRUTA:  8.4.11 */

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 9: You have an error in your SQL syntax; check
    the manual that corresponds to your MySQL server version for the right
    syntax to use near ', B AS Y WHERE X.ID = 999' at line 1
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 11: ... near 'WHERE A.ID = 999' at line 1

  LEITURA: o MySQL le "DELETE FROM A, B" como a lista de ALVOS da forma
  multi-tabela dele e so entao tropeca no WHERE sem FROM - por isso o trecho
  citado no erro e outro. Recusa do mesmo jeito.
*/

-- === 03 DELETE FROM A X, B Y ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 13: ... near ', B Y WHERE X.ID = 999' at line 1
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec) */

-- === 05 MySQL: DELETE X, Y FROM A AS X JOIN B AS Y  (semantica 2) ===
DELETE X, Y FROM A AS X INNER JOIN B AS Y ON Y.BID = X.ID WHERE X.ID = 999;
/* SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec) */

-- === 06 MySQL: DELETE X FROM A AS X, B AS Y  (semantica 1) ===
DELETE X FROM A AS X, B AS Y WHERE Y.BID = X.ID AND X.ID = 999;
/*
  SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec)

  LEITURA: o MySQL tem AS DUAS semanticas, distinguidas pela LISTA DE ALVOS que
  vem antes do FROM - e essa lista e exatamente a informacao que a chamada
  Delete.From(A,X).From(B,Y) do FluentSQL nao carrega.
*/

-- === 07 SEMANTICA: DELETE X, Y apaga de qual? ===
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
DELETE X, Y FROM A AS X INNER JOIN B AS Y ON Y.BID = X.ID WHERE X.ID = 1;
SELECT 'A' T, COUNT(*) N FROM A UNION ALL SELECT 'B', COUNT(*) FROM B;
/*
  SAIDA BRUTA:
    === antes ===
    +---+---+
    | T | N |
    +---+---+
    | A | 2 |
    | B | 2 |
    +---+---+

    Query OK, 2 rows affected (0.01 sec)

    === depois ===
    +---+---+
    | T | N |
    +---+---+
    | A | 1 |
    | B | 1 |
    +---+---+

  LEITURA: apagou DAS DUAS. Esta e a celula que prova que "multi-relacao" nao
  quer dizer a mesma coisa em MySQL e em T-SQL/PostgreSQL/Oracle. A MESMA
  sentenca e recusada pelo SQL Server (Parte 1, caso 06).
*/

-- === 08 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    ERROR 1064 (42000) at line 26: ... near 'A WHERE ID = 999' at line 1

  LEITURA: o cliente rodou com --force, que CONTINUA apos erro. Este controle e
  o que prova que os "Query OK" acima sao aceitacao medida, e nao erro engolido.
*/


/*
  ==============================================================================
  PARTE 5 - FIREBIRD
  ==============================================================================
*/

SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database;
/* SAIDA BRUTA:  5.0.4 */

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 19
    -,
    At line 10 in file /tmp/fb.sql
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 14
    -,
    At line 12 in file /tmp/fb.sql
*/

-- === 03 DELETE FROM A X, B Y ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 16
    -,
    At line 14 in file /tmp/fb.sql
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/*
  SAIDA BRUTA: sem erro (isql so imprime falha; execucao limpa nao imprime nada)

  LEITURA: a ausencia de bloco de erro para a linha 16 do script, entre os
  blocos das linhas 14 e 18, e o que atesta a aceitacao.
*/

-- === 05 Firebird tem USING no DELETE? ===
DELETE FROM A AS X USING B AS Y WHERE Y.BID = X.ID;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 20
    -USING
    At line 18 in file /tmp/fb.sql

  LEITURA: NAO tem. O Firebird nao oferece nenhuma das duas semanticas
  multi-relacao - so subconsulta no WHERE.
*/

-- === 06 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 8
    -FRUM
    At line 20 in file /tmp/fb.sql
*/


/*
  ==============================================================================
  PARTE 6 - SQLITE
  ==============================================================================
*/

SELECT sqlite_version();
/* SAIDA BRUTA:  3.53.4 */

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 7: near ",": syntax error
      DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
                        ^--- error here
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 9: near ",": syntax error
      DELETE FROM A, B WHERE A.ID = 999;
                   ^--- error here
*/

-- === 03 DELETE FROM A X, B Y ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 11: near "X": syntax error
      DELETE FROM A X, B Y WHERE X.ID = 999;
                    ^--- error here

  LEITURA: a SQLite tropeca ANTES da virgula, no apelido cru - ela e a unica dos
  sete que EXIGE o AS (medido na T18). Recusa do mesmo jeito.
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA: sem erro */

-- === 05 SQLite tem USING no DELETE? ===
DELETE FROM A AS X USING B AS Y WHERE Y.BID = X.ID;
/*
  SAIDA BRUTA:
    Parse error near line 15: near "USING": syntax error
      DELETE FROM A AS X USING B AS Y WHERE Y.BID = X.ID;
                         ^--- error here

  LEITURA: NAO tem. Nenhuma das duas semanticas multi-relacao existe na SQLite.
*/

-- === 06 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 17: near "FRUM": syntax error
      DELETE FRUM A WHERE ID = 999;
             ^--- error here
*/


/*
  ==============================================================================
  PARTE 7 - DB2
  ==============================================================================
*/

SELECT SERVICE_LEVEL FROM TABLE(SYSPROC.ENV_GET_INST_INFO());
/*
  SAIDA BRUTA:
    SERVICE_LEVEL
    -------------
    DB2 v12.1.5.0
*/

-- === 01 DELETE FROM A AS X, B AS Y ===
DELETE FROM A AS X, B AS Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    DB21034E  The command was processed as an SQL statement because it was not a
    valid Command Line Processor command.  During SQL processing it returned:
    SQL0104N  An unexpected token ", B AS Y" was found following "DELETE FROM A
    AS X".  Expected tokens may include:  "<space>".  SQLSTATE=42601
*/

-- === 02 DELETE FROM A, B ===
DELETE FROM A, B WHERE A.ID = 999;
/*
  SAIDA BRUTA:
    SQL0104N  An unexpected token ", B" was found following "DELETE FROM A".
    Expected tokens may include:  "<space>".  SQLSTATE=42601
*/

-- === 03 DELETE FROM A X, B Y ===
DELETE FROM A X, B Y WHERE X.ID = 999;
/*
  SAIDA BRUTA:
    SQL0104N  An unexpected token ", B Y" was found following "DELETE FROM A X".
    Expected tokens may include:  "<space>".  SQLSTATE=42601
*/

-- === 04 CONTROLE: DELETE FROM A ===
DELETE FROM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    SQL0100W  No row was found for FETCH, UPDATE or DELETE; or the result of a
    query is an empty table.  SQLSTATE=02000

  LEITURA: SQL0100W e AVISO, nao erro - "sintaxe aceita, zero linhas atingidas".
  E o equivalente DB2 do "(0 rows affected)".
*/

-- === 05 DB2 tem USING no DELETE? ===
DELETE FROM A X USING B Y WHERE Y.BID = X.ID;
/*
  SAIDA BRUTA:
    SQL0104N  An unexpected token "USING B Y" was found following "DELETE FROM A
    X ".  Expected tokens may include:  "<space>".  SQLSTATE=42601

  LEITURA: NAO tem. Nenhuma das duas semanticas multi-relacao existe no DB2.
*/

-- === 06 CONTROLE NEGATIVO ===
DELETE FRUM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    SQL0204N  "DB2INST1.FRUM" is an undefined name.  SQLSTATE=42704

  LEITURA: como na Oracle, o DB2 le "FRUM" como nome de tabela (o FROM e
  opcional) e devolve erro de NOME, nao de sintaxe. Recusa do mesmo jeito.
*/


/*
  ==============================================================================
  PARTE 8 - FRONTEIRA: o que este arquivo NAO afirma
  ==============================================================================

  1. NAO afirma nada sobre InterBase por MEDICAO. Nao foi executado - nao existe
     imagem publica. O que se afirma dele e que a guarda o alcanca por ser de
     NUCLEO, e isso e verificado por teste de unidade, nao por motor.

  2. NAO afirma que a forma "DELETE X FROM A JOIN B" (T-SQL), "DELETE FROM A
     USING B" (PostgreSQL, Oracle 23ai) ou "DELETE X, Y FROM ..." (MySQL) sejam
     ruins. Elas sao boas - no dialeto de cada uma. O que se afirma e que nao
     ha uma chamada de builder que possa mapear para elas sem escolher, por
     conta propria, uma semantica que o usuario nao pediu.

  3. NAO afirma que a Oracle sempre aceitou USING no DELETE. Foi medido em
     23.26.2.0.0 e so isso esta reportado.

  4. NAO afirma nada sobre MongoDB em motor real. MongoDB nao produz SQL e esta
     fora da intersecao relacional. O unico fato registrado sobre ele e o que o
     FluentSQL emitia: MQL citando apenas a primeira colecao, com a segunda
     descartada em silencio.

  5. A PORTA IRMA - DELETE COM JOIN - CONTINUA ABERTA, E ESTE ARQUIVO NAO A
     FECHA. Nao e nota de rodape: e o item que quem ler este arquivo precisa
     levar junto, porque a guarda desta tarefa NAO o cobre e a decisao la e
     OUTRA.

     Delete.From('A').InnerJoin('B').OnCond('B.ID = A.ID') emite hoje
     "DELETE FROM A INNER JOIN B ON B.ID = A.ID". Outra construcao, outra porta:
     TFluentSQL._CreateJoin nao chama _AssertSection e nao passa por
     ASTTableNames, entao a guarda de From nunca a ve. LeftJoin idem.
     PRE-EXISTENTE: identico em main e no HEAD desta tarefa.

     MEDIDO PELA REVISAO desta tarefa - NAO pela implementacao, e NAO por esta
     suite. A distincao esta escrita porque importa: quem transcreve nao mediu.

       SQL Server 2022   Msg 156
       PostgreSQL 16     syntax error at or near "INNER"
       MySQL 8.4         ERROR 1064
       Firebird 5.0.4    SQL error code = -104
       SQLite 3.53.4     Parse error near "INNER"
       Oracle, DB2, InterBase   NAO MEDIDOS nesta rodada

     E A NUANCE QUE MUDA A RESPOSTA - LEIA ANTES DE COPIAR A DECISAO DAQUI:

       Delete.From('A','X').InnerJoin('B','Y').OnCond(...)   para dbnMSSQL
       -> DELETE X FROM A AS X INNER JOIN B AS Y ON ...
       -> ACEITO pelo SQL Server: "(4 rows affected)", medido pela revisao.

     Ou seja: o irmao e TRADUZIVEL, nao recusavel. A razao e estrutural, e nao
     de gosto. No caso desta tarefa faltavam as duas informacoes que a traducao
     exige - qual relacao e o ALVO e COMO elas se relacionam. Na porta do JOIN
     as duas EXISTEM: o alvo e a relacao do From, e a juncao e o OnCond. A
     construcao SIGNIFICA algo, e por isso pode ser traduzida para a forma
     nativa de cada dialeto. Recusa-la seria tirar funcionalidade que da para
     entregar.

     ACHADO PRE-EXISTENTE QUE VAI JUNTO, tambem da revisao:
       Query(dbnMongoDB).Delete.From('A').InnerJoin('B')...
       -> EArgumentOutOfRangeException: List index out of bounds (0).
          TList<IFluentSQLName> is empty
     Erro cru de TList, sem nome de metodo, em main e no HEAD. Mesmo que a
     decisao relacional seja traduzir, o MongoDB precisa de recusa NOMEADA em
     vez de estouro de indice.
*/
