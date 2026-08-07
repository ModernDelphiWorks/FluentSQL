/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - FIREBIRD  (T10)

  MOTOR MEDIDO
    Firebird 5.0  (LI-V5.0.4.1812), imagem firebirdsql/firebird:5

  COMO REPETIR
    docker run -d --name t10fb -e FIREBIRD_ROOT_PASSWORD=fluent \
      -e FIREBIRD_DATABASE=t10.fdb -p 13050:3050 firebirdsql/firebird:5
    docker cp test.pagination.firebird.sql t10fb:/tmp/p.sql
    docker exec t10fb bash -lc "/opt/firebird/bin/isql -u SYSDBA -p fluent \
      -i /tmp/p.sql /var/lib/firebird/data/t10.fdb"

  MASSA: T com 60 linhas (ID 1..60, NOME 'N001'..'N060', ATIVO=1),
         U com 60 linhas (ID 1001..1060). Pagina certa de First(3)/Skip(20): 21,22,23.

  POR QUE O FIREBIRD NAO MIGROU PARA OFFSET/FETCH
    FIRST/SKIP funciona em toda versao - inclusive 2.5, onde OFFSET/FETCH nao
    existe - e aceita EXPRESSAO; o OFFSET/FETCH do Firebird so aceita literal ou
    parametro. Migrar trocaria algo que funciona por algo que funciona igual e
    aceita menos. A T10 mudou UMA coisa neste driver: a ORDEM em relacao ao
    DISTINCT. Ver o caso V1.
  ------------------------------------------------------------------------------
*/

SET ECHO ON;

/*
  ==============================================================================
  PARTE 1 - A ORDEM. Gramatica do Firebird 5.0 Language Reference, SELECT:
      SELECT [FIRST m] [SKIP n] [{DISTINCT | ALL}] <columns>
  FIRST/SKIP vem ANTES do DISTINCT. O driver emitia depois.
  ==============================================================================
*/

/* V1: ordem ANTERIOR do driver - DISTINCT na frente */
SELECT DISTINCT FIRST 3 SKIP 20 NOME FROM T;
/*
  SAIDA BRUTA:
    Statement failed, SQLSTATE = 42000
    Dynamic SQL Error
    -SQL error code = -104
    -Token unknown - line 1, column 23
    -3

  LEITURA: nao e "ordem feia", e erro de sintaxe. Toda consulta
  Select.Distinct...First/Skip do driver Firebird era recusada pelo motor.
  Coluna 23 e exatamente onde o "3" do FIRST cai.
*/

/* 06: ordem NOVA - FIRST/SKIP na frente */
SELECT FIRST 3 SKIP 20 DISTINCT NOME FROM T;
/* SAIDA: N021, N022, N023 */

/* 07: Skip sozinho + DISTINCT, ordem NOVA */
SELECT SKIP 57 DISTINCT NOME FROM T;
/* SAIDA: N058, N059, N060 */

/*
  ==============================================================================
  PARTE 2 - AS DEMAIS COMBINACOES (inalteradas pela T10, medidas para travar)
  ==============================================================================
*/

/* 01 First(3) */
SELECT FIRST 3 ID FROM T;
/* SAIDA: 1, 2, 3 */

/* 02 Skip(57) - sozinho, sem teto artificial: o Firebird aceita */
SELECT SKIP 57 ID FROM T;
/* SAIDA: 58, 59, 60 */

/* 03 First(3)+Skip(20) */
SELECT FIRST 3 SKIP 20 ID FROM T;
/* SAIDA: 21, 22, 23 */

/* 04 Where+First(3)+Skip(20) */
SELECT FIRST 3 SKIP 20 ID FROM T WHERE (ATIVO = 1);
/* SAIDA: 21, 22, 23 */

/* 05 Where+OrderBy+First(3)+Skip(20) */
SELECT FIRST 3 SKIP 20 ID FROM T WHERE (ATIVO = 1) ORDER BY NOME ASC;
/* SAIDA: 21, 22, 23 */

/* 08 GroupBy+First(3)+Skip(20) */
SELECT FIRST 3 SKIP 20 NOME FROM T GROUP BY NOME;
/* SAIDA: N021, N022, N023 */

/* 10 WithAlias+First(3)+Skip(20) */
WITH CTE AS (SELECT FIRST 3 SKIP 20 * FROM T) SELECT ID FROM CTE;
/* SAIDA: 21, 22, 23 */

/*
  ==============================================================================
  PARTE 3 - FRONTEIRA CONHECIDA E NAO CORRIGIDA: UNION

  O FluentSQL emite, para Union + First(3) + Skip(20):
      SELECT FIRST 3 SKIP 20 * FROM T UNION SELECT * FROM U
  ==============================================================================
*/

/* 09 Union+First(3)+Skip(20), a forma emitida */
SELECT FIRST 3 SKIP 20 * FROM T UNION SELECT * FROM U;
/*
  SAIDA BRUTA (resumida): 63 linhas - as 3 linhas da pagina de T (ID 21,22,23)
  MAIS as 60 linhas inteiras de U.

  LEITURA: no Firebird o FIRST/SKIP escrito no primeiro ramo pagina SO AQUELE
  RAMO, nao o resultado do UNION. Nos outros seis dialetos a cauda de paginacao
  fica depois do UNION e recorta o conjunto inteiro - 3 linhas, nao 63.

  Isto e SQL VALIDO com semantica DIVERGENTE, e nao foi corrigido na T10: o
  conserto exigiria embrulhar o UNION numa subconsulta, mudando substancialmente
  a forma emitida pelo Firebird, e o escopo da tarefa era explicito em nao mexer
  na forma deste driver. Fica registrado como achado.
*/

/*
  ==============================================================================
  PARTE Z - First(0) e Skip(0)

  FIRST 0 devolve zero linhas no Firebird, sem tratamento especial - mais um
  ponto a favor de nao ter migrado este driver para OFFSET/FETCH.
  ==============================================================================
*/

/* Z1 First(0)                 -> 0  */
SELECT COUNT(*) FROM (SELECT FIRST 0 * FROM T);
/* Z2 Skip(0): "nao pule nada" -> 60 */
SELECT COUNT(*) FROM (SELECT SKIP 0 * FROM T);
/* Z3 First(0)+Skip(20)        -> 0  */
SELECT COUNT(*) FROM (SELECT FIRST 0 SKIP 20 * FROM T);
/* Z4 First(10)+Skip(0)        -> 10 */
SELECT COUNT(*) FROM (SELECT FIRST 10 SKIP 0 * FROM T);
/* Z5 First(0) nas combinacoes -> 0 nas quatro */
SELECT COUNT(*) FROM (SELECT FIRST 0 * FROM T WHERE (ATIVO = 1));
SELECT COUNT(*) FROM (SELECT FIRST 0 * FROM T ORDER BY NOME ASC);
SELECT COUNT(*) FROM (SELECT FIRST 0 DISTINCT NOME FROM T);
SELECT COUNT(*) FROM (SELECT FIRST 0 NOME FROM T GROUP BY NOME);
