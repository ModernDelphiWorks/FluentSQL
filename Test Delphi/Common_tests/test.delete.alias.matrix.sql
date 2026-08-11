/*
  ------------------------------------------------------------------------------
  ORACULO DO APELIDO EM DELETE - SETE DIALETOS  (T18)

  MEDICAO em motor real da pergunta que a T12 nao respondeu: o apelido de relacao
  no DELETE e so uma questao de PALAVRA (AS / vazio), como e no FROM e no JOIN?

  NAO E. Em um dos sete a forma da CLAUSULA muda: no T-SQL o alvo do DELETE passa
  a ser o APELIDO, e a tabela apelidada vai para um FROM proprio. E o FluentSQL
  emitia, para o SQL Server, um texto que o motor RECUSA.

  ------------------------------------------------------------------------------
  A MATRIZ, EM UMA TELA

    forma emitida ->  | DELETE FROM t AS ap | DELETE FROM t ap | DELETE ap FROM t AS ap
    ------------------+---------------------+------------------+-----------------------
    SQL Server 2022   |  Msg 156  RECUSA    |  Msg 102 RECUSA  |  executa
    Oracle 23.26      |  ORA-03048 RECUSA   |  executa         |  ORA-03048 RECUSA
    PostgreSQL 16.14  |  executa            |  executa         |  syntax error RECUSA
    MySQL 8.4.11      |  executa            |  executa         |  executa
    Firebird 5.0.4    |  executa            |  executa         |  SQL -104 RECUSA
    SQLite 3.53.4     |  executa            |  syntax RECUSA   |  syntax error RECUSA
    DB2 12.1.5.0      |  executa            |  executa         |  SQL0104N RECUSA
    InterBase         |  NAO MEDIDO - nao existe imagem publica

  LEITURA: a interseccao e VAZIA. Nao ha uma forma que os sete aceitem:

    - "DELETE ap FROM t AS ap" e aceita por 2 de 7 (SQL Server e MySQL) e
      recusada pelos outros 5 medidos;
    - "DELETE FROM t AS ap" e aceita por 5 de 7 e recusada por SQL Server e
      Oracle;
    - "DELETE FROM t ap" e aceita por 4 de 7 e recusada por SQL Server e SQLite.

  Nem sequer a UNIAO de duas formas cobre tudo: SQL Server e SQLite se excluem
  em toda combinacao que nao seja "cada dialeto com a sua". Por isso a forma
  ficou no serializador do dialeto (IFluentSQLSerialize.DeleteClause) e nao virou
  uma regra unica no nucleo. RECUSAR o apelido em DELETE tambem foi considerado e
  descartado: 5 dos 7 aceitam a forma que o FluentSQL ja emite, e tirar a
  funcionalidade deles para uniformizar seria uma perda maior que a correcao.

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
    DB2         DB2/LINUXX8664 12.1.5.0  (SERVICE_LEVEL: DB2 v12.1.5.0)
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
    InterBase no FluentSQL e estrutural, nao empirico:
    TFluentSQLSerializerInterbase (Source\Drivers\FluentSQL.SerializeInterbase.pas:29,
    registrada em FluentSQL.Register.pas:178) descende de TFluentSQLSerialize e
    nao sobrescreve DeleteClause nem RelationAliasKeyword - seu unico override e
    AsString, cujo corpo delega ao inherited. Entao emite o texto da base -
    "DELETE FROM A AS AP" - exatamente como emitia antes da T18.

    ATENCAO A QUEM FOR CONFERIR: a classe tem "Serializer" com R, nao
    "Serialize". As versoes anteriores deste arquivo e de
    test.delete.alias.matrix.pas escreviam TFluentSQLSerializeInterbase, que NAO
    existe - quem fizesse grep nao encontrava nada, e esta e a unica evidencia
    estrutural que sustenta o que se afirma sobre InterBase aqui.

  ------------------------------------------------------------------------------
  COMO REPETIR - os sete docker run usados nesta medicao

    docker run -d --name t18-mssql -e ACCEPT_EULA=Y \
      -e MSSQL_SA_PASSWORD='Fluent!Passw0rd' mcr.microsoft.com/mssql/server:2022-latest
    docker exec t18-mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'Fluent!Passw0rd' -C -i /tmp/mssql.sql

    docker run -d --name t18-pg -e POSTGRES_PASSWORD=fluent postgres:16
    docker exec t18-pg psql -U postgres -f /tmp/pg.sql

    docker run -d --name t18-mysql -e MYSQL_ROOT_PASSWORD=fluent mysql:8.4
    docker exec t18-mysql sh -c "mysql -uroot -pfluent --force -vvv < /tmp/mysql.sql"

    docker run -d --name t18-fb -e FIREBIRD_ROOT_PASSWORD=masterkey \
      -e FIREBIRD_DATABASE=test.fdb firebirdsql/firebird:5.0.4
    docker exec t18-fb isql -u SYSDBA -p masterkey -i /tmp/fb.sql \
      /var/lib/firebird/data/test.fdb

    docker run -d --name t18-ora -e ORACLE_PASSWORD=fluent gvenzl/oracle-free:23-slim
    docker exec t18-ora bash -lc \
      "sqlplus -S system/fluent@//localhost:1521/FREEPDB1 @/tmp/ora.sql"

    docker run -d --name t18-db2 --privileged -e LICENSE=accept \
      -e DB2INST1_PASSWORD=fluentDB2pw -e DBNAME=testdb icr.io/db2_community/db2:latest
    docker exec t18-db2 su - db2inst1 -c "db2 -tvf /tmp/db2.sql"

    docker run -d --name t18-sqlite --entrypoint sh keinos/sqlite3 -c "sleep 3600"
    docker exec t18-sqlite sh -c "cd /tmp && sqlite3 t.db < /tmp/sqlite.sql"

  ------------------------------------------------------------------------------
  O QUE O FluentSQL EMITIA E O QUE PASSOU A EMITIR

    Delete.From('A','AP').Where('AP.ID').Equal(1)

      dbnMSSQL      antes: DELETE FROM A AS AP WHERE (AP.ID = :p1)   <- Msg 156
                    agora: DELETE AP FROM A AS AP WHERE (AP.ID = :p1)
      dbnMySQL      antes e agora: DELETE FROM A AS AP WHERE (AP.ID = ?)
      dbnFirebird   antes e agora: DELETE FROM A AS AP WHERE (AP.ID = :p1)
      dbnSQLite     antes e agora: DELETE FROM A AS AP WHERE (AP.ID = :p1)
      dbnInterbase  antes e agora: DELETE FROM A AS AP WHERE (AP.ID = :p1)
      dbnDB2        antes e agora: DELETE FROM A AS AP WHERE (AP.ID = :p1)
      dbnOracle     antes e agora: DELETE FROM A AP WHERE (AP.ID = :p1)
      dbnPostgreSQL antes e agora: DELETE FROM A AS AP WHERE (AP.ID = :p1)

    Delete.From('A')  (SEM apelido)  -> inalterado nos oito, "DELETE FROM A ..."

  A UNICA linha que muda e a do dbnMSSQL, e ela sai de SQL que o motor recusa
  para SQL que o motor executa.
  ------------------------------------------------------------------------------
*/


