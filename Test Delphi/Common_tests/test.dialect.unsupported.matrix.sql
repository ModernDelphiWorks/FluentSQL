/*
  ------------------------------------------------------------------------------
  ORACULO DAS SETE CONSTRUCOES EM QUE O DIALETO EMITIA SQL QUE ELE NAO SUPORTA
  (T35)

  As sete foram apontadas pela varredura do PR #163. As sete eram celulas VERDES
  da suite - ou seja, a suite CERTIFICAVA texto que o motor recusa. Este arquivo
  submete cada uma a motor real e responde, item a item, as tres perguntas que a
  tarefa fez:

    (a) o motor tem forma equivalente?
    (b) se tem, a semantica e a MESMA?
    (c) a construcao esta na INTERSECAO dos 6 relacionais ativos?

  O que este arquivo NAO faz: decidir a forma. Tres das sete foram corrigidas
  nesta rodada porque a decisao ja estava tomada ou porque so havia aplicar regra
  que o proprio framework ja aplica; as outras quatro estao MEDIDAS e
  DECLARADAS, sem conserto, porque exigem decisao de forma que nao e do
  implementador. Cada uma diz abaixo em qual grupo esta.

  ------------------------------------------------------------------------------
  MOTORES MEDIDOS - versao perguntada AO MOTOR, nao lida do nome da imagem

    MySQL       8.4.11  (SELECT VERSION(); @@version_comment = MySQL Community
                         Server - GPL)
                mysql:8.4
                sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
    Firebird    5.0.4   (SELECT rdb$get_context('SYSTEM','ENGINE_VERSION')
                         FROM rdb$database;  banner do servidor: LI-V5.0.4.1812)
                firebirdsql/firebird:5.0.4
                sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d
    PostgreSQL  PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu
                postgres:16
                sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b
    SQL Server  Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
                mcr.microsoft.com/mssql/server:2022-latest
                sha256:ba4c8329f48fb8f02e1416be6a930ebfd71268caee78aa985f3af4315e457c89
    Oracle      Oracle AI Database 26ai Free Release 23.26.2.0.0 (v$version.banner_full)
                gvenzl/oracle-free:23-slim-faststart
                sha256:d8913e4e4769b6e60197949bef30a4391713afe662b4b4e71a2665c881bdac8b
    SQLite      3.53.4  (SELECT sqlite_version();)
                keinos/sqlite3:latest
                sha256:a5610a155a8c9007f2050120406a0abcffab246570d6ac1ffe370f5f23e14dc1

    InterBase   NAO MEDIDO - nao existe imagem publica. Nenhuma afirmacao sobre
                este dialeto e feita aqui. Ele tambem esta DESLIGADO por omissao
                no FluentSQL.inc, junto com o DB2; os 6 acima sao exatamente os
                dialetos relacionais ativos no build padrao.

  Containers com prefixo proprio t35-* para nao tocar os de outra tarefa em
  paralelo. Docker engine 29.6.2.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  MATRIZ RESUMO   (S = aceito e verificado ponta a ponta; N = recusado, medido)

  construcao                       MySQL  FB   PG   MSSQL  Oracle  SQLite
  -------------------------------  -----  ---  ---  -----  ------  ------
  1  TRUNCATE TABLE a, b             N     n/m  S     N       N      n/m
  2  TRUNCATE TABLE t PARTITION(p)   N     n/m  n/m   n/m     n/m    n/m
  3  TRUNCATE TABLE t (uma tabela)   S     N    S     S       S      N
  4  renomear TABELA por DDL         S     N    S     N(*)    S      S
  5  DROP INDEX IF EXISTS            N     N    S     S       S      S
  6  INSERT ... VALUES (..),(..)     S     N    S     S       S(**)  S
  7  INTERSECT                       S     N    S     S       S      S

  n/m = o serializador daquele dialeto ja levantava antes de emitir, logo nao ha
        texto a submeter. Nao e "nao medido por preguica": e "nao existe enunciado".
  (*)  o MSSQL nao tem ALTER TABLE ... RENAME TO; tem o procedimento sp_rename,
       que executou. Nao e DDL de ALTER TABLE.
  (**) Oracle: aceito nesta versao (23ai). NAO era aceito em 19c/21c. A celula
       vale para a versao medida e esta dita assim de proposito.

  Conclusao da coluna (c): das sete, NENHUMA esta na intersecao dos 6. As linhas
  1, 2 e 5 tem o Firebird e/ou o MySQL fora; as linhas 3, 6 e 7 tem o Firebird
  sozinho fora; a linha 4 tem Firebird e MSSQL fora.

  PLACAR DA RODADA: das sete, QUATRO foram corrigidas (itens 1-2, 3, 5 e 6) e
  TRES ficam medidas e declaradas sem conserto (itens 4, 7 e 8), porque as tres
  convergem numa pergunta de convencao que subiu ao dono. Nenhuma foi desligada
  com [Ignore] para fechar numero; ao contrario, o item 3 RELIGOU uma celula que
  ja estava desligada.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ITEM 1-2   MySQL   TRUNCATE TABLE a, b       >>> CORRIGIDO NESTA RODADA <<<

  O HEAD antes emitia, e a suite fixava VERDE em DOIS lugares
  (test_esp074_unit.pas e test.ddl.mysql.pas):

      TRUNCATE TABLE `T1`, `T2`

  TRANSCRICAO   docker exec -i t35-mysql mysql -uroot -p... -t t35db

      mysql> CREATE TABLE T1 (ID INT PRIMARY KEY AUTO_INCREMENT, V VARCHAR(5));
      mysql> CREATE TABLE T2 (ID INT PRIMARY KEY AUTO_INCREMENT, V VARCHAR(5));
      mysql> INSERT INTO T1 (V) VALUES ('a'),('b');

      -- CONTROLE POSITIVO: a forma de UMA tabela executa
      mysql> TRUNCATE TABLE `T1`;
      mysql> SELECT COUNT(*) AS T1_APOS FROM T1;
      +---------+
      | T1_APOS |
      +---------+
      |       0 |
      +---------+

      -- O ENUNCIADO QUE A SUITE FIXAVA
      mysql> TRUNCATE TABLE `T1`, `T2`;
      ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check
      the manual that corresponds to your MySQL server version for the right
      syntax to use near ', `T2`' at line 1

  (a) FORMA EQUIVALENTE? Nao ha, em uma instrucao. Duas instrucoes TRUNCATE
      seguidas nao sao equivalentes: no MySQL o TRUNCATE faz COMMIT IMPLICITO,
      medido -

          mysql> START TRANSACTION;
          mysql> INSERT INTO T2 (V) VALUES ('z');
          mysql> TRUNCATE TABLE T2;
          mysql> ROLLBACK;
          mysql> SELECT COUNT(*) AS T2_APOS_ROLLBACK FROM T2;
          +------------------+
          | T2_APOS_ROLLBACK |
          +------------------+
          |                0 |
          +------------------+

      - de modo que "duas instrucoes" sao duas transacoes, enquanto o
      TRUNCATE multi-tabela do PostgreSQL e atomico. Alem disso o contrato
      declarado do builder e "one command per AsString" (ESP-029,
      FluentSQL.Interfaces.pas, IFluentDDLTruncateTableBuilder).
  (b) n/a - nao ha equivalente.
  (c) NAO. A lista de tabelas e exclusividade do PostgreSQL entre os 6:

          PostgreSQL   TRUNCATE TABLE "a1", "a2";      -> TRUNCATE TABLE (ok)
                       a1: 2 -> 0, a2: 2 -> 0
          MySQL        ERROR 1064 (acima)
          SQL Server   Msg 102, Level 15: Incorrect syntax near ','.
          Oracle       ORA-03291: Invalid truncate option - missing STORAGE keyword
          SQLite       nao tem TRUNCATE (o serializador ja mapeia DELETE FROM)
          Firebird     nao tem TRUNCATE (ver item 3)

  DECISAO APLICADA: levantar ENotSupportedException. Nao e convencao nova - o
  MSSQL e o Oracle JA levantavam exatamente isso na mesma construcao
  (FluentSQL.DDL.Serialize.MSSQL.pas e ...Oracle.pas, TruncateTable), assim como
  SQLite, Firebird e o proprio TFluentDDLSerializeAbstract.TruncateTable. O MySQL
  era o unico que conhecia a regra pelo vizinho e nao a aplicava a si.

  ------------------------------------------------------------------------------
  ITEM 3   MySQL   TRUNCATE TABLE t PARTITION (p)   >>> CORRIGIDO NESTA RODADA <<<

  ORDEM DOS FATOS, que importa: a medicao abaixo foi feita PRIMEIRO e entregue
  SEM conserto, porque trocar a forma do enunciado e decisao de forma. A decisao
  veio depois, do orquestrador, com estas razoes - todas medidas aqui: e a UNICA
  forma que o MySQL tem, a semantica e identica, e a expectativa ja estava
  escrita e DESLIGADA na suite. Nao e superficie nova: a API JA oferecia
  TRUNCATE ... PARTITION e ja emitia texto que o motor recusa; faze-la emitir a
  forma valida e conserto.

  O HEAD ANTES emitia, e test_esp074_unit.pas fixava VERDE:

      TRUNCATE TABLE `logs` PARTITION (p2023)

  TRANSCRICAO

      mysql> CREATE TABLE logs (ID INT NOT NULL, D DATE NOT NULL)
          -> PARTITION BY RANGE (YEAR(D))
          -> (PARTITION p2023 VALUES LESS THAN (2024),
          ->  PARTITION pmax  VALUES LESS THAN MAXVALUE);
      mysql> INSERT INTO logs VALUES (1,'2023-05-01'),(2,'2025-05-01');

      mysql> TRUNCATE TABLE `logs` PARTITION (p2023);
      ERROR 1064 (42000) at line 1: ... right syntax to use near
      'PARTITION (p2023)' at line 1

  (a) SIM, HA FORMA NATIVA, e ela foi verificada PONTA A PONTA - nao parou no
      parser:

          mysql> INSERT INTO logs VALUES (9,'2023-09-09');
          mysql> SELECT COUNT(*) AS P2023_ANTES FROM logs PARTITION (p2023);
          +-------------+
          | P2023_ANTES |
          +-------------+
          |           1 |
          +-------------+
          mysql> ALTER TABLE `logs` TRUNCATE PARTITION `p2023`;
          mysql> SELECT COUNT(*) AS P2023_DEPOIS FROM logs PARTITION (p2023);
          +--------------+
          | P2023_DEPOIS |
          +--------------+
          |            0 |
          +--------------+
          mysql> SELECT COUNT(*) AS PMAX_INTACTO FROM logs PARTITION (pmax);
          +--------------+
          | PMAX_INTACTO |
          +--------------+
          |            1 |
          +--------------+

      Aceita com e sem crase no nome da particao; as duas formas foram
      submetidas e as duas esvaziaram a particao.
  (b) SIM, a semantica e a MESMA - nao ha drift a declarar. "ALTER TABLE ...
      TRUNCATE PARTITION" nao e um substituto aproximado: e a UNICA forma que o
      MySQL tem para a operacao. Nao existe "TRUNCATE TABLE ... PARTITION" no
      MySQL para comparar contra ela.
  (c) NAO esta na intersecao. Dos 6, so MySQL e Oracle tem particao nesta
      forma (Oracle: ALTER TABLE t TRUNCATE PARTITION p); PostgreSQL levanta
      explicitamente ("PARTITION clause is not supported for TRUNCATE"),
      Firebird levanta, SQLite e MSSQL nao expressam.

  DECISAO APLICADA: emitir ALTER TABLE t TRUNCATE PARTITION p. O enunciado com
  particao deixou de ser "TRUNCATE TABLE com um sufixo" e passou a ser montado
  como outro comando, porque e outro comando.

  A CELULA [Ignore]ADA FOI RELIGADA, NAO REESCRITA. Ela estava em
  test.ddl.mysql.pas com o texto "T6: emite sintaxe Oracle (TRUNCATE TABLE t
  PARTITION (p)); MySQL exige ALTER TABLE t TRUNCATE PARTITION p." e ja
  assertava ALTER TABLE `T1` TRUNCATE PARTITION `p1`. Esse texto CASA
  EXATAMENTE com o que o HEAD passou a emitir - conferido caractere a caractere,
  inclusive as crases no nome da particao, que o motor aceita (medido com e sem).
  Nenhum ajuste foi feito na celula para casar com o codigo: o codigo veio ate
  ela. A outra celula, em test_esp074_unit.pas, essa sim foi reescrita, porque
  fixava o texto invalido.

  VERIFICACAO PONTA A PONTA DO TEXTO FINAL, submetido VERBATIM, com massa em
  DUAS particoes para que "esvaziou a certa" seja verificavel:

      mysql> SELECT VERSION();                       -> 8.4.11
      mysql> CREATE TABLE logs (ID INT NOT NULL, D DATE NOT NULL)
          -> PARTITION BY RANGE (YEAR(D))
          -> (PARTITION p2023 VALUES LESS THAN (2024),
          ->  PARTITION pmax  VALUES LESS THAN MAXVALUE);
      mysql> INSERT INTO logs VALUES (1,'2023-05-01'),(7,'2023-07-07'),(2,'2025-05-01');
      mysql> SELECT COUNT(*) AS P2023_ANTES FROM logs PARTITION (p2023);   -> 2
      mysql> SELECT COUNT(*) AS PMAX_ANTES  FROM logs PARTITION (pmax);    -> 1

      -- VERBATIM do HEAD:
      mysql> ALTER TABLE `logs` TRUNCATE PARTITION `p2023`;

      mysql> SELECT COUNT(*) AS P2023_DEPOIS FROM logs PARTITION (p2023);  -> 0
      mysql> SELECT COUNT(*) AS PMAX_DEPOIS  FROM logs PARTITION (pmax);   -> 1
      mysql> SELECT ID, D FROM logs;
      +----+------------+
      | ID | D          |
      +----+------------+
      |  2 | 2025-05-01 |
      +----+------------+

      -- CONTROLE NEGATIVO: o texto que o HEAD emitia ANTES
      mysql> TRUNCATE TABLE `logs` PARTITION (p2023);
      ERROR 1064 (42000) at line 1: ... near 'PARTITION (p2023)' at line 1

  Nao parou no parser: das tres linhas, sumiram exatamente as duas de 2023 e
  sobrou exatamente a de 2025.

  E OS DIALETOS SEM PARTICAO? Medido no HEAD final, chamando
  .TruncateTable('logs').Partition('p2023') em cada um:

      MySQL       EMITE    ALTER TABLE `logs` TRUNCATE PARTITION `p2023`
      PostgreSQL  LEVANTA  ENotSupportedException: DDL PostgreSQL: PARTITION
                           clause is not supported for TRUNCATE.
      Firebird    LEVANTA  ENotSupportedException: DDL Firebird: advanced
                           TRUNCATE options (RESTART IDENTITY, CASCADE,
                           PARTITION) are not supported.
      MSSQL       LEVANTA  ENotSupportedException: DDL MSSQL: advanced TRUNCATE
                           options are not supported in this build.
      Oracle      LEVANTA  ENotSupportedException: DDL Oracle: advanced TRUNCATE
                           options are not supported.
      SQLite      LEVANTA  ENotSupportedException: DDL SQLite: advanced TRUNCATE
                           options are not supported.

  Ou seja: NENHUM dos outros emite texto invalido - os cinco ja recusavam antes
  desta rodada e continuam recusando. Nao ha aqui achado da mesma familia.

  DUAS OBSERVACOES QUE FICAM DECLARADAS, sem conserto, por serem alem do pedido:

    1) Oracle: o dialeto TEM a construcao (ALTER TABLE t TRUNCATE PARTITION p),
       e mesmo assim o serializador recusa. Isso NAO e o defeito desta tarefa -
       recusar e honesto, nao produz texto invalido - e sim uma LACUNA DE
       CAPACIDADE. Se ela deve ser preenchida e decisao de produto.
    2) [ACHADO NA PRIMEIRA PASSAGEM, FECHADO NESTA] Ate aqui NENHUMA celula
       travava as guardas de PARTICAO de PostgreSQL, Firebird, MSSQL, Oracle e
       SQLite - os unicos tres usos de .Partition( na suite eram todos dbnMySQL.
       Provado por mutacao, nao suposto: M10 trocava o raise do PostgreSQL por
       uma emissao de ' PARTITION (...)' e a suite INTEIRA continuava verde - o
       mutante SOBREVIVIA.

       A lacuna foi trazida como recomendacao, sem execucao, porque ampliar
       cobertura nao e decisao do implementador. O orquestrador autorizou
       fecha-la, com a razao que a torna necessaria AGORA e nao antes: ate esta
       rodada o .Partition(...) nao produzia SQL valido em dialeto NENHUM - o
       MySQL emitia sintaxe Oracle, os outros cinco levantavam - e o que os
       cinco faziam era indiferente. Ao fazer um dialeto EMITIR de verdade, esta
       entrega criou o contrato "particao e so do MySQL". Guarda de contrato que
       ninguem mede e guarda que alguem remove por acidente, e a remocao passava
       silenciosa.

       As cinco celulas estao em test_esp074_unit.pas, como
       TestTruncateTable_<dialeto>_Partition_RaisesNotSupported, e cada uma foi
       medida load-bearing: M10..M14 na tabela de mutacao, cada mutante matando
       EXATAMENTE a sua celula e nenhuma outra. O M10 agora MORRE.

       O QUE CONTINUA SEM COBERTURA, de proposito: o M2, que troca so a MENSAGEM
       de um raise, segue sobrevivendo. Nao e o mesmo caso e nao vira celula. O
       M2 e decoracao - nenhuma celula assere mensagem, e mensagem nao e
       contrato aqui; o M10 era buraco real. Cobrir um e recusar o outro e a
       distincao, nao incoerencia.

  MongoDB, uma linha e fora de toda contagem: emite
  {"delete":"logs","deletes":[{"q":{},"limit":0}]}, descartando o modificador.

  ------------------------------------------------------------------------------
  ITEM 4   Firebird   TRUNCATE TABLE        >>> MEDIDO, NAO CORRIGIDO <<<

  O HEAD emite, e test.ddl.firebird.pas fixa VERDE:

      TRUNCATE TABLE "CLIENTES"

  TRANSCRICAO   isql, base /var/lib/firebird/data/t35b.fdb

      SQL> TRUNCATE TABLE "CLIENTES";
      Statement failed, SQLSTATE = 42000
      Dynamic SQL Error
      -SQL error code = -104
      -Token unknown - line 1, column 1
      -TRUNCATE

  (a) SIM: DELETE FROM "CLIENTES" executa (medido, sem erro).
  (b) NAO, A SEMANTICA DIFERE - e a diferenca foi MEDIDA, nao citada:

          SQL> CREATE TABLE T_IDENT (ID INTEGER GENERATED BY DEFAULT AS IDENTITY
               PRIMARY KEY, V VARCHAR(5));
          SQL> INSERT INTO T_IDENT (V) VALUES ('a');
          SQL> INSERT INTO T_IDENT (V) VALUES ('b');
          SQL> DELETE FROM T_IDENT;
          SQL> INSERT INTO T_IDENT (V) VALUES ('c');
          SQL> SELECT ID, V FROM T_IDENT;
                    ID V
          ============ ======
                     3 c

      O identificador seguiu em 3: o DELETE NAO reinicia a identidade, o que o
      TRUNCATE de MySQL e PostgreSQL faz (medido no MySQL: apos DELETE o proximo
      ID saiu 3; apos TRUNCATE saiu 1). E o DELETE e reversivel:

          SQL> SET AUTODDL OFF;
          SQL> DELETE FROM T_IDENT;
          SQL> ROLLBACK;
          SQL> SELECT COUNT(*) AS APOS_ROLLBACK FROM T_IDENT;
                 APOS_ROLLBACK
          =====================
                             1

      Alem disso o DELETE dispara gatilhos de linha e gera log por linha, o que
      o TRUNCATE nao faz. Emitir DELETE FROM sob o nome TruncateTable entrega
      uma operacao com custo, com gatilho e sem reinicio de identidade para
      quem pediu o contrario.
  (c) NAO. Firebird e SQLite sao os dois dos 6 sem TRUNCATE; MySQL, PostgreSQL,
      MSSQL e Oracle tem (medido em cada um).

  POR QUE NAO FOI CORRIGIDO - E O PONTO QUE PRECISA DE DECISAO: ha DUAS
  convencoes ja existentes no proprio repositorio, em conflito direto, para
  exatamente este caso.

      convencao A  (SQLite)   FluentSQL.DDL.Serialize.SQLite.pas, TruncateTable:
                              "SQLite mappings: DELETE FROM is the standard way
                              to clear a table" -> emite DELETE FROM, e a celula
                              TestTruncateTable_SQLite_GeneratesDeleteFrom esta
                              VERDE fixando isso.
      convencao B  (o resto)  levantar ENotSupportedException quando o dialeto
                              nao expressa a construcao.

  Ou seja: escolher "emitir DELETE FROM" para o Firebird e seguir o SQLite;
  escolher "levantar" e seguir todos os outros - e implica reabrir se o SQLite
  continua onde esta. Nao e aplicar regra existente, e escolher entre duas.
  Fica para o dono. RECOMENDACAO desta medicao: como a semantica difere de
  forma verificada, e a regra da casa e "se a semantica difere, emitir o
  equivalente e pior que recusar", a leitura consistente e LEVANTAR nos dois
  (Firebird e SQLite) - o que faz do SQLite um BREAKING adicional que esta
  tarefa nao tinha mandato para provocar.

  ------------------------------------------------------------------------------
  ITEM 5   Firebird   renomear TABELA        >>> CORRIGIDO NESTA RODADA <<<

  O HEAD antes emitia, e test.ddl.firebird.pas fixava VERDE:

      ALTER TABLE "TAB_A" TO "TAB_B"

  TRANSCRICAO - as TRES formas candidatas, todas recusadas:

      SQL> ALTER TABLE "TAB_A" TO "TAB_B";
      Statement failed, SQLSTATE = 42000
      -SQL error code = -104
      -Token unknown - line 1, column 21
      -TO

      SQL> ALTER TABLE "TAB_A" RENAME TO "TAB_B";
      -SQL error code = -104
      -Token unknown - line 1, column 21
      -RENAME

      SQL> RENAME TABLE "TAB_A" TO "TAB_B";
      -SQL error code = -104
      -Token unknown - line 1, column 1
      -RENAME

  CONTROLE POSITIVO na mesma sessao - o vizinho, que renomeia COLUNA e que o
  driver tambem emite, esta CERTO e nao foi tocado:

      SQL> ALTER TABLE "TAB_A" ALTER "LEGADO" TO "NOVO_NOME";
      SQL> SELECT RDB$FIELD_NAME FROM RDB$RELATION_FIELDS
           WHERE RDB$RELATION_NAME='TAB_A';
      RDB$FIELD_NAME
      ===============
      ID
      NOVO_NOME

  (a) NAO HA FORMA EQUIVALENTE. O Firebird nao tem DDL de renomear tabela -
      nenhuma. O caminho e recriar e migrar, que nao e uma instrucao.
  (b) n/a.
  (c) NAO. Dos 6: PostgreSQL, MySQL, SQLite e Oracle aceitam ALTER TABLE ...
      RENAME TO (medido nos quatro); o MSSQL recusa o ALTER TABLE ("Msg 102 ...
      Incorrect syntax near 'RENAME'") e resolve por sp_rename, que executou;
      o Firebird nao tem nada.

  DECISAO APLICADA: levantar. Nao e convencao nova - e a mesma que este arquivo
  ja aplica ao que o Firebird nao expressa (DropTable com IfExists, CreateSchema,
  DropSchema, sequencias com IF EXISTS). E nao ha aqui o dilema do item 4,
  porque nao existe segunda convencao: nao ha texto algum a emitir.

  ------------------------------------------------------------------------------
  ITEM 6   Firebird   DROP INDEX IF EXISTS   >>> CORRIGIDO NESTA RODADA <<<

  O HEAD antes emitia, e test.ddl.firebird.pas fixava VERDE:

      DROP INDEX IF EXISTS "IX_CLI_NOME"

  TRANSCRICAO - indice EXISTENTE e indice AUSENTE, o MESMO erro nos dois, o que
  prova que a recusa e de SINTAXE e nao de alvo:

      SQL> DROP INDEX IF EXISTS "IX_CLI_NOME";     -- o indice existia
      Statement failed, SQLSTATE = 42000
      -SQL error code = -104
      -Token unknown - line 1, column 15
      -EXISTS

      SQL> DROP INDEX IF EXISTS "IX_NAO_EXISTE";   -- o indice nao existia
      -SQL error code = -104
      -Token unknown - line 1, column 15
      -EXISTS

  CONTROLE POSITIVO - a forma nua, que o HEAD continua emitindo, executa e o
  efeito foi conferido no catalogo:

      SQL> CREATE INDEX "IX_TMP2" ON "TAB_A" ("NOVO_NOME");
      SQL> SELECT RDB$INDEX_NAME FROM RDB$INDICES WHERE RDB$INDEX_NAME='IX_TMP2';
      RDB$INDEX_NAME
      ===============
      IX_TMP2
      SQL> DROP INDEX "IX_TMP2";
      SQL> SELECT COUNT(*) AS AINDA_EXISTE FROM RDB$INDICES
           WHERE RDB$INDEX_NAME='IX_TMP2';
             AINDA_EXISTE
      =====================
                         0

  CONTROLE NEGATIVO - o que a aplicacao passa a ter de tratar no lugar do IF
  EXISTS:

      SQL> DROP INDEX "IX_NAO_EXISTE";
      Statement failed, SQLSTATE = 42000
      unsuccessful metadata update
      -DROP INDEX IX_NAO_EXISTE failed
      -Index not found

  (a) NAO, nao em uma instrucao DDL. O contorno e EXECUTE BLOCK consultando
      RDB$INDICES, que e outra coisa e nao cabe num serializador de DROP INDEX.
  (b) n/a.
  (c) NAO. PostgreSQL, SQL Server, SQLite e Oracle aceitam DROP INDEX IF EXISTS
      (medido nos quatro; no Oracle 23ai devolveu "Index dropped." para indice
      inexistente); o MySQL recusa - "ERROR 1064 ... near 'IF EXISTS
      ix_nao_existe ON T2'" - e o serializador MySQL ja levantava por isso
      (FluentSQL.DDL.Serialize.MySQL.pas, DropIndex/GetIfExists); o Firebird
      recusa.

  DECISAO APLICADA: levantar, espelhando literalmente o metodo vizinho DropTable
  do MESMO arquivo, que ja recusa o MESMO modificador neste MESMO dialeto. Era
  incoerencia interna, nao decisao de produto.

  ------------------------------------------------------------------------------
  ITEM 7   Firebird   INSERT ... VALUES (..),(..)   >>> MEDIDO, NAO CORRIGIDO <<<
                      (o INSERT em LOTE, que o CHANGELOG anuncia como entregue -
                       ESP-015, CHANGELOG [1.0.9])

  O HEAD emite, e test.core.params.pas fixa VERDE em
  TestInsertBatchTwoRowsFirebird (unidade viva: entra em PTestFluentSQLFirebird
  e em TestFluentSQL_MySQL):

      INSERT INTO USUARIOS (NOME, IDADE) VALUES (:p1, :p2), (:p3, :p4)

  TRANSCRICAO - submetido VERBATIM (forma :pN) e na forma que um driver
  realmente manda ao motor (posicional ?), via EXECUTE STATEMENT, que e um
  prepare de verdade dentro do motor:

      SQL> INSERT INTO USUARIOS (NOME, IDADE) VALUES (:p1, :p2), (:p3, :p4);
      Statement failed, SQLSTATE = 42000
      -SQL error code = -104
      -Token unknown - line 1, column 53
      -,

      SQL> EXECUTE BLOCK AS BEGIN
             EXECUTE STATEMENT
               ('INSERT INTO USUARIOS (NOME, IDADE) VALUES (?, ?), (?, ?)')
               ('ANA',20,'BOB',21);
           END
      Statement failed, SQLSTATE = 42000
      -SQL error code = -104
      -Token unknown - line 1, column 49
      -,

  CONTROLE POSITIVO - a forma de UMA linha, parametrizada, pelo mesmo caminho:

      SQL> EXECUTE BLOCK AS BEGIN
             EXECUTE STATEMENT
               ('INSERT INTO USUARIOS (NOME, IDADE) VALUES (?, ?)') ('CTRL1', 1);
           END
      -- executou; a linha CTRL1 aparece no SELECT final.

  O construtor de tabela VALUES tambem nao existe no dialeto, o que fecha a
  porta obvia:

      SQL> SELECT * FROM (VALUES (1),(2));
      -SQL error code = -104
      -Token unknown - line 1, column 16
      -VALUES

  (a) HA DUAS FORMAS DE LOTE que o Firebird aceita, e AS DUAS FORAM MEDIDAS
      PONTA A PONTA - mas as duas cobram um preco que o construtor atual nao
      pode pagar:

      A1) INSERT ... SELECT ... UNION ALL, com literais - FUNCIONA:

          SQL> INSERT INTO USUARIOS (NOME, IDADE)
               SELECT 'ANA',20 FROM RDB$DATABASE
               UNION ALL SELECT 'BOB',21 FROM RDB$DATABASE;
          SQL> SELECT * FROM USUARIOS;
          NOME                                  IDADE
          ============================== ============
          ANA                                      20
          BOB                                      21

          ... mas com PARAMETRO nu ela NAO prepara:

          SQL> EXECUTE BLOCK AS BEGIN EXECUTE STATEMENT
                 ('INSERT INTO USUARIOS (NOME, IDADE)
                   SELECT ?, ? FROM RDB$DATABASE
                   UNION ALL SELECT ?, ? FROM RDB$DATABASE') ('X2',9,'X3',9);
               END
          Statement failed, SQLSTATE = HY004
          -SQL error code = -804
          -Data type unknown

          E o contraste que isola a causa - SEM o UNION ALL, o mesmo parametro
          nu prepara e insere:

          SQL> EXECUTE BLOCK AS BEGIN EXECUTE STATEMENT
                 ('INSERT INTO USUARIOS (NOME, IDADE) SELECT ?, ? FROM RDB$DATABASE')
                 ('X1', 9);
               END
          -- executou; a linha X1 aparece no SELECT final.

          Com CAST explicito por coluna, a forma com UNION ALL passa a preparar
          e a inserir:

          SQL> EXECUTE BLOCK AS BEGIN EXECUTE STATEMENT
                 ('INSERT INTO USUARIOS (NOME, IDADE)
                   SELECT CAST(? AS VARCHAR(30)), CAST(? AS INTEGER) FROM RDB$DATABASE
                   UNION ALL
                   SELECT CAST(? AS VARCHAR(30)), CAST(? AS INTEGER) FROM RDB$DATABASE')
                 ('CARL', 30, 'DORA', 31);
               END
          -- executou; CARL/30 e DORA/31 aparecem no SELECT final.

      A2) EXECUTE BLOCK com parametros declarados - FUNCIONA:

          SQL> EXECUTE BLOCK AS BEGIN EXECUTE STATEMENT
                 ('EXECUTE BLOCK (A1 VARCHAR(30)=?, B1 INTEGER=?,
                                  A2 VARCHAR(30)=?, B2 INTEGER=?) AS
                   BEGIN
                     INSERT INTO USUARIOS (NOME,IDADE) VALUES (:A1,:B1);
                     INSERT INTO USUARIOS (NOME,IDADE) VALUES (:A2,:B2);
                   END')
                 ('EB1', 5, 'EB2', 6);
               END
          -- executou; EB1/5 e EB2/6 aparecem no SELECT final.

      LEITURA FINAL DA MASSA, que confirma tudo acima de uma vez:

          NOME                                  IDADE
          ============================== ============
          ANA                                      20
          BOB                                      21
          CARL                                     30
          CTRL1                                     1
          DORA                                     31
          EB1                                       5
          EB2                                       6
          X1                                        9

  (b) SEMANTICA: as duas inserem as mesmas linhas. A A2 nao e atomica do mesmo
      jeito que um INSERT unico (sao N instrucoes dentro de um bloco), e as duas
      exigem o que o construtor NAO TEM: o TIPO SQL de cada coluna. O
      IFluentSQL recebe SetValue('NOME','ANA') - um Variant, sem tipo declarado
      de coluna. Nao ha de onde tirar VARCHAR(30) nem INTEGER sem consultar o
      catalogo, que o FluentSQL nao faz e nao deve fazer. Este e o custo real da
      correcao, e e por isso que ela nao cabe numa guarda de tres linhas.
  (c) NAO esta na intersecao. Medido: PostgreSQL 16.14 (INSERT 0 2), SQLite
      3.53.4 (2 linhas), SQL Server 2022 (2 rows affected), MySQL 8.4.11 (2
      linhas) e Oracle 23.26 (2 rows created) aceitam. Firebird 5.0.4 nao.
      Ressalva registrada: o Oracle so aceita a partir do 23c - em 19c/21c a
      celula seria N, e este arquivo nao afirma nada sobre versoes que nao
      mediu.

  ESTE E O MAIS GRAVE DOS SETE, e por isso vai declarado sem conserto em vez de
  consertado as pressas: o CHANGELOG anuncia INSERT em lote como entregue
  (ESP-015 / [1.0.9]) e ele NAO FUNCIONA num dialeto ativo. As saidas possiveis
  sao (i) levantar no Firebird, que retira uma feature publicada de um dialeto,
  (ii) emitir a forma A1/A2, que exige o construtor aprender tipo de coluna, ou
  (iii) manter e documentar a lacuna. As tres sao decisao de produto.

  ------------------------------------------------------------------------------
  ITEM 8   Firebird   INTERSECT              >>> MEDIDO, NAO CORRIGIDO <<<

  O HEAD emite, e UTestFluentSQLFirebird.pas fixa VERDE em DUAS celulas
  (TestIntersect_SerializesCompoundSelect e
  TestParams_Firebird_Intersect_ParametersOnBothSides):

      SELECT ID FROM CLIENTES_ATIVOS INTERSECT SELECT ID FROM CLIENTES_PREFERENCIAIS

  TRANSCRICAO

      SQL> SELECT ID FROM CLIENTES_ATIVOS
           INTERSECT SELECT ID FROM CLIENTES_PREFERENCIAIS;
      Statement failed, SQLSTATE = 42000
      -SQL error code = -104
      -Token unknown - line 1, column 42
      -SELECT

  CONTROLE POSITIVO - a operacao de conjunto que o Firebird TEM:

      SQL> SELECT ID FROM CLIENTES_ATIVOS UNION SELECT ID FROM CLIENTES_PREFERENCIAIS;
                ID
      ============
                 1
                 2
                 3

  (a) HA um equivalente aproximado, medido:

      SQL> SELECT DISTINCT ID FROM CLIENTES_ATIVOS
           WHERE ID IN (SELECT ID FROM CLIENTES_PREFERENCIAIS);
                ID
      ============
                 2

      que devolve o mesmo conjunto que o INTERSECT devolveria neste caso.
  (b) A SEMANTICA NAO E A MESMA no caso geral, e a diferenca importa: o
      INTERSECT compara a LINHA INTEIRA (n colunas) e casa NULL com NULL; o
      "IN (subconsulta)" e de uma coluna e NAO casa NULL com NULL. Trocar um
      pelo outro em codigo gerado, sem o autor pedir, muda o resultado em massa
      com nulos. Alem disso o INTERSECT e um operador de conjunto sobre duas
      consultas independentes - a traducao para IN exige reescrever a estrutura
      da consulta, nao so trocar uma palavra.
  (c) NAO esta na intersecao, e o Firebird e o UNICO fora: medido, aceitam
      PostgreSQL 16.14, SQL Server 2022, Oracle 23.26, SQLite 3.53.4 e MySQL
      8.4.11 - este ultimo desde a 8.0.31, e nesta versao a forma explicita
      "(SELECT 1) INTERSECT (SELECT 1)" devolveu 1.

  POR QUE NAO FOI CORRIGIDO: IFluentSQL.Intersect e superficie PUBLICA do
  nucleo, nao um detalhe de um serializador de DDL. Fazer o dbnFirebird
  levantar retira da API uma operacao que a Fase 2 do ROADMAP lista como
  entregue, e reabre a pergunta que a regua da casa faz: se a API e a
  INTERSECAO dos dialetos, e o Firebird nao tem INTERSECT, o Intersect ainda
  deve existir na API? Isso e decisao do dono, nao do implementador.

  ACHADO INCIDENTAL, uma linha e sem tarefa: o EXCEPT tambem nao existe no
  Firebird 5.0.4 - "SELECT ID FROM CLIENTES_ATIVOS EXCEPT SELECT ID FROM
  CLIENTES_PREFERENCIAIS" devolve o mesmo -104 -Token unknown ... -SELECT.

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  VERIFICACAO PONTA A PONTA DO TEXTO QUE O HEAD FINAL EMITE

  O texto abaixo nao foi transcrito de teste nem digitado a mao: saiu de um
  programa que chama o HEAD e imprime o AsString (ou a excecao) de cada
  construcao. Cada linha "OK" foi entao submetida VERBATIM ao motor, com massa,
  conferindo o DADO e nao so o parser.

      MY_TRUNC_1     OK     TRUNCATE TABLE `CLIENTES`
      MY_TRUNC_N     RAISE  ENotSupportedException | DDL MySQL: multiple tables
                            in a single TRUNCATE are not supported.
      MY_TRUNC_PART  OK     ALTER TABLE `logs` TRUNCATE PARTITION `p2023`
      FB_TRUNC       OK     TRUNCATE TABLE "CLIENTES"                    <- item 4
      FB_RENAME_TAB  RAISE  ENotSupportedException | DDL Firebird: renaming a
                            table is not supported; ...
      FB_RENAME_COL  OK     ALTER TABLE "TAB_A" ALTER "LEGADO" TO "NOVO_NOME"
      FB_DROPIX      OK     DROP INDEX "IX_TMP3"
      FB_DROPIX_IFEX RAISE  ENotSupportedException | DDL DROP INDEX: IF EXISTS is
                            not emitted for Firebird in this build; ...
      FB_BATCH       OK     INSERT INTO USUARIOS (NOME, IDADE)
                            VALUES (:p1, :p2), (:p3, :p4)                <- item 7
      FB_INTERSECT   OK     SELECT ID FROM CLIENTES_ATIVOS INTERSECT
                            SELECT ID FROM CLIENTES_PREFERENCIAIS        <- item 8

  SUBMISSAO VERBATIM, base t35b.fdb / esquema t35db:

      [MY_TRUNC_1]     antes 3 linhas -> TRUNCATE TABLE `CLIENTES` -> depois 0. OK
      [MY_TRUNC_PART]  p2023 2->0 e pmax 1->1; sobrou exatamente a linha de 2025.
                       Controle negativo: o texto ANTIGO da ERROR 1064. OK
      [FB_RENAME_COL]  SELECT "LEGADO"    -> 'v'
                       ALTER TABLE "TAB_A" ALTER "LEGADO" TO "NOVO_NOME"
                       SELECT "NOVO_NOME" -> 'v'    dado preservado. OK
      [FB_DROPIX]      RDB$INDICES IX_TMP3: 1 -> DROP INDEX "IX_TMP3" -> 0. OK
      [FB_TRUNC]       -104 -TRUNCATE - item 4, declarado, nao consertado
      [FB_BATCH]       -104 -, (col 53) - item 7, declarado, nao consertado
      [FB_INTERSECT]   -104 -SELECT (col 42) - item 8, declarado, nao consertado

  As tres construcoes corrigidas nao tem texto a submeter: elas passaram a
  levantar. O que foi submetido delas e o que o HEAD PRESERVA ao redor -
  TRUNCATE de uma tabela no MySQL, rename de COLUNA e DROP INDEX nu no Firebird
  - para provar que a guarda nao levou o vizinho junto.

  ------------------------------------------------------------------------------
  MUTACAO DIRIGIDA - as guardas sao load-bearing, e os vizinhos estao travados

  Cada mutacao foi aplicada ao HEAD, compilada (11/11) e a suite inteira rodada;
  a coluna diz quais celulas caem ALEM das que ja caem no HEAD.

    id    mutacao                                          celulas mortas
    ----  -----------------------------------------------  --------------
    M1    remove a guarda multi-tabela do MySQL            3
          (Common.TestTruncateTable_MySQL_MultiTable_RaisesNotSupported,
           Common.TestTruncateTable_MySQL_MultiTableWithPartition_RaisesNotSupported,
           MySQL.TestTruncateTable_MySQL_MultiTable_RaisesNotSupported)
    M2    troca so a MENSAGEM do raise do rename Firebird  0  <- SOBREVIVE
          (esperado e declarado: nenhuma celula assere a mensagem, so a classe)
    M2b   faz o rename Firebird voltar a EMITIR            1
          (Firebird.TestAlterTableRenameTable_Firebird_RaisesNotSupported)
    M3    faz o DROP INDEX IF EXISTS Firebird voltar a EMITIR  1
          (Firebird.TestDropIndex_Firebird_IfExists_RaisesNotSupported)
    M4    faz o PostgreSQL RECUSAR TRUNCATE multi-tabela   2
          (Common e PostgreSQL .TestTruncateTable_PostgreSQL_MultiTable_GeneratesExpected)
    M5b   quebra o rename de tabela do serializador BASE   3
          (MySQL, PostgreSQL e SQLite .TestAlterTableRenameTable_*_GeneratesExpected)
    M6    quebra o DROP INDEX IF EXISTS do SQLite          1
          (SQLite.TestDropIndexIfExists_SQLite_GeneratesExpected)
    M7    quebra o DROP INDEX nu do Firebird               1
          (Firebird.TestDropIndex_Firebird_GeneratesExpected)
    M8    quebra o TRUNCATE de UMA tabela do MySQL         3
          (Common.TestTruncateTable_MySQL_GeneratesExpected,
           Common e MySQL .TestTruncateTable_MySQL_GeneratesExpected)
    M9    quebra o ramo ALTER TABLE ... TRUNCATE PARTITION 2
          (Common e MySQL .TestTruncateTable_MySQL_Partition_GeneratesExpected)
    M1b   remove a guarda multi-tabela do MySQL, ja com o   3
          item 3 aplicado
          (Common.TestTruncateTable_MySQL_MultiTableWithPartition_RaisesNotSupported,
           Common e MySQL .TestTruncateTable_MySQL_MultiTable_RaisesNotSupported)

    -- as cinco guardas de PARTICAO dos dialetos que NAO tem particao. Cada
    -- mutante faz o seu dialeto EMITIR em vez de levantar, e cada um mata
    -- EXATAMENTE a sua celula e nenhuma outra:
    M10   PostgreSQL emite ' PARTITION (...)'               1
          (Common.TestTruncateTable_PostgreSQL_Partition_RaisesNotSupported)
          ANTES das cinco celulas este mutante SOBREVIVIA - era a lacuna.
    M11   Firebird deixa de olhar PartitionName na guarda   1
          (Common.TestTruncateTable_Firebird_Partition_RaisesNotSupported)
    M12   MSSQL deixa de olhar PartitionName na guarda      1
          (Common.TestTruncateTable_MSSQL_Partition_RaisesNotSupported)
    M13   Oracle deixa de olhar PartitionName na guarda     1
          (Common.TestTruncateTable_Oracle_Partition_RaisesNotSupported)
    M14   SQLite deixa de olhar PartitionName na guarda     1
          (Common.TestTruncateTable_SQLite_Partition_RaisesNotSupported)

  M1b RESPONDE A PERGUNTA "a celula MultiTableWithPartition ainda e alcancavel
  pela razao certa?". O par M1b/M9 mede a resposta em vez de argumenta-la: M1b
  (guarda de multi-tabela) A MATA; M9 (ramo de PARTICAO) NAO A TOCA. Logo ela e
  atendida pela guarda de multi-tabela e virou uma SEGUNDA medicao dessa guarda,
  nao uma medicao da combinacao. Isso esta escrito na propria celula, em
  test_esp074_unit.pas, e ela nao foi desligada - o que ela afirma continua
  verdadeiro: a chamada levanta.

  M4, M5b, M6, M7 e M10..M14 sao as mutacoes ANTI-COLATERAL: elas perguntam se a
  suite gritaria caso esta correcao tivesse alcancado PostgreSQL, MySQL, SQLite,
  MSSQL, Oracle, Firebird ou o proprio serializador base. Hoje TODAS respondem
  que sim. O M10 respondeu NAO na primeira passagem, e em vez de esconder isso o
  achado subiu como recomendacao; autorizado, virou as cinco celulas de particao
  e o M10 passou a morrer.

  O UNICO mutante que ainda sobrevive e o M2, e sobrevive DE PROPOSITO: ele troca
  so a MENSAGEM de um raise, e mensagem nao e contrato nesta suite - nenhuma
  celula a assere. Cobri-lo seria decoracao. A distincao entre M2 e M10 e o que
  decide qual buraco vira celula e qual nao vira.

  O diff nominal de vermelhos entre ffb5701 e o HEAD e VAZIO nas duas
  configuracoes: os 46 (config A) e os 35 (config B) sao nome a nome os mesmos.

  ------------------------------------------------------------------------------
*/
