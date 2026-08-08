/*
  ORACULO DE MOTOR REAL - T6a / injecao via MERGE
  ==============================================================================

  Motor:     Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
             Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)
  Container: docker run -d --name t6a-mssql \
               -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Fluent#T6a2026" \
               -p 14333:1433 mcr.microsoft.com/mssql/server:2022-latest
  Cliente:   /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -d t6a

  Por que so MSSQL: e o unico dialeto com serializador de MERGE registrado
  (FluentSQL.SerializeMSSQL.pas:168). Os demais nao emitem MERGE nenhum - ver
  test.merge.matrix.pas para a matriz completa por dialeto.

  O SQL abaixo NAO foi escrito a mao: foi emitido pela propria biblioteca, nas
  duas arvores (e9ed0b9 e a corrigida), e depois executado tal e qual.

  ==============================================================================
  ESTADO INICIAL
  ==============================================================================
    CREATE TABLE TARGET (ID INT PRIMARY KEY, NOME VARCHAR(200), VALOR DECIMAL(10,2));
    CREATE TABLE SOURCE (ID INT PRIMARY KEY, NOME VARCHAR(200), VALOR DECIMAL(10,2));
    CREATE TABLE USERS  (ID INT PRIMARY KEY, LOGIN VARCHAR(50));
    INSERT INTO TARGET VALUES (1,'ANTIGO',1.00);
    INSERT INTO SOURCE VALUES (1,'NOVO',2.00),(2,'OUTRO',3.00);
    INSERT INTO USERS  VALUES (1,'admin'),(2,'ana');    -- 2 linhas

  ==============================================================================
  ANTES  (arvore e9ed0b9)  -  .WhenMatched.Update(['NOME', <valor>])
  ==============================================================================

  --- CASO 1  BENIGNO   valor = TESTE
  Emitido (0 parametros):
    MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
      WHEN MATCHED THEN UPDATE SET [NOME] = TESTE;
  Motor respondeu:
    Msg 207, Level 16, State 1, Line 1
    Invalid column name 'TESTE'.
  Leitura: o caso BENIGNO ja era SQL invalido. Sem aspas, o motor le o valor
  como nome de coluna. MERGE com valor string nunca funcionou.

  --- CASO 2  LEGITIMO  valor = O'Brien
  Emitido (0 parametros):
    MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
      WHEN MATCHED THEN UPDATE SET [NOME] = O'Brien;
  Motor respondeu:
    Msg 105, Level 15, State 1, Line 1
    Unclosed quotation mark after the character string 'Brien;
    '.
    Msg 10713, Level 15, State 1, Line 1
    A MERGE statement must be terminated by a semi-colon (;).
  Leitura: a aspa legitima quebra o batch.

  --- CASO 3  HOSTIL    valor = 1; DROP TABLE USERS; --
  Payload escolhido de proposito para casar com interpolacao SEM aspas: como o
  valor nao e delimitado, o ';' encerra o MERGE e o DROP vira comando proprio.
  Emitido (0 parametros):
    MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
      WHEN MATCHED THEN UPDATE SET [NOME] = 1; DROP TABLE USERS; --;

    SELECT COUNT(*) FROM USERS;   -- antes:  2
    <executa o MERGE acima>       -- (1 rows affected), sem erro
    SELECT CASE WHEN OBJECT_ID('USERS') IS NULL ...
      RESULTADO
      ----------------------------------------
      USERS FOI DROPADA - INJECAO BEM SUCEDIDA

  Leitura: nao e teorico. A tabela foi destruida por um valor passado a
  IFluentSQLMerge.Update - API publica, sem nada de exotico no caminho.

  ==============================================================================
  DEPOIS  (branch fix/merge-parameterization)
  ==============================================================================

  A biblioteca passa a emitir, nos TRES casos, o mesmo texto:
    MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
      WHEN MATCHED THEN UPDATE SET [NOME] = :p1;
  com 1 parametro, p1 = <valor intacto>.

  Executado no motor com o valor ligado como parametro (:p1 -> @p1, que e o que
  qualquer driver faz ao consumir IFluentSQLParams):

  --- CASO 1  BENIGNO   valor = TESTE          (antes: Msg 207)
    EXEC sp_executesql
      N'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
          WHEN MATCHED THEN UPDATE SET [NOME] = @p1;',
      N'@p1 VARCHAR(200)', @p1 = 'TESTE';
    (1 rows affected)
    SELECT ID, NOME FROM TARGET;
      ID   NOME
      ---- -----
      1    TESTE
  Leitura: passou a funcionar. Nao e so seguranca - e a funcionalidade.

  --- CASO 2  LEGITIMO  valor = O'Brien        (antes: Msg 105)
    ... @p1 = 'O''Brien';
    (1 rows affected)
    SELECT ID, NOME FROM TARGET;
      ID   NOME
      ---- -------
      1    O'Brien
  Leitura: a aspa legitima atravessa intacta, sem mutilacao.

  --- CASO 3  HOSTIL    valor = 1; DROP TABLE USERS; --
    ... @p1 = '1; DROP TABLE USERS; --';
    (1 rows affected)
    SELECT CASE WHEN OBJECT_ID('USERS') IS NULL ...
      RESULTADO
      ------------------------------------
      USERS INTACTA - INJECAO NEUTRALIZADA
    SELECT ID, NOME FROM TARGET;
      ID   NOME
      ---- ----------------------
      1    1; DROP TABLE USERS; --
  Leitura: o payload virou DADO na coluna, que e exatamente o certo. Nao foi
  escapado nem rejeitado - foi tratado como o texto que sempre foi.

  ==============================================================================
  ARRAY DE CONTAGEM IMPAR  -  corrigido nesta branch
  ==============================================================================
  Um nome sem valor nao tem serializacao possivel. As duas arvores emitiam SQL
  invalido em silencio; executado no motor:

    .Insert(['ID', 1, 'NOME'])  emitia
      ... WHEN NOT MATCHED THEN INSERT ([ID], [NOME]) VALUES (@p1, );
      Msg 102, Level 15, State 1, Line 1
      Incorrect syntax near ')'.

    .Update(['NOME'])           emitia
      ... WHEN MATCHED THEN UPDATE SET [NOME] = ;
      Msg 102, Level 15, State 1, Line 1
      Incorrect syntax near ';'.

  Agora ambos levantam EArgumentException na chamada, com a contagem na
  mensagem. Contagem par e NAO VAZIA continua passando.

  ATENCAO - a primeira versao desta secao terminava com "Contagem par, inclusive
  a lista vazia, continua passando". Isso era FALSO, e a proxima secao mede por
  que: zero pares e par, mas serializa como "UPDATE SET ;" / "INSERT;" - o mesmo
  SQL invalido que esta guarda existe para impedir.

  ==============================================================================
  LISTA VAZIA / FORMA SEM ARGUMENTOS  -  corrigido nesta branch
  ==============================================================================

  DUAS chamadas distintas da API produzem o MESMO texto, porque as duas chegam
  ao serializador com ZERO pares nome/valor:

    .Update([])   e   .Update      -> ... WHEN MATCHED THEN UPDATE SET ;
    .Insert([])   e   .Insert      -> ... WHEN NOT MATCHED THEN INSERT;

  E o mesmo texto por construcao, nao por coincidencia: em
  FluentSQL.SerializeMSSQL.pas:211-217 o ramo matUpdate escreve 'UPDATE SET ' e
  depois percorre a lista de pares - lista vazia, nada escrito -, e em :220-239 o
  ramo matInsert escreve 'INSERT' e so acrescenta ' (cols) VALUES (vals)' se
  LPairs.Count > 0. O ';' final vem de :244. Por isso UMA medicao por motor
  cobre as DUAS chamadas.

  A forma SEM ARGUMENTOS importa em especial porque era a que o guia
  docs-src/docs/fluentsql/guides/dml-merge.md RECOMENDAVA, como resposta a
  "quero copiar coluna a coluna da fonte". Era conselho para escrever SQL que
  nenhum motor executa.

  ------------------------------------------------------------------------------
  MEDIDO - 6 motores, execucao real, nenhum aceita nenhuma das duas formas
  ------------------------------------------------------------------------------

  (1) Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
      Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)
      docker run -d --name t6a-mssql -e "ACCEPT_EULA=Y" \
        -e "MSSQL_SA_PASSWORD=Fluent#T6a2026" -p 14333:1433 \
        mcr.microsoft.com/mssql/server:2022-latest

      MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
        WHEN MATCHED THEN UPDATE SET ;
        -> Msg 102, Level 15, State 1, Line 1
           Incorrect syntax near ';'.

      MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
        WHEN NOT MATCHED THEN INSERT;
        -> Msg 102, Level 15, State 1, Line 1
           Incorrect syntax near ';'.

  (2) PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
      docker run -d --name t6a-pg -e POSTGRES_PASSWORD=fluent -p 54333:5432 \
        postgres:16

      MERGE INTO target AS t USING source AS s ON (t.id = s.id)
        WHEN MATCHED THEN UPDATE SET ;
        -> ERROR:  syntax error at or near ";"
           LINE 1: ... WHEN MATCHED THEN UPDATE SET ;
                                                    ^

      MERGE INTO target AS t USING source AS s ON (t.id = s.id)
        WHEN NOT MATCHED THEN INSERT;
        -> ERROR:  syntax error at or near ";"
           LINE 1: ... WHEN NOT MATCHED THEN INSERT;
                                                   ^

      CONTROLE - a mesma consulta com DEFAULT VALUES atravessa o parser:
      MERGE INTO target AS t USING source AS s ON (t.id = s.id)
        WHEN NOT MATCHED THEN INSERT DEFAULT VALUES;
        -> ERROR:  null value in column "id" of relation "target" violates
           not-null constraint
           DETAIL:  Failing row contains (null, null).
      Isto e erro de RESTRICAO, nao de sintaxe: prova que a recusa acima e
      especifica da forma NUA, e nao "o PostgreSQL nao gosta desse MERGE".
      A gramatica exige VALUES(...) ou DEFAULT VALUES; bare INSERT nao e nem um
      nem outro.

  (3) Oracle AI Database 26ai Free Release 23.26.2.0.0
      docker run -d --name t6a-ora -e ORACLE_PASSWORD=fluent -p 15210:1521 \
        gvenzl/oracle-free:23-slim

      MERGE INTO TARGET t USING SOURCE s ON (t.ID = s.ID)
        WHEN MATCHED THEN UPDATE SET ;
        -> ORA-00921: unexpected end of SQL command

      MERGE INTO TARGET t USING SOURCE s ON (t.ID = s.ID)
        WHEN NOT MATCHED THEN INSERT;
        -> ORA-00926: Missing VALUES or SET keyword

      O ORA-00926 e a confirmacao mais explicita das seis: o motor NOMEIA o que
      falta.

  (4) Firebird 5.0.4  (RDB$GET_CONTEXT('SYSTEM','ENGINE_VERSION') = 5.0.4)
      docker run -d --name t6a-fb -e FIREBIRD_ROOT_PASSWORD=fluent \
        -e FIREBIRD_DATABASE=t6a.fdb -p 30500:3050 firebirdsql/firebird:5.0.4

      MERGE INTO TARGET t USING SOURCE s ON (t.ID = s.ID)
        WHEN MATCHED THEN UPDATE SET ;
        -> Statement failed, SQLSTATE = 42000
           Dynamic SQL Error / -SQL error code = -104
           -Unexpected end of command - line 1, column 78

      MERGE INTO TARGET t USING SOURCE s ON (t.ID = s.ID)
        WHEN NOT MATCHED THEN INSERT;
        -> Statement failed, SQLSTATE = 42000
           Dynamic SQL Error / -SQL error code = -104
           -Unexpected end of command - line 1, column 75

  (5) MySQL 8.4.11
      docker run -d --name t6a-my -e MYSQL_ROOT_PASSWORD=fluent -p 33066:3306 \
        mysql:8.4

      As duas formas:
        -> ERROR 1064 (42000): You have an error in your SQL syntax; ... near
           'MERGE INTO TARGET t USING SOURCE s ON (t.ID = s.ID) WHEN MATCHED
           THEN UPDATE SET' at line 1

      CONTROLE - um MERGE PERFEITAMENTE VALIDO recebe o MESMO ERROR 1064:
        MERGE ... WHEN MATCHED THEN UPDATE SET t.NOME = 'x';
        -> ERROR 1064 (42000): ... near 'MERGE INTO ...' at line 1
      Ou seja: em MySQL a recusa nao e da forma nua, e da palavra MERGE - ela
      nao existe na gramatica. Registrado como controle justamente para nao
      confundir "recusa a forma" com "recusa a instrucao".

  (6) SQLite 3.53.4  (docker run --rm -i keinos/sqlite3:latest sqlite3 :memory:)

      As duas formas:
        -> Parse error: near "MERGE": syntax error
      Mesma leitura do MySQL: MERGE nao existe em SQLite.

  ------------------------------------------------------------------------------
  LEITURA
  ------------------------------------------------------------------------------
  Nos QUATRO motores que TEM MERGE (MSSQL, PostgreSQL, Oracle, Firebird) as duas
  formas sao recusadas por SINTAXE, e o controle do PostgreSQL e o ORA-00926 do
  Oracle mostram exatamente o porque: a lista de atribuicoes do UPDATE e
  obrigatoria, e o INSERT do MERGE exige VALUES(...) ou DEFAULT VALUES. Nos
  outros DOIS (MySQL, SQLite) a instrucao inteira nao existe - a biblioteca ja
  levanta EFluentSQLStatementNotSupported antes de emitir texto.

  Zero motores aceitam. Nao ha caminho em que essas duas chamadas produzam algo
  executavel, entao nao existe "limitacao conhecida" a documentar para o
  consumidor se desviar: e defeito, e as duas passam a levantar
  EArgumentException na chamada, junto com a guarda de contagem impar.

  Travado por, em Test Delphi\MSSQL_tests\test.merge.mssql.pas:
    TestMerge_UpdateEmptyArray_RaisesInsteadOfEmittingUpdateSetSemicolon
    TestMerge_InsertEmptyArray_RaisesInsteadOfEmittingBareInsert
    TestMerge_UpdateNoArgs_RaisesInsteadOfEmittingUpdateSetSemicolon
    TestMerge_InsertNoArgs_RaisesInsteadOfEmittingBareInsert
    TestMerge_RaisedGuard_LeavesNoHalfClauseInSql

  ==============================================================================
  nil EM POSICAO DE VALOR  -  corrigido nesta branch
  ==============================================================================
  Nao ha SQL a medir aqui, porque o defeito nao produzia SQL invalido: produzia
  SQL VALIDO com o dado ERRADO, o que e pior, porque nenhum motor reclama.

  `nil` escrito num array of const chega como vtPointer, e
  TUtils._VarRecToString mapeia vtPointer por IntToHex. Em 32 bits o resultado e
  a string '00000000'. Portanto:

    .Update(['NOME', nil])   ->  SET [NOME] = :p1   com  p1 = '00000000'

  e o SQL Server grava OITO ZEROS na coluna NOME, sem erro, sem aviso. O usuario
  escreveu nil querendo NULL e recebeu uma string de lixo.

  O par nome/valor NAO tem como exprimir NULL: o slot par e sempre ligado como
  parametro e nao existe marcador de nulidade nesta API. Entre gravar lixo
  calado e recusar a chamada, recusa - EArgumentException, mesma classe das
  outras guardas. Dar semantica de NULL ao nil e decisao de CONVENCAO, nao
  conserto de defeito, e por isso NAO foi feita aqui: se a coluna deve ficar
  NULL, omita-a da lista de pares.

  Travado por:
    TestMerge_UpdateNilValue_RaisesInsteadOfCorruptingDataAsHexString
    TestMerge_InsertNilValue_RaisesInsteadOfCorruptingDataAsHexString

  ==============================================================================
  FRONTEIRA  -  o que esta correcao NAO fecha
  ==============================================================================

  (1) O NOME DA COLUNA (slot impar) CONTINUA INJETAVEL.
      O valor foi parametrizado; o identificador nao pode ser, e o QuotedName do
      MSSQL (FluentSQL.SerializeMSSQL.pas:248) envolve em colchetes SEM duplicar
      o ']' de dentro. Vale IGUAL na base e nesta branch - nao e regressao, e
      nao foi introduzido aqui.

      Nao basta um ']' solto: com nome "NOME]; DROP TABLE USERS; --" o texto sai
      "SET [NOME]; DROP TABLE USERS; --] = @p1;" e o motor recusa com Msg 102
      (near ';'), porque o SET fica sem atribuicao. Mas um payload que FECHA o
      colchete e COMPLETA a atribuicao passa. Nome de coluna:

        NOME] = 'x'; DROP TABLE USERS; --

      emitido pela biblioteca:
        MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)
          WHEN MATCHED THEN UPDATE SET [NOME] = 'x'; DROP TABLE USERS; --] = @p1;

        SELECT COUNT(*) FROM USERS;   -- antes: 2
        <executa>                     -- (1 rows affected), sem erro
        SELECT CASE WHEN OBJECT_ID('USERS') IS NULL ...
          RESULTADO
          ------------------------------------------------------
          USERS FOI DROPADA - NOME DE COLUNA E INJETAVEL DE FATO

      Ou seja: num documento chamado "injecao via MERGE", a metade do VALOR
      fechou e a metade do IDENTIFICADOR nao. Escape de delimitador de
      identificador e decisao de arquitetura propria - toca todos os QuotedName
      e Quote dos 9 dialetos, e colide com o passthrough por StartsWith/Contains
      que hoje permite passar nome ja qualificado. Fica para essa tarefa.
      Travado por TestMerge_ColumnNamesStayLiteral_OnlyValuesBecomeParams, que
      afirma que o slot continua literal.

  (2) Merge.On(array of const) CONTINUA INTERPOLANDO VERBATIM.
      Mesmo builder de MERGE, outro caminho: On([...]) passa por
      SqlArrayOfConstToParameterizedSql (FluentSQL.Merge.pas:298), onde a RN-P3
      trata string como FRAGMENTO de SQL e nao como valor - por isso nao foi
      tocado aqui. Emitido hoje:

        .On(['t.NOME =', 'x''; DROP TABLE USERS; --'])
          -> ON (t.NOME = x'; DROP TABLE USERS; --)

      O escalar numerico ali VIRA parametro (.On(['ID =', 100]) -> ON (ID = :p1));
      so a string e que segue literal. A distincao valor x expressao por tras
      disso e tarefa de arquitetura propria.

  (3) OS OUTROS OITO DIALETOS nao tem oraculo porque nenhum deles emite MERGE:
      cinco levantavam EStackOverflow antes desta branch e agora levantam
      EFluentSQLStatementNotSupported, dois nao estao compilados no .inc, e o
      MongoDB descarta a clausula (e ainda acumula 1 parametro orfao). Onde nao
      ha SQL emitido, nao ha SQL para executar. A matriz completa esta em
      test.merge.matrix.pas.
*/
