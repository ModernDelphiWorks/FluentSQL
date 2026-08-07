/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - SQL SERVER  (T10)

  Nao e um teste. E a MEDICAO em motor real das formas que
  FluentSQL.QualifierMSSQL.pas e FluentSQL.SerializeMSSQL.pas passaram a emitir,
  para que as afirmacoes do codigo e dos testes nao vivam so no comentario de
  quem mediu.

  MOTOR MEDIDO
    Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
    Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS)

  COMO REPETIR (nao exige SQL Server instalado)
    docker run -d --name t10mssql -e ACCEPT_EULA=Y \
      -e MSSQL_SA_PASSWORD='Fluent#SQL2026' -p 14433:1433 \
      mcr.microsoft.com/mssql/server:2022-latest
    docker cp test.pagination.mssql.sql t10mssql:/tmp/p.sql
    docker exec t10mssql /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U sa -P 'Fluent#SQL2026' -C -d master -i /tmp/p.sql

  MASSA
    T tem 60 linhas, ID 1..60, NOME 'N001'..'N060', ATIVO=1.
    U tem 60 linhas, ID 1001..1060, NOME 'U001'..'U060', ATIVO=1.
    Com First(3)/Skip(20) a pagina certa e sempre ID 21,22,23 - qualquer outro
    trio denuncia recorte errado. O SQL abaixo usa 3 em vez de 10 so para caber
    na saida; a forma e a mesma.
  ------------------------------------------------------------------------------
*/

SET NOCOUNT ON;
IF OBJECT_ID('dbo.T') IS NOT NULL DROP TABLE dbo.T;
IF OBJECT_ID('dbo.U') IS NOT NULL DROP TABLE dbo.U;
CREATE TABLE dbo.T (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
CREATE TABLE dbo.U (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
INSERT INTO dbo.T
SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
       'N' + RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(4)), 3),
       1, 20
FROM sys.all_objects;
INSERT INTO dbo.U SELECT ID + 1000, 'U' + CAST(ID AS VARCHAR(4)), 1, 30 FROM dbo.T;
GO

/*
  ==============================================================================
  PARTE 1 - POR QUE A CLAUSULA ORDER BY ENTRA, E POR QUE O PREENCHIMENTO NAO E UM SO
  ==============================================================================
*/

PRINT '=== L: OFFSET/FETCH sem ORDER BY nenhum ===';
GO
SELECT ID FROM T OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    Msg 102, Level 15, State 1, Line 1
    Incorrect syntax near '20'.
    Msg 153, Level 15, State 2, Line 1
    Invalid usage of the option NEXT in the FETCH statement.

  LEITURA: o <offset_fetch> nao existe fora do ORDER BY. Por isso o FluentSQL
  emite uma clausula ORDER BY mesmo quando o usuario nao pediu nenhuma. Isso NAO
  e conserto de determinismo - e preenchimento gramatical.
*/

PRINT '=== K: FETCH sem OFFSET ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) FETCH NEXT 3 ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    Msg 153, Level 15, State 2, Line 1
    Invalid usage of the option NEXT in the FETCH statement.

  LEITURA: no T-SQL o FETCH exige o OFFSET. E por isso que First(m) SOZINHO sai
  como "OFFSET 0 ROWS FETCH NEXT m ROWS ONLY", e nao so como FETCH. Na Oracle os
  dois membros sao independentes e First sozinho sai so com FETCH - a diferenca
  entre os dois drivers e essa, e e de gramatica, nao de gosto.
*/

PRINT '=== E: DISTINCT + ORDER BY (SELECT NULL) ===';
GO
SELECT DISTINCT ATIVO FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    Msg 145, Level 15, State 1, Line 1
    ORDER BY items must appear in the select list if SELECT DISTINCT is specified.
*/

PRINT '=== G: UNION + ORDER BY (SELECT NULL) ===';
GO
SELECT * FROM T UNION SELECT * FROM U ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    Msg 104, Level 16, State 1, Line 1
    ORDER BY items must appear in the select list if the statement contains a
    UNION, INTERSECT or EXCEPT operator.

  LEITURA DOS DOIS (E e G): sob DISTINCT ou UNION, o item do ORDER BY tem que
  estar na lista de selecao, e (SELECT NULL) nunca esta. O unico item que SEMPRE
  esta e o ordinal. Dai ORDER BY 1 nesses dois casos, e so nesses dois.
