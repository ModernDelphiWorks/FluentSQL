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
  FRONTEIRA
  ==============================================================================
  Nao medido em motor real: os outros oito dialetos, porque nenhum deles emite
  MERGE (cinco levantavam EStackOverflow antes desta branch, dois nao estao
  compilados no .inc, e o MongoDB descarta a clausula). Nao ha SQL para executar
  onde nao ha SQL emitido.
*/
