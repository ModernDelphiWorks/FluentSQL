/*
  ORACULO DE MOTOR REAL - T13 / parametro em posicao de THEN e ELSE
  ==============================================================================

  POR QUE ESTE ARQUIVO EXISTE

  A T13 propunha dar ao CASE um slot de VALOR: IfThen/ElseIf passariam a levar o
  valor por IFluentSQLParams, de modo que o CASE saisse

      CASE WHEN <cond> THEN :p1 ELSE :p2 END

  em vez de interpolar o valor verbatim no texto. Antes de fixar a assinatura a
  tarefa mandava MEDIR se os motores aceitam parametro nu (sem CAST) nessa
  posicao. Mediu-se. DOIS DOS SETE RECUSAM, e por isso a assinatura NAO foi
  alterada nesta branch - ver a secao VEREDITO no fim.

  Este arquivo e uma MEDICAO, nao uma suite: nao ha teste DUnitX que o execute.
  Ele fica ao lado dos demais oraculos (test.merge.mssql.sql,
  test.setvalue.mssql.sql, test.pagination.*.sql) pela mesma razao que eles: e a
  prova citavel de uma afirmacao sobre motor real. O sufixo e ".matrix" e nao um
  dialeto porque a afirmacao so existe comparando os sete.

  NAO FOI MEDIDO: Interbase. Nao ha imagem de container publica (produto pago da
  Embarcadero) e nao ha instancia disponivel neste ambiente. A celula dele esta
  marcada "nao medido" e nao foi inferida a partir do Firebird - sao motores com
  a mesma origem mas com dialetos ja divergentes. MongoDB esta fora por decisao
  do dono (a intersecao e relacional).

  ==============================================================================
  MOTORES, COMO SUBIRAM E O QUE RESPONDERAM QUANDO PERGUNTADOS A VERSAO
  ==============================================================================

  PostgreSQL
    docker run -d --name t13-pg -e POSTGRES_PASSWORD=... -p 54321:5432 postgres:16
    cliente: docker exec -i t13-pg psql -U postgres
    SELECT version();
      PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu,
      compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit

  MySQL
    docker run -d --name t13-my -e MYSQL_ROOT_PASSWORD=... -p 33061:3306 mysql:8.4
    cliente: docker exec -i t13-my mysql -uroot -p...
    SELECT VERSION();   ->   8.4.11

  SQLite
    docker run --rm -i keinos/sqlite3 sqlite3
    SELECT sqlite_version();   ->   3.53.4

  SQL Server
    docker run -d --name t13-mssql -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=... \
      -p 14411:1433 mcr.microsoft.com/mssql/server:2022-latest
    cliente: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C
    SELECT @@VERSION;
      Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
      Jul  7 2026 14:37:25
      Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)

  Oracle
    docker run -d --name t13-ora -e ORACLE_PASSWORD=... -p 15211:1521 \
      gvenzl/oracle-free:23-slim
    cliente: sqlplus -S system/...@localhost/FREEPDB1
    SELECT banner_full FROM v$version;
      Oracle AI Database 26ai Free Release 23.26.2.0.0 - Develop, Learn, and
      Run for Free
      Version 23.26.2.0.0

    ATENCAO A TAG. "gvenzl/oracle-free:23-slim" NAO entrega 23c: entrega
    Oracle AI Database 26ai 23.26.2.0.0. Quem citar "Oracle 23c" a partir desta
    imagem esta citando versao que nao rodou.

  Firebird
    docker run -d --name t13-fb -e FIREBIRD_ROOT_PASSWORD=... \
      -e FIREBIRD_DATABASE=test.fdb -p 30511:3050 firebirdsql/firebird:5.0.4
    cliente: /opt/firebird/bin/isql -user SYSDBA -password ...
    SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM RDB$DATABASE;  -> 5.0.4

  DB2
    docker run -d --name t13-db2 --privileged=true -e LICENSE=accept \
      -e DB2INST1_PASSWORD=... -e DBNAME=testdb -p 50011:50000 \
      icr.io/db2_community/db2:latest
    cliente: db2 CLP como db2inst1, conectado a testdb
    SELECT service_level FROM TABLE(sysproc.env_get_inst_info());  -> DB2 v12.1.5.0

  ==============================================================================
  COMO O PARAMETRO FOI ENTREGUE EM CADA MOTOR
  ==============================================================================

  O ponto da medicao e o PREPARE: interessa se o motor consegue resolver o tipo
  do marcador na posicao de THEN/ELSE. Cada cliente foi usado na forma que de
  fato prepara e so depois liga o valor - que e o que um driver Delphi faz.

    PostgreSQL  PREPARE nome AS <sql com $1,$2>   depois EXECUTE nome(...)
    MySQL       PREPARE s FROM '<sql com ?,?>'    depois EXECUTE s USING @a,@b
    SQLite      .parameter set :p1 <v>            depois a query com :p1
    SQL Server  sp_executesql com N'@p1 <tipo>'   (o cliente DECLARA o tipo)
    Oracle      VARIABLE p1 VARCHAR2(20)          (o cliente DECLARA o tipo)
    Firebird    EXECUTE STATEMENT ('<sql>') (a := ..., b := ...) dentro de
                EXECUTE BLOCK - o texto interno e preparado ANTES de os valores
                serem conhecidos, exatamente como um prepare de cliente
    DB2         db2 CLP com "?" - o CLP prepara e so entao pede valor

  Consequencia que o leitor precisa ter em mente: em SQL Server e Oracle o tipo
  do bind e DECLARADO pelo cliente. E o caso favoravel, e e tambem o que os
  drivers reais fazem (IFluentSQLParam ja carrega DataType). Em PostgreSQL,
  MySQL, Firebird e DB2 o marcador chega SEM tipo e o motor tem de inferir do
  contexto - e e ai que dois deles desistem.

  ==============================================================================
  CASO A - OS DOIS RAMOS SAO PARAMETRO, VALOR STRING, CASE NA PROJECAO
           CASE WHEN 1=1 THEN :p1 ELSE :p2 END      p1='yes'  p2='no'
  ==============================================================================

  PostgreSQL 16.14 .......... ACEITA
    PREPARE a1 AS SELECT CASE WHEN 1=1 THEN $1 ELSE $2 END AS r;
    EXECUTE a1('yes','no');
      PREPARE
        r
      -----
       yes
      (1 row)

  MySQL 8.4.11 .............. ACEITA
    PREPARE m FROM 'SELECT CASE WHEN 1=1 THEN ? ELSE ? END AS r';
    SET @s='yes',@t='no'; EXECUTE m USING @s,@t;
      +------+
      | r    |
      +------+
      | yes  |
      +------+

  SQLite 3.53.4 ............. ACEITA
    .parameter set :p1 'yes'
    .parameter set :p2 'no'
    SELECT CASE WHEN 1=1 THEN :p1 ELSE :p2 END AS r;
      yes

  SQL Server 2022 ........... ACEITA
    EXEC sp_executesql N'SELECT CASE WHEN 1=1 THEN @p1 ELSE @p2 END AS r',
         N'@p1 nvarchar(20), @p2 nvarchar(20)', @p1=N'yes', @p2=N'no';
      r
      --------------------
      yes
      (1 rows affected)

  Oracle 26ai 23.26.2.0.0 ... ACEITA
    VARIABLE s1 VARCHAR2(20)
    VARIABLE s2 VARCHAR2(20)
    EXEC :s1 := 'yes'; :s2 := 'no';
    SELECT CASE WHEN 1=1 THEN :s1 ELSE :s2 END AS r FROM DUAL;
      R
      --------------------------------
      yes

  Firebird 5.0.4 ............ RECUSA          <=== ACHADO
    EXECUTE BLOCK RETURNS (r VARCHAR(40)) AS
    BEGIN
      EXECUTE STATEMENT
        ('SELECT CASE WHEN 1=1 THEN :a ELSE :b END FROM RDB$DATABASE')
        (a := 'yes', b := 'no') INTO r;
      SUSPEND;
    END
      Statement failed, SQLSTATE = HY004
      Dynamic SQL Error
      -SQL error code = -804
      -Data type unknown
      -At block line: 4, col: 3

  DB2 v12.1.5.0 ............. RECUSA          <=== ACHADO
    db2 "SELECT CASE WHEN 1=1 THEN ? ELSE ? END AS R FROM SYSIBM.SYSDUMMY1"
      SQL0418N  The statement was not processed because the statement contains an
      invalid use of one of the following: an untyped parameter marker, the DEFAULT
      keyword, or a null value.  SQLSTATE=42610

  Interbase ................. NAO MEDIDO (sem imagem publica; ver cabecalho)

  ==============================================================================
  CASO B - OS DOIS RAMOS SAO PARAMETRO, VALOR NUMERICO
           CASE WHEN 1=0 THEN :p1 ELSE :p2 END      p1=10  p2=20
  ==============================================================================

  PostgreSQL 16.14 .......... ACEITA   ->  20
  MySQL 8.4.11 .............. ACEITA   ->  20
  SQLite 3.53.4 ............. ACEITA   ->  20
  SQL Server 2022 ........... ACEITA   ->  20   (@p1 int, @p2 int)
  Oracle 26ai ............... ACEITA   ->  20   (VARIABLE n1 NUMBER)

  Firebird 5.0.4 ............ RECUSA - mesmo erro do caso A, o tipo do valor
                              nao muda nada:
      Statement failed, SQLSTATE = HY004
      Dynamic SQL Error
      -SQL error code = -804
      -Data type unknown

  DB2 v12.1.5.0 ............. RECUSA - SQL0418N, idem.

  Leitura: a recusa e do MARCADOR SEM TIPO, nao do tipo do dado. Trocar string
  por numero nao salva.

  ==============================================================================
  CASO C - OS DOIS RAMOS SAO PARAMETRO E TEM TIPOS DIFERENTES ENTRE SI
           CASE WHEN 1=1 THEN :p1 ELSE :p2 END      p1='yes' (texto)  p2=20 (int)
  ==============================================================================

  Aqui a divergencia nao e sobre parametro: e sobre a regra de tipo unico do
  resultado do CASE, que vale igual para literal. Vale registrar porque a API,
  ao expor um slot de valor, deixa o chamador escolher tipos diferentes nos dois
  ramos sem nenhum aviso.

  PostgreSQL 16.14 .......... ACEITA - unifica em text
    EXECUTE c1('abc', 5);   ->   abc

  MySQL 8.4.11 .............. ACEITA - devolveu o ramo tomado
    EXECUTE m USING @s,@b;  ->   yes

    RESSALVA MEDIDA: numa sessao em que o MESMO prepared statement ja tinha sido
    executado com os DOIS parametros inteiros, a execucao seguinte com string no
    primeiro devolveu 0, e nao 'yes' - o MySQL reaproveita o tipo resolvido na
    execucao anterior. Repetida a medicao com PREPARE novo, devolve 'yes'. Nao e
    defeito do FluentSQL (cada consulta e preparada uma vez), mas e perda
    SILENCIOSA de valor e por isso fica anotada.

  SQLite 3.53.4 ............. ACEITA - tipagem dinamica, devolve 'yes'

  SQL Server 2022 ........... RECUSA
    EXEC sp_executesql N'SELECT CASE WHEN 1=1 THEN @p1 ELSE @p2 END AS r',
         N'@p1 nvarchar(20), @p2 int', @p1=N'yes', @p2=20;
      Msg 245, Level 16, State 1, Server 13613932577d, Line 1
      Conversion failed when converting the nvarchar value 'yes' to data type int.

    (precedencia de tipo resolve o CASE como int e so entao tenta converter)

  Oracle 26ai 23.26.2.0.0 ... RECUSA
    SELECT CASE WHEN 1=1 THEN :s1 ELSE :n2 END AS r FROM DUAL
                                        *
    ERROR at line 1:
    ORA-00932: expression (:1) is of data type NUMBER, which is incompatible
    with expected data type CHAR

  Firebird 5.0.4 ............ ACEITA se os dois ramos vierem com CAST:
    SELECT CASE WHEN 1=1 THEN CAST(:a AS VARCHAR(20))
                          ELSE CAST(:b AS INTEGER) END FROM RDB$DATABASE
      R    yes

  DB2 v12.1.5.0 ............. nao isolado (para em SQL0418N antes, no caso A)

  ==============================================================================
  CASO D - O MESMO CASE DENTRO DO WHERE, EM VEZ DA PROJECAO
           SELECT 1 WHERE (CASE WHEN 1=1 THEN :p1 ELSE :p2 END) = 'yes'
  ==============================================================================

  A pergunta aqui e se a comparacao com um literal da ao motor o contexto de
  tipo que faltava na projecao. A resposta NAO e a mesma nos dois que recusam.

  PostgreSQL 16.14 .......... ACEITA   ->  ok = 1
  MySQL 8.4.11 .............. ACEITA   ->  ok = 1
  SQLite 3.53.4 ............. ACEITA   ->  ok = 1
  SQL Server 2022 ........... ACEITA   ->  ok = 1
  Oracle 26ai ............... ACEITA   ->  OK = 1

  Firebird 5.0.4 ............ ACEITA   <-- muda de figura em relacao ao caso A
    EXECUTE STATEMENT
      ('SELECT ''ok'' FROM RDB$DATABASE
          WHERE (CASE WHEN 1=1 THEN :a ELSE :b END) = ''yes''')
      (a := 'yes', b := 'no') INTO r;
      R    ok

  DB2 v12.1.5.0 ............. RECUSA   <-- NAO muda de figura
    db2 "SELECT 1 AS OK FROM SYSIBM.SYSDUMMY1
           WHERE (CASE WHEN 1=1 THEN ? ELSE ? END) = 'yes'"
      SQL0418N  The statement was not processed because the statement contains an
      invalid use of one of the following: an untyped parameter marker, the DEFAULT
      keyword, or a null value.  SQLSTATE=42610

  ==============================================================================
  CASO E - ONDE A FRONTEIRA DO FIREBIRD/DB2 REALMENTE ESTA
  ==============================================================================

  Isolado no Firebird, para nao atribuir ao CASE o que e regra geral do motor:

  E1  parametro nu numa projecao SIMPLES, sem CASE nenhum
        SELECT :a FROM RDB$DATABASE
          Statement failed, SQLSTATE = HY004
          Dynamic SQL Error
          -SQL error code = -804
          -Data type unknown

      Ou seja: o -804 NAO e do CASE. E do marcador sem tipo em posicao onde nada
      lhe da tipo. O CASE so e mais um lugar onde isso acontece.

  E2  parametro comparado a um literal (contexto disponivel)
        SELECT 'ok' FROM RDB$DATABASE WHERE :a = 'yes'
          R    ok                                          ACEITA

  E3  THEN literal / ELSE parametro
        SELECT CASE WHEN 1=1 THEN 'yes' ELSE :b END FROM RDB$DATABASE
          R    yes                                         ACEITA

  E4  THEN parametro / ELSE literal
        SELECT CASE WHEN 1=1 THEN :a ELSE 'no' END FROM RDB$DATABASE
          Statement failed, SQLSTATE = 22001
          arithmetic exception, numeric overflow, or string truncation
          -string right truncation
          -expected length 2, actual 3

      PREPARA (nao e -804), mas o bind herda o tipo do OUTRO ramo - aqui
      VARCHAR(2), de 'no' - e o valor de 3 caracteres estoura. Aceito no
      prepare, quebrado na execucao, com mensagem que nao aponta para o CASE.

  E5  os dois ramos com CAST
        SELECT CASE WHEN 1=1 THEN CAST(:a AS VARCHAR(20))
                              ELSE CAST(:b AS VARCHAR(20)) END FROM RDB$DATABASE
          R    yes                                         ACEITA

  E no DB2, o equivalente de E5 tambem passa do prepare:
        SELECT CASE WHEN 1=1 THEN CAST(? AS VARCHAR(20))
                              ELSE CAST(? AS VARCHAR(20)) END FROM SYSIBM.SYSDUMMY1
          SQL0313N  The number of variables in the EXECUTE statement ... is not
          equal to the number of values required.  SQLSTATE=07004

      SQL0313N e o CLP dizendo "voce nao me deu valor", ou seja o PREPARE
      passou. E o contraste que fecha o diagnostico: sem CAST da SQL0418N no
      prepare, com CAST chega a execucao.

  ==============================================================================
  RESUMO
  ==============================================================================

    caso A/B: os dois ramos sao parametro nu, CASE na projecao
    caso D:   os dois ramos sao parametro nu, CASE dentro do WHERE

    motor                          A/B        D
    ---------------------------  --------  --------
    PostgreSQL 16.14              ACEITA    ACEITA
    MySQL 8.4.11                  ACEITA    ACEITA
    SQLite 3.53.4                 ACEITA    ACEITA
    SQL Server 2022 CU26          ACEITA    ACEITA
    Oracle 26ai 23.26.2.0.0       ACEITA    ACEITA
    Firebird 5.0.4                RECUSA    ACEITA
    DB2 v12.1.5.0                 RECUSA    RECUSA
    Interbase                     nao medido

  ==============================================================================
  ATUALIZACAO T13 - A ASSINATURA MUDOU. LEIA ESTA SECAO ANTES DO VEREDITO ABAIXO
  ==============================================================================

  O VEREDITO que fecha este arquivo ("por isso a assinatura NAO foi alterada
  nesta branch") descrevia a situacao na branch da T14. ELE ESTA SUPERADO. Fica
  aqui porque a medicao que ele resume continua valendo e e a razao de o desenho
  ter ficado como ficou - mas a conclusao dele nao e mais a conclusao.

  O QUE MUDOU ENTRE UMA COISA E OUTRA: a T17 (PR #157). Ela tirou
  IFluentSQLFunctions.Cast do padrao A e o pos a despachar por dialeto, com a
  largura resolvida por driver e a intersecao portavel em fonte unica. Isso
  entrega, pronta, a peca que faltava - a opcao (i) da lista do veredito.

  A DECISAO DO DONO foi a (i): emitir CAST(:pN AS <tipo do dialeto>) nos SETE, e
  nao so nos dois que exigem. A razao de uniformizar e que esta e uma sobrecarga
  NOVA - nao ha SQL emitido hoje por ela, logo nao ha oraculo a quebrar - e a
  alternativa seria manter uma tabela de "quem precisa de tipo" que envelhece com
  a versao do motor.

  O QUE A T13 EMITE, MEDIDO NO BUILD (nao inferido da gramatica): o texto exato
  sai em test.cases.value.pas, celula por celula. Resumo:

    Firebird ..... CASE ... THEN CAST(:p1 AS VARCHAR(4000)) ...
    SQL Server ... CASE ... THEN CAST(:p1 AS NVARCHAR(4000)) ...
    MySQL ........ CASE ... THEN CAST(? AS CHAR) ...        (:pN -> ? no driver)
    Oracle ....... CASE ... THEN CAST(:p1 AS VARCHAR2(4000)) ...
    PostgreSQL ... CASE ... THEN CAST(:p1 AS VARCHAR) ...
    SQLite ....... CASE ... THEN CAST(:p1 AS TEXT) ...
    DB2 .......... CASE ... THEN CAST(:p1 AS VARCHAR) ...   (sem largura)
    InterBase .... levanta EFluentSQLFunctionNotSupported (matriz nao medida)
    MongoDB ...... levanta EFluentSQLFunctionNotSupported (fora da intersecao)

  ==============================================================================
  CASO F - A FORMA QUE A T13 EMITE, MEDIDA NOS SETE  (2026-08-11)
  ==============================================================================

  Esta secao NAO cita a T17: e medicao PROPRIA, feita na branch da T13, com as
  strings EXATAS que a implementacao emite - as mesmas que test.cases.value.pas
  trava celula por celula. Docker engine 29.6.2. Imagens iguais as do cabecalho
  deste arquivo; as versoes foram PERGUNTADAS ao motor em cada sessao, nao
  presumidas da tag.

  O que se perguntou em cada motor:

    controle    CASE 1 WHEN 1 THEN <marcador nu> ELSE <marcador nu> END
    dftString   CASE 1 WHEN 1 THEN CAST(p AS <grafia>) ELSE CAST(p AS <grafia>) END
    dftInteger  idem, ramo ELSE tomado, valores 10 e 20
    dftFloat    idem, ramo ELSE tomado, valores 1.5 e 2.5

  --- Firebird 5.0.4 --------------------------------------------------------
  SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM RDB$DATABASE  ->  5.0.4
  Metodo: EXECUTE STATEMENT dentro de EXECUTE BLOCK - o texto interno e preparado
  ANTES de os valores serem conhecidos, como o prepare de um cliente.

    controle
      EXECUTE STATEMENT
        ('SELECT (CASE 1 WHEN 1 THEN :a ELSE :b END) FROM RDB$DATABASE')
        (a := 'yes', b := 'no') INTO r;
          Statement failed, SQLSTATE = HY004
          Dynamic SQL Error
          -SQL error code = -804
          -Data type unknown
          -At block line: 3, col: 3                 RECUSA (bloqueio reproduzido)

    dftString   CAST(:a AS VARCHAR(4000)) nos dois ramos
          R
          ========================================
          yes                                                        ACEITA

    dftInteger  CAST(:a AS INTEGER) nos dois ramos
                     R
          ============
                    20                                               ACEITA

    dftFloat    CAST(:a AS DOUBLE PRECISION) nos dois ramos
                                R
          =======================
                2.500000000000000            ACEITA   <== ANTES SO INFERIDO

  --- DB2 v12.1.5.0 ---------------------------------------------------------
  SELECT service_level FROM TABLE(sysproc.env_get_inst_info())  ->  DB2 v12.1.5.0
  Metodo: db2 CLP com "?" - o CLP prepara e so entao pede valor. SQL0313N ("voce
  nao me deu valores") prova que o PREPARE PASSOU; SQL0418N prova que nao passou.

    controle    THEN ? ELSE ?
          SQL0418N  The statement was not processed because the statement
          contains an ... keyword, or a null value.  SQLSTATE=42610
                                                    RECUSA (bloqueio reproduzido)

    dftString   CAST(? AS VARCHAR)     SQL0313N ... SQLSTATE=07004  PREPARE PASSOU
    dftInteger  CAST(? AS INTEGER)     SQL0313N ... SQLSTATE=07004  PREPARE PASSOU
    dftFloat    CAST(? AS DOUBLE)      SQL0313N ... SQLSTATE=07004  PREPARE PASSOU
                                                          <== ANTES SO INFERIDO

  --- PostgreSQL 16.14 ------------------------------------------------------
  SELECT version() -> PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
  Metodo: PREPARE ... AS <sql com $1,$2>, depois EXECUTE.
    dftString   CAST($1 AS VARCHAR)              -> yes            ACEITA
    dftInteger  CAST($1 AS INTEGER)              -> 20             ACEITA
    dftFloat    CAST($1 AS DOUBLE PRECISION)     -> 2.5            ACEITA

  --- MySQL 8.4.11 ----------------------------------------------------------
  SELECT VERSION() -> 8.4.11
  Metodo: PREPARE m FROM '<sql com ?>', depois EXECUTE m USING @a,@b.
    dftString   CAST(? AS CHAR)                  -> yes            ACEITA
    dftInteger  CAST(? AS SIGNED)                -> 20             ACEITA
    dftFloat    CAST(? AS DOUBLE)                -> 2.5            ACEITA

  --- SQLite 3.53.4 ---------------------------------------------------------
  SELECT sqlite_version() -> 3.53.4
  Metodo: .parameter set :p1 <v>, e entao a query.
    dftString   CAST(:p1 AS TEXT)                -> yes            ACEITA
    dftInteger  CAST(:p1 AS INTEGER)             -> 20             ACEITA
    dftFloat    CAST(:p1 AS REAL)                -> 2.5            ACEITA

  --- SQL Server 2022 (RTM-CU26) 16.0.4265 ----------------------------------
  Metodo: sp_executesql - o cliente DECLARA o tipo do bind.
    dftString   CAST(@p1 AS NVARCHAR(4000))      -> yes            ACEITA
    dftInteger  CAST(@p1 AS INT)                 -> 20             ACEITA
    dftFloat    CAST(@p1 AS FLOAT)               -> 2.5            ACEITA

  --- Oracle AI Database 26ai Free Release 23.26.2.0.0 ----------------------
  SELECT banner_full FROM v$version -> Oracle AI Database 26ai Free Release
  23.26.2.0.0 (a tag da imagem diz "23-slim"; o motor diz 26ai - use o que o
  motor diz)
  Metodo: VARIABLE + EXEC - o cliente DECLARA o tipo do bind.
    dftString   CAST(:s1 AS VARCHAR2(4000))      -> yes            ACEITA
    dftInteger  CAST(:n1 AS INTEGER)             -> 20             ACEITA
    dftFloat    CAST(:f1 AS BINARY_DOUBLE)       -> 2.5E+000       ACEITA

  --- InterBase -------------------------------------------------------------
    NAO MEDIDO, e nao ha o que procurar: nao existe imagem publica do motor
    (produto pago da Embarcadero). A grafia do CAST do InterBase NAO foi inferida
    do Firebird, de proposito - mesma decisao da T17.

    O que EXISTE sobre o InterBase nesta entrega e de outra natureza e nao
    depende de motor: o driver LEVANTA EFluentSQLFunctionNotSupported neste slot,
    e essa recusa e observavel medindo o ESTADO DA COLECAO Params, nao a resposta
    de um banco. Tem celula propria em test.cases.value.pas, e foi ela que
    revelou o parametro orfao da porta 5. NADA neste arquivo afirma como o motor
    InterBase se comportaria.

  RESUMO DO CASO F

    motor                        controle nu   String    Integer   Float
    -------------------------  ------------  --------  --------  --------
    PostgreSQL 16.14               ACEITA     ACEITA    ACEITA    ACEITA
    MySQL 8.4.11                   ACEITA     ACEITA    ACEITA    ACEITA
    SQLite 3.53.4                  ACEITA     ACEITA    ACEITA    ACEITA
    SQL Server 2022 CU26           ACEITA     ACEITA    ACEITA    ACEITA
    Oracle 26ai 23.26.2.0.0        ACEITA     ACEITA    ACEITA    ACEITA
    Firebird 5.0.4                 RECUSA     ACEITA    ACEITA    ACEITA
    DB2 v12.1.5.0                  RECUSA     PREPARE   PREPARE   PREPARE
    InterBase                      nao medido em coluna nenhuma

  A COLUNA DO CONTROLE E O PONTO. E a unica com RECUSA, e o CAST a converte em
  ACEITA nos dois motores que recusavam. Nas outras cinco o CAST nao era
  necessario e TAMBEM NAO ATRAPALHOU - que era a outra metade da aposta da
  decisao "emitir CAST nos sete", e ate aqui essa metade nao tinha sido medida.

  O QUE CONTINUA SEM MEDICAO, PARA NAO SER LIDO COMO MEDIDO

    * InterBase, em qualquer forma (ver acima).
    * o comportamento com valor que NAO CABE no tipo declarado - por exemplo
      IfThen('BANANA', dftInteger). Nada na biblioteca valida AValue contra
      ADataType. A divergencia entre motores nesse caso ja esta documentada na
      matriz da T17 (no SQLite e no MySQL o CAST devolve 0 CALADO), e esta
      declarada no CHANGELOG - mas o CASO F mediu o uso CORRETO, e so ele.

  ==============================================================================
  VEREDITO (HISTORICO, DA BRANCH DA T14) - POR QUE A ASSINATURA NAO MUDOU LA
  ==============================================================================

  A forma que a T13 propunha emitir - CASE WHEN <cond> THEN :p1 ELSE :p2 END -
  nao e portavel. Dois dos sete recusam no PREPARE, e um deles, o Firebird, e o
  dialeto de maior cobertura desta biblioteca. Emitir essa forma transformaria
  consultas que hoje funcionam em consultas que o motor recusa antes de executar.

  Fazer o slot de valor funcionar nos sete exige envolver o parametro em CAST,
  e CAST portavel e por dialeto (VARCHAR2 na Oracle, VARCHAR alhures; a largura
  do VARCHAR teria de ser inventada por quem serializa). Isso e despacho por
  driver - desenho novo, nao ajuste de assinatura - e colide com tarefa ja
  catalogada em separado sobre Cast sem despacho.

  Por isso esta branch entrega a MEDICAO e para. A escolha entre

    (i)   emitir CAST(:pN AS <tipo do dialeto>) nos sete,
    (ii)  parametrizar so onde o motor aceita e manter verbatim nos outros dois,
    (iii) manter o slot de expressao como esta e nao criar slot de valor,

  e decisao de convencao, e cabe ao dono.

  O QUE ESTA BRANCH MUDOU NO CASE foi outra coisa, independente desta medicao:
  as guardas de ordem de IfThen/ElseIf, que eram Assert (some em release) ou
  nao existiam. Ver test.cases.guards.matrix.sql e test.builder.guards.pas.
*/
