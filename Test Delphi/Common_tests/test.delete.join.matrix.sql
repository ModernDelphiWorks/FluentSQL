/*
  ------------------------------------------------------------------------------
  ORACULO DO DELETE COM JOIN - SETE DIALETOS  (T30)

  MEDICAO em motor real da porta que a T26 declarou ABERTA de proposito (Parte 8,
  item 5 de test.delete.multirelacao.matrix.sql). A guarda da T26 morava em
  TFluentSQL.From e contava ASTTableNames; TFluentSQL._CreateJoin nao passa por
  ASTTableNames, entao o JOIN seguia alcancavel de dentro do DELETE.

  ESTA PORTA AGORA ESTA FECHADA: TFluentSQL._CreateJoin recusa a secao DELETE
  para os QUATRO tipos de juncao, com EFluentSQLConstructNotSupported. A razao
  esta na Parte 9, e ela e o DANO SILENCIOSO medido no caso C07 - nao a
  invalidade do texto emitido.

  ⚠️ ESTE ARQUIVO E O ORACULO, NAO O TESTE. O que ele traz e transcricao de
  motor real: digest de imagem, versao perguntada ao motor, controle positivo e
  negativo, e contagem antes/depois. Quem trava o comportamento na suite e
  test.delete.join.pas, nesta mesma pasta. Um arquivo mede, o outro afirma.

  ------------------------------------------------------------------------------
  O QUE O FLUENTSQL EMITE HOJE - lido do proprio builder, nao suposto

  Levantado em 7c9ed45 com um programa que percorre TFluentSQLDriver inteiro.
  Reproduzivel: Query(D).Delete.From(...).InnerJoin(...).OnCond(...).Where(...).

    Delete.From('A').InnerJoin('B').OnCond('B.AID = A.ID').Where('A.X').Equal(1)
      seis dialetos  DELETE FROM A INNER JOIN B ON B.AID = A.ID WHERE (A.X = :p1)
      Oracle         idem (o apelido e que muda, nao ha apelido aqui)
      MySQL          idem, com ? no lugar de :p1

    Delete.From('A','X').InnerJoin('B','Y').OnCond('Y.AID = X.ID').Where('X.ID').Equal(1)
      MSSQL          DELETE X FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = :p1)
      cinco          DELETE FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = :p1)
      Oracle         DELETE FROM A X INNER JOIN B Y ON Y.AID = X.ID WHERE (X.ID = :p1)

    Delete.From('A','X').InnerJoin('B','Y')            <-- SEM OnCond
      MSSQL          DELETE X FROM A AS X INNER JOIN B AS Y ON
      cinco          DELETE FROM A AS X INNER JOIN B AS Y ON
      Oracle         DELETE FROM A X INNER JOIN B Y ON

  ATENCAO ao terceiro: sem OnCond o texto sai com um ON PENDURADO, sem predicado
  nenhum. Nao e "juncao cartesiana" - e sentenca truncada. O DB2 e quem diz isso
  com todas as letras: SQL0104N, token "END-OF-STATEMENT" apos "INNER JOIN B AS
  Y ON", esperado "<boolean_predicate>". LeftJoin, RightJoin e FullJoin trocam
  so a palavra; a forma e a mesma.

  ------------------------------------------------------------------------------
  A MATRIZ, EM UMA TELA

  Legenda: RECUSA = o motor nao analisa. ACEITA = executou, com a contagem ao lado.
  Massa em todos: A com 4 linhas (ID 1..4, X=1), B com 2 (AID 1 e 2), C com 1.
  Logo a juncao Y.AID = X.ID casa 2 das 4 linhas de A.

    caso                              | MSSQL | Oracle | PgSQL | MySQL | Firebird | SQLite | DB2
    ----------------------------------+-------+--------+-------+-------+----------+--------+------
    C02 emitido hoje, sem apelido     |RECUSA | RECUSA |RECUSA |RECUSA |  RECUSA  | RECUSA |RECUSA
    C03 emitido hoje, com apelido     |RECUSA | RECUSA |RECUSA |RECUSA |  RECUSA  | RECUSA |RECUSA
    C04 "DELETE X FROM A AS X JOIN.." |ACEITA | RECUSA |RECUSA |ACEITA |  RECUSA  | RECUSA |RECUSA
    C05 ON pendurado (sem OnCond)     |RECUSA | RECUSA |RECUSA |RECUSA |  RECUSA  | RECUSA |RECUSA
    C06 emitido hoje, LEFT JOIN       |RECUSA | RECUSA |RECUSA |RECUSA |  RECUSA  | RECUSA |RECUSA
    C11 "DELETE FROM A USING B"       |RECUSA | ACEITA |ACEITA |RECUSA |  RECUSA  | RECUSA |RECUSA
    ----------------------------------+-------+--------+-------+-------+----------+--------+------
    C08 EXISTS, com apelido           |ACEITA | ACEITA |ACEITA |ACEITA |  ACEITA  | ACEITA |ACEITA
    C09 EXISTS, sem apelido           |ACEITA | ACEITA |ACEITA |ACEITA |  ACEITA  | ACEITA |ACEITA
    C10 EXISTS, com DOIS joins        |ACEITA | ACEITA |ACEITA |ACEITA |  ACEITA  | ACEITA |ACEITA
    C13 EXISTS, sem WHERE do usuario  |ACEITA | ACEITA |ACEITA |ACEITA |  ACEITA  | ACEITA |ACEITA

    InterBase: NAO MEDIDO em caso nenhum - nao existe imagem Docker publica.

  DUAS LEITURAS, e a segunda e a que decide a tarefa:

  1. O TEXTO QUE O FLUENTSQL EMITE HOJE NAO EXECUTA EM MOTOR NENHUM. Nem com
     apelido, nem sem, nem com INNER, nem com LEFT. A unica excecao e o C04 -
     que e exatamente o que o dbnMSSQL emite quando ha apelido - e ele executa em
     2 dos 7. Ou seja: dos 8 dialetos, UM emite texto que o seu proprio motor
     aceita, e so no caminho COM apelido.

  2. A INTERSECAO NAO E VAZIA. A forma EXISTS e aceita pelos SETE, com a MESMA
     contagem nos sete, nas quatro variantes. Ela existe. O que se discute
     abaixo NAO e se ela funciona - funciona, esta medido - e sim se traduzir
     para ela e correto.

  ------------------------------------------------------------------------------
  ⭐ O NUMERO QUE MUDA A RESPOSTA: LEFT JOIN NAO SIGNIFICA FILTRAR

  A premissa de que a porta do JOIN e traduzivel apoia-se em o alvo ser a relacao
  do From e a juncao ser o OnCond. Isso vale para o InnerJoin. Para o LeftJoin,
  MEDIDO, nao vale - e a diferenca aparece na contagem, nao na argumentacao.

  MESMA chamada de builder - From('A','X').LeftJoin('B','Y').OnCond('Y.AID = X.ID'),
  sem Where. MESMA massa: A com 4 linhas, das quais 2 casam com B.

    forma nativa do dialeto que a aceita:
      DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID
        SQL Server 2022   A: 4 -> 0     B: 2 -> 2     apagou TUDO
        MySQL 8.4.11      A: 4 -> 0     B: 2 -> 2     apagou TUDO
        os outros cinco   RECUSAM por parse

    forma portavel EXISTS, para a MESMA chamada:
      DELETE FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID)
        os SETE           A: 4 -> 2     B: 2 -> 2     apagou so o que casa

  QUATRO LINHAS CONTRA DUAS, para a mesma chamada. No LEFT JOIN a juncao e
  DECORATIVA: ela nao filtra nada, porque a juncao externa preserva toda linha da
  relacao da esquerda. "Apagar de A filtrando por B" NAO e o que o LeftJoin
  significa nos dois motores que o analisam.

  Isso NAO e um detalhe do LEFT. E a demonstracao de que a familia JOIN nao tem
  UMA semantica dentro do DELETE: InnerJoin filtra, LeftJoin nao. Traduzir a
  familia inteira para EXISTS trocaria, no caso do LeftJoin, "SQL que nao executa
  em 5 motores e apaga 4 linhas em 2" por "SQL que executa nos 7 apagando 2". A
  troca e silenciosa e destrutiva na direcao contraria - deixa linhas vivas que o
  usuario mandou apagar. E o mesmo defeito que a T26 recusou cometer, com o sinal
  invertido.

  RightJoin e FullJoin nao foram medidos em contagem. A forma emitida por eles
  foi medida (RECUSA nos sete, identica a C06) - o que nao se mediu foi a
  semantica da forma nativa, porque so 2 motores a analisariam e a conclusao do
  LEFT ja basta para a decisao. Esta escrito aqui para nao ser lido como medido.

  ------------------------------------------------------------------------------
  MOTORES MEDIDOS - versao perguntada AO MOTOR, nao lida do nome da imagem

    SQL Server  Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
                Jul  7 2026 14:37:25 / Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)
                mcr.microsoft.com/mssql/server:2022-latest
                sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0 (v$instance.version_full)
                gvenzl/oracle-free:23-slim
                sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8
    PostgreSQL  PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
                postgres:16
                sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
    MySQL       8.4.11  (VERSION())
                mysql:8.4
                sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
    Firebird    5.0.4  (rdb$get_context('SYSTEM','ENGINE_VERSION'))
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    SQLite      3.53.4  (sqlite_version())
                keinos/sqlite3
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1
    DB2         DB2 v12.1.5.0  (SYSPROC.ENV_GET_INST_INFO SERVICE_LEVEL)
                icr.io/db2_community/db2:latest
                sha256:2de8151713c261843868c5c3411b57be6ae79d99d70a5b3022337836776bfda6

    INTERBASE NAO FOI MEDIDO. Nao existe imagem Docker publica de InterBase. A
    convencao da casa e declarar nao medido em vez de deduzir. O que se sabe
    dele aqui e estrutural: TFluentSQLSerializerInterbase
    (Source\Drivers\FluentSQL.SerializeInterbase.pas) descende de
    TFluentSQLSerialize e nao sobrescreve DeleteClause, entao emite o texto da
    base - o mesmo dos cinco. Isso e leitura de codigo, nao medicao.

    RESSALVA DE FRONTEIRA: os codigos de erro transcritos sao os que ESTAS
    versoes devolveram. Nao se afirma nada sobre versoes anteriores.

  ------------------------------------------------------------------------------
  CONTROLE POSITIVO E NEGATIVO - sem eles a matriz nao vale

  Toda sessao roda, antes dos casos, dois casos de calibragem:

    C00 CONTROLE POSITIVO   DELETE FROM A WHERE A.ID = 999
                            tem de EXECUTAR (0 linhas). Se falhasse, "RECUSA"
                            nos demais casos poderia ser do ambiente e nao da
                            sentenca.
    C01 CONTROLE NEGATIVO   DELETE FRUM A
                            tem de FALHAR. Se passasse, o arnes nao estaria
                            mostrando erro nenhum e todo "ACEITA" seria suspeito.

  Os dois se comportaram como esperado nos SETE. Transcricao do negativo:

    SQL Server   Msg 102, Level 15, State 1, Line 1 / Incorrect syntax near 'A'.
    Oracle       ORA-00942: table or view "SYSTEM"."FRUM" does not exist
    PostgreSQL   ERROR:  syntax error at or near "FRUM"
    MySQL        ERROR 1064 (42000) at line 21 ... near 'A' at line 1
    Firebird     SQLSTATE = 42000 / SQL error code = -104 / Token unknown - line 1, column 8 / FRUM
    SQLite       Parse error near line 15: near "FRUM": syntax error
    DB2          SQL0204N  "DB2INST1.FRUM" is an undefined name.  SQLSTATE=42704

  Oracle e DB2 devolvem "nome indefinido" em vez de "erro de sintaxe", porque
  ambos leem FRUM como o nome da tabela. O que o controle precisa provar e que a
  sentenca FALHA e que a falha CHEGA a transcricao - e isso os sete provam.

  ==============================================================================
  PARTE 1 - SQL SERVER 2022 (16.0.4265.3)
  ==============================================================================

  docker run -d --name t30-mssql -e ACCEPT_EULA=Y \
    -e MSSQL_SA_PASSWORD='Fluent!Passw0rd' mcr.microsoft.com/mssql/server:2022-latest
  docker exec t30-mssql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'Fluent!Passw0rd' -C -i /tmp/mssql.sql

  C02  DELETE FROM A INNER JOIN B ON B.AID = A.ID WHERE (A.X = 1);
       Msg 156, Level 15, State 1, Line 1
       Incorrect syntax near the keyword 'INNER'.                      RECUSA

  C03  DELETE FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1);
       Msg 156, Level 15, State 1, Line 1
       Incorrect syntax near the keyword 'AS'.                         RECUSA

  C04  DELETE X FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1);
       t n
       - -----------
       A           3
       B           2                                                   ACEITA

  C05  DELETE FROM A AS X INNER JOIN B AS Y ON;
       Msg 156 ... Incorrect syntax near the keyword 'AS'.             RECUSA

  C06  DELETE FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1);
       Msg 156 ... Incorrect syntax near the keyword 'AS'.             RECUSA

  C07  DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID;          <-- SEMANTICA
       t n
       - -----------
       A           0
       B           2                        ACEITA - E APAGOU AS 4 LINHAS DE A

  C08  DELETE X FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID AND X.ID = 1);
       t n
       - -----------
       A           3
       B           2                                                   ACEITA

  C08b DELETE FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID AND X.ID = 1);
       Msg 156 ... Incorrect syntax near the keyword 'AS'.             RECUSA

       ⚠️ LEIA O C08b JUNTO COM O C08. O T-SQL exige o DESIGNADOR DE ALVO
       ("DELETE X FROM ...") sempre que ha apelido - inclusive quando nao ha
       JOIN nenhum. A forma dos outros seis, "DELETE FROM A AS X WHERE ...", ele
       RECUSA. Isso ja e o que TFluentSQLSerializerMSSQL.DeleteClause emite
       desde a T18, entao a forma EXISTS nao exigiria uma linha nova de driver:
       o cabecalho certo de cada dialeto ja sai do gancho que existe.

  C09  DELETE FROM A WHERE EXISTS (SELECT 1 FROM B WHERE B.AID = A.ID AND A.X = 1);
       A 2 / B 2                                                       ACEITA
  C10  DELETE X FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y INNER JOIN C AS Z ON Z.BID = Y.ID WHERE Y.AID = X.ID AND X.ID = 1);
       A 3 / B 2                                                       ACEITA
  C13  DELETE X FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID);
       A 2 / B 2                                                       ACEITA
  C11  DELETE FROM A AS X USING B AS Y WHERE Y.AID = X.ID AND X.ID = 1;
       Msg 156 ... Incorrect syntax near the keyword 'AS'.             RECUSA

  C14  ANTI-COLATERAL  SELECT * FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1);
       ID          X           ID          AID
                 1           1          10           1                 ACEITA
  C15  ANTI-COLATERAL  DELETE X FROM A AS X WHERE (X.ID = 1);          ACEITA

  ==============================================================================
  PARTE 2 - ORACLE 23.26.2.0.0
  ==============================================================================

  docker run -d --name t30-ora -e ORACLE_PASSWORD=fluent gvenzl/oracle-free:23-slim
  docker exec t30-ora bash -c "sqlplus -S system/fluent@localhost/FREEPDB1 @/tmp/ora.sql"

  Os casos usam a forma SEM AS no apelido de relacao, que e a que o dbnOracle
  emite (RelationAliasKeyword = '' desde a T12).

  C02  DELETE FROM A INNER JOIN B ON B.AID = A.ID WHERE (A.X = 1)
                     *
       ERROR at line 1:
       ORA-03049: SQL keyword 'INNER' is not syntactically valid following '...JOIN'
                                                                       RECUSA

  C03  DELETE FROM A X INNER JOIN B Y ON Y.AID = X.ID WHERE (X.ID = 1)
                       *
       ORA-03049: SQL keyword 'INNER' is not syntactically valid following
                  'DELETE FROM A X '                                   RECUSA

  C04  DELETE X FROM A X INNER JOIN B Y ON Y.AID = X.ID WHERE (X.ID = 1)
              *
       ORA-00942: table or view "SYSTEM"."X" does not exist            RECUSA

  C05  DELETE FROM A X INNER JOIN B Y ON
       ORA-03049 ... following 'DELETE FROM A X '                      RECUSA

  C06  DELETE FROM A X LEFT JOIN B Y ON Y.AID = X.ID WHERE (X.ID = 1)
       ORA-03049: SQL keyword 'LEFT' is not syntactically valid following
                  'DELETE FROM A X '                                   RECUSA

  C08  DELETE FROM A X WHERE EXISTS (SELECT 1 FROM B Y WHERE Y.AID = X.ID AND X.ID = 1);
       1 row deleted.
            QTD_A      QTD_B
       ---------- ----------
                3          2                                           ACEITA
  C09  DELETE FROM A WHERE EXISTS (SELECT 1 FROM B WHERE B.AID = A.ID AND A.X = 1);
       2 rows deleted.   QTD_A 2 / QTD_B 2                             ACEITA
  C10  DELETE FROM A X WHERE EXISTS (SELECT 1 FROM B Y INNER JOIN C Z ON Z.BID = Y.ID WHERE Y.AID = X.ID AND X.ID = 1);
       1 row deleted.    QTD_A 3 / QTD_B 2                             ACEITA
  C13  DELETE FROM A X WHERE EXISTS (SELECT 1 FROM B Y WHERE Y.AID = X.ID);
       2 rows deleted.   QTD_A 2 / QTD_B 2                             ACEITA
  C11  DELETE FROM A X USING B Y WHERE Y.AID = X.ID AND X.ID = 1;
       1 row deleted.                                                  ACEITA

  C14  ANTI-COLATERAL  SELECT * FROM A X INNER JOIN B Y ON Y.AID = X.ID WHERE (X.ID = 1);
       1 linha                                                         ACEITA
  C15  ANTI-COLATERAL  DELETE FROM A X WHERE (X.ID = 1);               ACEITA

  ⚠️ NOTA SOBRE O ORA-03049. A T26 transcreveu ORA-03048 para a lista separada
  por virgula; aqui o codigo e ORA-03049, e a mensagem nomeia a palavra-chave
  ('INNER', 'LEFT'). Sao erros diferentes para construcoes diferentes; nenhum
  dos dois foi copiado do outro.

  ==============================================================================
  PARTE 3 - POSTGRESQL 16.14
  ==============================================================================

  docker run -d --name t30-pg -e POSTGRES_PASSWORD=fluent postgres:16
  docker exec t30-pg psql -U postgres -f /tmp/pg.sql

  C02  ERROR:  syntax error at or near "INNER"
       LINE 1: DELETE FROM A INNER JOIN B ON B.AID = A.ID WHERE (A.X = 1);
                             ^                                         RECUSA
  C03  ERROR:  syntax error at or near "INNER"
       LINE 1: DELETE FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (...
                                  ^                                    RECUSA
  C04  ERROR:  syntax error at or near "X"
       LINE 1: DELETE X FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE...
                      ^                                                RECUSA
  C05  ERROR:  syntax error at or near "INNER"
       LINE 1: DELETE FROM A AS X INNER JOIN B AS Y ON;                RECUSA
  C06  ERROR:  syntax error at or near "LEFT"
       LINE 1: DELETE FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID WHERE (X...
                                  ^                                    RECUSA

  C08  DELETE FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID AND X.ID = 1);
       DELETE 1
        t | count
       ---+-------
        A |     3
        B |     2                                                      ACEITA
  C09  DELETE 2   A 2 / B 2                                            ACEITA
  C10  DELETE 1   A 3 / B 2                                            ACEITA
  C13  DELETE 2   A 2 / B 2                                            ACEITA
  C11  DELETE FROM A AS X USING B AS Y WHERE Y.AID = X.ID AND X.ID = 1;
       DELETE 1                                                        ACEITA

  C14  ANTI-COLATERAL  1 linha                                         ACEITA
  C15  ANTI-COLATERAL  DELETE 1                                        ACEITA

  ==============================================================================
  PARTE 4 - MYSQL 8.4.11
  ==============================================================================

  docker run -d --name t30-mysql -e MYSQL_ROOT_PASSWORD=fluent mysql:8.4
  docker exec t30-mysql sh -c "mysql -uroot -pfluent --force -t < /tmp/mysql.sql"

  C02  ERROR 1064 (42000) at line 24: ... right syntax to use near
       'INNER JOIN B ON B.AID = A.ID WHERE (A.X = 1)' at line 1        RECUSA
  C03  ERROR 1064 (42000) at line 27: ... near
       'INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1)' at line 1  RECUSA
  C04  DELETE X FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1);
       +---+---+
       | t | n |
       | A | 3 |
       | B | 2 |                                                       ACEITA
  C05  ERROR 1064 (42000) at line 34: ... near 'INNER JOIN B AS Y ON'  RECUSA
  C06  ERROR 1064 (42000) at line 37: ... near
       'LEFT JOIN B AS Y ON Y.AID = X.ID WHERE (X.ID = 1)' at line 1   RECUSA

  C07  DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID;          <-- SEMANTICA
       +---+---+
       | t | n |
       | A | 0 |
       | B | 2 |                            ACEITA - E APAGOU AS 4 LINHAS DE A

  C08  A 3 / B 2                                                       ACEITA
  C09  A 2 / B 2                                                       ACEITA
  C10  A 3 / B 2                                                       ACEITA
  C13  A 2 / B 2                                                       ACEITA
  C11  ERROR 1064 (42000) at line 60: ... near
       'USING B AS Y WHERE Y.AID = X.ID AND X.ID = 1'                  RECUSA

       (o MySQL TEM uma forma com USING - "DELETE FROM A USING A, B WHERE ..." -
        que e OUTRA gramatica; a que se mediu aqui e a do PostgreSQL, e essa ele
        recusa.)

  C14  ANTI-COLATERAL  1 linha                                         ACEITA
  C15  ANTI-COLATERAL  executou                                        ACEITA

  ==============================================================================
  PARTE 5 - FIREBIRD 5.0.4
  ==============================================================================

  docker run -d --name t30-fb -e FIREBIRD_ROOT_PASSWORD=masterkey \
    -e FIREBIRD_DATABASE=test.fdb firebirdsql/firebird:5.0.4
  docker exec t30-fb sh -c "isql -u SYSDBA -p masterkey -i /tmp/fb.sql \
    /var/lib/firebird/data/test.fdb"

  C02  Statement failed, SQLSTATE = 42000
       Dynamic SQL Error / -SQL error code = -104
       -Token unknown - line 1, column 15 / -INNER                     RECUSA
  C03  -Token unknown - line 1, column 20 / -INNER                     RECUSA
  C04  -Token unknown - line 1, column 8  / -X                         RECUSA
  C05  -Token unknown - line 1, column 20 / -INNER                     RECUSA
  C06  -Token unknown - line 1, column 20 / -LEFT                      RECUSA

  C08  DELETE FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID AND X.ID = 1);
                     ANTES_A                DEPOIS_A               DEPOIS_B
       ===================== ===================== =====================
                           4                     3                     2
                                                                       ACEITA
  C09  QTD_A 2 / QTD_B 2                                               ACEITA
  C10  QTD_A 3 / QTD_B 2                                               ACEITA
  C13  QTD_A 2 / QTD_B 2                                               ACEITA
  C11  -Token unknown - line 1, column 20 / -USING                     RECUSA

  C14  ANTI-COLATERAL  1 linha                                         ACEITA
  C15  ANTI-COLATERAL  QTD_A 3                                         ACEITA

  NOTA DE ARNES: nesta rodada o isql do Firebird encerrou a leitura do script
  logo apos o COMMIT do C08 quando os casos vinham todos num arquivo so, SEM
  emitir mensagem. Os casos C09..C15 foram entao rodados um por arquivo, e e
  dessas execucoes que vem a transcricao acima. Fica registrado porque um leitor
  que reproduza o arquivo unico vera o script parar no meio e nao deve concluir
  que os casos seguintes falharam.

  ==============================================================================
  PARTE 6 - SQLITE 3.53.4
  ==============================================================================

  docker run -d --name t30-sqlite --entrypoint sh keinos/sqlite3 \
    -c "while true; do sleep 30; done"
  docker exec t30-sqlite sh -c "sqlite3 /tmp/t30.db < /tmp/sqlite.sql"

  C02  Parse error near line 20: near "INNER": syntax error
         DELETE FROM A INNER JOIN B ON B.AID = A.ID WHERE (A.X = 1);
                       ^--- error here                                 RECUSA
  C03  Parse error near line 23: near "INNER": syntax error            RECUSA
  C04  Parse error near line 26: near "X": syntax error                RECUSA
  C05  Parse error near line 29: near "INNER": syntax error            RECUSA
  C06  Parse error near line 32: near "LEFT": syntax error             RECUSA

  C08  A=3 B=2                                                         ACEITA
  C09  A=2 B=2                                                         ACEITA
  C10  A=3 B=2                                                         ACEITA
  C13  A=2 B=2                                                         ACEITA
  C11  Parse error near line 59: near "USING": syntax error            RECUSA

  C14  ANTI-COLATERAL  1|1|10|1                                        ACEITA
  C15  ANTI-COLATERAL  A=3                                             ACEITA

  ==============================================================================
  PARTE 7 - DB2 12.1.5.0
  ==============================================================================

  docker run -d --name t30-db2 --privileged -e LICENSE=accept \
    -e DB2INST1_PASSWORD=fluent -e DBNAME=testdb icr.io/db2_community/db2:latest
  docker exec t30-db2 bash -c "su - db2inst1 -c 'bash /tmp/db2.sh'"

  C02  SQL0104N  An unexpected token "JOIN" was found following "".
                 Expected tokens may include:  "FROM".  SQLSTATE=42601 RECUSA
  C03  SQL0104N  An unexpected token "JOIN" was found following "".
                 Expected tokens may include:  "FROM".  SQLSTATE=42601 RECUSA
  C04  SQL0104N  An unexpected token "A" was found following "DELETE X FROM ".
                 Expected tokens may include:  "JOIN".  SQLSTATE=42601 RECUSA
  C05  SQL0104N  An unexpected token "END-OF-STATEMENT" was found following
                 "INNER JOIN B AS Y ON".  Expected tokens may include:
                 "<boolean_predicate>".  SQLSTATE=42601                RECUSA

       ⚠️ ESTA E A MELHOR DESCRICAO DO "SEM OnCond" ENTRE OS SETE. O motor diz
       que falta um PREDICADO, nao que a juncao seja cartesiana. Confirma que o
       texto emitido sem OnCond e sentenca TRUNCADA.

  C06  SQL0104N  An unexpected token "JOIN" was found following "".
                 Expected tokens may include:  "FROM".  SQLSTATE=42601 RECUSA

  C08  DELETE FROM A AS X WHERE EXISTS (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID AND X.ID = 1)
       DB20000I  The SQL command completed successfully.
       B           2
       A           3                                                   ACEITA
  C09  A 2 / B 2                                                       ACEITA
  C10  A 3 / B 2                                                       ACEITA
  C13  A 2 / B 2                                                       ACEITA
  C11  SQL0104N  An unexpected token "USING B AS Y" was found following
                 "DELETE FROM A AS X ".                                RECUSA

  C14  ANTI-COLATERAL  1 record(s) selected.                           ACEITA
  C15  ANTI-COLATERAL  DB20000I                                        ACEITA

  ==============================================================================
  PARTE 8 - O QUE A TRADUCAO CUSTARIA, MEDIDO NO BUILDER
  ==============================================================================

  Esta parte NAO e opiniao sobre esforco. Sao dois fatos lidos do texto que o
  builder emite hoje, e ambos mudam o DESENHO de qualquer traducao.

  1. O WHERE DE UM DELETE-COM-JOIN PODE CITAR A RELACAO JUNTADA.

       Delete.From('A','X').InnerJoin('B','Y').OnCond('Y.AID = X.ID')
             .Where('Y.Status').Equal(1)
       -> DELETE FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID WHERE (Y.Status = ?)

     Na forma EXISTS, Y so existe DENTRO da subconsulta. Logo o WHERE inteiro
     tem de migrar para dentro do EXISTS - o que e exato para o INNER JOIN
     (apagar x tal que existe y com juncao E filtro), mas NAO e uma mudanca
     local: e ComposeSqlCore deixando de emitir AAST.Where.Serialize na posicao
     de sempre para UMA secao. O nucleo nao tem como saber quais predicados do
     WHERE citam Y, entao "mover so o que cita Y" nao esta disponivel.

  2. A CONDICAO DE JUNCAO CARREGA PARAMETRO, E NO MYSQL O BIND E POSICIONAL.

       Delete.From('A','X')
             .InnerJoin('B','Y').OnCond(['Y.AID = X.ID AND Y.K =', 7])
             .InnerJoin('C','Z').OnCond(['Z.BID = Y.ID AND Z.K =', 8])
             .Where('X.ID').Equal(9)
       dbnMySQL      -> ... ON Y.AID = X.ID AND Y.K = ? INNER JOIN C AS Z
                        ON Z.BID = Y.ID AND Z.K = ? WHERE (X.ID = ?)
       dbnPostgreSQL -> ... :p1 ... :p2 ... :p3

     A forma EXISTS promove a PRIMEIRA relacao juntada ao FROM da subconsulta e
     o ON dela ao WHERE da subconsulta. Com DOIS ou mais joins isso inverte a
     ordem de :p1 e :p2 - inofensivo onde o bind e NOMEADO, mas o dbnMySQL emite
     "?" e o bind e POSICIONAL. Valor trocado em silencio e pior que erro de
     parse.

     ISSO TEM SAIDA, e fica dita para nao superestimar o custo: montar a
     subconsulta com juncao por VIRGULA - "SELECT 1 FROM B AS Y, C AS Z WHERE j1
     AND j2 AND w" - preserva a ordem j1, j2, w e e portavel nos sete. O preco e
     que a palavra que o usuario escreveu (INNER JOIN) desaparece do texto
     emitido, e a forma so serve enquanto TODOS os joins forem internos.

  ==============================================================================
  PARTE 9 - A DECISAO, E A FRONTEIRA DO QUE ESTE ARQUIVO NAO AFIRMA
  ==============================================================================

  ⭐ A RAZAO DA RECUSA, EM UMA LINHA: A FORMA NATIVA DESTROI DADOS EM SILENCIO.

  Nao e "o texto emitido nao executa" - essa e verdadeira e e a MENOR das duas.
  A que decide esta no caso C07 da Parte 1 e da Parte 4:

      DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID
      SQL Server 2022   A: 4 -> 0     executou e reportou SUCESSO
      MySQL 8.4.11      A: 4 -> 0     executou e reportou SUCESSO

  Sem WHERE nenhum, e com o que parece ser um filtro escrito pelo usuario. Na
  juncao EXTERNA a condicao e DECORATIVA: nao filtra nada, porque a juncao
  preserva toda linha da relacao da esquerda. Quem escreveu aquilo achava estar
  restringindo, e perde a tabela inteira sem uma linha de erro.

  E A MESMA CLASSE DO ACHADO DO ORACLE NO PR #160 - apagar MAIS do que se pediu,
  sem erro. La era a relacao errada; aqui e a relacao certa, por inteiro. Nao e
  caso isolado: e classe conhecida. Nao se traduz construcao cuja forma nativa
  destroi dados em silencio, e nao se deixa aberta - e por isso a porta FECHA.

  A COLISAO DE SEMANTICAS E CONSEQUENCIA DISSO, NAO A CAUSA: o InnerJoin FILTRA
  (a forma nativa apaga 2 das 4), o LeftJoin NAO (apaga 4 das 4). Por isso nao
  existe traducao unica para a familia, e liberar so o InnerJoin criaria uma
  distincao que a superficie fluente nao insinua e que gramatica nenhuma dos
  sete espelha - 5 dos 7 recusam os dois por parse, 2 dos 7 aceitam os dois.

  NOTA DE PROCEDENCIA: a primeira versao desta Parte 9 ordenava os argumentos ao
  contrario - liderava pela colisao de semanticas e tratava o dano silencioso
  como detalhe, e por isso concluia que a decisao ainda estava em aberto. Os
  NUMEROS eram os mesmos e nenhuma transcricao mudou; o que estava errado era a
  HIERARQUIA. Fica registrado porque quem le um oraculo precisa saber quando a
  leitura dele foi corrigida.

  1. NAO afirma nada sobre InterBase por MEDICAO. Nao foi executado.

  2. NAO afirma que a forma EXISTS seja ruim. Ela e boa e esta medida: aceita
     pelos SETE, com contagem identica nos sete, nas quatro variantes. A
     INTERSECAO NAO E VAZIA - e este arquivo derruba, com numero, a hipotese de
     que fosse.

  3. NAO afirma que RightJoin e FullJoin tenham a semantica do LeftJoin. So o
     LEFT teve a contagem medida. Do RIGHT e do FULL mediu-se apenas que a forma
     EMITIDA e recusada pelos sete.

  4. NAO afirma nada sobre MongoDB em motor real. MongoDB esta fora da promessa
     relacional e fora de toda contagem desta entrega. Registro do estado:
     antes, Query(dbnMongoDB).Delete.From('A').InnerJoin('B') levantava
     EArgumentOutOfRangeException cru de TList ("List index out of bounds (0).
     TList<IFluentSQLName> is empty"), sem nome de metodo. A guarda desta tarefa
     e de NUCLEO e o alcanca pelo mesmo caminho dos demais, entao ele passa a
     receber EFluentSQLConstructNotSupported - verificado. Isso e EFEITO, nao
     promessa: nao houve uma linha escrita para o MongoDB.

  5. A SAIDA APONTADA PELA MENSAGEM EXISTE, E ISSO FOI VERIFICADO - nao herdado.
     Este arquivo foi escrito, na sua primeira versao, quando
     IFluentSQL.Exists(String) ainda PARAMETRIZAVA a subconsulta e emitia
     "WHERE (exists :p1)", com o texto virando valor de bind. Naquele estado,
     recusar o JOIN teria mandado o usuario para uma porta que nao abria - e foi
     por isso que a recusa esperou. O conserto do Exists entrou antes desta
     entrega, e hoje:

       Delete.From('A','X').Where('').Exists('SELECT 1 FROM B AS Y WHERE Y.AID = X.ID')
       dbnMSSQL      -> DELETE X FROM A AS X WHERE (exists (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID))
       dbnPostgreSQL -> DELETE FROM A AS X WHERE (exists (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID))
       dbnOracle     -> DELETE FROM A X WHERE (exists (SELECT 1 FROM B AS Y WHERE Y.AID = X.ID))

     A subconsulta sai VERBATIM. O caso C08 deste arquivo mediu essa forma nos
     SETE motores. Ha teste dedicado a nao deixar a mensagem virar mentira:
     test.delete.join.TTestDeleteJoin.
     TestSaidaApontadaPelaMensagemRealmenteEmiteSubconsulta - falsificado por
     mutacao dirigida que devolve o Exists a parametrizacao.

  6. O QUE FICA DE FORA DE PROPOSITO, e nao por esquecimento:

       - A forma EXISTS para o InnerJoin ISOLADO. Ela e boa, esta medida e e
         aceita pelos sete - a INTERSECAO NAO E VAZIA, e este arquivo derruba
         com numero a hipotese de que fosse. E tarefa propria, com o custo da
         Parte 8 ja levantado.
       - O 'ON' incondicional de TFluentSQLJoins.Serialize, que produz o mesmo
         ON pendurado TAMBEM NO SELECT, onde esta guarda nao chega.
       - O Exception.Create('Error Message') de
         TFluentSQLJoins.SerializeJoinType.
       - From(IFluentSQL), que descarta os parametros da subconsulta.

     Os quatro estao catalogados e NENHUM foi tocado aqui.
*/