*/

PRINT '=== S: PLANOS de (SELECT NULL) x ORDER BY 1, ambos com OFFSET/FETCH ===';
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
SELECT ID FROM T ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
SET SHOWPLAN_TEXT OFF;
GO
/*
  SAIDA BRUTA:

    SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
      |--Top(OFFSET EXPRESSION:((20)),TOP EXPRESSION:((3)))
           |--Compute Scalar(DEFINE:([Expr1003]=NULL))
                |--Table Scan(OBJECT:([master].[dbo].[T]))

    SELECT ID FROM T ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
      |--Top(OFFSET EXPRESSION:((20)),TOP EXPRESSION:((3)))
           |--Sort(TOP 23, ORDER BY:([master].[dbo].[T].[ID] ASC))
                |--Table Scan(OBJECT:([master].[dbo].[T]))

  LEITURA: ORDER BY 1 CUSTA um operador Sort; (SELECT NULL) nao custa. E por isso
  que ORDER BY 1 nao virou o preenchimento universal - ele so entra onde
  (SELECT NULL) e recusado pelo motor (casos E e G).
*/

/*
  ==============================================================================
  PARTE 2 - AS FORMAS QUE O FluentSQL EMITE HOJE, UMA POR COMBINACAO
  Cada bloco e o AsString literal, so com First(3) no lugar de First(10).
  ==============================================================================
*/

PRINT '=== 01 First(3) ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 1, 2, 3 */

PRINT '=== 02 Skip(57) ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 57 ROWS;
GO
/* SAIDA: 58, 59, 60  -- Skip sozinho, sem teto, e a cauda e valida */

PRINT '=== 03 First(3)+Skip(20) ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 21, 22, 23 */

PRINT '=== 04 Where+First(3)+Skip(20) ===';
GO
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 21, 22, 23  -- o predicado sobrevive, que e a regra da T9 */

PRINT '=== 05 Where+OrderBy+First(3)+Skip(20) ===';
GO
SELECT ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 21, 22, 23 */

PRINT '=== 06 Distinct+First(3)+Skip(20) ===';
GO
SELECT DISTINCT NOME FROM T ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: N021, N022, N023  -- antes: Exception crua "Unknown qualifier" */

PRINT '=== 07 Distinct+Skip(20) ===';
GO
SELECT DISTINCT NOME FROM T ORDER BY 1 OFFSET 20 ROWS;
GO
/* SAIDA: N021..N060 */

PRINT '=== 08 GroupBy+First(3)+Skip(20) ===';
GO
SELECT NOME FROM T GROUP BY NOME ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: N021, N022, N023 */

PRINT '=== 09 Union+First(3)+Skip(20) ===';
GO
SELECT ID FROM T UNION SELECT ID FROM U ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 21, 22, 23  -- antes o UNION e o ramo inteiro sumiam EM SILENCIO */

PRINT '=== 10 WithAlias+First(3)+Skip(20) ===';
GO
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
GO
/* SAIDA: 21, 22, 23  -- antes a CTE sumia EM SILENCIO */

/*
  ==============================================================================
  PARTE 3 - FRONTEIRA: o que continua invalido e NAO e defeito de paginacao
  Os dois casos abaixo ja falhavam SEM paginacao nenhuma. Estao aqui para que
  ninguem os confunda com regressao desta tarefa.
  ==============================================================================
*/

PRINT '=== I: CTE com ORDER BY do usuario DENTRO, sem paginacao ===';
GO
WITH CTE AS (SELECT * FROM T ORDER BY NOME ASC) SELECT * FROM CTE;
GO
/*
  SAIDA BRUTA:
    Msg 1033, Level 15, State 1, Line 1
    The ORDER BY clause is invalid in views, inline functions, derived tables,
    subqueries, and common table expressions, unless TOP, OFFSET or FOR XML is
    also specified.

  CAUSA no FluentSQL: FluentSQL.Serialize.pas:88-104 monta o ORDER BY dentro de
  LBase e so depois embrulha LBase na CTE. Defeito de composicao WITH x OrderBy,
  independente de paginacao. NAO corrigido na T10.
*/

