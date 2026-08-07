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
