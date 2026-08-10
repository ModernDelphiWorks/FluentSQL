/*
  ORACULO DE MOTOR REAL - T17 / matriz CAST: dialeto x TFluentSQLDataFieldType
  ==============================================================================

  POR QUE ESTE ARQUIVO EXISTE

  Ate a T17, IFluentSQLFunctions.Cast estava no PADRAO A - o core emitia
  'CAST(x AS ' + ADataType + ')' sem consultar o driver, e nenhum dos nove drivers
  o sobrescrevia. O tipo chegava como String livre, entao quem chamava escolhia a
  palavra, e a palavra escolhida era sempre a de UM fabricante.

  A tarefa mandava MEDIR antes de fixar a assinatura, por causa de tres riscos
  concretos. Mediu-se. OS TRES SE CONFIRMARAM, e um deles e pior do que a suspeita
  original.

  Este arquivo e uma MEDICAO, nao uma suite: nenhum teste DUnitX o executa. Ele
  fica ao lado dos demais oraculos (test.cases.bind.matrix.sql,
  test.merge.mssql.sql, test.pagination.*.sql) pela mesma razao que eles: e a prova
  citavel das afirmacoes que test.cast.matrix.pas trava como contrato.

  NAO MEDIDO: InterBase. Nao ha imagem de container publica (produto pago da
  Embarcadero) e nao ha instancia neste ambiente. As dez celulas dele estao
  marcadas "nao medido" e NAO foram inferidas a partir do Firebird. Este arquivo
  mostra por que essa recusa nao e preciosismo: Oracle e DB2 sao ambos SQL de
  grande porte e divergem em CLOB; Firebird e DB2 divergem na obrigatoriedade da
  largura. Semelhanca de familia nao prediz a celula.

  MongoDB esta fora por decisao do dono (a intersecao e relacional).

  ==============================================================================
  MOTORES, COMO SUBIRAM E O QUE RESPONDERAM QUANDO PERGUNTADOS A VERSAO
  ==============================================================================

  PostgreSQL
    docker run -d --name t17pg -e POSTGRES_PASSWORD=... -p 54320:5432 postgres:16
    cliente: docker exec t17pg psql -U postgres
    SELECT version();
      PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu,
      compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit

  MySQL
    docker run -d --name t17my -e MYSQL_ROOT_PASSWORD=... -p 33060:3306 mysql:8.4
    cliente: docker exec t17my mysql -uroot -p...
    SELECT VERSION();   ->   8.4.11

  SQLite
    docker run --rm keinos/sqlite3 sqlite3 :memory:
    SELECT sqlite_version();   ->   3.53.4

  SQL Server
    docker run -d --name t17mssql -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=... \
      -p 14330:1433 mcr.microsoft.com/mssql/server:2022-latest
    cliente: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C
    SELECT @@VERSION;
      Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
      Jul  7 2026 14:37:25
      Copyright (C) 2022 Microsoft Corporation

  Oracle
    docker run -d --name t17ora -e ORACLE_PASSWORD=... -p 15210:1521 \
      gvenzl/oracle-free:23-slim
    cliente: sqlplus -S system/...@//localhost:1521/FREEPDB1
    SELECT banner_full FROM v$version;
      Oracle AI Database 26ai Free Release 23.26.2.0.0 - Develop, Learn, and
      Run for Free
      Version 23.26.2.0.0

    ATENCAO A TAG. "gvenzl/oracle-free:23-slim" NAO entrega 23c: entrega
    Oracle AI Database 26ai 23.26.2.0.0. Quem citar "Oracle 23c" a partir desta
    imagem esta citando versao que nao rodou.

  Firebird
    docker run -d --name t17fb -e FIREBIRD_ROOT_PASSWORD=... \
      -e FIREBIRD_DATABASE=test.fdb -p 30500:3050 firebirdsql/firebird:5.0.4
    cliente: /opt/firebird/bin/isql -user SYSDBA -password ...
    SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM RDB$DATABASE;  -> 5.0.4
    (o servidor anuncia LI-V5.0.4.1812 Firebird 5.0; charset do test.fdb: NONE)

  DB2
    docker run -d --name t17db2 --privileged=true -e LICENSE=accept \
      -e DB2INST1_PASSWORD=... -e DBNAME=testdb -p 55000:50000 \
      icr.io/db2_community/db2:latest
    cliente: db2 CLP como db2inst1, conectado a testdb
    SELECT service_level FROM TABLE(sysproc.env_get_inst_info());  -> DB2 v12.1.5.0
    (Database server = DB2/LINUXX8664 12.1.5.0)

  Interbase ..................... NAO MEDIDO (sem imagem publica)

  ==============================================================================
  RISCO 1 - A PALAVRA SOZINHA NAO E O TIPO INTEIRO, E O ERRO E SILENCIOSO
  ==============================================================================

  A suspeita era que 'NVARCHAR' sem (n) truncasse calado no SQL Server. Confirmada,
  e o numero e 30. Mas a medicao achou TRES comportamentos distintos, nao dois -
  e sao mutuamente incompativeis, o que sozinho ja mata qualquer grafia unica.

  Entrada: string de 40 caracteres, '12345678901234567890123456789012345678AB'

  --- (a) TRUNCA EM SILENCIO -------------------------------------------------

  SQL Server 2022
    SELECT LEN(CAST('...40 chars...' AS VARCHAR))  AS len_varchar,
           LEN(CAST('...40 chars...' AS NVARCHAR)) AS len_nvarchar,
               CAST('...40 chars...' AS NVARCHAR)  AS v;
      len_varchar len_nvarchar v
      ----------- ------------ -
      30          30           123456789012345678901234567890

    40 caracteres entram, 30 saem. Sem erro, sem aviso, sem warning. O default de
    comprimento de CAST/CONVERT no T-SQL e 30.

    ISTO E A RAZAO DE A ASSINATURA TER LARGURA. Um mapeamento dftString ->
    'NVARCHAR' compila, roda, passa em teste com dado curto e corrompe em
    producao com dado longo - estritamente pior que a incoerencia de API que a
    T17 veio corrigir.

  --- (b) E ERRO DE SINTAXE, A LARGURA E OBRIGATORIA -------------------------

  Firebird 5.0.4
    SELECT CHAR_LENGTH(CAST('...40 chars...' AS VARCHAR)) FROM RDB$DATABASE;
      Statement failed, SQLSTATE = 42000
      Dynamic SQL Error
      -SQL error code = -104
      -Token unknown - line 1, column 78
      -)

  Oracle 26ai 23.26.2.0.0
    SELECT LENGTH(CAST('...40 chars...' AS VARCHAR2)) FROM DUAL;
      SELECT LENGTH(CAST('12345678901234567890123456789012345678AB' AS VARCHAR2)) FROM DUAL
                                                                               *
      ERROR at line 1:
      ORA-00906: missing left parenthesis

  --- (c) PASSA SEM TRUNCAR, LARGURA E DESNECESSARIA -------------------------

  PostgreSQL 16.14
    SELECT length(CAST('...40 chars...' AS VARCHAR)) AS len, ... AS v;
       len |                    v
      -----+------------------------------------------
        40 | 12345678901234567890123456789012345678AB

  MySQL 8.4.11
    SELECT CHAR_LENGTH(CAST('...40 chars...' AS CHAR)) AS len, ...;
      +------+------------------------------------------+
      | len  | v                                        |
      +------+------------------------------------------+
      |   40 | 12345678901234567890123456789012345678AB |
      +------+------------------------------------------+

  SQLite 3.53.4
    SELECT length(CAST('...40 chars...' AS TEXT)), length(CAST('...' AS VARCHAR));
      40|40

  DB2 v12.1.5.0
    SELECT LENGTH(CAST(REPEAT('x',300) AS VARCHAR)) AS R FROM SYSIBM.SYSDUMMY1;
      R
      -----------
              300

  --- COMO O ESTOURO SE COMPORTA QUANDO HA LARGURA --------------------------

  Firebird e HONESTO no estouro - erro, nao truncamento:
    SELECT CAST('...40 chars...' AS VARCHAR(20)) FROM RDB$DATABASE;
      Statement failed, SQLSTATE = 22001
      arithmetic exception, numeric overflow, or string truncation
      -string right truncation
      -expected length 20, actual 40

  PostgreSQL e SILENCIOSO no estouro - a largura INTRODUZ a corrupcao que a
  ausencia dela nao tinha:
    SELECT CAST('abcdefghij' AS VARCHAR(4)) AS r;
        r
      ------
       abcd

  Consequencia de desenho, e nao e simetrica: no SQL Server a largura SALVA; no
  PostgreSQL a largura MATA. Por isso a largura e decisao POR DRIVER, e nao um
  parametro que o core carimba igual para todos.

  --- QUAL LARGURA DEFAULT, E POR QUE 4000 NAO E ARBITRARIO ------------------

  4000 e o MAIOR valor simultaneamente legal nos dois motores mais restritivos.
  Nao foi escolhido por ser redondo; foi o teto que os dois acusaram:

  Oracle 26ai
    SELECT LENGTH(CAST('ab' AS VARCHAR2(4000))) AS r FROM DUAL;   ->  2      ok
    SELECT LENGTH(CAST('ab' AS VARCHAR2(4001))) AS r FROM DUAL;
      ERROR at line 1:
      ORA-00910: specified length too long for its datatype

  SQL Server 2022
    SELECT LEN(CAST('ab' AS NVARCHAR(4000))) AS r;   ->  2                   ok
    SELECT LEN(CAST('ab' AS NVARCHAR(4001))) AS r;
      Msg 131, Level 16, State 1, Server 37a3b7f6cb88, Line 1
      The size (4001) given to the convert specification 'nvarchar' exceeds the
      maximum allowed for any data type (4000).

  Firebird aceita 4000 inclusive na pior codificacao. O limite dele e por BYTES
  (32765), entao em UTF8 (4 bytes/char) o teto de caracteres e 8191:
    SET NAMES UTF8;  CONNECT ...;
    SELECT CHAR_LENGTH(CAST('ab' AS VARCHAR(4000))) FROM RDB$DATABASE;  ->  2  ok
    SELECT CHAR_LENGTH(CAST('ab' AS VARCHAR(8192))) FROM RDB$DATABASE;
      Statement failed, SQLSTATE = HY004
      Dynamic SQL Error
      -SQL error code = -204
      -Data type unknown
      -Implementation limit exceeded
      -COLUMN

  Ou seja 4000 < 8191: seguro no Firebird ate em UTF8.

  SQLite IGNORA a largura por completo - mais um motivo para nao emiti-la la:
    SELECT CAST('abcdefghij' AS TEXT(4)), typeof(CAST('abcdefghij' AS TEXT(4)));
      abcdefghij|text

  ==============================================================================
  RISCO 2 - NEM TODA CELULA DO ENUM EXISTE EM TODO DIALETO
  ==============================================================================

  Sao 10 valores x 7 dialetos medidos = 70 celulas. 22 NAO EXISTEM. A tabela
  completa esta no fim; aqui ficam as transcricoes que a sustentam.

  --- dftUnknown: nao e tipo em lugar nenhum ---------------------------------

  Nao ha o que emitir: o enum usa dftUnknown como "nao sei", e um CAST para "nao
  sei" nao tem significado. Curiosidade medida, que NAO muda a decisao: o
  PostgreSQL tem um pseudo-tipo interno com esse nome e aceita
    SELECT CAST('x' AS UNKNOWN) AS r;   ->  x
  mas 'unknown' no PostgreSQL e o tipo de literal nao resolvido, nao um tipo de
  usuario. Emiti-lo seria acidente, nao portabilidade.

  --- dftArray: nao existe como alvo generico em NENHUM dos sete -------------

  PostgreSQL 16.14   SELECT CAST('{1,2}' AS ARRAY) AS r;
                       ERROR:  syntax error at or near "ARRAY"
                       LINE 1: SELECT CAST('{1,2}' AS ARRAY) AS r;
                                                      ^
                     (com o tipo do ELEMENTO funciona:
                      SELECT CAST('{1,2}' AS INTEGER[]) AS r;  ->  {1,2}
                      mas o enum nao carrega o tipo do elemento)

  SQL Server 2022    Msg 243, Level 16, State 1 ...
                     Type ARRAY is not a defined system type.

  MySQL 8.4.11       ERROR 1064 (42000) ... near 'ARRAY) AS r' at line 1

  Oracle 26ai        ORA-00902: invalid datatype

  Firebird 5.0.4     -SQL error code = -607 / -Invalid command
                     -Specified domain or source column ARRAY does not exist

  DB2 v12.1.5.0      SQL0204N  "ARRAY" is an undefined name.  SQLSTATE=42704

  SQLite 3.53.4      ACEITA - e este e o problema. Ver o risco 3 abaixo.

  --- dftGuid: existe em 2 dos 7 --------------------------------------------

  PostgreSQL 16.14   SELECT CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UUID);
                       6f9619ff-8b86-d011-b42d-00c04fc964ff              OK

  SQL Server 2022    ... AS UNIQUEIDENTIFIER
                       6F9619FF-8B86-D011-B42D-00C04FC964FF              OK

  MySQL 8.4.11       ERROR 1064 (42000) ... near 'UUID) AS r' at line 1

  Firebird 5.0.4     -SQL error code = -607 / -Invalid command
                     -Specified domain or source column UUID does not exist

  DB2 v12.1.5.0      SQL0204N  "UUID" is an undefined name.  SQLSTATE=42704

  Oracle 26ai        o equivalente e RAW(16), e ele parte o caso de uso:
                       CAST('6F9619FF8B86D011B42D00C04FC964FF' AS RAW(16))
                         6F9619FF8B86D011B42D00C04FC964FF                OK
                       CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS RAW(16))
                         ERROR at line 1:
                         ORA-01465: invalid hex number
                     Ou seja RAW(16) so aceita hex puro. A forma com hifens - que
                     e a que um GUID carrega em qualquer consumidor - explode.
                     Emitir RAW(16) daria SQL que passa no teste e quebra no uso.

  SQLite 3.53.4      ACEITA e destroi. Ver o risco 3.

  --- dftBoolean: existe em 5 dos 7, com grafias diferentes ------------------

  PostgreSQL 16.14   CAST('true' AS BOOLEAN)   ->  t                      OK
  Firebird 5.0.4     CAST('true' AS BOOLEAN)   ->  <true>                 OK
  Oracle 26ai        CAST('true' AS BOOLEAN)   ->  TRUE                   OK
                     (SO porque este motor e 23ai+; em 19c e anterior nao ha
                      BOOLEAN em SQL - risco registrado no driver)
  DB2 v12.1.5.0      CAST(1 AS BOOLEAN)        ->  1                      OK
  SQL Server 2022    NAO tem BOOLEAN, tem BIT:
                       CAST(1 AS BIT)          ->  1                      OK
                       CAST(1 AS BOOLEAN)
                         Msg 243, Level 16, State 1 ...
                         Type BOOLEAN is not a defined system type.
  MySQL 8.4.11       ERROR 1064 (42000) ... near 'BOOLEAN) AS r' at line 1
                     (CAST(1 AS UNSIGNED) devolve 1, mas e INTEIRO, nao booleano)
  SQLite 3.53.4      ACEITA e destroi. Ver o risco 3.

  --- dftText: a divergencia menos obvia da matriz ---------------------------

  PostgreSQL 16.14   CAST('abcdefghij' AS TEXT)             ->  abcdefghij  OK
  DB2 v12.1.5.0      LENGTH(CAST('abcdefghij' AS CLOB))     ->  10          OK
  Firebird 5.0.4     CAST('abcdefghij' AS BLOB SUB_TYPE TEXT) -> abcdefghij OK
  SQL Server 2022    CAST('abcdefghij' AS NVARCHAR(MAX))    ->  abcdefghij  OK
                     (AS TEXT tambem responde, mas TEXT esta deprecado)
  MySQL 8.4.11       CAST('x' AS TEXT)
                       ERROR 1064 (42000) ... near 'TEXT) AS r' at line 1
                     (a grafia do MySQL para texto em CAST e CHAR)
  Oracle 26ai        CAST('abcdefghij' AS CLOB)
                       SELECT CAST('abcdefghij' AS CLOB) AS r FROM DUAL
                              *
                       ERROR at line 1:
                       ORA-22849: Type CLOB is not supported for this function or
                       operator.

                     ESTA E A CELULA QUE MAIS ENGANA: CLOB EXISTE na Oracle, e
                     todo mundo escreveria CAST(x AS CLOB) sem hesitar. Ele so nao
                     e alvo valido de CAST - a forma Oracle e TO_CLOB(x). O DB2,
                     que e o motor "primo" mais proximo em porte, aceita CLOB
                     normalmente. Nao ha como acertar isso sem medir.

  --- dftInteger: a grafia ANSI e erro de SINTAXE no MySQL -------------------

  MySQL 8.4.11       CAST('123' AS INTEGER)
                       ERROR 1064 (42000) ... near 'INTEGER) AS r' at line 1
                     CAST('123' AS SIGNED)     ->  123                    OK

    O alvo de CAST no MySQL e LISTA FECHADA na gramatica: o que vale em CREATE
    TABLE nao vale aqui. E este e o achado que condena o padrao A retroativamente:
    o core emitia 'CAST(x AS ' + ADataType + ')' e o proprio teste da casa
    (test.driver.functions.matrix.pas) exercitava Cast('C','INTEGER') e o dava por
    bom nos sete - quando no MySQL essa string nunca teria rodado.

  Os demais aceitam INTEGER: PostgreSQL 123, Oracle 123, Firebird 123, DB2 123,
  SQLite 123, SQL Server usa INT (INTEGER tambem responde).

  ==============================================================================
  RISCO 3 - O SQLITE E O PIOR CASO, E NAO ESTAVA NA LISTA DE SUSPEITAS
  ==============================================================================

  O SQLite NUNCA recusa um alvo de CAST. Qualquer palavra e aceita e resolvida
  pelas regras de AFINIDADE. Nao ha erro para capturar, e o dado e destruido.

    SELECT typeof(CAST('2026-08-10' AS DATE)),
           typeof(CAST('true' AS BOOLEAN)),
           typeof(CAST('x' AS ARRAY)),
           typeof(CAST('x' AS TEXT)),
           typeof(CAST('123' AS INTEGER)),
           typeof(CAST('1.5' AS REAL)),
           typeof(CAST('abc' AS BANANA));
      integer|integer|integer|text|integer|real|integer
                                                 ^^^^^^^
                                   'BANANA' e aceito como nome de tipo

    SELECT CAST('2026-08-10' AS DATE),
           CAST('true' AS BOOLEAN),
           CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS UUID);
      2026|0|6

    SELECT CAST('2026-08-10 12:34:56' AS DATETIME),
           typeof(CAST('2026-08-10 12:34:56' AS DATETIME));
      2026|integer

  Leitura, uma linha de cada vez:
    a data '2026-08-10'        virou o INTEIRO 2026
    o booleano 'true'          virou 0        (ou seja, FALSO)
    o GUID '6F9619FF-...'      virou 6
    o timestamp completo       virou 2026

  Nenhuma dessas linhas levanta. Um mapeamento ingenuo dftDate -> 'DATE' no SQLite
  nao produziria SQL invalido: produziria SQL VALIDO COM O DADO ERRADO, que e o
  unico modo de falha pior que os outros dois.

  E este o dialeto que decidiu a politica. Se a sobrecarga de enum oferecesse a
  UNIAO - cada celula em que o motor responde - o mesmo Cast(x, dftDate) que roda
  certo no PostgreSQL chegaria aqui, nao levantaria nada, e devolveria 2026. O bug
  nao apareceria em teste, apareceria em relatorio, meses depois. Por isso dftDate,
  dftDateTime, dftGuid e dftBoolean nao sao oferecidos pela sobrecarga de enum em
  NENHUM dialeto - nem naqueles em que funcionam.

  ==============================================================================
  O QUE DESBLOQUEIA A T13 - PARAMETRO EM POSICAO DE THEN/ELSE
  ==============================================================================

  A T13 (slot de valor do CASE) ficou bloqueada porque Firebird e DB2 recusam
  'CASE WHEN c THEN :p1 ELSE :p2 END' no PREPARE. Medido em test.cases.bind.
  matrix.sql. Aqui a pergunta e outra e mais estreita: A FORMA QUE ESTE DRIVER
  EMITE, com a grafia e a largura exatas, faz o PREPARE passar?

  --- FIREBIRD 5.0.4 --------------------------------------------------------

  Metodo: EXECUTE STATEMENT dentro de EXECUTE BLOCK - o texto interno e preparado
  ANTES de os valores serem conhecidos, que e o que um driver Delphi faz.

  CONTROLE (sem CAST) - o bloqueio da T13, reproduzido:
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
      -At block line: 3, col: 3

  COM A FORMA QUE O DRIVER EMITE - Cast(':p1', dftString) devolve exatamente
  'CAST(:p1 AS VARCHAR(4000))':
    EXECUTE BLOCK RETURNS (r VARCHAR(40)) AS
    BEGIN
      EXECUTE STATEMENT
        ('SELECT CASE WHEN 1=1 THEN CAST(:a AS VARCHAR(4000))
                                ELSE CAST(:b AS VARCHAR(4000)) END
            FROM RDB$DATABASE')
        (a := 'yes', b := 'no') INTO r;
      SUSPEND;
    END
      R
      ========================================
      yes                                          ACEITA

  E com tipo numerico, para nao atribuir o resultado ao tipo texto:
    ('SELECT CASE WHEN 1=0 THEN CAST(:a AS INTEGER)
                           ELSE CAST(:b AS INTEGER) END FROM RDB$DATABASE')
      (a := 10, b := 20)
      R
      ============
                20                                 ACEITA

  --- DB2 v12.1.5.0 ---------------------------------------------------------

  Metodo: db2 CLP com "?" - o CLP prepara e so entao pede valor. SQL0313N ("voce
  nao me deu valores") e a prova de que o PREPARE PASSOU; SQL0418N e a prova de
  que nao passou.

  CONTROLE (sem CAST) - o bloqueio da T13, reproduzido:
    SELECT CASE WHEN 1=1 THEN ? ELSE ? END AS R FROM SYSIBM.SYSDUMMY1
      SQL0418N  The statement was not processed because the statement contains an
      invalid use of one of the following: an untyped parameter marker, the DEFAULT
      keyword, or a null value.  SQLSTATE=42610

  COM A FORMA QUE O DRIVER EMITE - Cast('?', dftString) devolve exatamente
  'CAST(? AS VARCHAR)', SEM largura (o DB2 nao precisa dela):
    SELECT CASE WHEN 1=1 THEN CAST(? AS VARCHAR)
                          ELSE CAST(? AS VARCHAR) END AS R FROM SYSIBM.SYSDUMMY1
      SQL0313N  The number of variables in the EXECUTE statement, the number of
      variables in the OPEN statement, or the number of arguments in an OPEN
      statement for a parameterized cursor is not equal to the number of values
      required.  SQLSTATE=07004                    PREPARE PASSOU

  E as variantes, para mostrar que nao depende da largura nem do tipo:
    ... CAST(? AS VARCHAR(4000)) ...   SQL0313N    PREPARE PASSOU
    ... CAST(? AS INTEGER) ...         SQL0313N    PREPARE PASSOU

  --- VEREDITO DA T13 -------------------------------------------------------

  A T17 DESBLOQUEIA A T13. Nos dois motores que recusavam, a forma emitida por
  este driver passa do PREPARE, com as strings exatas:

    Firebird ..... CAST(:p1 AS VARCHAR(4000))     (largura obrigatoria; 4000 e o
                                                   default declarado)
    DB2 .......... CAST(? AS VARCHAR)             (sem largura; o DB2 nao trunca)

  As duas strings estao travadas por teste em test.cast.matrix.pas
  (TestFormaQueDesbloqueiaAT13): se mudarem, a T13 volta a ficar bloqueada e a
  prova tem de ser refeita contra motor real.

  A LARGURA DO FIREBIRD NAO E ARBITRARIA, mas E UMA ESCOLHA DE DESENHO e por isso
  fica declarada aqui: 4000 e o teto da Oracle e do SQL Server (medido acima), e
  esta com folga sob o teto do Firebird em UTF8 (8191). Um valor menor truncaria
  texto que hoje passa; um valor maior quebraria Oracle e SQL Server. Quem quiser
  outro passa ALength explicito.

  A T13 NAO FOI IMPLEMENTADA nesta branch - so foi provado que deixou de estar
  bloqueada.

  ==============================================================================
  A MATRIZ - 10 TIPOS x 7 DIALETOS MEDIDOS
  ==============================================================================

  "-" = celula NAO EXISTE no dialeto, medido contra o motor.

  LEIA ISTO ANTES DE USAR A TABELA COMO MAPA DA API. Ela e o retrato dos MOTORES,
  nao a lista do que a sobrecarga portavel oferece. As duas nao coincidem, e a
  diferenca e deliberada:

    a tabela abaixo ...... 46 celulas existem, 24 nao
    Cast(x, dftTipo) ..... oferece TRES: dftString, dftInteger, dftFloat

  A sobrecarga de enum e a INTERSECAO dos sete, e so estes tres estao nos sete.
  Todas as outras celulas - inclusive as 43 que EXISTEM em algum motor - sao
  recusadas por ela em TODOS os dialetos, com a mesma mensagem, inclusive naquele
  em que a celula funciona. A lista canonica esta em cFluentSQLCastPortableTypes
  (Source\Core\FluentSQL.Interfaces.pas) e o porque esta em test.cast.matrix.pas.

  Isso NAO torna as 43 inalcancaveis: elas continuam acessiveis pela sobrecarga
  Cast(AExpression, ADataType: String), que emite verbatim, e por ForDialectOnly.
  O que muda e de quem e a garantia de portabilidade. E por isso que esta tabela
  segue viva: ela e a fonte para quem for escrever a grafia a mao, e e o que
  impede alguem de alargar cFluentSQLCastPortableTypes sem remedir.

                 Firebird 5.0.4   SQL Server 2022    MySQL 8.4.11    SQLite 3.53.4
  dftUnknown     -                -                  -               -
  dftString      VARCHAR(4000)    NVARCHAR(4000)     CHAR            TEXT
  dftInteger     INTEGER          INT                SIGNED          INTEGER
  dftFloat       DOUBLE PRECISION FLOAT              DOUBLE          REAL
  dftDate        DATE             DATE               DATE            -
  dftArray       -                -                  -               -
  dftText        BLOB SUB_TYPE    NVARCHAR(MAX)      CHAR            TEXT
                 TEXT
  dftDateTime    TIMESTAMP        DATETIME           DATETIME        -
  dftGuid        -                UNIQUEIDENTIFIER   -               -
  dftBoolean     BOOLEAN          BIT                -               -

                 Oracle 26ai      PostgreSQL 16.14   DB2 v12.1.5.0   Interbase
  dftUnknown     -                -                  -               nao medido
  dftString      VARCHAR2(4000)   VARCHAR            VARCHAR         nao medido
  dftInteger     INTEGER          INTEGER            INTEGER         nao medido
  dftFloat       BINARY_DOUBLE    DOUBLE PRECISION   DOUBLE          nao medido
  dftDate        DATE             DATE               DATE            nao medido
  dftArray       -                -                  -               nao medido
  dftText        -                TEXT               CLOB            nao medido
  dftDateTime    TIMESTAMP        TIMESTAMP          TIMESTAMP       nao medido
  dftGuid        -                UUID               -               nao medido
  dftBoolean     BOOLEAN          BOOLEAN            BOOLEAN         nao medido

  Contagem: 70 celulas medidas, 46 existem, 24 nao existem.
  Por dialeto, quantas das 10 existem:
    PostgreSQL 8   SQL Server 8   DB2 7   Firebird 7   Oracle 6   MySQL 6   SQLite 4

  Nenhum dialeto tem as 10. So dftString, dftInteger e dftFloat existem nos sete -
  e mesmo dftString sai em SEIS grafias distintas (VARCHAR(4000), NVARCHAR(4000),
  VARCHAR2(4000), VARCHAR, CHAR, TEXT) sob DUAS politicas de largura OPOSTAS: onde
  o SQL Server precisa dela para nao corromper, o PostgreSQL corrompe se a receber.
  E o resultado que justifica o padrao B: nao ha grafia unica, nem sequer para o
  tipo mais banal da lista.

  ==============================================================================
  O QUE ESTA MEDICAO NAO COBRE
  ==============================================================================

  * Interbase, em nenhuma celula - sem imagem publica. As dez levantam.
  * Oracle 19c e anteriores: a celula BOOLEAN foi medida em 23ai, onde BOOLEAN
    existe em SQL. Em 19c nao existe, e o FluentSQL nao tem como saber a versao do
    servidor. Foi este o argumento decisivo para dftBoolean ficar FORA da
    intersecao: uma celula cuja validade depende de informacao que a biblioteca
    nao possui nao e promessa, e palpite. Hoje Cast(x, dftBoolean) e recusado em
    todos os dialetos; quem quiser assumir o risco escreve Cast(x, 'BOOLEAN') e a
    escolha fica visivel na linha dele.
  * SQL Server: a grafia sem teto e NVARCHAR(MAX), alcancavel pela sobrecarga de
    String (dftText nao esta na intersecao). Nao foi medido se algum consumidor
    dependia do TEXT deprecado.
  * Comportamento de CAST sobre COLUNA com dado real - todas as medicoes acima usam
    literal. O que se mediu foi a GRAFIA aceita e o comportamento de largura, que
    e o que o FluentSQL escolhe; conversao de dado e do motor.
*/