/*
  ==============================================================================
  PARTE 1 - SQL SERVER  (o dialeto do defeito)

  Script executado: /tmp/mssql.sql, com GO entre os lotes para que uma recusa de
  parse nao engula os casos seguintes.
  ==============================================================================
*/

-- SETUP
IF OBJECT_ID('A') IS NOT NULL DROP TABLE A;
CREATE TABLE A (ID INT, NOME VARCHAR(30));
INSERT INTO A VALUES (1,'um');
GO

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emitia ate a T18) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 156, Level 15, State 1, Server 8bf7c783b21e, Line 1
    Incorrect syntax near the keyword 'AS'.

  LEITURA: e o defeito. O texto que o FluentSQL produzia para dbnMSSQL nunca
  chegou a executar em motor nenhum.
*/

-- === 02 DELETE FROM A AP  (apelido cru, a forma que resolveu a Oracle) ===
DELETE FROM A AP WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Server 8bf7c783b21e, Line 1
    Incorrect syntax near 'AP'.

  LEITURA: CODIGO DIFERENTE, mesma recusa. Este caso e o que prova que a T18 nao
  cabia dentro da T12: se bastasse "tirar o AS", como bastou na Oracle, esta
  linha executaria. Nao executa.
*/

-- === 03 DELETE AP FROM A AS AP  (a forma que o FluentSQL passa a emitir) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: aceita. Zero linhas porque nao ha ID 999; o ponto e a GRAMATICA, nao
  a massa.
*/

