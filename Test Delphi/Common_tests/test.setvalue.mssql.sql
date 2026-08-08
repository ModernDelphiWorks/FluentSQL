/*
  ORACULO DE MOTOR REAL - T6a / SetValue e Values (array of const)
  ==============================================================================

  Motor:     Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
             Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)
  Container: docker run -d --name t6a-mssql \
               -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Fluent#T6a2026" \
               -p 14333:1433 mcr.microsoft.com/mssql/server:2022-latest
  Cliente:   /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -d t6a

  Este arquivo mede um caminho DIFERENTE do de test.merge.mssql.sql. La e o
  MERGE; aqui e o INSERT/UPDATE comum, pelos overloads

    IFluentSQL.SetValue(const AColumnName: String; const AColumnValue: array of const)
    IFluentSQL.Values  (const AColumnName: String; const AColumnValue: array of const)

  Os dois desembocam em TFluentSQL._InternalSet, que afirma a propria posicao com
  _AssertSection([secInsert, secUpdate]): o array e o lado DIREITO de
  "COLUNA = ...", ou seja, posicao de VALOR - nunca de expressao.

  O DEFEITO era de ASSIMETRIA dentro do MESMO slot: o escalar numerico
  parametrizava e a string ia VERBATIM para o texto do SQL, sem aspas e sem
  escape.

    .SetValue('NOME', ['TESTE']).SetValue('NIVEL', [7])
      antes ->  INSERT INTO USUARIOS (NOME, NIVEL) VALUES (TESTE, :p1)   1 param
      depois->  INSERT INTO USUARIOS (NOME, NIVEL) VALUES (:p1, :p2)     2 params

  ==============================================================================
  ESTADO INICIAL
  ==============================================================================
    CREATE TABLE USERS (ID INT IDENTITY, NOME VARCHAR(200));
    INSERT INTO USERS (NOME) VALUES ('admin'),('ana');
    SELECT COUNT(*) AS ANTES FROM USERS;
      ANTES
      -----------
                2

  ==============================================================================
  ANTES  (arvore e9ed0b9)  -  o texto abaixo foi EMITIDO pela biblioteca
  ==============================================================================

  --- CASO 1  BENIGNO    .SetValue('NOME', ['TESTE'])
  Emitido (0 parametros):
    INSERT INTO USERS (NOME) VALUES (TESTE)
  Motor respondeu:
    Msg 207, Level 16, State 1, Line 1
    Invalid column name 'TESTE'.
  Leitura: o caso BENIGNO ja era SQL invalido. Sem aspas, o motor le o valor como
  nome de coluna. Nao e so seguranca - a funcionalidade nunca funcionou.

  --- CASO 2  LEGITIMO   .SetValue('NOME', ['O''Brien'])
  Emitido (0 parametros):
    INSERT INTO USERS (NOME) VALUES (O'Brien)
  Motor respondeu:
    Msg 105, Level 15, State 1, Line 1
    Unclosed quotation mark after the character string 'Brien)
    '.
    Msg 102, Level 15, State 1, Line 1
  Leitura: a aspa legitima quebra o batch.

  --- CASO 3  HOSTIL COM ASPA   .SetValue('NOME', ['x''; DROP TABLE USERS; --'])
  Emitido (0 parametros):
    INSERT INTO USERS (NOME) VALUES (x'; DROP TABLE USERS; --)
  Motor respondeu:
    Msg 105, Level 15, State 1, Line 1
    Unclosed quotation mark after the character string '; DROP TABLE USERS; --)
    '.
    Msg 102, Level 15, State 1, Line 1
    Incorrect syntax near '; DROP TABLE USERS; --)
    SELECT CASE WHEN OBJECT_ID('USERS') IS NULL ...
      RESULTADO
      -----------------
      USERS INTACTA

  ATENCAO - LEITURA HONESTA DESTE CASO: com ESTE payload a tabela NAO caiu. A
  aspa simples do payload ABRE um literal que engole o resto do comando, e o
  batch morre antes do DROP. Ou seja: o payload que funciona no MERGE (onde o
  valor nao e delimitado nem cercado por parenteses) NAO funciona aqui.
  Registrado porque afirmar "a tabela caiu" para este caso seria falso - e a
  regra desta suite e medir, nao supor.

  --- CASO 4  HOSTIL SEM ASPA   .SetValue('NOME', ['1); DROP TABLE USERS; --'])
  O payload certo para ESTA gramatica nao precisa de aspa nenhuma: basta FECHAR o
  parenteses do VALUES e encerrar o comando.
  Emitido (0 parametros):
    INSERT INTO USERS (NOME) VALUES (1); DROP TABLE USERS; --)

    SELECT COUNT(*) FROM USERS;   -- antes: 2
    <executa o INSERT acima>      -- (1 rows affected), SEM ERRO
    SELECT CASE WHEN OBJECT_ID('USERS') IS NULL
                THEN 'USERS FOI DROPADA - INJECAO BEM SUCEDIDA'
                ELSE 'USERS INTACTA' END AS RESULTADO;
      RESULTADO
      ----------------------------------------
      USERS FOI DROPADA - INJECAO BEM SUCEDIDA

  Leitura: injecao executavel, sem erro nenhum no caminho, por um valor passado a
  IFluentSQL.SetValue - API publica, INSERT comum, nada de exotico. Nao e
  teorico e nao depende do MERGE.

  ==============================================================================
  DEPOIS  (branch fix/merge-parameterization)
  ==============================================================================

  Nos QUATRO casos a biblioteca emite o mesmo texto:
    INSERT INTO USERS (NOME) VALUES (:p1)
  com 1 parametro, p1 = <valor intacto>.

  Executado com o valor ligado como parametro (:p1 -> @p1, que e o que qualquer
  driver faz ao consumir IFluentSQLParams):

  --- CASO 4  HOSTIL SEM ASPA  (antes: tabela dropada)
    EXEC sp_executesql
      N'INSERT INTO USERS (NOME) VALUES (@p1);',
      N'@p1 VARCHAR(200)', @p1 = '1); DROP TABLE USERS; --';
    (1 rows affected)
    SELECT NOME FROM USERS WHERE NOME LIKE '%DROP%';
      NOME
      -------------------------
      1); DROP TABLE USERS; --
    SELECT CASE WHEN OBJECT_ID('USERS') IS NULL ...
      RESULTADO
      ------------------------------------
      USERS INTACTA - INJECAO NEUTRALIZADA

  --- CASO 1  BENIGNO  (antes: Msg 207, Invalid column name 'TESTE')
    EXEC sp_executesql
      N'INSERT INTO USERS (NOME) VALUES (@p1);',
      N'@p1 VARCHAR(200)', @p1 = 'TESTE';
    (1 rows affected)
    SELECT NOME FROM USERS WHERE NOME = 'TESTE';
      NOME
      -----
      TESTE

  O payload virou DADO da coluna, que e exatamente o certo - nao foi escapado
  nem rejeitado, foi tratado como o texto que sempre foi. E o CASO 1 (benigno)
  passou a FUNCIONAR, que antes nem isso.

  ==============================================================================
  CARDINALIDADE DO SLOT DE VALOR  -  medicao em SEIS motores
  ==============================================================================

  Duas formas que o overload emitia CALADO antes da guarda _AssertSingleValue
  (FluentSQL.Utils.pas:263, chamada em :285). Medidas em execucao real ANTES da forma
  da correcao, cada recusa acompanhada de um CONTROLE - sem controle, "o motor
  recusou" nao distingue recusa da FORMA de recusa da INSTRUCAO.

  Containers (todos ja em execucao nesta maquina, docker 29.6.2):
    docker exec -i t6a4mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P ... -C
    docker exec -i -e PGPASSWORD=pg t6a4pg psql -U postgres
    docker exec -i t6a4my mysql -uroot -pmy --force -t
    docker exec -i t6a4fb isql -u sysdba -p fb /var/lib/firebird/data/test.fdb -e
    docker exec -i t6a4ora sqlplus -S system/ora@localhost/FREEPDB1
    docker run  --rm -i keinos/sqlite3:latest sqlite3 :memory:
  Esquema comum:  CREATE TABLE T2 (D varchar(10), E varchar(10));

  --- FORMA A  lista vazia   .SetValue('D', [])
      emitia    INSERT INTO T2 (D) VALUES ();      e     UPDATE T2 SET D = ;

      MSSQL 2022 16.0.4265.3  Msg 102 Incorrect syntax near ')'
                              Msg 102 Incorrect syntax near ';'
      PostgreSQL 16.14        ERROR: syntax error at or near ")"
                              ERROR: syntax error at or near ";"
      Oracle Free 23          ORA-00936: missing expression   (as duas formas)
      Firebird 5.0.4          -104 Token unknown - line 1, column 28  ')'
                              -104 Unexpected end of command - line 1, column 17
      MySQL 8.4.11            ERROR 1136 Column count doesn't match value count
                              ERROR 1064 ... near '' at line 1
      SQLite 3.53.4           Parse error near ")": syntax error
                              Parse error near ";": syntax error

      ZERO dos seis aceitam. Nuance registrada: o MySQL recusa por CONTAGEM
      (1136) e nao por gramatica - "INSERT INTO T2 () VALUES ()" com zero
      colunas e legal la. A forma que o FluentSQL emitia nomeia a coluna, logo
      cai no 1136 de qualquer modo.

  --- FORMA C  placeholders JUSTAPOSTOS   .SetValue('D', ['CURRENT','TIMESTAMP'])
      emitia    INSERT INTO T2 (D,E) VALUES (:p1 :p2)     -- sem virgula

      MSSQL                   Msg 102 Incorrect syntax near '@p2'
      PostgreSQL 16.14        ERROR: syntax error at or near "$2"
      Firebird 5.0.4          -104 Token unknown - line 1, column 32  '?'
      MySQL 8.4.11            ERROR 1064 ... near '?)' at line 1
      SQLite 3.53.4           Parse error near "?": syntax error
      Oracle Free 23          ORA-00947: not enough values      <-- LEIA ABAIXO

      CONTROLE (mesma tabela, mesmos binds, so a virgula muda):
        INSERT INTO T2 (D,E) VALUES (:p1, :p2)   ACEITO nos SEIS.
      Logo a recusa e da FORMA justaposta, e nao do INSERT.

  --- ORACLE E A EXCECAO, E ELA E PIOR QUE UMA RECUSA
      O Oracle NAO recusa a justaposicao por gramatica. O ORA-00947 acima diz
      "not enough values": ele leu ":p1 :p2" como UM valor so. E a sintaxe de
      VARIAVEL INDICADORA do Oracle (:host:indicator), onde o segundo bind e o
      indicador de nulidade do primeiro, e nao um segundo valor.

      Consequencia medida: com UMA coluna a mesma forma e ACEITA e grava dado
      errado, calada.

        SQL> INSERT INTO T2 (D) VALUES (:p1 :p2);     -- :p1='a'  :p2='b'
        1 row created.
        SQL> SELECT D, E FROM T2;
        D          E
        ---------- ----------
        a          z
        a

      Gravou 'a' e DESCARTOU :p2 sem erro nenhum. Ou seja, dos seis motores um
      aceita a forma - e justamente aceitando-a produz perda silenciosa de
      valor, que e pior que o erro de sintaxe dos outros cinco. Isso REFORCA a
      guarda em vez de enfraquece-la: o unico motor que nao protege o usuario
      pela sintaxe e o que mais precisa da protecao na biblioteca.

      (Nao escreva "zero aceitam" para esta forma. Para a FORMA A, sim.)

  --- MERGE SEM NENHUMA CLAUSULA WHEN   (guarda em FluentSQL.Merge.pas:296)
      emitia    MERGE INTO T2 t USING T2 s ON (t.D = s.D);

      MSSQL                   Msg 102 Incorrect syntax near ';'
      PostgreSQL 16.14        ERROR: syntax error at or near ";"
      Oracle Free 23          ORA-02000: missing WHEN keyword
      Firebird 5.0.4          -104 Unexpected end of command - line 1, column 41
      MySQL 8.4.11            ERROR 1064  -  nao tem MERGE
      SQLite 3.53.4           Parse error near "MERGE"  -  nao tem MERGE

      CONTROLE (mesmo texto + uma clausula):
        MERGE INTO T2 t USING T2 s ON (t.D = s.D)
          WHEN MATCHED THEN UPDATE SET t.E = 'z';
        MSSQL "(0 rows affected)" / PG "MERGE 0" / Oracle "1 row merged." /
        Firebird sem erro.  ACEITO nos quatro que tem MERGE.
      Logo a recusa e da forma SEM WHEN, e nao do MERGE.

  ==============================================================================
  ONDE ISTO ESTA TRAVADO NA SUITE
  ==============================================================================
    Test Delphi\Common_tests\test.core.params.pas
      TestSetValueArrayOfConstStringBecomesParam
      TestValuesArrayOfConstStringBecomesParam
      TestSetValueArrayOfConstHostileStringNeverReachesSqlText
      TestSetValueArrayOfConstNilRaisesInsteadOfWriting00000000
      TestValuesArrayOfConstNilRaisesInsteadOfWriting00000000
      TestUpdateSetValueArrayOfConstNilRaises
      TestSetValueArrayOfConstEmptyRaisesInsteadOfEmittingValuesEmpty
      TestValuesArrayOfConstEmptyRaises
      TestUpdateSetValueArrayOfConstEmptyRaisesInsteadOfDanglingSet
      TestSetValueArrayOfConstTwoElementsRaisesInsteadOfJuxtaposedParams
      TestSetValueArrayOfConstRejectedCallLeavesNoHalfColumn

    Test Delphi\MSSQL_tests\test.merge.mssql.pas
      TestMerge_NoWhenClause_RaisesInsteadOfEmittingHeaderOnly

  Os onze primeiros rodam nos projetos Firebird e MySQL, que sao os dois que
  compilam test.core.params.pas.

  Prova de que nao sao decoracao (mutacao no Source, suite inteira recompilada):
    vtPointer -> "if False"                 6 vermelhos: os 3 de nil, em CADA um
                                            dos dois projetos. (Antes desta
                                            rodada essa mutacao so derrubava os
                                            2 testes de MERGE, no MSSQL.)
    _AssertSingleValue comentado           10 vermelhos: os 5 de cardinalidade,
                                            em CADA um dos dois projetos.
    "FMatchedClauses.Count = 0" -> False     1 vermelho: o de MERGE sem WHEN.

  ==============================================================================
  FRONTEIRA  -  o que esta correcao NAO fecha
  ==============================================================================

  (1) O NOME DA COLUNA continua literal e nao escapado - mesma fronteira do
      MERGE, ver test.merge.mssql.sql. Nao construa nome de coluna a partir de
      entrada nao confiavel.

  (2) array of const em posicao de EXPRESSAO segue interpolando string verbatim,
      de proposito - la a string PODE ser fragmento de SQL (identificador,
      operador, trecho). Isso NAO vale para meia duzia de metodos: vale para
      TODO array of const que nao seja um dos quatro slots de VALOR. Hoje sao
      17 pontos de entrada publicos; uma versao anterior desta secao listava 6,
      omitindo 11 - entre eles AndOpe, que e a forma mais comum da API logo
      depois do Where.

      REGRA (audite isto, nao a lista):
        passa por TUtils.SqlArrayOfConstToParameterizedSql   -> string LITERAL
        passa por TUtils.SqlArrayOfConstToParameterizedValue -> string vira :pN
      Nao ha terceiro caminho.

      Os 17 literais, conferidos no codigo e executados um a um:

        IFluentSQL                    Where          FluentSQL.pas:1422
                                      AndOpe         FluentSQL.pas:367
                                      OrOpe          FluentSQL.pas:372
                                      Column         FluentSQL.pas:664
                                      Having         FluentSQL.pas:968
                                      OnCond         FluentSQL.pas:420
                                      CaseExpr       FluentSQL.pas:342
                                      ForDialectOnly FluentSQL.pas:325
                                      Expression     FluentSQL.pas:873
        IFluentSQLCriteriaExpression  AndOpe         FluentSQL.Expression.pas:261
                                      OrOpe          FluentSQL.Expression.pas:344
                                      Ope            FluentSQL.Expression.pas:358
                                      Fun            FluentSQL.Expression.pas:318
        IFluentSQLCriteriaCase        When           FluentSQL.Cases.pas:346
                                      AndOpe         FluentSQL.Cases.pas:267
                                      OrOpe          FluentSQL.Cases.pas:317
        IFluentSQLMerge               On             FluentSQL.Merge.pas:376

      Amostra do emitido, payload  x'; DROP TABLE U; --  :

        AndOpe(array)         => SELECT * FROM T WHERE (A = :p1) AND (NOME = x'; DROP TABLE U; --)   params=1
        OrOpe(array)          => SELECT * FROM T WHERE ((A = :p1) OR (NOME = x'; DROP TABLE U; --))  params=1
        Expression(array)     => SELECT * FROM T WHERE NOME = x'; DROP TABLE U; --                   params=0
        ForDialectOnly(array) => SELECT * FROM TOPTION(x'; DROP TABLE U; --)                         params=0

      Os quatro slots de VALOR - os unicos que mudaram - sao SetValue, Values,
      Merge.Update e Merge.Insert, porque neles o array e comprovadamente uma
      lista de valores.
      A distincao valor x expressao e tarefa de arquitetura propria.

  (3) nil em posicao de valor NAO virou NULL: passou a LEVANTAR. Ver a secao
      "nil EM POSICAO DE VALOR" em test.merge.mssql.sql - a causa e o mesmo
      _StringVarRecAsParam, compartilhado pelos dois caminhos.
*/
