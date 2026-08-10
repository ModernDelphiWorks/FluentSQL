/*
  ------------------------------------------------------------------------------
  ORACULO DO APELIDO - ORACLE  (T12)

  MEDICAO em motor real de uma pergunta que a equipe consumidora levantou e
  declarou honestamente NAO ter conseguido responder por nao ter instancia
  Oracle: qual erro exato a Oracle devolve para "FROM tabela AS apelido" e para
  "LEFT JOIN tabela AS apelido"?

  O palpite corrente era ORA-00933. NAO E. Medido, sao DOIS codigos diferentes,
  nenhum deles o 00933:

    FROM  T AS AP  -> ORA-03048
    JOIN  B AS X   -> ORA-02000

  E o contraste que sustenta a correcao inteira: apelido de COLUNA com AS e
  ACEITO. A Oracle trata os dois papeis de forma oposta, e a doc do SELECT diz
  isso do jeito dela - define t_alias (tabela, view, subconsulta) sem citar AS
  em momento algum, e define c_alias (coluna) dizendo "The AS keyword is
  optional". Declara opcional onde e permitido e omite onde nao e.

  MOTOR MEDIDO
    Oracle AI Database 26ai Free Release 23.26.2.0.0
    Version 23.26.2.0.0
    imagem gvenzl/oracle-free:23-slim
    sha256:fbbd3023d5abc33e36d3814816e6fd740e8efabeaa70cf470ddeab5874a3f6f8

    RESSALVA DE FRONTEIRA: os codigos ORA transcritos abaixo sao os que ESTA
    versao devolveu. A restricao de t_alias e antiga e nao se afirma aqui que a
    12c ou a 19c devolvam os MESMOS codigos - so que recusam. O que nao foi
    medido nao esta reportado como medido.

  COMO REPETIR
    docker run -d --name t12ora -e ORACLE_PASSWORD=fluent -p 1521:1521 \
      gvenzl/oracle-free:23-slim
    docker cp test.alias.oracle.sql t12ora:/tmp/a.sql
    docker exec t12ora bash -lc \
      "sqlplus -S system/fluent@//localhost:1521/FREEPDB1 @/tmp/a.sql"

  O QUE O FluentSQL EMITIA E O QUE PASSOU A EMITIR
    From('CLIENTES','CLI')      antes: SELECT * FROM CLIENTES AS CLI
                                agora: SELECT * FROM CLIENTES CLI
    LeftJoin('B','X')           antes: ... LEFT JOIN B AS X ON ...
                                agora: ... LEFT JOIN B X ON ...
    Delete.From('A','AP')       antes: DELETE FROM A AS AP WHERE ...
                                agora: DELETE FROM A AP WHERE ...
    Column('NOME').Alias('N')   antes e agora: SELECT NOME AS N   (nao mudou)
  ------------------------------------------------------------------------------
*/

SET ECHO ON
SET FEEDBACK ON
SET LINESIZE 200
WHENEVER SQLERROR CONTINUE;

PROMPT === SETUP ===
DROP TABLE D1 PURGE;
DROP TABLE B PURGE;
DROP TABLE A PURGE;
CREATE TABLE A (ID NUMBER, NOME VARCHAR2(30));
CREATE TABLE B (ID NUMBER, A_ID NUMBER, DESCR VARCHAR2(30));
INSERT INTO A VALUES (1,'um');
INSERT INTO B VALUES (10,1,'dez');
COMMIT;

/*
  ==============================================================================
  PARTE 1 - APELIDO DE RELACAO NO FROM
  ==============================================================================
*/

PROMPT
PROMPT === 01 FROM com AS - a forma que o FluentSQL emitia ate eb48337 ===
SELECT * FROM A AS AP;
/*
  SAIDA BRUTA:
    SELECT * FROM A AS AP
                    *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    'SELECT * FROM A '

  LEITURA: nao e ORA-00933. E ORA-03048, e a mensagem nomeia a palavra AS e o
  ponto exato. Nao ha caminho em que esta consulta rode.
*/

PROMPT
PROMPT === 02 FROM sem AS - a forma que o FluentSQL emite agora ===
SELECT * FROM A AP;
/*
  SAIDA BRUTA:
        ID NOME
    ---------- ------------------------------
             1 um

    1 row selected.
*/

/*
  ==============================================================================
  PARTE 2 - APELIDO DE RELACAO NOS QUATRO JOINS

  As quatro sobrecargas de join com apelido do FluentSQL - InnerJoin, LeftJoin,
  RightJoin e FullJoin - chamam Alias(...) e caiam todas no mesmo defeito.
  ==============================================================================
*/