-- === 04 DELETE AP FROM A AP  (T-SQL sem o AS - tambem aceito) ===
DELETE AP FROM A AP WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: o T-SQL aceita as duas. Escolheu-se manter o AS porque ele ja vem de
  IFluentSQLSerialize.RelationAliasKeyword, que e 'AS' para este dialeto - a T18
  nao precisou (e nao quis) tocar na palavra do apelido de dialeto nenhum.
*/

-- === 05 DELETE FROM AP FROM A AS AP  (FROM duplicado) ===
DELETE FROM AP FROM A AS AP WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: registrado por completude - o T-SQL tolera o FROM extra antes do
  alvo. NAO foi adotado: escreve "FROM" duas vezes sem ganho, e o alvo do DELETE
  na doc do T-SQL e <table_or_view_name>, nao "FROM <alias>".
*/

-- === 06 DELETE FROM A  (SEM apelido - o controle do anti-colateral) ===
DELETE FROM A WHERE ID = 999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: esta e a forma que o FluentSQL emite quando nao ha apelido, e ela
  SEMPRE funcionou. A correcao da T18 nao pode encostar nela - e por isso que
  TFluentSQLSerializerMSSQL.DeleteClause devolve inherited quando Alias = ''.
*/

-- === 07 DELETE AP FROM A AS AP com JOIN ===
DELETE AP FROM A AS AP INNER JOIN A AS B ON B.ID = AP.ID WHERE AP.ID = 999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: a forma nova convive com o JOIN que o FluentSQL ja sabia emitir. Nao
  ha teste de unidade para esta combinacao nesta tarefa (o builder nao expoe
  DELETE com JOIN por porta propria); esta aqui porque foi medido.
*/

-- === 08 UPDATE com apelido (FORA DE ESCOPO - registro) ===
UPDATE AP SET AP.NOME='x' FROM A AS AP WHERE AP.ID=999;
GO
/*
  SAIDA BRUTA:
    (0 rows affected)

  LEITURA: o T-SQL tem forma analoga para o UPDATE. FluentSQL.Update.pas NAO
  serializa apelido de tabela hoje, entao esta forma nao sai do framework e a
  T18 nao a implementou. Registrado para quem for mexer no UPDATE depois.
*/


/*
  ==============================================================================
  PARTE 2 - ORACLE  (recusa o AS; ja estava certa desde a T12)
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    DELETE FROM A AS AP WHERE AP.ID = 999
                  *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    'DELETE FROM A '
*/

-- === 02 DELETE FROM A AP  (o que o FluentSQL emite para dbnOracle) ===
DELETE FROM A AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    0 rows deleted.
*/

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    DELETE AP FROM A AS AP WHERE AP.ID = 999
                     *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    'DELETE AP FROM A '
*/

-- === 04 DELETE AP FROM A AP  (T-SQL sem AS) ===
DELETE AP FROM A AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    DELETE AP FROM A AP WHERE AP.ID = 999
           *
    ERROR at line 1:
    ORA-00942: table or view "SYSTEM"."AP" does not exist

  LEITURA: a Oracle NAO devolve erro de sintaxe aqui - ela le "DELETE AP" como
  "apague da tabela AP" e so entao descobre que AP nao existe. Ou seja: o
  ORA-00942 nao e a Oracle recusando a forma, e a Oracle ACEITANDO a forma e
  reclamando de outra coisa. O caso 04b abaixo mostra o que acontece quando a
  tabela existe, e e MUITO pior.
*/

