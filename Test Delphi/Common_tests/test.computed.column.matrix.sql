/*
  ------------------------------------------------------------------------------
  ORACULO DA COLUNA COMPUTADA + VARREDURA DOS ORACULOS DE TEXTO DA SUITE  (T27)

  Este arquivo tem DOIS conteudos, e o segundo e o maior:

    PARTE I   a medicao que justifica a correcao da coluna computada do T-SQL.
    PARTE II  a VARREDURA: os 626 enunciados SQL que a suite produz, submetidos
              um a um a motor real, dialeto por dialeto, com o metodo declarado
              e a lista nominal do que cada motor RECUSA.

  A Parte II existe porque a T27 nao nasceu de um defeito: nasceu da descoberta
  de que a suite contem celulas VERDES que fixam SQL que o motor recusa. A
  pergunta da tarefa nao era "conserte esta celula", era "QUANTAS OUTRAS
  EXISTEM?". Sem esta transcricao a resposta nao e reproduzivel por ninguem.

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
    Firebird    LI-V5.0.4.1812 Firebird 5.0, ODS 13.1, SQL dialect 3
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0
                gvenzl/oracle-free:23-slim
                sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8
    SQLite      3.53.4 2026-07-24 19:02:57
                keinos/sqlite3:latest
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
    DB2         DB2/LINUXX8664 12.1.5.0
                icr.io/db2_community/db2:latest
                sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6
    InterBase   NAO MEDIDO - nao existe imagem publica. 50 enunciados ficaram
                sem submissao. Nao ha afirmacao alguma sobre este dialeto aqui.

  Os containers foram criados com prefixo proprio t27-* justamente para nao
  tocar os de outra tarefa em paralelo (t26-*), e derrubados no fim.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  PARTE I - A COLUNA COMPUTADA

  O DEFEITO: o oraculo de test.ddl.mssql.pas fixava, VERDE,

    CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT,
                           [TOTAL] INT AS (QTD * PRECO))

  e o SQL Server RECUSA esse texto. A gramatica de
  <computed_column_definition> no T-SQL e "column_name AS
  computed_column_expression": nao ha <data_type> nela.

  ------------------------------------------------------------------------------
  I.1  SQL SERVER - metodo SET PARSEONLY ON

  PARSEONLY faz o servidor PARSEAR e nao executar nem resolver nome. E o metodo
  mais limpo dos sete: mede gramatica pura, sem efeito colateral e sem precisar
  que objeto nenhum exista.

    docker run -d --name t27-mssql -e ACCEPT_EULA=Y \
      -e 'MSSQL_SA_PASSWORD=T27#pass_2026' mcr.microsoft.com/mssql/server:2022-latest
    docker exec t27-mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'T27#pass_2026' -C -i /tmp/po_test.sql

  Transcricao literal:

    PRINT '###1'
    GO
    SET PARSEONLY ON
    GO
    SELECT * FROM NAO_EXISTE_TABELA_XYZ
    GO
    SET PARSEONLY OFF
    GO
    PRINT '###2'
    GO
    SET PARSEONLY ON
    GO
    CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT, [TOTAL] INT AS (QTD * PRECO))
    GO
    SET PARSEONLY OFF
    GO
    PRINT '###3'
    GO
    SET PARSEONLY ON
    GO
    CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT, [TOTAL] AS (QTD * PRECO))
    GO
    SET PARSEONLY OFF
    GO
    PRINT '###4'
    GO

  SAIDA:

    ###1
    ###2
    Msg 156, Level 15, State 1, Server 7c035481c1e7, Line 1
    Incorrect syntax near the keyword 'AS'.
    ###3
    ###4

  TRES leituras, nao uma:
    * entre ###1 e ###2 nao ha erro: PARSEONLY nao reclama de tabela
      inexistente. E isso que autoriza usar o metodo sem montar esquema.
    * entre ###2 e ###3 esta o defeito: a forma COM tipo devolve Msg 156.
    * entre ###3 e ###4 nao ha erro: a forma SEM tipo parseia limpo.
      A correcao esta medida, nao suposta.

  ------------------------------------------------------------------------------
  I.2  OS OUTROS CINCO - por que a correcao NAO pode ir para o caminho comum

  A correcao obvia seria "parar de emitir o tipo antes da clausula de
  computacao". Ela conserta o T-SQL e QUEBRA o PostgreSQL.

  PostgreSQL 16.14 - as TRES medicoes que separam o que a matriz afirma do que
  ela nao afirma:

    docker exec -e PGPASSWORD=t27pass t27-pg psql -U postgres -f /tmp/c.sql

    \set VERBOSITY verbose
    \warn ### A: como o framework emite hoje
    BEGIN; CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER,
      "TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PRECO) STORED); ROLLBACK;
    \warn ### B: mesma sentenca com a expressao delimitada
    BEGIN; CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER,
      "TOTAL" INTEGER GENERATED ALWAYS AS ("QTD" * "PRECO") STORED);
      SELECT 'CRIOU-OK'; ROLLBACK;
    \warn ### C: sem o tipo (a alternativa recusada nesta tarefa)
    BEGIN; CREATE TABLE "V2" ("QTD" INTEGER,
      "TOTAL" GENERATED ALWAYS AS ("QTD" * 2) STORED); ROLLBACK;

  SAIDA:

    ### A: como o framework emite hoje
    BEGIN
    psql:/tmp/c.sql:4: ERROR:  42703: column "qtd" does not exist
    LINE 1: ...CO" INTEGER, "TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PREC...
                                                                 ^
    ### B: mesma sentenca com a expressao delimitada
    BEGIN
    CREATE TABLE
     CRIOU-OK
    ### C: sem o tipo (a alternativa recusada nesta tarefa)
    BEGIN
    psql:/tmp/c.sql:8: ERROR:  42601: syntax error at or near "ALWAYS"
    LINE 1: ...EATE TABLE "V2" ("QTD" INTEGER, "TOTAL" GENERATED ALWAYS AS ...
                                                                 ^

  LEITURA, e ela e a razao de existir do gancho de dialeto:

    C prova que o PostgreSQL EXIGE o tipo. Tirar o tipo para todos trocaria um
    dialeto quebrado por outro. Por isso ComputedColumnCarriesType tem default
    True e SO o MSSQL sobrescreve.

    A prova que ESTA CELULA continua fixando texto recusado (A). Isso e um
    defeito ABERTO e de OUTRA tarefa - o gerador delimita o NOME e repassa a
    EXPRESSAO crua, e o PG dobra a expressao para minuscula. E a T22
    (delimitacao de identificador), parada esperando decisao do dono. B mostra
    qual sera a forma correta quando ela fechar.

    A celula correspondente em test.computed.column.matrix.pas carrega este
    aviso no corpo, e nao esta [Ignore]ada de proposito: desligada, ela deixaria
    de segurar o anti-colateral e a mutacao "default -> False" voltaria a passar.

  MySQL 8.4.11, Oracle 23.26.2.0.0 e Firebird 5.0.4 ACEITAM o tipo - por isso
  nenhum deles sobrescreve o gancho:

    MySQL      `TOTAL` INT AS (QTD * PRECO) VIRTUAL
    Oracle     "TOTAL" NUMBER(10) GENERATED ALWAYS AS (QTD * PRECO) VIRTUAL
    Firebird   "TOTAL" INTEGER COMPUTED BY (QTD * PRECO)

  SQLite nao entra: levanta ENotSupportedException antes de emitir texto.

  Ou seja, dos SEIS serializadores DDL: 4 a favor do tipo, 1 contra (MSSQL),
  1 fora da conta (SQLite, que nao emite). O default True nao e "cinco votaram" -
  o SQLite nao vota.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  PARTE II - A VARREDURA DOS ORACULOS DE TEXTO

  II.1  COMO O CORPUS FOI LEVANTADO - e por que NAO por leitura de codigo

  Extracao estatica dos Assert.AreEqual nao funciona aqui: boa parte dos
  oraculos e COMPOSTA em runtime (Format, concatenacao, tabelas por dialeto em
  test.alias.matrix.pas e irmaos). Regex sobre .pas devolveria um numero
  bonito e errado.

  O corpus foi colhido do RUNTIME. Numa COPIA DESCARTAVEL do Source (o repo
  nunca foi tocado) instrumentei 27 pontos:

      FluentSQL.pas          TFluentSQL.AsString, apos
                             "Result := FRegister.Serialize(FDatabase).AsString(FAST);"
      FluentSQL.Merge.pas    TFluentSQLMerge.AsString, apos
                             "Result := LReg.Serialize(FDialect).AsString(FAST);"
      FluentSQL.DDL.Serialize.pas
                             os 25 metodos, todos da mesma forma, apos
                             "Result := LReg.DDLSerialize(ADef.Dialect).<X>(ADef);"

  cada um gravando "<DIALETO>\t<SQL>" num arquivo por runner. Depois rodei a
  suite INTEIRA nas duas configuracoes de build e deduplicquei por
  (dialeto, texto).

  NEUTRALIDADE DA INSTRUMENTACAO - medida, nao afirmada: com os 27 pontos
  ligados a suite deu exatamente 662/596/20/46 (sem defines) - identico, caso a
  caso, a medicao SEM instrumentacao da mesma arvore. A colheita nao altera o
  que ela mede. (Conferido tambem na arvore anterior ao merge, onde o par era
  652/586/20/46; o numero que vale e sempre o da arvore que se esta medindo.)

  O QUE ISSO COLHE, COM PRECISAO: o texto PRODUZIDO, nao o literal FIXADO. Nas
  celulas verdes os dois coincidem - e isso que torna o metodo valido, e VER
  II.6, onde essa premissa foi finalmente MEDIDA e achada falsa em 12 celulas.

  O QUE ISSO NAO COLHE: os 20 testes [Ignore]ados nao rodam, logo nao produzem
  texto. Eles foram conferidos a parte, por leitura - todos os 20 sao divida T6
  ja declarada, com razao escrita no proprio atributo. Nenhum deles e "celula
  verde mentindo": estao honestamente desligados.

  II.2  O CORPUS

    colheitas brutas (2 configuracoes) ....................... 2558
    distintos por (dialeto, texto) ...........................  725
      MongoDB - fora da promessa multi-banco, nao e SQL .......   49
      relacionais ............................................  676
        InterBase - NAO MEDIDO, sem imagem publica ...........   50
        SUBMETIDOS A MOTOR REAL ..............................  626

  Conferido contra a ARVORE FINAL desta branch, ja com a main mergeada, e nao
  contra a arvore em que a varredura comecou. O merge trouxe
  test.delete.multirelacao.pas, que acrescentou 24 enunciados distintos - 3 por
  dialeto, nos 8 relacionais:
      SELECT * FROM A, B
      SELECT * FROM A AS X, B AS Y      (no Oracle: SELECT * FROM A X, B Y)
      DELETE FROM B WHERE (ID = :p1)    (no MySQL: ID = ?)
  Nenhum enunciado DESAPARECEU no merge. Os 21 novos submetiveis foram
  efetivamente SUBMETIDOS, nao presumidos: a varredura inteira foi refeita nos
  sete motores sobre este corpus, com os containers recriados do zero.

  II.3  O QUE FOI SUBMETIDO - a substituicao de parametro, explicita

  :pN e ? NAO sao SQL: sao a convencao de bind do framework, e quem os traduz e
  a camada de acesso. Submeter ":p1" cru mede a convencao de bind, nao a
  gramatica do gerador - o T-SQL devolve "Msg 102 Incorrect syntax near ':'"
  para QUALQUER sentenca que carregue o marcador, e esse ruido afogaria o sinal.

  (De proposito sem contagem aqui: quantas sentencas carregam marcador e funcao
  do corpus, e corpus muda a cada merge. O argumento nao muda - ele vale para
  uma sentenca ou para trezentas. Numero que depende do corpus apodrece; a razao
  de ser da substituicao, nao. Quem quiser a contagem tem a matriz de II.7.)

  As DUAS regex, literais, de corpus.py:

      PARAM = re.compile(r':p\d+')            # todos os dialetos -> '1'
      re.sub(r'(?<![\w])\?', '1', s)          # so MySQL          -> '1'

  Elas sao ESTREITAS de proposito. Comportamento demonstrado:

    entra  SELECT * FROM CLIENTES WHERE (NOME LIKE :p1)
    sai    SELECT * FROM CLIENTES WHERE (NOME LIKE 1)

    entra  SELECT ... TO_DATE(NASCTO,'dd/MM/yyyy') = :p1 TO_DATE('02/11/2020','dd/MM/yyyy')
    sai    SELECT ... TO_DATE(NASCTO,'dd/MM/yyyy') = 1 TO_DATE('02/11/2020','dd/MM/yyyy')
           -> a JUSTAPOSICAO sobrevive, e continua sendo recusada (DB2 SQL0104N).
              Uma regex mais larga como ':\w*' teria comido o marcador junto com
              a expressao e MASCARADO este defeito. Foi por isso que ela ficou
              em ':p\d+'.

    entra  CREATE OR ALTER PROCEDURE "SP_UPDATE_STOCK" (P_ID INT) AS
             BEGIN UPDATE STOCK SET QTY = 1 WHERE ID = :P_ID; END;
    sai    (inalterado)
           -> ':P_ID' e parametro de PSQL do Firebird, parte da LINGUAGEM, nao
              marcador de bind. ':p\d+' nao o alcanca. Correto.

    entra  SELECT * FROM PRODUTOS WHERE (PRECO > ?) AND (CATEGORIA IN (?, ?))
    sai    SELECT * FROM PRODUTOS WHERE (PRECO > 1) AND (CATEGORIA IN (1, 1))

  FICA DECLARADO: a varredura mede gramatica COM O PARAMETRO JA LIGADO. Ela
  nunca mede o marcador.

  II.4  METODO POR DIALETO - e o efeito colateral de cada um

    MSSQL       SET PARSEONLY ON por sentenca.
                So gramatica; NAO resolve nome. Nenhum efeito colateral.
    PostgreSQL  BEGIN; <sentenca>; ROLLBACK;
                DDL e transacional no PG: o CREATE executa DE VERDADE e e
                desfeito. Parse + analise. Nenhum efeito colateral.
    Firebird    isql com SET AUTODDL OFF e ROLLBACK por sentenca.
                DDL transacional. Nenhum efeito colateral.
    DB2         db2 +c (autocommit OFF) e ROLLBACK por sentenca.
                DDL transacional. Nenhum efeito colateral.
    SQLite      EXPLAIN <sentenca> numa base :memory: NOVA por sentenca.
                EXPLAIN prepara e nao executa; a base morre junto. Nenhum
                efeito colateral por construcao.
    MySQL       DDL do MySQL NAO e transacional. Cada sentenca roda num banco
                recem-criado (DROP DATABASE / CREATE DATABASE / USE) e o banco
                e descartado. Efeito colateral confinado e destruido.
    Oracle      DDL do Oracle NAO e transacional. DML via EXPLAIN PLAN FOR
                (parse + analise, nao executa); DDL executado num usuario
                descartavel (T27U), derrubado com DROP USER CASCADE no fim.

  VALIDAR GRAMATICA NAO E EXECUTAR. A diferenca esta acima, motor a motor, e a
  consequencia esta em II.7.

  II.5  O CONTROLE DO METODO - a varredura enxerga o que diz enxergar?

  Todo o desenho depende de UMA propriedade: o erro de SINTAXE e relatado ANTES
  do erro de OBJETO AUSENTE. Se fosse o contrario, submeter DML sem esquema
  mediria nada. Isso foi MEDIDO nos motores, nao deduzido do manual.

  CONTROLE (sentenca malformada EM TABELA INEXISTENTE) - todos acusam SINTAXE:

    Oracle      EXPLAIN PLAN FOR SELECT * FROM NAOEXISTE_ZZZ AS AP;
                ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    Oracle      EXPLAIN PLAN FOR SELECT * FROM NAOEXISTE_ZZZ WHERE ORDER BY;
                ORA-00936: missing expression
    PostgreSQL  SELECT * FROM naoexiste_zzz WHERE ORDER BY
                ERROR:  syntax error at or near "ORDER"
    MySQL       SELECT * FROM naoexiste_zzz WHERE ORDER BY
                ERROR 1064 (42000) ... near 'ORDER BY'
    Firebird    SELECT * FROM NAOEXISTE_ZZZ WHERE ORDER BY;
                SQLSTATE = 42000 / -SQL error code = -104 / -Token unknown - ORDER
    SQLite      EXPLAIN SELECT * FROM naoexiste_zzz WHERE ORDER BY;
                Parse error near line 1: near "ORDER": syntax error

    NOTA sobre o Oracle: o CODIGO depende da malformacao usada - 'AS' em relacao
    da ORA-03048, 'WHERE ORDER BY' da ORA-00936. Ambos sao da classe SINTAXE, e
    e a CLASSE que sustenta o metodo, nao o numero. Citar um codigo especifico
    como se fosse a assinatura do controle seria citar demais.

  RECIPROCA (sentenca BEM-FORMADA em tabela inexistente) - so objeto ausente,
  nenhum ruido de sintaxe:

    Oracle      EXPLAIN PLAN FOR SELECT * FROM NAOEXISTE_ZZZ;
                ORA-00942: table or view "SYSTEM"."NAOEXISTE_ZZZ" does not exist

  As duas metades juntas e que autorizam a leitura: erro de sintaxe => defeito
  de gramatica do gerador; erro de objeto => gramatica aceita, semantica nao
  medida.

  II.6  A PREMISSA QUE FALTAVA MEDIR - "produzido == fixado nas celulas verdes"

  A varredura colhe o PRODUZIDO e conclui sobre o FIXADO. Isso so vale se os
  dois coincidirem nas celulas verdes. Assert.AreEqual do DUnitX e
  CASE-INSENSITIVE por default, entao "verde" nao garante igualdade de texto.

  MEDICAO: injetei "Assert.IgnoreCaseDefault := False;" nos 11 runners, antes do
  TDUnitX.CheckCommandLine, reconstrui e rodei tudo:

  MEDIDO CONTRA A ARVORE FINAL DESTA BRANCH (a de 662 casos), nao contra a base.
  Os pares abaixo tem de fechar com a medicao de II.7-bis; se um dia lerem
  "582 -> 574" aqui, sao numeros de outra arvore e o documento apodreceu:

    sem defines ............... 46 -> 58 vermelhos   (596 -> 584 passed)
    com -DDB2 -DINTERBASE ..... 35 -> 47 vermelhos   (609 -> 597 passed)

  Delta 12 e 12 - o mesmo numero anunciado na linha seguinte, como tem de ser.
  Invariante conferida: 596 + 46 = 642 = 662 - 20, e 584 + 58 = 642.

  SAO 12 CELULAS HOJE VERDES cujo texto produzido difere do fixado em CAIXA.
  As MESMAS 12 nas duas configuracoes, todas em PTestFluentSQLFirebird:

    Test Delphi/Firebird_tests/test.operators.firebird.pas   -- 6 celulas
      TestWhereIsNull      fixa (NOME IS NULL)          emite (NOME is null)
      TestOrIsNull         fixa (... OR (NOME IS NULL))  emite (... OR (NOME is null))
      TestAndIsNull        fixa (NOME IS NULL)          emite (NOME is null)
      TestWhereIsNotNull   fixa (NOME IS NOT NULL)      emite (NOME is not null)
      TestOrIsNotNull      fixa (NOME IS NOT NULL)      emite (NOME is not null)
      TestAndIsNotNull     fixa (NOME IS NOT NULL)      emite (NOME is not null)

    Test Delphi/Firebird_tests/test.operators.like.firebird.pas -- 6 celulas
      TestLikeFull, TestLikeRight, TestLikeLeft
                           fixa (NOME LIKE :p1)         emite (NOME like :p1)
      TestNotLikeFull, TestNotLikeRight, TestNotLikeLeft
                           fixa (NOME NOT LIKE :p1)     emite (NOME not like :p1)

  ORIGEM, no nucleo - Source/Core/FluentSQL.Operators.pas, o MESMO case:

      235:    fcIn           : Result := 'IN';          <- MAIUSCULA
      236:    fcNotIn        : Result := 'NOT IN';      <- MAIUSCULA
      237:    fcIsNull       : Result := 'is null';     <- minuscula
      238:    fcIsNotNull    : Result := 'is not null'; <- minuscula
      239:    fcBetween      : Result := 'between';     <- minuscula, CODIGO MORTO
      240:    fcNotBetween   : Result := 'not between'; <- minuscula, CODIGO MORTO
      241:    fcExists       : Result := 'exists';      <- minuscula
      242:    fcNotExists    : Result := 'not exists';  <- minuscula
      246:    fcLikeRight    : Result := 'like';        <- minuscula
      250:    fcNotLikeRight : Result := 'not like';    <- minuscula

  ESTADO DA DIVIDA, conferido caso a caso. A distincao que importa nao e
  "tem teste ou nao tem" - e SE O RAMO E ALCANCAVEL:

    * as 6 de LIKE tem divida DECLARADA em
      test.operators.like.firebird.pas:18-41, que ate explica o mecanismo e
      marca com [Ignore] os dois unicos testes que ja comparavam com caixa.

    * as 6 de IS NULL NAO ESTAO DECLARADAS EM LUGAR NENHUM. Varri o repositorio
      por IgnoreCase / case-insensitive / caixa / minusculo e
      test.operators.firebird.pas nao tem uma linha sobre o assunto.

    * exists / not exists (241-242) SAO ALCANCAVEIS - ha produtor:
        Operators.pas:367   _CreateOperator('', AValue, fcExists,    dftText)
        Operators.pas:487   _CreateOperator('', AValue, fcNotExists, dftText)
      Tem o MESMO vicio de caixa e os unicos testes que os exercitam estao
      [Ignore]ados em test.operators.exists.firebird.pas:18-22, por outra razao
      (a subquery inteira vira parametro). ESTE e o exemplo honesto do limite
      declarado em II.8(e): ramo VIVO, com defeito, sem celula que possa cair.

    * between / not between (239-240) sao CODIGO MORTO, e nao "caminho sem
      cobertura". Nao existe produtor: um grep por fcBetween/fcNotBetween em
      todo o Source devolve TRES LINHAS, e NENHUMA DELAS E PRODUTOR - a
      declaracao no enum (Interfaces.pas:844) e os dois ramos do case acima
      (Operators.pas:239 e :240), que so traduzem o valor em texto. Nenhum
      metodo fluente atribui esses valores, entao nenhum teste PODERIA
      exercita-los e nenhum SQL com 'between' pode sair da biblioteca hoje.
      Compare com fcExists logo acima, que TEM produtor - e a comparacao que
      separa as duas situacoes.
      Isto e um achado desta varredura, mas de OUTRA familia: e da mesma
      especie dos "overrides mortos e inalcancaveis" que o CHANGELOG ja
      removeu, e nao da familia da caixa. Fica catalogado como tal.
      UMA REDACAO ANTERIOR DESTE ARQUIVO os listava como "SEM CELULA", o que
      fazia o leitor concluir que havia caminho VIVO com defeito e sem teste.
      Nao ha.

  NAO CORRIGIDO, E DE PROPOSITO: trocar 'is null' por 'IS NULL' muda o SQL
  emitido em TODOS os dialetos. E BREAKING de convencao e a decisao e do dono.
  Fica catalogado como tarefa propria. A remocao do codigo morto de between
  tambem nao e desta tarefa.

  CONSEQUENCIA HONESTA PARA ESTA VARREDURA: em 12 dos 626 enunciados o texto
  submetido ao motor e o produzido pela biblioteca, que NAO e byte a byte o
  fixado pelo oraculo. Como a diferenca e so de caixa e SQL e
  case-insensitive em palavra-chave, nenhum veredito da matriz muda - mas a
  premissa nao era universal, e agora esta medida em vez de suposta.

  II.7  A MATRIZ DA VARREDURA

  SAO TRES ESTADOS, NAO DOIS - e por isso sao tres colunas. Uma redacao anterior
  tinha so "aceitos" e "recusados", e enfiava o terceiro estado ora numa coluna
  ora na outra: o resultado foi uma tabela cuja coluna "aceitos" somava 595
  debaixo de um TOTAL que dizia 596. Os tres estados:

    ACEITO             o motor nao recusou o texto. Inclui o caso "objeto
                       ausente": a gramatica passou e a analise parou por falta
                       de tabela, o que NAO e recusa do texto (ver II.5). Inclui
                       tambem os artefatos do meu arnes, cada um refutado no
                       motor logo abaixo.
    RECUSADO/GERADOR   o motor recusa, e o texto e responsabilidade do gerador.
                       E O ACHADO DESTA VARREDURA.
    RECUSADO/CHAMADOR  o motor recusa, mas o trecho recusado foi escrito pelo
                       PROPRIO TESTE e so repassado verbatim - .Body('...'), o
                       literal '...', ou o fragmento de ForDialectOnly. O
                       gerador emitiu fielmente o que lhe pediram.

    dialeto      submetidos  aceitos  RECUSADO/  RECUSADO/
                                       GERADOR    CHAMADOR
    -----------  ----------  -------  ---------  ---------
    MSSQL              106      105          0          1
    PostgreSQL         102      101          1          0
    MySQL               80       77          2          1
    Firebird           160      152          6          2
    SQLite              54       54          0          0
    Oracle              67       67          0          0
    DB2                 57       56          1 (*)      0
    InterBase           50        -          -          -    NAO MEDIDO
    -----------  ----------  -------  ---------  ---------
    TOTAL              626      612         10          4

    Confere: 612 + 10 + 4 = 626, e a coluna de submetidos soma 626 sem o
    InterBase, que nao foi submetido a motor nenhum.

    (*) DB2, SQL0104N em
          SELECT * FROM CLIENTES WHERE TO_DATE(NASCTO,'dd/MM/yyyy')
                                       = :p1 TO_DATE('02/11/2020','dd/MM/yyyy')
        E recusa ATRIBUIVEL AO GERADOR - a justaposicao de placeholder e
        expressao e dele - mas o teste que a fixa (TestDate) JA ESTA VERMELHO na
        suite, nas duas configuracoes. Por isso ela conta na coluna do gerador e
        NAO entra nas 11 celulas VERDES da PARTE III. A distincao e o assunto
        inteiro desta tarefa: defeito conhecido e vermelho e divida declarada;
        defeito verde e oraculo mentindo.

    Logo: 10 recusas atribuiveis ao gerador, das quais 9 sao fixadas por celula
    VERDE (as da PARTE III, ja descontada a do MSSQL que esta corrigida) e 1 ja
    esta vermelha.

    MSSQL: era 1 recusa de gerador antes desta tarefa - a coluna computada.
    Depois da correcao reenviei os 106 enunciados sob PARSEONLY e deu 0. A unica
    mensagem restante e o corpo verbatim '...' do proprio teste.

  ARTEFATOS DO ARNES - cada um ISOLADO E REFUTADO no motor, nao presumido:

    MySQL DELIMITER   o cliente mysql corta a sentenca no ';' do corpo da
                      rotina. Com "DELIMITER $$" as tres rotinas criam sem erro
                      (saida: ROTINAS-OK). Nao e defeito do gerador.
    Firebird SET TERM  mesmo mecanismo no isql. Com "SET TERM ^ ;" a FUNCTION e
                      a TRIGGER criam. A PROCEDURE ainda falha, mas em
                      "Column unknown P_QTY" DENTRO do corpo, e o corpo foi
                      escrito pelo teste em .Body('...'), nao pelo gerador.
    PG CONCURRENTLY   ERROR 25001 "cannot run inside a transaction block" e o
                      MEU envelope BEGIN/ROLLBACK. Rodadas fora de transacao,
                      as duas so acusam objeto ausente.
    Oracle ORA-00955  o corpus tem DOIS CREATE TABLE "LOGS" diferentes e o DDL
                      do Oracle faz commit. Isolada em esquema limpo, a segunda
                      cria ("Table created").
    MySQL 1007        CREATE DATABASE `MY_SCHEMA` ja criado por execucao
                      anterior do PROPRIO arnes. Desapareceu na rodada final,
                      feita com o container recriado do zero - o que confirma
                      que era artefato de estado, e nao do gerador.

  CONTAMINACAO QUE EU MESMO CAUSEI, e como corrigi: uma rodada de verificacao no
  Firebird deu COMMIT em tabelas de apoio; a rodada seguinte passou a acusar 24
  recusas em vez de 17, porque objetos passaram a existir. Recriei o container e
  a base do zero e refiz a varredura. O numero valido e o da base limpa: 17
  mensagens, 6 recusas de gerador.

  II.8  O QUE A VARREDURA NAO MEDE - e onde isso morde

  (a) SEMANTICA DE DML. As tabelas nao existem, entao a analise para na
      resolucao de nome. Recusei montar esquema sintetico: tipos inventados
      gerariam achados FALSOS, que e exatamente o pecado que esta tarefa audita.
      Aceitavel porque o DML sai SEM DELIMITADOR em todos os dialetos
      (PostgreSQL: 46 de 46), entao o risco de caixa vive no DDL, que e
      executado de verdade.

  (b) ERROS DE ANALISE, e nao so de caixa. Tudo que o motor so descobre DEPOIS
      de resolver nome fica invisivel aqui:
        - aridade de INTERSECT / UNION (numero de colunas dos dois lados);
        - apelido ambiguo (a familia do ORA-00918 "column ambiguously defined");
        - incompatibilidade de tipo entre colunas de um compound select.
      Nenhum desses seria visto por esta varredura em sentenca de DML.

  (c) O RISCO DE CAIXA DO POSTGRESQL E SISTEMATICAMENTE INVISIVEL QUANDO O
      OBJETO E EXTERNO. A varredura so consegue julgar caixa em sentenca
      AUTO-CONTIDA (o CREATE TABLE que declara suas proprias colunas). Quando o
      objeto vem de fora, o 42P01/42703 e classificado como "objeto ausente" e
      o defeito de delimitacao passa batido. Exemplo real medido:

        CREATE VIEW "VW_CLI" AS SELECT ID FROM CLIENTES
        -> ERROR 42P01: relation "clientes" does not exist

      E a MESMA familia do defeito #11 (a coluna gerada): nome delimitado,
      corpo cru. Aqui e indistinguivel de "a tabela realmente nao existe". O
      PostgreSQL e o unico dos sete onde isso morde, porque e o unico que dobra
      identificador nao delimitado para MINUSCULA (Oracle e Firebird dobram para
      MAIUSCULA, que e a caixa em que o framework ja escreve).

  (d) INTERBASE: zero medicao, 50 enunciados.

  (e) A varredura cobre o que a suite EXERCITA. Caminho ALCANCAVEL mas sem teste
      nao produz texto, logo nao foi submetido, logo esta varredura nao diz nada
      sobre ele. Isto mede os ORACULOS EXISTENTES, nao a corretude do gerador.

      O exemplo concreto e exists / not exists (II.6): o ramo E alcancavel -
      Operators.pas:367 e :487 o produzem -, tem defeito de caixa, e os unicos
      testes que passariam por ele estao [Ignore]ados. Resultado: nao aparece em
      nenhum dos 626 enunciados e a varredura e cega para ele.

      NAO confundir com between / not between, que nao tem produtor nenhum: ali
      nao ha caminho vivo para medir, e a lacuna e outra (codigo morto). A
      diferenca esta detalhada em II.6.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  PARTE III - AS 11 CELULAS VERDES QUE CERTIFICAM SQL RECUSADO

  Todas confirmadas 'Success' no XML de resultado das duas configuracoes.
  Todas as recusas do Firebird reconfirmadas COM AS TABELAS PRESENTES, em base
  recriada limpa.

  CUIDADO AO CRUZAR COM A MATRIZ DE II.7 - as duas contam COISAS DIFERENTES, e
  os numeros nao batem por isso, nao por erro:

    II.7 conta ENUNCIADOS  (texto SQL distinto submetido ao motor)
    III  conta CELULAS     (procedure de teste que fixa aquele texto)

  A conversao, item a item:

    10 enunciados recusados e atribuiveis ao gerador em II.7
     - 1 do DB2, que NAO tem celula verde (o TestDate ja esta vermelho)
     = 9 enunciados fixados por celula verde
     + 1 enunciado do MSSQL, JA CORRIGIDO por esta tarefa - por isso ele nao
       aparece mais na coluna "RECUSADO/GERADOR" de II.7, que e pos-correcao,
       mas aparece aqui como item 1, porque a celula existia e era verde
     = 10 enunciados listados abaixo
     + 1 celula A MAIS, porque os itens 2 e 3 sao DUAS celulas (uma em
       Common_tests, outra em MySQL_tests) fixando O MESMO enunciado
     = 11 CELULAS

    #   dialeto     construcao                     erro literal do motor
    --  ----------  -----------------------------  ---------------------------------
     1  MSSQL       [TOTAL] INT AS (...)           Msg 156 Incorrect syntax near
                                                   the keyword 'AS'
        -> Test Delphi/MSSQL_tests/test.ddl.mssql.pas
           CORRIGIDA NESTA TAREFA.

     2  MySQL       TRUNCATE TABLE `T1`, `T2`      ERROR 1064 ... near ', `T2`'
        -> Test Delphi/Common_tests/test_esp074_unit.pas
           TestTruncateTable_MySQL_MultiTable_GeneratesExpected
     3  MySQL       (a mesma construcao)           (o mesmo 1064)
        -> Test Delphi/MySQL_tests/test.ddl.mysql.pas
           TestTruncateTable_MySQL_MultiTable_GeneratesExpected
     4  MySQL       TRUNCATE TABLE `logs`          ERROR 1064 ... near
                    PARTITION (p2023)              'PARTITION (p2023)'
        -> Test Delphi/Common_tests/test_esp074_unit.pas
           TestTruncateTable_MySQL_Partition_GeneratesExpected
           A forma que o MySQL aceita foi medida:
             ALTER TABLE `logs` TRUNCATE PARTITION p2023   -> executa.
           NOTA: o homonimo em MySQL_tests/test.ddl.mysql.pas esta [Ignore]ado
           com a razao correta. O MESMO defeito ficou desligado num projeto e
           VERDE no outro. Cruzados os 19 nomes [Ignore]ados contra a arvore,
           este par e o UNICO com esse padrao.

     5  Firebird    TRUNCATE TABLE "CLIENTES"      -104 Token unknown - TRUNCATE
        -> Test Delphi/Firebird_tests/test.ddl.firebird.pas
           TestTruncateTable_Firebird_GeneratesExpected
     6  Firebird    ALTER TABLE "TAB_A" TO "TAB_B" -104 Token unknown - TO
        -> Test Delphi/Firebird_tests/test.ddl.firebird.pas
           TestAlterTableRenameTable_Firebird_GeneratesExpected
     7  Firebird    DROP INDEX IF EXISTS "..."     -104 Token unknown - EXISTS
        -> Test Delphi/Firebird_tests/test.ddl.firebird.pas
           TestDropIndex_Firebird_IfExists_GeneratesExpected
           Medido: o 5.0.4 recusa IF EXISTS nas QUATRO formas de DROP
           (TABLE, VIEW, INDEX, SEQUENCE).
     8  Firebird    VALUES (..), (..) multi-linha  -104 Token unknown - ,
        -> Test Delphi/Common_tests/test.core.params.pas
           TestInsertBatchTwoRowsFirebird
     9  Firebird    INTERSECT                      -104 Token unknown - SELECT
        -> Test Delphi/Firebird_tests/UTestFluentSQLFirebird.pas
           TestIntersect_SerializesCompoundSelect
    10  Firebird    INTERSECT (com parametros)     -104 Token unknown - INTERSECT
        -> Test Delphi/Firebird_tests/UTestFluentSQLFirebird.pas
           TestParams_Firebird_Intersect_ParametersOnBothSides
           INTERSECT so tem teste para Firebird. Nenhum outro dialeto e coberto.

    11  PostgreSQL  GENERATED ALWAYS AS (QTD *     ERROR 42703 column "qtd"
                    PRECO) STORED                  does not exist
        -> Test Delphi/PostgreSQL_tests/test.ddl.postgresql.pas
           TestComputedColumn_PostgreSQL_GeneratesExpected
           NAO CORRIGIDA: e a T22, decisao do dono. Ver PARTE I.2.

  DUAS CORRECOES AO RELATO QUE ORIGINOU A TAREFA:

    * test.ddl.postgresql.pas, o CHECK de tabela
      (CHECK (PRECO_MAX > PRECO_MIN)) esta [Ignore]ado, NAO verde. Nao e celula
      verde certificando invalido: e divida T6 ja declarada. So a coluna gerada
      (#11) e verde.
    * o par MySQL do TRUNCATE PARTITION (#4) e o achado NOVO desta varredura:
      Ignore num projeto, verde no outro.

  O QUE NAO E DEFEITO DO GERADOR, e por isso ficou FORA das 11:

    * SELECT * FROM T WHERE (ID = :p1) OFFSET :p2   (Firebird -104)
      test.core.params.pas, TestDialectOnlyArrayOfConstBindsParams.
      O texto ' OFFSET ' veio do CHAMADOR, em
      .ForDialectOnly(dbnFirebird, [' OFFSET ', 0]). O Firebird exige
      "OFFSET n ROWS" - medido: com ROWS executa. O gerador emitiu fielmente o
      que lhe pediram. Fica registrado como possivel lacuna de guarda, nao
      como oraculo mentiroso.
    * corpos verbatim de rotina - .Body('...') e o literal '...'. O ENVELOPE do
      gerador parseia; o miolo e do teste.

  DETALHE QUE PESA NO CASO DO MySQL: o framework JA levanta
  ENotSupportedException para TRUNCATE multi-tabela em MSSQL e em Oracle
  (TestTruncateTable_MSSQL_MultiTable_RaisesNotSupported,
  TestTruncateTable_Oracle_MultiTable_RaisesNotSupported, ambos verdes). Ele
  CONHECE a regra; so nao a aplica ao MySQL.

  ------------------------------------------------------------------------------
  COMO REFAZER

  1. Suba os sete containers com prefixo proprio (nao reaproveite os de outra
     tarefa - DDL executado suja a base do vizinho):

       docker run -d --name t27-mssql -e ACCEPT_EULA=Y \
         -e 'MSSQL_SA_PASSWORD=T27#pass_2026' mcr.microsoft.com/mssql/server:2022-latest
       docker run -d --name t27-pg -e POSTGRES_PASSWORD=t27pass postgres:16
       docker run -d --name t27-mysql -e MYSQL_ROOT_PASSWORD=t27pass mysql:8.4
       docker run -d --name t27-fb -e FIREBIRD_ROOT_PASSWORD=t27pass \
         -e FIREBIRD_DATABASE=t27.fdb firebirdsql/firebird:5.0.4
       docker run -d --name t27-sqlite --entrypoint sleep keinos/sqlite3 infinity
       docker run -d --name t27-ora -e ORACLE_PASSWORD=t27pass gvenzl/oracle-free:23-slim
       docker run -d --name t27-db2 --privileged -e LICENSE=accept \
         -e DB2INST1_PASSWORD=t27pass -e DBNAME=t27db icr.io/db2_community/db2:latest

     O DB2 leva varios minutos para inicializar; espere o "db2 connect" responder.

  2. Copie Source/ para fora do repo, aplique a instrumentacao dos 27 pontos
     (II.1), compile os 11 .dpr contra essa copia e rode. Confira que a medicao
     nao mudou (662/596/20/46 sem defines NESTA arvore) - se mudou, a
     instrumentacao nao e neutra e a colheita nao vale. Compare sempre contra a
     MESMA arvore: comparar com o numero de outra e o defeito que esta propria
     tarefa foi reprovada por cometer.

  3. Deduplique por (dialeto, texto), aplique as regex de II.3 e submeta
     conforme II.4.

  4. Rode SEMPRE o controle de II.5 antes de acreditar em qualquer resultado.

  5. Para reproduzir II.6, injete "Assert.IgnoreCaseDefault := False;" antes do
     TDUnitX.CheckCommandLine nos 11 .dpr e compare os vermelhos.
  ------------------------------------------------------------------------------
*/