PRINT '=== J: UNION com ORDER BY do usuario no primeiro ramo, sem paginacao ===';
GO
SELECT * FROM T ORDER BY NOME ASC UNION SELECT * FROM U;
GO
/*
  SAIDA BRUTA:
    Msg 156, Level 15, State 1, Line 1
    Incorrect syntax near the keyword 'UNION'.

  CAUSA no FluentSQL: mesma linha - o ORDER BY entra em LBase, e o UNION e
  concatenado depois. Defeito de composicao UNION x OrderBy, independente de
  paginacao. NAO corrigido na T10.
*/

/*
  ==============================================================================
  PARTE Z - First(0): "me devolva ZERO linhas"

  TFluentSQLPagination declara que First(0) e pedido LEGITIMO e distinto de "sem
  First". A primeira versao da T10 nao tinha teste para isso e introduziu uma
  REGRESSAO: passou a emitir FETCH NEXT 0 ROWS ONLY, que o motor recusa, onde a
  base 79450e9 emitia ROWNUMBER <= 0, valido.
  ==============================================================================
*/

PRINT '=== Z1: FETCH NEXT 0 - o que a 1a versao da T10 emitia [REGRESSAO] ===';
GO
SELECT * FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 0 ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    Msg 10744, Level 15, State 1, Line 1
    The number of rows provided for a FETCH clause must be greater then zero.
*/

PRINT '=== Z2: o mesmo pedido na forma da base 79450e9 ===';
GO
SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER FROM T) AS T WHERE (ROWNUMBER <= 0);
GO
/* SAIDA: 0 linhas, sem erro. Confirma que Z1 e regressao, nao defeito herdado. */

PRINT '=== Z3: a restricao e do LITERAL, nao da semantica ===';
GO
DECLARE @n BIGINT = 0;
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT @n ROWS ONLY;
GO
/*
  SAIDA: 0 linhas, SEM ERRO.

  LEITURA: o mesmo FETCH com zero e aceito quando o contador vem de variavel.
  "Zero linhas" e pedido legitimo para o motor; o que nao existe e a forma
  LITERAL de escreve-lo. Como o FluentSQL emite literais, precisa de outro
  caminho - dai os candidatos abaixo.
*/

PRINT '=== Z4: CANDIDATO RECUSADO - TOP 0 nao coexiste com OFFSET ===';
GO
SELECT TOP 0 * FROM T ORDER BY (SELECT NULL) OFFSET 20 ROWS;
GO
/*
  SAIDA BRUTA:
    Msg 10741, Level 15, State 2, Line 1
    A TOP can not be used in the same query or sub-query as a OFFSET.
*/

PRINT '=== Z5: CANDIDATO RECUSADO - TOP 0 num UNION limita so o PRIMEIRO RAMO ===';
GO
SELECT TOP 0 * FROM T UNION SELECT * FROM U;
GO
/*
  SAIDA BRUTA: 60 linhas - a tabela U INTEIRA.

  LEITURA: e por isto que "SELECT TOP 0", a forma obvia e a mais barata, foi
  recusada. Ela acerta em quase todas as combinacoes e ERRA no UNION, devolvendo
  dados onde o usuario pediu nada. Forma que erra numa combinacao nao serve para
  uma API que promete a mesma semantica nos sete dialetos. Alem disso o TOP mora
  na clausula SELECT, o que devolveria ao TFluentSQLSelectMSSQL o conhecimento
  da paginacao que a T10 tirou de la - foi esse acoplamento que fazia UNION e
  CTE sumirem em silencio.
*/

PRINT '=== Z6: CANDIDATO RECUSADO - FETCH NEXT (SELECT 0) so vale com OFFSET 0 ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT (SELECT 0) ROWS ONLY;
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT (SELECT 0) ROWS ONLY;
GO
/*
  SAIDA BRUTA:
    primeiro -> 0 linhas, sem erro
    segundo  -> Msg 10744, The number of rows provided for a FETCH clause must
                be greater then zero.

  LEITURA: aceito E barato (0 leituras logicas), mas SO quando o OFFSET e o
  literal 0. Com OFFSET 1, 20 ou (SELECT 20) volta a dar Msg 10744. Como
  First(0) tem que valer junto com Skip(n), tambem nao serve.
*/

