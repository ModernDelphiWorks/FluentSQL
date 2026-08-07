-- ============================================================================
-- FluentSQL - oraculo da T9: o que o SQL Server responde de verdade
--
-- Este script existe porque test.pagination.filter.pas afirma coisas sobre o
-- comportamento do SQL Server, e afirmacao dessas nao pode viver so no
-- comentario de quem mediu. Aqui esta a medicao inteira, repetivel por quem
-- clonar o repositorio.
--
-- COMO REPETIR (nao precisa de SQL Server instalado, so Docker):
--
--   docker run -d --name fsqlora -e ACCEPT_EULA=Y ^
--     -e "MSSQL_SA_PASSWORD=Fluent#SQL2026" -e MSSQL_PID=Developer ^
--     mcr.microsoft.com/mssql/server:2022-latest
--
--   docker cp "test.pagination.filter.mssql.sql" fsqlora:/tmp/o.sql
--   docker exec fsqlora /opt/mssql-tools18/bin/sqlcmd ^
--     -S localhost -U sa -P "Fluent#SQL2026" -C -d tempdb -i /tmp/o.sql
--
--   docker rm -f fsqlora
--
-- A saida bruta obtida esta transcrita no fim deste arquivo, para conferencia
-- sem precisar rodar. Motor usado na medicao:
--
--   Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
--
-- Se a sua saida divergir da transcrita, o comentario do teste e que esta
-- errado - conserte o teste, nao o banco.
--
-- ----------------------------------------------------------------------------
-- O QUE ESTE ARQUIVO AFIRMA, E O QUE ELE NAO AFIRMA
--
-- AFIRMA: com ORDER BY do usuario, a janela do ROW_NUMBER() passa a usar esse
-- ORDER BY, e so entao a "pagina 2" e a pagina 2 daquilo que o usuario ordenou.
-- Essa e a correcao de verdade (casos D2/D2b/D2c).
--
-- NAO AFIRMA que trocar CURRENT_TIMESTAMP por (SELECT NULL) tenha consertado
-- determinismo. Nao consertou, e o caso P mede por que: os dois EMPATAM TODAS
-- as linhas igualmente e produzem PLANO IDENTICO, sem operador Sort. A troca e
-- de idioma e de legibilidade, nada mais. Quem quiser conferir sem rodar, a
-- doc da Microsoft e explicita:
--
--   "There is no guarantee that the rows returned by a query using ROW_NUMBER()
--    will be ordered exactly the same with each execution unless [...] Values of
--    the ORDER BY columns are unique."  /  "ROW_NUMBER() is nondeterministic."
--   https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql
--
--   estabilidade entre paginas exige que "The ORDER BY clause contains a column
--   or combination of columns that are guaranteed to be unique."
--   https://learn.microsoft.com/en-us/sql/t-sql/queries/select-order-by-clause-transact-sql
--
--   medicao independente dos planos (Itzik Ben-Gan), que o caso P reproduz:
--   https://sqlperformance.com/2019/11/t-sql-queries/row-numbers-with-nondeterministic-order
--
-- POR QUE ENTAO (SELECT NULL) FICOU NO CODIGO: porque no SQL Server alguma
-- ordenacao e OBRIGATORIA pela gramatica - o order_by_clause do OVER "is
-- required", e <offset_fetch> so existe como sub-clausula do ORDER BY. Nao ha
-- como nao escrever nada. Entre os preenchimentos possiveis, (SELECT NULL) e o
-- unico medido que nao acrescenta operador Sort ao plano; NEWID() acrescenta,
-- porque e avaliado por linha (caso P).
--
-- RESSALVA HONESTA, que vale ate quando o usuario DA um OrderBy: a doc acima
-- exige coluna UNICA para a paginacao ser estavel entre execucoes. O FluentSQL
-- NAO impoe unicidade - por decisao de projeto, nao por esquecimento. Ordenar
-- por uma coluna com repeticoes deixa as linhas empatadas dentro do grupo e a
-- fronteira entre paginas pode variar. Quem precisa de estabilidade ordena por
-- chave unica, ou acrescenta uma como desempate.
--
-- E PAGINAR SEM NENHUMA ORDENACAO? Devolve um subconjunto arbitrario. Isso e
-- semantica do SQL, nao defeito nosso, e vale nos 7 dialetos. A doc do
-- PostgreSQL diz na cara:
--
--   "This is not a bug; it is an inherent consequence of the fact that SQL does
--    not promise to deliver the results of a query in any particular order
--    unless ORDER BY is used."
--   https://www.postgresql.org/docs/current/queries-limit.html
--
-- O FluentSQL NAO exige OrderBy para paginar, de proposito: 6 dos 7 dialetos
-- aceitam paginar sem ordenacao, e exigir seria inventar restricao que os
-- bancos nao tem.
-- ============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..T') IS NOT NULL DROP TABLE T;
GO

