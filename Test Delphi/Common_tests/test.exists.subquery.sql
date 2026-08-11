/*
  ------------------------------------------------------------------------------
  ORACULO DE MOTOR REAL - Exists/NotExists com subconsulta  (T32)

  O QUE ESTE ARQUIVO MEDE

  Ate a T32, IFluentSQL.Exists(const ASubQuery: String) PARAMETRIZAVA o
  argumento, emitindo

      DELETE X FROM A AS X WHERE (exists :p1)          (MSSQL)
      DELETE FROM A AS X WHERE (exists ?)              (MySQL)

  com p1 = 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID'. Este arquivo submete a
  motor real as DUAS coisas - o que a base emitia e o que o HEAD emite - e
  registra a resposta literal de cada um.

  A VERIFICACAO NAO PARA NO PARSER. Em cada motor foram criadas as relacoes

      A (ID, NAME)  com 5 linhas: 1..5
      B (ID, AID)   com 3 linhas apontando para A.ID 1, 2 e 3

  contada a massa ANTES, submetido VERBATIM o enunciado que o HEAD emite, e
  conferido que sobraram EXATAMENTE as linhas 4 e 5 (Exists) e 1, 2 e 3
  (NotExists). Contagem antes/depois em toda celula.

  CONTROLES

    NEGATIVO N1  o enunciado da BASE, com o marcador de bind no lugar da
                 subconsulta: "(exists :p1)" / "(exists ?)" / "(exists @p1)".
                 Onde o cliente interceptava o bind antes do servidor (Oracle),
                 o teste foi refeito com EXECUTE IMMEDIATE ... USING para que o
                 SERVIDOR parseasse, com o bind CARREGANDO a subconsulta.
    NEGATIVO N2  a subconsulta chegando como VALOR DE STRING:
                 "(exists 'SELECT 1 FROM B ...')". E o que o motor receberia se
                 o bind da base fosse resolvido.
    POSITIVO     o enunciado do HEAD: "(exists (SELECT 1 FROM B ...))".

  Os dois negativos tem de ser RECUSADOS e a massa tem de ficar INTACTA; o
  positivo tem de EXECUTAR e apagar exatamente as linhas certas.

  ------------------------------------------------------------------------------
  MOTORES MEDIDOS - versao perguntada AO MOTOR, nao lida do nome da imagem

    PostgreSQL  PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
                postgres:16
                sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
    MySQL       8.4.11
                mysql:8.4
                sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
    SQL Server  Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
                mcr.microsoft.com/mssql/server:2022-latest
                sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
    Firebird    5.0.4  (RDB$GET_CONTEXT('SYSTEM','ENGINE_VERSION'))
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    SQLite      3.53.4
                keinos/sqlite3:latest
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0
                gvenzl/oracle-free:23-slim
                sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8
    DB2         DB2/LINUXX8664 12.1.5.0  (SERVICE_LEVEL: DB2 v12.1.5.0)
                icr.io/db2_community/db2:latest
                sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
    InterBase   NAO MEDIDO - nao existe imagem publica. Nenhuma afirmacao sobre
                este dialeto e feita a partir de motor neste arquivo nem no
                teste que o acompanha.

  Containers criados com prefixo proprio t32-* para nao tocar os de outras
  tarefas em paralelo, e derrubados no fim.

  A FORMA DO DELETE varia por dialeto por conta da T12/T18 (palavra do apelido),
  nao por conta desta tarefa: o SQL Server poe o apelido como alvo
  ("DELETE X FROM A AS X") e a Oracle recusa o AS ("DELETE FROM A X").

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  POSTGRESQL 16.14

    docker run -d --name t32-pg -e POSTGRES_PASSWORD=t32pass postgres:16
    docker exec -e PGPASSWORD=t32pass t32-pg psql -U postgres -f /tmp/pg.sql

  TRANSCRICAO LITERAL:

    === VERSION
     PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, ...
    === MASS BEFORE (expect 5)
     a_before
    ----------
            5
    === NEGATIVE CONTROL N1  DELETE FROM A AS X WHERE (exists $1)
    psql:/tmp/pg.sql:11: ERROR:  syntax error at or near "$1"
    LINE 1: PREPARE bad1 AS DELETE FROM A AS X WHERE (exists $1);
                                                             ^
    === NEGATIVE CONTROL N2  a subconsulta como VALOR DE STRING
    psql:/tmp/pg.sql:13: ERROR:  syntax error at or near "'SELECT 1 FROM B AS Y WHERE...'"
    LINE 1: DELETE FROM A AS X WHERE (exists 'SELECT 1 FROM B AS Y WHERE...
                                             ^
    === MASS UNCHANGED AFTER NEGATIVES (expect 5)
     a_after_neg
    -------------
               5
    === HEAD EMITS  DELETE FROM A AS X WHERE (exists (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID))
    DELETE 3
    === MASS AFTER (expect 2)
     a_after
    ---------
           2
    === SURVIVORS (expect 4,5)
     id
    ----
      4
      5
    === SURVIVORS NOT EXISTS (expect 1,2,3)
     id
    ----
      1
      2
      3

  ------------------------------------------------------------------------------
  MYSQL 8.4.11

    docker run -d --name t32-mysql -e MYSQL_ROOT_PASSWORD=t32pass mysql:8.4
    docker exec t32-mysql sh -c "mysql -uroot -pt32pass --force -t < /tmp/my.sql"

  TRANSCRICAO LITERAL:

    | VERSION() |  ->  | 8.4.11 |
    === MASS BEFORE (expect 5)      | a_before | -> | 5 |
    === NEG N1: DELETE FROM A AS X WHERE (exists ?)
    ERROR 1064 (42000) at line 10: You have an error in your SQL syntax; check
    the manual that corresponds to your MySQL server version for the right
    syntax to use near '?)' at line 1
    === NEG N2: subquery as STRING VALUE
    ERROR 1064 (42000) at line 12: ... near ''SELECT 1 FROM B AS Y WHERE Y.AID
    = X.ID')' at line 1
    === MASS AFTER NEGATIVES (expect 5)   | a_after_neg | -> | 5 |
    === HEAD EMITS (positive)
    === MASS AFTER (expect 2)             | a_after | -> | 2 |
    === SURVIVORS (expect 4,5)            | ID | -> | 4 | 5 |
    === SURVIVORS NOT EXISTS (expect 1,2,3)  | ID | -> | 1 | 2 | 3 |

  ------------------------------------------------------------------------------
  SQL SERVER 2022  16.0.4265.3

    docker run -d --name t32-mssql -e ACCEPT_EULA=Y \
      -e 'MSSQL_SA_PASSWORD=T32#pass_2026' mcr.microsoft.com/mssql/server:2022-latest
    docker exec t32-mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'T32#pass_2026' -C -i /tmp/ms.sql

  O negativo N1 usa SET PARSEONLY ON - mede gramatica pura, sem executar nem
  resolver nome.

  TRANSCRICAO LITERAL:

    === VERSION
    Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
    === MASS BEFORE (expect 5)
    a_before
    -----------
              5
    === NEG N1: base emits  DELETE X FROM A AS X WHERE (exists @p1)
    Msg 102, Level 15, State 1, Line 1
    Incorrect syntax near '@p1'.
    === NEG N2: subquery as STRING VALUE
    Msg 102, Level 15, State 1, Line 1
    Incorrect syntax near 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID'.
    === MASS AFTER NEGATIVES (expect 5)
    a_after_neg
    -----------
              5
    === HEAD EMITS (positive)
    (3 rows affected)
    === MASS AFTER (expect 2)
    a_after
    -----------
              2
    === SURVIVORS (expect 4,5)
    ID
    -----------
              4
              5
    === SURVIVORS NOT EXISTS (expect 1,2,3)
    ID
    -----------
              1
              2
              3

  ------------------------------------------------------------------------------
  FIREBIRD 5.0.4

    docker run -d --name t32-fb -e FIREBIRD_ROOT_PASSWORD=t32pass firebirdsql/firebird:5.0.4
    docker exec t32-fb sh -c "isql -q -u SYSDBA -p t32pass -i /tmp/fb.sql"

  TRANSCRICAO LITERAL:

    RDB$GET_CONTEXT
    ===============
    5.0.4

    TAG                                      N
    ==================== =====================
    MASS BEFORE expect 5                     5

    Statement failed, SQLSTATE = 42000        <- NEG N1  (exists ?)
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 34
    -?

    Statement failed, SQLSTATE = 42000        <- NEG N2  (exists '...')
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 34
    -'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID'

    TAG                                          N
    ======================== =====================
    AFTER NEGATIVES expect 5                     5

    TAG                                N
    ============== =====================
    AFTER expect 2                     2

              ID
    ============
               4
               5

    TAG
    =================================
    NOT EXISTS SURVIVORS expect 1,2,3

              ID
    ============
               1
               2
               3

  ------------------------------------------------------------------------------
  SQLITE 3.53.4

    docker run --rm -i -v <sqldir>:/w keinos/sqlite3:latest \
      sh -c "cd /tmp && sqlite3 t32.db < /w/lite.sql"

  TRANSCRICAO LITERAL:

    === VERSION|3.53.4
    === MASS BEFORE expect 5|5
    Parse error near line 8: near ":p1": syntax error          <- NEG N1
      DELETE FROM A AS X WHERE (exists :p1);
                         error here ---^
    Parse error near line 10: near "'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID'": syntax error
      DELETE FROM A AS X WHERE (exists 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID');
                         error here ---^                       <- NEG N2
    === AFTER NEGATIVES expect 5|5
    === HEAD EMITS
    === AFTER expect 2|2
    === SURVIVORS expect 4,5
    4
    5
    === NOT EXISTS SURVIVORS expect 1,2,3
    1
    2
    3

  ------------------------------------------------------------------------------
  ORACLE  Oracle AI Database 26ai Free Release 23.26.2.0.0

    docker run -d --name t32-ora -e ORACLE_PASSWORD=T32pass gvenzl/oracle-free:23-slim
    docker exec t32-ora sqlplus -S system/T32pass@FREEPDB1 @/tmp/ora.sql

  NOTA DE METODO: o SQL*Plus intercepta ":p1" no CLIENTE (SP2-0552, "Bind
  variable P1 not declared") e nesse caso o SERVIDOR nunca ve o enunciado. Para
  medir o motor, e nao o cliente, o negativo N1 foi refeito com

      EXECUTE IMMEDIATE 'DELETE FROM A X WHERE (exists :p1)'
        USING 'SELECT 1 FROM B Y WHERE Y.AID = X.ID';

  que e a reproducao FIEL do que a base produzia: o bind CARREGANDO a
  subconsulta como valor.

  TRANSCRICAO LITERAL:

    BANNER_FULL
    -----------
    Oracle AI Database 26ai Free Release 23.26.2.0.0 - Develop, Learn, and Run for Free
    Version 23.26.2.0.0

    === MASS BEFORE expect 5
      A_BEFORE
    ----------
             5
    === NEG N1 server-side parse of what the BASE emits, bind CARRYING the subquery
    N1 REJECTED: ORA-00906: missing left parenthesis
    PL/SQL procedure successfully completed.
    === NEG N2 subquery as STRING VALUE
    N2 REJECTED: ORA-00906: missing left parenthesis
    PL/SQL procedure successfully completed.
    === MASS AFTER NEGATIVES expect 5
    A_AFTER_NEG
    -----------
              5
    === HEAD EMITS positive
    3 rows deleted.
    === MASS AFTER expect 2
       A_AFTER
    ----------
             2
    === SURVIVORS expect 4,5
        ID
    ----------
         4
         5
    === NOT EXISTS SURVIVORS expect 1,2,3
        ID
    ----------
         1
         2
         3

  ------------------------------------------------------------------------------
  DB2  12.1.5.0

    docker run -d --name t32-db2 --privileged=true -e LICENSE=accept \
      -e DB2INST1_PASSWORD=T32pass -e DBNAME=testdb icr.io/db2_community/db2:latest
    docker exec t32-db2 su - db2inst1 -c ". ~/sqllib/db2profile && db2 -tvf /tmp/db2.sql"

  TRANSCRICAO LITERAL:

     Database server        = DB2/LINUXX8664 12.1.5.0
    SERVICE_LEVEL
    -------------
    DB2 v12.1.5.0

    TAG                      N
    ------------------------ -----------
    === MASS BEFORE expect 5           5

    DELETE FROM A AS X WHERE (exists ?)                        <- NEG N1
    SQL0104N  An unexpected token "?" was found following "A AS X WHERE (exists".
    Expected tokens may include:  "<space>".  SQLSTATE=42601

    DELETE FROM A AS X WHERE (exists 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID')
    SQL0104N  An unexpected token "'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID'" was
    found following "A AS X WHERE (exists".  Expected tokens may include:
    "<space>".  SQLSTATE=42601                                 <- NEG N2

    TAG                          N
    ---------------------------- -----------
    === AFTER NEGATIVES expect 5           5

    DELETE FROM A AS X WHERE (exists (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID))
    DB20000I  The SQL command completed successfully.          <- POSITIVO

    TAG                N
    ------------------ -----------
    === AFTER expect 2           2

    === SURVIVORS expect 4,5
    ID
    -----------
              4
              5
      2 record(s) selected.

    === NOT EXISTS SURVIVORS expect 1,2,3
    ID
    -----------
              1
              2
              3
      3 record(s) selected.

  ------------------------------------------------------------------------------
  RESUMO DA MATRIZ - 7 motores medidos, 1 declarado nao medido

    Dialeto      NEG N1 (bind)      NEG N2 (string)    POSITIVO (subconsulta)
    -----------  -----------------  -----------------  ----------------------
    PostgreSQL   syntax error $1    syntax error       DELETE 3, sobram 4,5
    MySQL        ERROR 1064         ERROR 1064         sobram 4,5
    SQL Server   Msg 102            Msg 102            3 rows affected, 4,5
    Firebird     -104 Token unknown -104 Token unknown sobram 4,5
    SQLite       near ":p1"         near "'SELECT..."  sobram 4,5
    Oracle       ORA-00906          ORA-00906          3 rows deleted, 4,5
    DB2          SQL0104N           SQL0104N           sobram 4,5
    InterBase    NAO MEDIDO         NAO MEDIDO         NAO MEDIDO

  Os SETE recusam as duas formas que a base produzia, e os SETE executam a
  forma que o HEAD produz apagando exatamente as linhas certas. Nao e "a
  intersecao e vazia" para o enunciado antigo: e a UNIAO que e vazia - nao ha um
  motor sequer em que "(exists :p1)" executasse.

  NotExists foi medido nos sete com massa nova e sobrevivem 1, 2 e 3 em todos.
*/