PRINT '=== Z7: FORMA ESCOLHIDA - OFFSET 2^63-1 ROWS ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 9223372036854775807 ROWS;
GO
/* SAIDA: 0 linhas. */

PRINT '=== Z8: 2^63 e recusado - prova de que 2^63-1 e o teto ===';
GO
SELECT ID FROM T ORDER BY (SELECT NULL) OFFSET 9223372036854775808 ROWS;
GO
/*
  SAIDA BRUTA:
    Msg 8115, Level 16, State 2, Line 1
    Arithmetic overflow error converting expression to data type bigint.
*/

PRINT '=== Z9: O PRECO da forma escolhida, em tabela de 200 mil linhas ===';
GO
IF OBJECT_ID('dbo.BIG') IS NOT NULL DROP TABLE dbo.BIG;
SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID INTO dbo.BIG
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO
SET STATISTICS IO ON;
GO
SELECT ID FROM BIG ORDER BY (SELECT NULL) OFFSET 9223372036854775807 ROWS;
GO
SELECT TOP 0 ID FROM BIG;
GO
SET STATISTICS IO OFF;
GO
/*
  SAIDA BRUTA:
    OFFSET 2^63-1 -> Table 'BIG'. Scan count 1, logical reads 767, ...
    TOP 0         -> Table 'BIG'. Scan count 0, logical reads 0, ...

  LEITURA HONESTA: a forma escolhida CUSTA uma varredura completa - o motor le
  para contar o que pula; o TOP 0 curto-circuita. O preco foi aceito em troca de
  correcao uniforme (Z4 e Z5) e vale so para First(0), pedido degenerado. Se um
  dia o custo pesar, o caminho e TOP 0 COM excecao para UNION: duas formas para
  o mesmo pedido, que e justamente o que se evitou aqui.
*/

PRINT '=== Z10: a forma escolhida em TODAS as combinacoes ===';
GO
SELECT * FROM T WHERE (ATIVO = 1) ORDER BY (SELECT NULL) OFFSET 9223372036854775807 ROWS;
SELECT * FROM T ORDER BY NOME ASC OFFSET 9223372036854775807 ROWS;
SELECT DISTINCT NOME FROM T ORDER BY 1 OFFSET 9223372036854775807 ROWS;
SELECT * FROM T UNION SELECT * FROM U ORDER BY 1 OFFSET 9223372036854775807 ROWS;
SELECT NOME FROM T GROUP BY NOME ORDER BY (SELECT NULL) OFFSET 9223372036854775807 ROWS;
WITH CTE AS (SELECT * FROM T) SELECT ID FROM CTE ORDER BY (SELECT NULL) OFFSET 9223372036854775807 ROWS;
GO
/* SAIDA: (0 rows affected) nas seis. */

PRINT '=== Z11: Skip(0) e First(10)+Skip(0) - inalterados e corretos ===';
GO
SELECT * FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS;
GO
/* SAIDA: 60 linhas. Skip(0) e "nao pule nada", nao "sem Skip". */
SELECT * FROM T ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
GO
/* SAIDA: 10 linhas. */

/*
  ==============================================================================
  ARMADILHA DE MEDICAO, para quem repetir este arquivo

  NAO conte linhas embrulhando a consulta em "SELECT COUNT(*) FROM (...) z"
  quando ela tiver UNION. Medido:

    SELECT COUNT(*) FROM (SELECT * FROM T UNION SELECT * FROM U
                          ORDER BY 1 OFFSET 9223372036854775807 ROWS) z;  -> 60
    SELECT * FROM T UNION SELECT * FROM U
                          ORDER BY 1 OFFSET 9223372036854775807 ROWS;     ->  0

  Dentro da subconsulta o T-SQL liga o ORDER BY/OFFSET ao SEGUNDO RAMO do UNION,
  nao ao conjunto. O embrulho MENTE; vale a execucao direta. O mesmo embrulho
  com OFFSET 20 FETCH 3 devolve 63 em vez de 3. Este erro de medicao chegou a
  produzir um falso negativo durante a T10.
  ==============================================================================
*/
