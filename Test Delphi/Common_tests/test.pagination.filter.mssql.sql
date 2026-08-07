-- ============================================================================
-- FluentSQL - oraculo da T9: o que o SQL Server responde de verdade
--
-- Este script existe porque test.pagination.filter.pas afirma coisas sobre o
-- comportamento do SQL Server (que forma ele recusa, que forma devolve a pagina
-- certa) e uma afirmacao dessas nao pode viver so no comentario de quem mediu.
-- Aqui esta a medicao inteira, repetivel por quem clonar o repositorio.
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

DROP TABLE T;
GO

-- ============================================================================
-- SAIDA BRUTA da execucao acima, transcrita verbatim.
--
--   imagem : mcr.microsoft.com/mssql/server:2022-latest
--            (digest local ba4c8329f48f no dia da medicao)
--   motor  : Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)
--   cliente: /opt/mssql-tools18/bin/sqlcmd de dentro do proprio container
--
-- COMO LER:
--
--   Q1/Q1b  CURRENT_TIMESTAMP e (SELECT NULL) sao os DOIS aceitos na janela.
--           Trocar um pelo outro NAO conserta sintaxe. Q1c e a contra-prova:
--           o Msg 5308 so alcanca literal INTEIRO, e por isso que a forma
--           antiga nunca deu erro e o defeito ficou calado.
--
--   D1      a forma de ce9efd0 e recusada: Msg 156. Nenhuma consulta filtrada
--           e paginada rodava no SQL Server. D1b e a mesma consulta na branch.
--
--   D2/D2b/D2c  o ponto. Pedindo a pagina 2 de 10 ordenada por NOME:
--           a forma ANTIGA devolve K..T; a NOVA devolve B..K; e o gabarito
--           independente (OFFSET/FETCH nativo do proprio motor) tambem B..K.
--           A forma antiga nao erra - ela acerta a sintaxe e devolve OUTRA
--           PAGINA, calada.
--
--           ATENCAO ao repetir: o K..T de D2 NAO e um valor estavel a ser
--           esperado. Ordenar por constante empata todas as linhas, entao a
--           numeracao fica a criterio do plano de execucao; aqui saiu a ordem
--           de insercao. Outro plano - indice diferente, paralelismo, mais
--           linhas - pode devolver outra faixa. Essa instabilidade E a
--           afirmacao; o valor exato nao e.
--
--   D3      First sozinho e Skip sozinho na forma da branch: 10 primeiras e
--           as 15 depois da vigesima. Antes, o limite nao pedido saia como
--           lixo de pilha e o numero mudava a cada execucao.
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
-- Msg 5308, Level 16, State 1, Server d590842f3bb4, Line 1
-- Windowed functions, aggregates and NEXT VALUE FOR functions do not support integer indices as ORDER BY clause expressions.
-- === D1  o SQL que ce9efd0 emitia com Where (predicado perdido, AND sem WHERE) ===
-- Msg 156, Level 15, State 1, Server d590842f3bb4, Line 1
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
--