CREATE TABLE T (ID INT, NOME VARCHAR(20), ATIVO INT, IDADE INT);
INSERT INTO T (ID, NOME, ATIVO) VALUES
 (1,'A',1),(2,'B',1),(3,'C',1),(4,'D',1),(5,'E',1),
 (6,'F',1),(7,'G',1),(8,'H',1),(9,'I',1),(10,'J',1),
 (11,'K',1),(12,'L',1),(13,'M',1),(14,'N',1),(15,'O',1),
 (16,'P',1),(17,'Q',1),(18,'R',1),(19,'S',1),(20,'T',1),
 (21,'U',1),(22,'V',1),(23,'W',1),(24,'X',1),(25,'Y',1),
 (26,'Z',1),(27,'AA',1),(28,'AB',1),(29,'AC',1),(30,'AD',1),
 (31,'AE',1),(32,'AF',1),(33,'AG',1),(34,'AH',1),(35,'AI',1);
UPDATE T SET IDADE = ID + 10;
GO

PRINT '=== Q1  a janela aceita CURRENT_TIMESTAMP? ===';
GO
SELECT TOP 3 ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS RN, NOME FROM T;
GO

PRINT '=== Q1b a janela aceita (SELECT NULL)? ===';
GO
SELECT TOP 3 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RN, NOME FROM T;
GO

PRINT '=== Q1c e literal inteiro, aceita? (contra-prova do Msg 5308) ===';
GO
SELECT TOP 3 ROW_NUMBER() OVER(ORDER BY 1) AS RN, NOME FROM T;
GO

PRINT '=== D1  o SQL que ce9efd0 emitia com Where (predicado perdido, AND sem WHERE) ===';
GO
SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS ROWNUMBER FROM T) AS T AND (ROWNUMBER > 20 AND ROWNUMBER <= 30);
GO

PRINT '=== D1b o SQL que a branch emite (predicado preservado) ===';
GO
SELECT NOME FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER FROM T) AS T WHERE (ATIVO = 1) AND (ROWNUMBER > 20 AND ROWNUMBER <= 30);
GO

PRINT '=== D2  pagina 2 de 10 por NOME - forma ANTIGA (janela por CURRENT_TIMESTAMP) ===';
GO
SELECT NOME FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS ROWNUMBER FROM T) AS T WHERE (ROWNUMBER > 10 AND ROWNUMBER <= 20) ORDER BY NOME ASC;
GO

PRINT '=== D2b pagina 2 de 10 por NOME - forma NOVA (janela pelo OrderBy do usuario) ===';
GO
SELECT NOME FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY NOME ASC) AS ROWNUMBER FROM T) AS T WHERE (ROWNUMBER > 10 AND ROWNUMBER <= 20) ORDER BY NOME ASC;
GO

PRINT '=== D2c pagina 2 de 10 por NOME - gabarito independente (OFFSET/FETCH nativo) ===';
GO
SELECT NOME FROM T ORDER BY NOME ASC OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
GO

PRINT '=== D3  First sozinho e Skip sozinho, forma da branch ===';
GO
SELECT NOME FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER FROM T) AS T WHERE (ATIVO = 1) AND (ROWNUMBER <= 10);
GO
SELECT NOME FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER FROM T) AS T WHERE (ATIVO = 1) AND (ROWNUMBER > 20);
GO