-- === 04b DELETE AP FROM A AP  QUANDO EXISTE uma tabela chamada AP ===
--     (a mesma sentenca do 04, com a tabela AP criada de verdade)
DROP TABLE A PURGE;
DROP TABLE AP PURGE;
CREATE TABLE A  (A_ID NUMBER, NOME VARCHAR2(30));
CREATE TABLE AP (ID   NUMBER, NOME VARCHAR2(30));
INSERT INTO A  VALUES (1,'A-um');
INSERT INTO A  VALUES (1,'A-dois');
INSERT INTO AP VALUES (1,'AP-um');
INSERT INTO AP VALUES (1,'AP-dois');
COMMIT;
SELECT 'A' AS TABELA, COUNT(*) AS N FROM A UNION ALL SELECT 'AP', COUNT(*) FROM AP;
DELETE AP FROM A AP WHERE AP.ID = 1;
SELECT 'A' AS TABELA, COUNT(*) AS N FROM A UNION ALL SELECT 'AP', COUNT(*) FROM AP;
/*
  SAIDA BRUTA:

    === ANTES ===
    TA	    N
    -- ----------
    A	    2
    AP	    2

    2 rows selected.

    === DELETE AP FROM A AP WHERE AP.ID = 1 ===

    2 rows deleted.

    === DEPOIS ===
    TA	    N
    -- ----------
    A	    2
    AP	    0

    2 rows selected.

  LEITURA - E ESTA E A CELULA MAIS IMPORTANTE DO ARQUIVO INTEIRO.

  Nao ha erro. Nao ha aviso. A Oracle responde "2 rows deleted." e a contagem
  DEPOIS mostra o estrago: a tabela A, que o usuario queria apagar, ficou
  INTACTA com suas 2 linhas, e a tabela AP - que so por acaso se chama como o
  apelido - foi ESVAZIADA. Nao e "apagar as linhas erradas": e apagar a TABELA
  ERRADA por completo, em silencio, com o motor reportando sucesso.

  Ou seja: se a T18 tivesse adotado a forma do T-SQL como padrao para todos os
  dialetos - que era uma das alternativas em cima da mesa -, toda consulta
  Delete.From(tabela, apelido) contra Oracle viraria uma bomba armada: funciona
  ate o dia em que existir no schema uma tabela homonima do apelido, e nesse dia
  destroi a tabela errada sem uma linha de log. Apelidos curtos ("C", "P", "T")
  tornam a colisao provavel, nao teorica.

  E POR ISSO que a forma tem de ser do DIALETO, e nao um denominador comum
  escolhido por ser "o que mais motores aceitam".

  RESSALVA HONESTA sobre o cenario do caso 04b: para chegar ao "2 rows deleted"
  as duas tabelas precisam ter colunas de nomes diferentes. Com A e AP ambas
  tendo uma coluna ID, a MESMA sentenca devolve

    DELETE AP FROM A AP WHERE AP.ID = 1
                              *
    ERROR at line 1:
    ORA-00918: ID: column ambiguously specified - appears in AP and A

  e nada e apagado (medido, com as contagens antes e depois iguais). Ou seja: o
  desastre silencioso depende do schema. Isso NAO o torna menos grave - torna-o
  intermitente, que e pior para diagnosticar.
*/

-- === 05 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/*
  SAIDA BRUTA:
    0 rows deleted.
*/


/*
  ==============================================================================
  PARTE 3 - POSTGRESQL  (aceita as duas formas de FROM; recusa a do T-SQL)
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emite) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/* SAIDA BRUTA:  DELETE 0 */

-- === 02 DELETE FROM A AP ===
DELETE FROM A AP WHERE AP.ID = 999;
/* SAIDA BRUTA:  DELETE 0 */

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    ERROR:  syntax error at or near "AP"
    LINE 1: DELETE AP FROM A AS AP WHERE AP.ID = 999;
                   ^
*/

-- === 04 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  DELETE 0 */

-- === 05 DELETE FROM A AS AP USING ...  (registro: o multi-tabela do PG) ===
DELETE FROM A AS AP USING A AS B WHERE B.ID = AP.ID AND AP.ID = 999;
/* SAIDA BRUTA:  DELETE 0 */


/*
  ==============================================================================
  PARTE 4 - MYSQL  (o unico que aceita as TRES)
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emite) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/* SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec) */

-- === 02 DELETE FROM A AP ===
DELETE FROM A AP WHERE AP.ID = 999;
/* SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec) */

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec)

  LEITURA: o MySQL aceita a forma do T-SQL porque ela e a sintaxe multi-tabela
  dele. Ainda assim o FluentSQL NAO passou o dbnMySQL para essa forma: o que ele
  ja emitia funciona, e trocar o texto de um dialeto que funciona seria uma
  quebra sem contrapartida.
*/

-- === 04 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  Query OK, 0 rows affected (0.00 sec) */

/*
  CONTROLE DA PROPRIA MEDICAO: o cliente do MySQL rodou com --force, que CONTINUA
  apos erro. Para provar que ele nao estava engolindo as recusas em silencio,
  rodou-se de proposito uma sentenca invalida:

    DELETE FRUM A AS AP WHERE AP.ID=999;
    -> ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; ...
       near 'A AS AP WHERE AP.ID=999' at line 1

  Ou seja: os quatro "Query OK" acima sao aceitacao medida, nao ausencia de
  relatorio.
*/


/*
  ==============================================================================
  PARTE 5 - FIREBIRD
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emite) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/* SAIDA BRUTA: sem erro (isql so imprime falha; execucao limpa nao imprime nada) */