PROMPT
PROMPT === 03 LEFT JOIN com AS - forma anterior ===
SELECT * FROM A LEFT JOIN B AS X ON (X.A_ID = A.ID);
/*
  SAIDA BRUTA:
    SELECT * FROM A LEFT JOIN B AS X ON (X.A_ID = A.ID)
                                *
    ERROR at line 1:
    ORA-02000: missing ON or USING keyword

  LEITURA: no JOIN o codigo e OUTRO - ORA-02000, nao ORA-03048. O parser trata
  o "AS" como se fosse o apelido da tabela, e ai o "X" seguinte ocupa a posicao
  onde ele esperava ON/USING. A mensagem aponta para uma clausula ON que ESTA
  escrita na consulta, o que torna o diagnostico enganoso para quem le.
*/

PROMPT
PROMPT === 04 LEFT JOIN sem AS - forma atual ===
SELECT * FROM A LEFT JOIN B X ON (X.A_ID = A.ID);
/*
  SAIDA BRUTA:
        ID NOME                             ID       A_ID DESCR
    ---------- ------------------------ ---------- ---------- ----------------
             1 um                               10          1 dez

    1 row selected.
*/

PROMPT
PROMPT === 05 INNER / RIGHT / FULL com AS - os tres recusam igual ===
SELECT * FROM A INNER JOIN B AS X ON (X.A_ID = A.ID);
SELECT * FROM A RIGHT JOIN B AS X ON (X.A_ID = A.ID);
SELECT * FROM A FULL  JOIN B AS X ON (X.A_ID = A.ID);
/*
  SAIDA BRUTA: ORA-02000 nas tres, com o cursor sobre o AS.
*/

PROMPT
PROMPT === 06 INNER / RIGHT / FULL sem AS - os tres executam ===
SELECT * FROM A INNER JOIN B X ON (X.A_ID = A.ID);
SELECT * FROM A RIGHT JOIN B X ON (X.A_ID = A.ID);
SELECT * FROM A FULL  JOIN B X ON (X.A_ID = A.ID);
/*
  SAIDA BRUTA: 1 row selected nas tres.
*/

/*
  ==============================================================================
  PARTE 3 - O CONTRASTE: APELIDO DE COLUNA

  Esta e a razao de a correcao NAO poder ser "tirar o AS de
  TFluentSQLName.Serialize". A MESMA classe serializa apelido de coluna e de
  tabela; a Oracle aceita um e recusa o outro.
  ==============================================================================
*/

PROMPT
PROMPT === 07 apelido de COLUNA COM AS - ACEITO ===
SELECT A.NOME AS N FROM A;
/*
  SAIDA BRUTA:
    N
    ------------------------------
    um

    1 row selected.

  LEITURA: e o que o FluentSQL ja emitia e continua emitindo. Nao mudou nada
  aqui, em dialeto nenhum.
*/

PROMPT
PROMPT === 08 apelido de COLUNA SEM AS - tambem aceito ===
SELECT A.NOME N FROM A;
/* SAIDA: mesma linha. Confirma o "AS keyword is optional" da doc, para c_alias. */

PROMPT
PROMPT === 09 coluna e relacao na MESMA consulta, cada uma na sua forma ===
SELECT AP.NOME AS N FROM A AP LEFT JOIN B X ON (X.A_ID = AP.ID);
/*
  SAIDA BRUTA:
    N
    ------------------------------
    um

    1 row selected.

  LEITURA: e exatamente o SQL que
  test.alias.matrix.TTestAliasMatrix.TestOracleApelidoDeColunaEDeRelacaoNaMesmaConsulta
  afirma que o FluentSQL emite hoje para dbnOracle.
*/

/*
  ==============================================================================
  PARTE 4 - SUBCONSULTA E DELETE

  t_alias tambem vale para subconsulta no FROM, e o DELETE do FluentSQL passa
  pelo MESMO TFluentSQL.From - entao herda a regra sem codigo proprio.
  ==============================================================================
*/

PROMPT
PROMPT === 10 subconsulta com AS - recusada ===
SELECT * FROM (SELECT ID FROM A) AS S;
/*
  SAIDA BRUTA:
    SELECT * FROM (SELECT ID FROM A) AS S
                                     *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    '...* FROM (SELECT ID FROM A) '
*/

PROMPT
PROMPT === 11 subconsulta sem AS - aceita ===
SELECT * FROM (SELECT ID FROM A) S;
/* SAIDA: 1 */

PROMPT
PROMPT === 12 DELETE com apelido COM AS - recusado ===
DELETE FROM A AS AP WHERE (AP.ID = 999);
/*
  SAIDA BRUTA:
    DELETE FROM A AS AP WHERE (AP.ID = 999)
                  *
    ERROR at line 1:
    ORA-03048: SQL reserved word 'AS' is not syntactically valid following
    'DELETE FROM A '
*/

PROMPT
PROMPT === 13 DELETE com apelido SEM AS - aceito ===
DELETE FROM A AP WHERE (AP.ID = 999);
/* SAIDA: 0 rows deleted.  (nao ha ID 999; o ponto e a GRAMATICA, nao a massa) */

/*
  ==============================================================================
  PARTE 5 - FRONTEIRA: o que este arquivo NAO afirma
  ==============================================================================
*/