PRINT '=== P  planos das 4 formas de janela: (SELECT NULL), CURRENT_TIMESTAMP, NEWID(), coluna ===';
GO
IF OBJECT_ID('tempdb..P') IS NOT NULL DROP TABLE P;
CREATE TABLE P (ID INT, NOME VARCHAR(20));
INSERT INTO P (ID, NOME) SELECT TOP 500 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), 'X' FROM sys.all_objects;
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RN FROM P;
GO
SELECT *, ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS RN FROM P;
GO
SELECT *, ROW_NUMBER() OVER(ORDER BY NEWID()) AS RN FROM P;
GO
SELECT *, ROW_NUMBER() OVER(ORDER BY NOME) AS RN FROM P;
GO
SET SHOWPLAN_TEXT OFF;
GO
DROP TABLE P;
DROP TABLE T;
GO

-- ============================================================================
-- SAIDA BRUTA da execucao acima, transcrita verbatim.
--
--   imagem : mcr.microsoft.com/mssql/server:2022-latest
--   motor  : Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
--   cliente: /opt/mssql-tools18/bin/sqlcmd de dentro do proprio container
--
-- COMO LER:
--
--   Q1/Q1b  CURRENT_TIMESTAMP e (SELECT NULL) sao os DOIS aceitos na janela.
--           Trocar um pelo outro nao conserta sintaxe nem determinismo - ver P.
--           Q1c e a contra-prova de que o Msg 5308 so alcanca literal INTEIRO,
--           e por isso que a forma antiga nunca deu erro e o defeito ficou
--           calado por tanto tempo.
--
--   D1      a forma de ce9efd0 e recusada: Msg 156. Nenhuma consulta filtrada
--           e paginada rodava no SQL Server. D1b e a mesma consulta na branch.
--           ESTE e o defeito que o fix principal corrige.
--
--   D2/D2b/D2c  pedindo a pagina 2 de 10 ordenada por NOME: a forma ANTIGA
--           devolve K..T; a NOVA devolve B..K; e o gabarito independente
--           (OFFSET/FETCH nativo) tambem B..K. A forma antiga nao erra - ela
--           acerta a sintaxe e devolve OUTRA PAGINA, calada. Passar o OrderBy
--           do usuario para a janela e o que conserta isso.
--
--           ATENCAO ao repetir: o K..T de D2 NAO e valor estavel a esperar.
--           Ordenar por constante empata todas as linhas, entao quem numera e
--           o plano; aqui saiu a ordem de insercao. Outro plano - indice
--           diferente, paralelismo, mais linhas - pode devolver outra faixa.
--           A instabilidade E a afirmacao; o valor exato nao e.
--
--           E NOME nao e coluna unica neste exemplo por acaso - e por sorte:
--           os 35 valores nao se repetem. Se repetissem, nem D2b seria estavel,
--           porque a doc da Microsoft exige UNICIDADE. O framework nao impoe.
--
--   D3      First sozinho e Skip sozinho na forma da branch: as 10 primeiras e
--           as 15 depois da vigesima. Antes, o limite nao pedido saia como lixo
--           de pilha e o numero mudava a cada execucao.
--
--   P       o caso que desmonta a tentacao de creditar a troca de constante.
--           Os planos:
--
--             (SELECT NULL)      Sequence Project / Segment / Table Scan
--             CURRENT_TIMESTAMP  Sequence Project / Segment / Table Scan
--             NEWID()            Sequence Project / Segment / SORT /
--                                Compute Scalar / Table Scan
--             coluna NOME        Sequence Project / Segment / SORT / Table Scan
--
--           (SELECT NULL) e CURRENT_TIMESTAMP dao o MESMO plano, sem Sort:
--           sao intercambiaveis para o otimizador. Trocar um pelo outro nao
--           mudou uma linha do que o motor faz - foi escolha de idioma, e o
--           idioma importa porque CURRENT_TIMESTAMP sugere uma ordenacao que
--           nao existe.
--
--           NEWID() aparece aqui para explicar por que NAO foi escolhido: e
--           avaliado por linha e acrescenta Sort ao plano, custo real em troca
--           de nada - continuaria sem unicidade garantida entre execucoes.
--
--           So ORDER BY por coluna faz o motor de fato ordenar. E so ordenacao
--           por coluna UNICA da paginacao estavel.
-- ============================================================================
--
-- === Q1  a janela aceita CURRENT_TIMESTAMP? ===
-- RN                   NOME
-- -------------------- --------------------
--                    1 A
--                    2 B
--                    3 C
-- === Q1b a janela aceita (SELECT NULL)? ===
-- RN                   NOME
-- -------------------- --------------------
--                    1 A
--                    2 B
--                    3 C
-- === Q1c e literal inteiro, aceita? (contra-prova do Msg 5308) ===
-- Msg 5308, Level 16, State 1, Server 4b382dcbe1c6, Line 1
-- Windowed functions, aggregates and NEXT VALUE FOR functions do not support integer indices as ORDER BY clause expressions.
-- === D1  o SQL que ce9efd0 emitia com Where (predicado perdido, AND sem WHERE) ===
-- Msg 156, Level 15, State 1, Server 4b382dcbe1c6, Line 1
-- Incorrect syntax near the keyword 'AND'.
-- === D1b o SQL que a branch emite (predicado preservado) ===
-- NOME
-- --------------------
-- U
-- V
-- W
-- X
-- Y
-- Z
-- AA
-- AB
-- AC
-- AD
-- === D2  pagina 2 de 10 por NOME - forma ANTIGA (janela por CURRENT_TIMESTAMP) ===
-- NOME
-- --------------------
-- K
-- L
-- M
-- N
-- O
-- P
-- Q
-- R
-- S
-- T
-- === D2b pagina 2 de 10 por NOME - forma NOVA (janela pelo OrderBy do usuario) ===
-- NOME
-- --------------------
-- B
-- C
-- D
-- E
-- F
-- G
-- H
-- I
-- J
-- K
-- === D2c pagina 2 de 10 por NOME - gabarito independente (OFFSET/FETCH nativo) ===
-- NOME
-- --------------------
-- B
-- C
-- D
-- E
-- F
-- G
-- H
-- I
-- J
-- K
-- === D3  First sozinho e Skip sozinho, forma da branch ===
-- NOME
-- --------------------
-- A
-- B
-- C
-- D
-- E
-- F
-- G
-- H
-- I
-- J
-- NOME
-- --------------------
-- U
-- V
-- W
-- X
-- Y
-- Z
-- AA
-- AB
-- AC
-- AD
-- AE
-- AF
-- AG
-- AH
-- AI
-- === P  planos das 4 formas de janela: (SELECT NULL), CURRENT_TIMESTAMP, NEWID(), coluna ===
-- StmtText
-- -------------------------------------------------------------------
-- SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RN FROM P;
-- StmtText
-- -------------------------------------------------------
--   |--Sequence Project(DEFINE:([Expr1005]=row_number))
--        |--Segment
--             |--Table Scan(OBJECT:([tempdb].[dbo].[P]))
-- StmtText
-- -----------------------------------------------------------------------
-- SELECT *, ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS RN FROM P;
-- StmtText
-- -------------------------------------------------------
--   |--Sequence Project(DEFINE:([Expr1004]=row_number))
--        |--Segment
--             |--Table Scan(OBJECT:([tempdb].[dbo].[P]))
-- StmtText
-- -------------------------------------------------------------
-- SELECT *, ROW_NUMBER() OVER(ORDER BY NEWID()) AS RN FROM P;
-- StmtText
-- -----------------------------------------------------------------
--   |--Sequence Project(DEFINE:([Expr1004]=row_number))
--        |--Segment
--             |--Sort(ORDER BY:([Expr1003] ASC))
--                  |--Compute Scalar(DEFINE:([Expr1003]=newid()))
--                       |--Table Scan(OBJECT:([tempdb].[dbo].[P]))
-- StmtText
-- ----------------------------------------------------------
-- SELECT *, ROW_NUMBER() OVER(ORDER BY NOME) AS RN FROM P;
-- StmtText
-- --------------------------------------------------------------
--   |--Sequence Project(DEFINE:([Expr1003]=row_number))
--        |--Segment
--             |--Sort(ORDER BY:([tempdb].[dbo].[P].[NOME] ASC))
--                  |--Table Scan(OBJECT:([tempdb].[dbo].[P]))
--