-- === 02 DELETE FROM A AP ===
DELETE FROM A AP WHERE AP.ID = 999;
/* SAIDA BRUTA: sem erro */

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 8
    -AP
    At line 11 in file /tmp/fb.sql
*/

-- === 04 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA: sem erro */


/*
  ==============================================================================
  PARTE 6 - SQLITE  (o unico que EXIGE o AS)
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emite) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/* SAIDA BRUTA: sem erro */

-- === 02 DELETE FROM A AP  (apelido cru) ===
DELETE FROM A AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 7: near "AP": syntax error
      DELETE FROM A AP WHERE AP.ID = 999;
                    ^--- error here

  LEITURA: este caso e o que fecha a porta da "forma unica". A SQLite recusa
  exatamente a forma que a Oracle EXIGE. Nao existe texto de DELETE com apelido
  que sirva as duas ao mesmo tempo.
*/

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    Parse error near line 9: near "AP": syntax error
      DELETE AP FROM A AS AP WHERE AP.ID = 999;
             ^--- error here
*/

-- === 04 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA: sem erro */


/*
  ==============================================================================
  PARTE 7 - DB2

  ATENCAO: o DB2 e o dialeto que a T12 marcou como mina. TFluentSQLSelectDB2
  instancia o qualificador da ORACLE (FluentSQL.SelectDB2.pas:46), entao regra
  hospedada no qualificador vaza para ele em silencio. Por isso a forma do DELETE
  ficou no SERIALIZADOR, e por isso o DB2 foi MEDIDO em vez de deduzido.
  ==============================================================================
*/

-- === 01 DELETE FROM A AS AP  (o que o FluentSQL emite) ===
DELETE FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    SQL0100W  No row was found for FETCH, UPDATE or DELETE; or the result of a
    query is an empty table.  SQLSTATE=02000

  LEITURA: SQL0100W e AVISO, nao erro - significa "sintaxe aceita, zero linhas
  atingidas". E o equivalente DB2 do "(0 rows affected)".
*/

-- === 02 DELETE FROM A AP ===
DELETE FROM A AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    SQL0100W  No row was found for FETCH, UPDATE or DELETE; or the result of a
    query is an empty table.  SQLSTATE=02000
*/

-- === 03 DELETE AP FROM A AS AP  (a forma do T-SQL) ===
DELETE AP FROM A AS AP WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    DB21034E  The command was processed as an SQL statement because it was not a
    valid Command Line Processor command.  During SQL processing it returned:
    SQL0104N  An unexpected token "FROM" was found following "DELETE AP ".
    Expected tokens may include:  "NPS_DOUBLE_DOT".  SQLSTATE=42601

  LEITURA: RECUSA. Confirma que o DB2 nao podia herdar a forma do MSSQL, e que
  deixa-lo na base foi a decisao certa - nao por analogia com a Oracle, mas
  porque foi medido.
*/

-- === 04 DELETE FROM A  (sem apelido - controle) ===
DELETE FROM A WHERE ID = 999;
/* SAIDA BRUTA:  SQL0100W ... SQLSTATE=02000 */


/*
  ==============================================================================
  PARTE 8 - FRONTEIRA: o que este arquivo NAO afirma
  ==============================================================================

  1. NAO afirma nada sobre InterBase. Nao foi executado.

  2. NAO afirma que "DELETE ap FROM t AS ap" seja preferivel em MySQL. Foi
     medido aceito la e deliberadamente NAO adotado.

  3. NAO encosta no "WITH x AS (" de FluentSQL.Serialize.pas. Aquele AS e outra
     gramatica (query_name) e a Oracle o EXIGE - esta medido na secao 14 de
     test.alias.oracle.sql. Correcao de apelido nao e pretexto para tirar AS de
     todo lugar.

  4. NAO afirma nada sobre DELETE com apelido em MongoDB. MongoDB nao produz SQL
     e esta fora da interseccao relacional.

  5. ACHADO FORA DO ESCOPO, medido nesta sessao e registrado por honestidade: com
     mais de uma relacao no DELETE (IFluentSQLNames.Count > 1, alcancavel
     chamando From duas vezes), o FluentSQL emite hoje "DELETE FROM A AS X, B AS
     Y". Nenhum dos sete motores foi consultado sobre essa forma nesta tarefa, e
     TFluentSQLSerializerMSSQL.DeleteClause cai de proposito no inherited nesse
     caso - ou seja, o MSSQL continua emitindo o texto de sempre ali. Qual
     relacao seria o alvo do DELETE e decisao de convencao, nao conserto.
*/
