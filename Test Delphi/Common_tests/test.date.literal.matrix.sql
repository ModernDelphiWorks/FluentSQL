/*
  ------------------------------------------------------------------------------
  ORACULO DE MOTOR REAL DO LITERAL DE DATA EM DEFAULT DE COLUNA  (T19)

  O DEFEITO: TUtils.DateToSQLFormat emitia, para dbnOracle, o literal CRU entre
  aspas simples. O Oracle RECUSA esse texto com ORA-01861 ja no CREATE TABLE.

  A PERGUNTA QUE ESTE ARQUIVO RESPONDE, e que decidiu o desenho da correcao:

      EXISTE UMA FORMA DE LITERAL DE DATA ACEITA PELOS SETE?

  Resposta medida: NAO. Ver a matriz consolidada no fim (secao VIII). A correcao
  e, por isso, um RAMO DE DIALETO, e nao uma troca no caminho comum.

  ------------------------------------------------------------------------------
  MOTORES MEDIDOS - versao perguntada AO MOTOR, nao lida do nome da imagem

    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0
                (SELECT BANNER_FULL FROM V$VERSION)
                gvenzl/oracle-free:23-slim
                sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8
    SQL Server  Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
                (SELECT @@VERSION)
                mcr.microsoft.com/mssql/server:2022-latest
                sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
    PostgreSQL  PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
                (SELECT version())
                postgres:16
                sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
    MySQL       8.4.11   (SELECT VERSION())
                mysql:8.4
                sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
    Firebird    5.0.4    (rdb$get_context('SYSTEM','ENGINE_VERSION'))
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    SQLite      3.53.4   (SELECT sqlite_version())
                keinos/sqlite3:latest
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
    DB2         DB2 v12.1.5.0
                (SELECT SERVICE_LEVEL FROM TABLE(SYSPROC.ENV_GET_INST_INFO()))
                icr.io/db2_community/db2:latest
                sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
    InterBase   NAO MEDIDO - nao existe imagem publica. Nao ha afirmacao alguma
                sobre este dialeto neste arquivo. O ramo dbnInterbase de
                DateToSQLFormat/DateTimeToSQLFormat NAO foi tocado pela T19.

  Containers com prefixo proprio t19-* para nao tocar os de outra tarefa em
  paralelo, e derrubados no fim.

  ------------------------------------------------------------------------------
  I  ORACLE - o defeito, e as duas formas que funcionam

    docker run -d --name t19-ora -e ORACLE_PASSWORD=t19pass gvenzl/oracle-free:23-slim
    docker exec t19-ora bash -lc "sqlplus -S system/t19pass@FREEPDB1 @/tmp/ora.sql"

  NLS da sessao, PERGUNTADO, nao suposto - este numero e o que da sentido ao
  resto:

    SELECT VALUE FROM NLS_SESSION_PARAMETERS WHERE PARAMETER='NLS_DATE_FORMAT';
      -> DD-MON-RR

  Transcricao literal (marcadores por PROMPT):

    ###NEG negative control - deliberate garbage
      CREATE TABLE T19_NEG (D DATE DEFAULT ZZZ_NAO_EXISTE);
        ORA-00904: "ZZZ_NAO_EXISTE": invalid identifier
      -- o controle negativo GRITA: o metodo detecta recusa.

    ###POS positive control - SYSDATE
      CREATE TABLE T19_POS (D DATE DEFAULT SYSDATE);
        Table created.
      -- o controle positivo PASSA: o metodo nao recusa tudo.

    ###A DATE col, bare ISO quoted          <-- O QUE A BASE 7c9ed45 EMITE
      CREATE TABLE T19_A (ID NUMBER, D DATE DEFAULT '2026-08-10');
        ORA-01861: literal does not match format string
      -- o defeito. Morre no CREATE TABLE, nao no INSERT.

    ###B DATE col, ANSI DATE literal        <-- O QUE O HEAD DA T19 EMITE
      CREATE TABLE T19_B (ID NUMBER, D DATE DEFAULT DATE '2026-08-10');
        Table created.
      INSERT INTO T19_B (ID) VALUES (1);
        1 row created.
      SELECT TO_CHAR(D,'YYYY-MM-DD') FROM T19_B;
        2026-08-10
      -- cria E o valor volta certo. Nao basta parsear.

    ###C DATE col, TO_DATE
      CREATE TABLE T19_C (ID NUMBER, D DATE DEFAULT TO_DATE('2026-08-10','YYYY-MM-DD'));
        Table created.  /  1 row created.  /  2026-08-10
      -- tambem funciona. Foi PRETERIDA: e a unica das duas que nao e ANSI, e
      -- obriga o core a conhecer mascara de formato de fabricante.

    ###D DATE col, bare US mm/dd/yyyy (a forma do Firebird/Interbase)
      CREATE TABLE T19_D (ID NUMBER, D DATE DEFAULT '04/14/2026');
        ORA-01843: An invalid month was specified.

    ###E TIMESTAMP col, bare ISO quoted     <-- O QUE A BASE 7c9ed45 EMITE
      CREATE TABLE T19_E (ID NUMBER, D TIMESTAMP DEFAULT '2026-08-10 12:34:56');
        ORA-01843: An invalid month was specified.

    ###F TIMESTAMP col, ANSI TIMESTAMP literal   <-- O QUE O HEAD DA T19 EMITE
      CREATE TABLE T19_F (ID NUMBER, D TIMESTAMP DEFAULT TIMESTAMP '2026-08-10 12:34:56');
        Table created.  /  1 row created.  /  2026-08-10 12:34:56

    ###G DATE col alimentado por literal ANSI TIMESTAMP
      CREATE TABLE T19_G (ID NUMBER, D DATE DEFAULT TIMESTAMP '2026-08-10 12:34:56');
        Table created.  /  1 row created.  /  2026-08-10 12:34:56
      -- medido de proposito: no Oracle o tipo DATE guarda hora. Se algum dia o
      -- caminho de dltDateTime cair numa coluna DATE, o literal TIMESTAMP
      -- continua valido e nao perde a hora.

    ###H A DEPENDENCIA DE NLS - a medicao que tira o "quase certo" do texto antigo
      ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD';
        Session altered.
      CREATE TABLE T19_H (ID NUMBER, D DATE DEFAULT '2026-08-10');
        Table created.  /  1 row created.  /  2026-08-10
      -- A MESMA sentenca de ###A, que morreu com ORA-01861, passa depois do
      -- ALTER SESSION. Ou seja: o literal cru nao estava "quase certo" - ele
      -- dependia de configuracao de sessao que o framework nao controla e nao
      -- pode assumir. O literal ANSI tipado nao depende de NLS nenhum.

  ------------------------------------------------------------------------------
  I.2  ORACLE - o literal ANSI tambem vale FORA do DEFAULT

  TUtils.DateToSQLFormat e chamada de duas superficies. A T19 corrige a funcao,
  entao o texto novo tambem sai no caminho inline de FluentSQL.Operators.pas
  (alcancavel so por instanciacao direta de TFluentSQLOperators sem params).
  As posicoes foram submetidas para que a correcao nao troque um erro por outro:

    ###SETUP
      CREATE TABLE T19_S (ID NUMBER, D DATE, TS TIMESTAMP);
      INSERT INTO T19_S VALUES (1, DATE '2026-08-10', TIMESTAMP '2026-08-10 12:34:56');

    ###W1 WHERE com literal cru (o que a base emite)
      SELECT ID FROM T19_S WHERE D = '2026-08-10';
        ORA-01861: literal does not match format string
    ###W2 WHERE com literal ANSI DATE
      SELECT ID FROM T19_S WHERE D = DATE '2026-08-10';                    -> 1
    ###W3 WHERE em TIMESTAMP com literal cru
      SELECT ID FROM T19_S WHERE TS = '2026-08-10 12:34:56';
        ORA-01843: An invalid month was specified.
    ###W4 WHERE em TIMESTAMP com literal ANSI TIMESTAMP
      SELECT ID FROM T19_S WHERE TS = TIMESTAMP '2026-08-10 12:34:56';     -> 1
    ###I1 INSERT VALUES
      INSERT INTO T19_S (ID, D) VALUES (2, DATE '2026-08-10');   1 row created.
    ###U1 UPDATE SET
      UPDATE T19_S SET D = DATE '2026-08-11' WHERE ID = 2;       1 row updated.
    ###B1 BETWEEN
      SELECT ID FROM T19_S WHERE D BETWEEN DATE '2026-08-01' AND DATE '2026-08-31';
                                                                 -> 1 e 2

  Nas SEIS posicoes o literal ANSI e aceito e o cru e recusado. A correcao na
  funcao e segura para as duas superficies.

  ------------------------------------------------------------------------------
  II  SQL SERVER 2022 - RECUSA a forma ANSI

    docker run -d --name t19-mssql -e ACCEPT_EULA=Y \
      -e 'MSSQL_SA_PASSWORD=T19#pass_2026' mcr.microsoft.com/mssql/server:2022-latest
    docker exec t19-mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'T19#pass_2026' -C -i /tmp/mssql.sql

    ### NEG  CREATE TABLE t19_neg (d DATE DEFAULT zzz_nao_existe)
             Msg 128, Level 15: The name "zzz_nao_existe" is not permitted in
             this context.
    ### POS  CREATE TABLE t19_pos (d DATE DEFAULT GETDATE())        (criou)
    ### A    CREATE TABLE t19_a (id INT, d DATE DEFAULT '2026-08-10')
             criou; INSERT + SELECT -> 2026-08-10
    ### B    CREATE TABLE t19_b (id INT, d DATE DEFAULT DATE '2026-08-10')
             Msg 128, Level 15: The name "DATE" is not permitted in this
             context. Valid expressions are constants, constant expressions,
             and (in some contexts) variables.
    ### C    CREATE TABLE t19_c (... DEFAULT CONVERT(DATE,'2026-08-10',23))
             criou -> 2026-08-10
    ### D    CREATE TABLE t19_d (... DEFAULT '04/14/2026')  criou -> 2026-04-14
    ### E    CREATE TABLE t19_e (... DATETIME DEFAULT '2026-08-10 12:34:56')
             criou -> 2026-08-10 12:34:56
    ### F    CREATE TABLE t19_f (... DATETIME DEFAULT TIMESTAMP '2026-08-10 12:34:56')
             Msg 128, Level 15: The name "TIMESTAMP" is not permitted in this
             context.

  ESTA E A MEDICAO QUE MATA A IDEIA DE FORMA UNICA. O T-SQL nao tem literal
  tipado ANSI: "TIMESTAMP" ali e ate um TIPO do proprio T-SQL, e mesmo assim o
  parser rejeita a construcao em posicao de DEFAULT.

  ------------------------------------------------------------------------------
  III  POSTGRESQL 16.14 - aceita as duas

    docker run -d --name t19-pg -e POSTGRES_PASSWORD=t19pass postgres:16
    docker exec -e PGPASSWORD=t19pass t19-pg psql -U postgres -f /tmp/pg.sql

  Cada caso em BEGIN/ROLLBACK, para nao deixar residuo:

    ### NEG  CREATE TABLE t19_neg (d DATE DEFAULT zzz_nao_existe);
             ERROR: cannot use column reference in DEFAULT expression
    ### POS  d DATE DEFAULT CURRENT_DATE                 CREATE TABLE / OK-POS
    ### A    d DATE DEFAULT '2026-08-10'                 -> 2026-08-10
    ### B    d DATE DEFAULT DATE '2026-08-10'            -> 2026-08-10
    ### C    d DATE DEFAULT TO_DATE('2026-08-10','YYYY-MM-DD')  -> 2026-08-10
    ### D    d DATE DEFAULT '04/14/2026'                 -> 2026-04-14
    ### E    d TIMESTAMP DEFAULT '2026-08-10 12:34:56'   -> 2026-08-10 12:34:56
    ### F    d TIMESTAMP DEFAULT TIMESTAMP '2026-08-10 12:34:56'
                                                         -> 2026-08-10 12:34:56
    ### G    d DATE DEFAULT TIMESTAMP '2026-08-10 12:34:56'      -> 2026-08-10

  ------------------------------------------------------------------------------
  IV  MYSQL 8.4.11 - RECUSA a forma ANSI SOLTA

    docker run -d --name t19-mysql -e MYSQL_ROOT_PASSWORD=t19pass mysql:8.4
    docker exec t19-mysql bash -c "mysql -uroot -pt19pass --force -t t19db < /tmp/mysql.sql"

    ### NEG  d DATE DEFAULT zzz_nao_existe
             ERROR 1064 (42000): You have an error in your SQL syntax ... near
             'zzz_nao_existe)'
    ### POS  d DATE DEFAULT (CURRENT_DATE)               criou
    ### A    d DATE DEFAULT '2026-08-10'                 -> 2026-08-10
    ### B    d DATE DEFAULT DATE '2026-08-10'
             ERROR 1067 (42000) at line 13: Invalid default value for 'd'
    ### B2   d DATE DEFAULT (DATE '2026-08-10')          -> 2026-08-10
    ### C    d DATE DEFAULT (STR_TO_DATE('2026-08-10','%Y-%m-%d'))  -> 2026-08-10
    ### D    d DATE DEFAULT '04/14/2026'
             ERROR 1067 (42000) at line 25: Invalid default value for 'd'
    ### E    d DATETIME DEFAULT '2026-08-10 12:34:56'    -> 2026-08-10 12:34:56
    ### F    d DATETIME DEFAULT TIMESTAMP '2026-08-10 12:34:56'
             ERROR 1067 (42000) at line 32: Invalid default value for 'd'
    ### F2   d DATETIME DEFAULT (TIMESTAMP '2026-08-10 12:34:56')
                                                         -> 2026-08-10 12:34:56

  O MySQL so admite o literal tipado ENTRE PARENTESES, e ai ja nao e um literal
  de DEFAULT: e uma EXPRESSAO de DEFAULT (recurso de 8.0.13+). Emitir parenteses
  para todos quebraria os outros seis. Registrado, nao adotado.

  ------------------------------------------------------------------------------
  V  SQLITE 3.53.4 - RECUSA a forma ANSI, com ou sem parenteses

    docker run -d --name t19-sqlite --entrypoint sleep keinos/sqlite3 infinity
    docker exec t19-sqlite sh -c "sqlite3 /tmp/t19.db < /tmp/sqlite.sql"

    ### NEG  d DATE DEFAULT zzz nao existe
             Parse error near line 3: near "nao": syntax error
    ### POS  d DATE DEFAULT CURRENT_DATE                 criou
    ### A    d DATE DEFAULT '2026-08-10'                 -> 2026-08-10
    ### B    d DATE DEFAULT DATE '2026-08-10'
             Parse error near line 13: near "'2026-08-10'": syntax error
    ### B2   d DATE DEFAULT (DATE '2026-08-10')
             Parse error near line 15: near "'2026-08-10'": syntax error
             -- nem entre parenteses: o SQLite nao tem literal tipado.
    ### C    d DATE DEFAULT (date('2026-08-10'))         -> 2026-08-10
    ### D    d DATE DEFAULT '04/14/2026'                 -> 04/14/2026
             -- o SQLite nao converte: guarda o texto como veio (tipagem
             -- dinamica). Achado registrado, fora do escopo da T19.
    ### E    d DATETIME DEFAULT '2026-08-10 12:34:56'    -> 2026-08-10 12:34:56
    ### F    d DATETIME DEFAULT TIMESTAMP '2026-08-10 12:34:56'
             Parse error near line 32: near "'2026-08-10 12:34:56'": syntax error

  ------------------------------------------------------------------------------
  VI  FIREBIRD 5.0.4 - aceita as duas, E aceita o formato US que o framework
      ja emitia

    docker run -d --name t19-fb -e FIREBIRD_ROOT_PASSWORD=t19pass \
      -e FIREBIRD_DATABASE=t19.fdb firebirdsql/firebird:5.0.4
    docker exec t19-fb sh -c "isql -q -m -i /tmp/fb2.sql"
    (base NOVA por execucao, SET AUTODDL ON e COMMIT explicito - sem isso o isql
     deixa a tabela "in use" e a segunda rodada mede residuo da primeira.)

    ### NEG  d DATE DEFAULT zzz_nao_existe
             SQLSTATE 42000, SQL error code = -104, Token unknown - zzz_nao_existe
    ### POS  d DATE DEFAULT CURRENT_DATE                 criou
    ### A    d DATE DEFAULT '2026-08-10'                 -> 2026-08-10
    ### B    d DATE DEFAULT DATE '2026-08-10'            -> 2026-08-10
    ### D    d DATE DEFAULT '04/14/2026'                 -> 2026-04-14
             <-- E EXATAMENTE O QUE O FRAMEWORK EMITE PARA FIREBIRD/INTERBASE.
                 O motor ACEITA. Nao ha defeito aqui, e por isso a T19 NAO
                 mexeu no ramo dbnFirebird/dbnInterbase.
    ### D2   d DATE DEFAULT '12/13/2026'                 -> 2026-12-13
    ### D3   d DATE DEFAULT '13/12/2026'                 criou (sem erro)
             -- ACHADO SEPARADO, FORA DO ESCOPO: o mesmo motor aceita '13/12/2026'
             -- caindo para DD/MM quando o mes seria invalido. O formato US do
             -- framework e AMBIGUO no Firebird: '04/14' e mes 04, mas '13/12'
             -- vira dia 13. Nao consertado aqui - mudar o formato do Firebird
             -- seria BREAKING sem defeito medido, e e decisao do dono.
    ### E    d TIMESTAMP DEFAULT '2026-08-10 12:34:56'   -> 2026-08-10 12:34:56.0000
    ### F    d TIMESTAMP DEFAULT TIMESTAMP '2026-08-10 12:34:56'
                                                         -> 2026-08-10 12:34:56.0000
    ### G    d TIMESTAMP DEFAULT DATE '2026-08-10'       criou

  ------------------------------------------------------------------------------
  VII  DB2 12.1.5.0 - aceita as duas

    docker run -d --name t19-db2 --privileged -e LICENSE=accept \
      -e DB2INST1_PASSWORD=t19pass -e DBNAME=t19db icr.io/db2_community/db2:latest
    docker exec t19-db2 su - db2inst1 -c "db2 -tvf /tmp/db2.sql"
    (a instancia leva ~40 min para inicializar nesta maquina; antes disso o
     CONNECT devolve SQL1035N e TODO o resto devolve SQL1024N - se aparecer
     SQL1024N em massa, o motor nao mediu nada, so nao estava pronto.)

    ### NEG  D DATE DEFAULT zzz_nao_existe
             SQL0104N An unexpected token ")" was found following
             "FAULT zzz_nao_existe". SQLSTATE=42601
    ### POS  D DATE DEFAULT CURRENT DATE                 DB20000I (criou)
    ### A    D DATE DEFAULT '2026-08-10'      criou; CHAR(D) -> 08/10/2026
    ### B    D DATE DEFAULT DATE '2026-08-10'            DB20000I (criou)
    ### B3   idem, em rodada limpa: criou; CHAR(D) -> 08/10/2026
    ### B2   D DATE DEFAULT DATE('2026-08-10')           DB20000I (criou)
    ### D    D DATE DEFAULT '04/14/2026'      criou; CHAR(D) -> 04/14/2026
    ### E    D TIMESTAMP DEFAULT '2026-08-10 12:34:56'
             criou; CHAR(D) -> 2026-08-10-12.34.56.000000
    ### F2   D TIMESTAMP DEFAULT TIMESTAMP '2026-08-10 12:34:56'
             criou; CHAR(D) -> 2026-08-10-12.34.56.000000

  Observacao de metodo: a primeira rodada do script nao derrubou T19_B/T19_B2/
  T19_F, e a rodada seguinte devolveu SQL0601N "name ... is identical to the
  existing name". Isso PROVA que a primeira criou - mas foi refeito com nomes
  limpos (###B3, ###F2) para nao depender de leitura indireta.

  Nota: o FluentSQL nao tem serializador de DDL para DB2 (nao existe
  Source\Drivers\FluentSQL.DDL.Serialize.DB2.pas), entao o DB2 nao emite DEFAULT
  de coluna hoje. A celula existe para responder a pergunta da forma unica, nao
  para certificar texto emitido.

  ------------------------------------------------------------------------------
  VIII  A MATRIZ, E A RESPOSTA

  Posicao medida: DEFAULT de coluna, em CREATE TABLE.

    dialeto            '2026-08-10' cru        DATE '2026-08-10'
    ---------------------------------------------------------------------------
    Oracle 23ai        RECUSA (ORA-01861)      ACEITA
    SQL Server 2022    ACEITA                  RECUSA (Msg 128)
    PostgreSQL 16.14   ACEITA                  ACEITA
    MySQL 8.4.11       ACEITA                  RECUSA (ERRO 1067)
    SQLite 3.53.4      ACEITA                  RECUSA (parse error)
    Firebird 5.0.4     ACEITA                  ACEITA
    DB2 12.1.5.0       ACEITA                  ACEITA
    InterBase          NAO MEDIDO              NAO MEDIDO

  E o mesmo quadro para DATETIME/TIMESTAMP, com TIMESTAMP '...' no lugar de
  DATE '...': Oracle RECUSA o cru (ORA-01843) e aceita o tipado; SQL Server
  (Msg 128), MySQL (1067) e SQLite (parse error) recusam o tipado.

  RESPOSTA: NAO EXISTE forma aceita pelos sete.
    * o literal cru e aceito por 6 e recusado por 1 (Oracle);
    * o literal ANSI tipado e aceito por 4 e recusado por 3 (MSSQL, MySQL, SQLite).
  A interseccao e VAZIA. Logo a correcao TEM de despachar por dialeto - e o ramo
  ficou restrito a dbnOracle, que e o unico com defeito medido. Os outros seis
  seguem emitindo byte a byte o que emitiam, e isso e travado por mutacao
  dirigida em test.date.literal.matrix.pas.

  ------------------------------------------------------------------------------
  IX  O TEXTO QUE O HEAD DA T19 EMITE, SUBMETIDO VERBATIM

  Nao basta medir a FORMA: o que vale e o enunciado que o framework produz. Cada
  string abaixo foi copiada da saida do proprio gerador (o mesmo texto que os
  Assert.AreEqual de test.date.literal.matrix.pas fixam) e submetida ao motor.

    ORACLE   CREATE TABLE "T" ("D" DATE DEFAULT DATE '2024-04-14')
             Table created. / 1 row created. / TO_CHAR -> 2024-04-14
             CREATE TABLE "T" ("D" TIMESTAMP DEFAULT TIMESTAMP '2024-04-14 12:34:56')
             Table created. / 1 row created. / TO_CHAR -> 2024-04-14 12:34:56
             e, para contraste, os DOIS textos que a base 7c9ed45 emitia:
             CREATE TABLE "T" ("D" DATE DEFAULT '2024-04-14')       ORA-01861
             CREATE TABLE "T" ("D" TIMESTAMP DEFAULT '2024-04-14 12:34:56')
                                                                    ORA-01843

    MSSQL    CREATE TABLE [T] ([D] DATE DEFAULT '2024-04-14')       -> 2024-04-14
             CREATE TABLE [T] ([D] DATETIME2 DEFAULT '2024-04-14 12:34:56')
                                                          -> 2024-04-14 12:34:56
    PGSQL    CREATE TABLE "T" ("D" DATE DEFAULT '2024-04-14')       -> 2024-04-14
             CREATE TABLE "T" ("D" TIMESTAMP DEFAULT '2024-04-14 12:34:56')
                                                          -> 2024-04-14 12:34:56
    MYSQL    CREATE TABLE `T` (`D` DATE DEFAULT '2024-04-14')       -> 2024-04-14
             CREATE TABLE `T` (`D` DATETIME DEFAULT '2024-04-14 12:34:56')
                                                          -> 2024-04-14 12:34:56
    SQLITE   CREATE TABLE `T` (`D` TEXT DEFAULT '2024-04-14')       -> 2024-04-14
             CREATE TABLE `T` (`D` DATETIME DEFAULT '2024-04-14 12:34:56')
                                                          -> 2024-04-14 12:34:56
    FIREBIRD CREATE TABLE "T" ("D" DATE DEFAULT '04/14/2024')       -> 2024-04-14
             CREATE TABLE "T" ("D" TIMESTAMP DEFAULT '04/14/2024 12:34:56')
                                                     -> 2024-04-14 12:34:56.0000

  Os doze enunciados criaram a tabela E devolveram o valor certo no SELECT. Os
  dois enunciados da base para Oracle foram recusados.

  ------------------------------------------------------------------------------
  COMO REFAZER

  1. Suba os sete containers com prefixo proprio (os comandos exatos estao em
     cada secao). Espere o DB2 - "db2level" respondendo NAO basta, e preciso que
     o CONNECT pare de devolver SQL1035N.
  2. Rode cada script de secao e confira PRIMEIRO o controle negativo e o
     positivo. Se o negativo nao gritar, o metodo nao esta medindo nada.
  3. Compile os 11 .dpr contra Source\ e confira a medicao: nesta arvore,
     666/600/20/46 sem defines e 668/613/20/35 com -DDB2 -DINTERBASE, contra
     662/596/20/46 e 664/609/20/35 na base 7c9ed45 - +4 achados, +4 passados, e
     o CONJUNTO de vermelhos identico nome a nome nas duas configuracoes.
  4. Para refazer as mutacoes: troque, nas DUAS funcoes de FluentSQL.Utils.pas,
     "if ADriverName = dbnOracle then" por
     "if ADriverName in [dbnOracle, <outro dialeto>] then" e recompile.
  ------------------------------------------------------------------------------
*/