PROMPT
PROMPT === 14 CTE: "WITH x AS (...)" EXIGE o AS - nao e t_alias ===
WITH CTE AS (SELECT ID FROM A) SELECT * FROM CTE;
/*
  SAIDA BRUTA:
        ID
    ----------
             1

    1 row selected.

  LEITURA: o AS do WITH e outra gramatica (query_name), e continua obrigatorio.
  FluentSQL.Serialize.pas:104 monta 'WITH <alias> AS (' e esta CERTO - a T12 nao
  encostou nele. Registrado aqui para que ninguem "padronize" os dois.
*/

PROMPT
PROMPT === 15 UPDATE com apelido - o FluentSQL NAO emite isto hoje ===
UPDATE A AS AP SET AP.NOME = 'x' WHERE AP.ID = 999;
/*
  SAIDA BRUTA:
    UPDATE A AS AP SET AP.NOME = 'x' WHERE AP.ID = 999
             *
    ERROR at line 1:
    ORA-00971: missing SET keyword

  LEITURA: TERCEIRO codigo, para a mesma classe de erro - o que reforca que
  presumir o codigo em vez de medir nao era opcao. Registrado por completude:
  FluentSQL.Update.pas nao serializa apelido de tabela, entao esta forma nao sai
  do framework hoje. Se um dia sair, ja se sabe o que a Oracle responde.
*/

PROMPT
PROMPT === 16 ACHADO FORA DO ESCOPO DA T12: literal de data ===
CREATE TABLE D1 (ID NUMBER, DT DATE);
INSERT INTO D1 VALUES (1, DATE '2026-08-10');
COMMIT;
SELECT COUNT(*) FROM D1 WHERE DT = '2026-08-10';
/*
  SAIDA BRUTA:
    SELECT COUNT(*) FROM D1 WHERE DT = '2026-08-10'
                                       *
    ERROR at line 1:
    ORA-01861: literal does not match format string

  LEITURA: TUtils.DateToSQLFormat (FluentSQL.Utils.pas:381-397) devolve
  '2026-08-10' entre aspas para dbnOracle. O NLS_DATE_FORMAT padrao da Oracle e
  DD-MON-RR, entao esse literal NAO casa com coluna DATE. Isto NAO e a T12 e
  NAO foi consertado aqui - esta transcrito porque foi medido nesta sessao e
  seria desonesto omitir. Registrar como divida.
*/

PROMPT
PROMPT === 17 ACHADO FORA DO ESCOPO DA T12: aspa embutida no apelido ===
SELECT * FROM A A'B;
SELECT * FROM A LEFT JOIN B X'Y ON 1=1;
SELECT NOME AS N'M FROM A;
SELECT NOME AS "N'M" FROM A;
/*
  SAIDA BRUTA (as tres primeiras):
    ERROR:
    ORA-01756: quoted string not properly terminated

  SAIDA BRUTA (a quarta, com aspas duplas):
    N'M
    ------------------------------
    um

    1 row selected.

  LEITURA: o FluentSQL entrega o texto do apelido CRU, sem nenhum tratamento de
  identificador, em TODOS os dialetos. Medido no proprio framework:

    dbnMSSQL/MySQL/Firebird/SQLite/PostgreSQL  ->  FROM CLIENTES AS A'B
    dbnOracle                                  ->  FROM CLIENTES A'B
    todos                                      ->  SELECT NOME AS N'M FROM A

  ISTO NAO E DEFEITO DA T12 E NAO FOI CONSERTADO AQUI. Tres razoes para nao
  encostar:

  1. E PRE-EXISTENTE E INALTERADO. O apelido sempre foi concatenado cru em
     TFluentSQLName.Serialize; a T12 trocou a PALAVRA que o antecede, nao o
     tratamento do texto. Na base (eb48337) o texto emitido para apelido com
     aspa e byte-identico ao de agora em seis dos sete dialetos, e no setimo
     (Oracle) a unica diferenca e o "AS" que sumiu - a aspa continua crua nos
     dois lados.

  2. NAO E ESPECIFICO DE RELACAO. A quarta consulta acima mostra o apelido de
     COLUNA caindo no MESMO ORA-01756, e o apelido de coluna e justamente o lado
     que a T12 provou nao ter tocado. Consertar so o lado da relacao deixaria o
     defeito de pe pela outra metade.

  3. EXIGE DECISAO DE CONVENCAO QUE NAO E DO IMPLEMENTADOR. Citar identificador
     e por dialeto (aspas duplas na Oracle, PostgreSQL, Firebird e SQLite;
     colchetes no MSSQL; crase no MySQL) e mexe com QuotedName, que ja existe em
     IFluentSQLSerialize e hoje NAO e chamado no caminho do apelido. Decidir se
     o framework passa a citar sempre, a citar sob demanda ou a recusar
     identificador invalido e escolha do dono, nao conserto silencioso.

  Registrado como divida, junto com a da secao 16.
*/

ROLLBACK;
EXIT
