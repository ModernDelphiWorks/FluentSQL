# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/).
Versionamento segue [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Removed

- **BREAKING CHANGE — `TFluentSQLDriver` perdeu 6 valores.** Foram removidos da enum pública (`FluentSQL.Interfaces.pas`), do `FluentSQL.Register.pas`, do `FluentSQL.Utils.pas` e do `FluentSQL.inc`:
  `dbnInformix`, `dbnADS`, `dbnASA`, `dbnAbsoluteDB`, `dbnElevateDB`, `dbnNexusDB`.
  Nenhum deles jamais teve implementação: as units `FluentSQL.Serialize*`, `FluentSQL.Select*` e `FluentSQL.Functions*` correspondentes não existem no repositório, e o `uses` condicional do `Register` referenciava ficheiros inexistentes. Qualquer chamada com esses valores terminava em `EAccessViolation`.
  **O que fazer:** código que nomeie qualquer um dos 6 deixa de compilar (`E2003 Undeclared identifier`). Não há substituto — migre para um dos 9 dialetos restantes (`dbnMSSQL`, `dbnMySQL`, `dbnFirebird`, `dbnSQLite`, `dbnInterbase`, `dbnDB2`, `dbnOracle`, `dbnPostgreSQL`, `dbnMongoDB`). `dbnInterbase` e `dbnDB2` **permanecem**: têm implementação real, apenas continuam desligados por omissão no `FluentSQL.inc`.
- Removidos overrides mortos e inalcançáveis de `Round`, `Floor` e `Abs` em `FluentSQL.Functions{MSSQL,MySQL,PostgreSQL}.pas`, e os overrides de agregação de `FluentSQL.FunctionsMongoDB.pas`.

### Changed

- **BREAKING CHANGE (SQL emitido) — Oracle: o apelido de TABELA perdeu a palavra `AS`.** O Oracle **não aceita** `AS` antes de apelido de tabela, view ou subconsulta, e o núcleo emitia `AS` para todo apelido sem consultar dialeto nenhum — a linha era `Result := TUtils.Concat([Result, 'AS', FAlias])`, em `FluentSQL.Name.pas:114` **na árvore anterior à correção** (commit `eb48337`); no HEAD atual essa linha não existe mais, e o ponto equivalente é `FluentSQL.Name.pas:161`, já lendo `FAliasKeyword`. Todo `From(tabela, apelido)` e as **quatro** sobrecargas de join com apelido (`InnerJoin`/`LeftJoin`/`RightJoin`/`FullJoin`) produziam SQL que o Oracle recusa. **Quem compara o SQL gerado com string fixa para `dbnOracle` precisa atualizar as expectativas**; quem executa a consulta passa a executar SQL que o motor aceita.

  | Construção | Antes (Oracle) | Depois (Oracle) | Motor real |
  |---|---|---|---|
  | `From('CLIENTES','CLI')` | `SELECT * FROM CLIENTES AS CLI` | `SELECT * FROM CLIENTES CLI` | antes: **`ORA-03048`** |
  | `LeftJoin('B','X')` | `... LEFT JOIN B AS X ON ...` | `... LEFT JOIN B X ON ...` | antes: **`ORA-02000`** |
  | `InnerJoin`/`RightJoin`/`FullJoin` `('B','X')` | `... JOIN B AS X ON ...` | `... JOIN B X ON ...` | antes: **`ORA-02000`** |
  | `Delete.From('A','AP')` | `DELETE FROM A AS AP WHERE ...` | `DELETE FROM A AP WHERE ...` | antes: **`ORA-03048`** |
  | `From('(SELECT ...)')` + `Alias` | `... AS S` | `... S` | antes: **`ORA-03048`** |
  | **`Column('NOME').Alias('N')`** | `SELECT NOME AS N` | **inalterado** | aceito nos dois |

  **O apelido de COLUNA não mudou, em dialeto nenhum** — e é esse contraste que sustenta a correção. A documentação do `SELECT` do Oracle define `t_alias` (tabela/view/subconsulta) sem citar `AS` em momento algum, e define `c_alias` (coluna) dizendo *"The `AS` keyword is optional"*: declara opcional onde é permitido e omite onde não é. Como `TFluentSQLName` serve os **dois** papéis com o mesmo `Serialize`, tirar o `AS` do serializador consertaria a tabela e quebraria a coluna.

  Os códigos acima foram **medidos**, não presumidos — o palpite corrente era `ORA-00933` e não é nenhum dos dois. As execuções brutas, incluindo o `docker run` e a versão do motor (Oracle AI Database 26ai Free Release 23.26.2.0.0), estão em `Test Delphi\Common_tests\test.alias.oracle.sql`.

  **Os outros seis dialetos relacionais não mudaram uma vírgula.** A alternativa "emitir sem `AS` em todos" — gramaticalmente válida nos sete — foi recusada: trocaria o texto de seis dialetos para consertar um. A palavra passou a vir de `IFluentSQLSerialize.RelationAliasKeyword` (`'AS'` na base, `''` só no Oracle). Ela mora no **serializador**, e não no qualificador, por duas razões: o qualificador não alcança o `JOIN` (serializado por `FluentSQL.Joins.pas`), e `TFluentSQLSelectDB2` instancia o qualificador **do Oracle** (`FluentSQL.SelectDB2.pas:46`) — hospedar a regra ali faria o **DB2** herdar calado a forma do Oracle. Medido: o DB2 continua em `tabela AS apelido`.

- **BREAKING CHANGE (SQL emitido) — a paginação mudou de forma em 5 dos 7 dialetos ativos.** O framework anunciava paginação nos sete e ela só estava correta em dois (PostgreSQL e MongoDB). Quem compara o SQL gerado com string fixa **precisa atualizar as expectativas**; quem executa a consulta passa a executar SQL que o motor aceita. Com `Skip(20)` sozinho, antes → depois:

  | Dialeto | Antes | Depois |
  |---|---|---|
  | MSSQL | `...) AS T WHERE (ROWNUMBER > 20)` (subconsulta + `ROW_NUMBER()`) | `... ORDER BY (SELECT NULL) OFFSET 20 ROWS` |
  | Oracle | `...) AND ROWINI > 20` — **`AND` sem `WHERE`**, `ORA-03048` | `... OFFSET 20 ROWS` |
  | SQLite | `SELECT OFFSET 20 * FROM T` — **posição errada na gramática**, inválido sempre | `... LIMIT -1 OFFSET 20` |
  | MySQL | `... OFFSET 20` — **`OFFSET` sem `LIMIT`**, `ERROR 1064` | `... LIMIT 18446744073709551615 OFFSET 20` |
  | Firebird | `SELECT SKIP 20 * FROM T` | inalterado |
  | PostgreSQL | `... OFFSET 20` | inalterado |
  | MongoDB | `"skip":20` | inalterado |

  Os tetos do MySQL (2^64−1) e do SQLite (`LIMIT -1`) não são invenção: são as receitas documentadas em cada manual para "todas as linhas a partir de um deslocamento", e são **necessários** porque nesses dois motores `OFFSET` não é cláusula independente — só no PostgreSQL é. O **Firebird não migrou** para `OFFSET/FETCH` de propósito: `FIRST/SKIP` funciona em toda versão (inclusive 2.5) e aceita expressão, enquanto o `OFFSET/FETCH` do Firebird só aceita literal ou parâmetro.

  No MSSQL, como `<offset_fetch>` só existe dentro de um `ORDER BY`, sem `OrderBy` do usuário é emitido `ORDER BY (SELECT NULL)` — preenchimento **gramatical**, que não promete determinismo e não acrescenta operador `Sort` ao plano. Sob `DISTINCT` ou `UNION` o motor recusa `(SELECT NULL)` (`Msg 145` e `Msg 104`) e é emitido `ORDER BY 1`, o único item que está sempre na lista de seleção. Todas as formas foram medidas em motor real; os `docker run`, versões e saídas brutas estão em `Test Delphi\Common_tests\test.pagination.<dialeto>.sql`.

- **BREAKING CHANGE (SQL emitido) — `First(0)` passou a devolver zero linhas nos 7 dialetos.** `First(0)` é pedido legítimo e distinto de "sem `First`", como o próprio `TFluentSQLPagination` declara. Estava errado em dois dialetos, cada um de um jeito:

  | Dialeto | Antes | Depois |
  |---|---|---|
  | MSSQL | `... OFFSET 0 ROWS FETCH NEXT 0 ROWS ONLY` — **`Msg 10744`**, recusado | `SELECT TOP 0 ...` → 0 linhas |
  | MSSQL, com `UNION`/`UNION ALL`/`EXCEPT`/`INTERSECT` | idem | `... ORDER BY 1 OFFSET 9223372036854775807 ROWS` → 0 linhas |
  | MongoDB (`find`) | `"limit":0` — **devolvia a coleção INTEIRA**, em silêncio | `"skip":9223372036854775807` → 0 documentos |
  | MongoDB (`aggregate`) | `{"$limit":0}` — `the limit must be positive` | `{"$skip":9223372036854775807}` → 0 documentos |
  | Firebird / MySQL / SQLite / PostgreSQL / Oracle | já corretos | inalterados |

  No MongoDB `limit: 0` significa **sem limite** — o usuário pedia nada e recebia tudo, sem erro. Era o único dos sete em que `First(0)` falhava calado, e os dois caminhos do próprio driver (`find` e `aggregate`) discordavam entre si sobre o que `First(0)` queria dizer.

  No SQL Server a restrição é do **literal**, não da semântica: o mesmo `FETCH` com o contador vindo de uma variável `BIGINT` valendo `0` é aceito e devolve zero linhas. A forma usada é `SELECT TOP 0`, e ela **descarta o `Skip(n)`** do usuário — pular *n* linhas de um conjunto vazio dá o mesmo conjunto vazio, e é esse descarte que evita o `Msg 10741` (`TOP` não coexiste com `OFFSET`). De quebra, dispensa a cláusula `ORDER BY` de preenchimento, que só existia para hospedar o `OFFSET/FETCH`.

  A **única** combinação em que `TOP 0` não serve é a operação de conjunto: o `TOP` pertence a uma *query specification* e limita só o ramo em que está escrito — medido, `SELECT TOP 0 * FROM T UNION SELECT * FROM U` devolve as 60 linhas de `U`. Só aí entra a cauda `OFFSET 9223372036854775807 ROWS`, que **custa uma varredura completa da tabela, contra I/O zero do `TOP 0`** — com `ORDER BY`, a forma cara ainda acrescenta uma *Worktable*, ou seja, ordenação. A afirmação é o **contraste**: `TOP 0` não lê a tabela, a cauda lê tudo. O número absoluto de leituras lógicas depende da largura da linha e do tamanho da massa — na medição registrada em `test.pagination.mssql.sql` (200 mil linhas, uma coluna `INT`) deu 767, e uma revisão independente mediu 446 numa tabela mais estreita. **Não trate o número como propriedade da forma; trate o contraste.** O custo ficou confinado a esse caso em vez de valer para todo `First(0)` — `First(pageSize)` com `pageSize` zerado dentro de um laço, numa tabela grande, é incidente de produção.

  Também medido e recusado: `FETCH NEXT (SELECT 0) ROWS ONLY`, aceito e barato, mas só quando o `OFFSET` é o literal `0`. Todas as medições estão em `test.pagination.mssql.sql`, parte Z — **inclusive os caminhos não seguidos**, para que quem pensar em `TOP 0` ou em `(SELECT 0)` encontre a medição pronta em vez de refazê-la.

  No MongoDB o `Skip(n)` também é descartado, pelo mesmo motivo. Os outros cinco dialetos preservam os dois números, porque conseguem exprimir o zero pelo limite.

  **`Skip(0)` foi medido correto nos 7 antes e depois** e não mudou — é "não pule nada", não "sem `Skip`".

- **BREAKING CHANGE (SQL emitido) — Firebird: `FIRST`/`SKIP` passaram a preceder o `DISTINCT`.** Era `SELECT DISTINCT FIRST 3 SKIP 20 ...`, forma que o Firebird 5.0.4 **recusa** com `-104 Token unknown`; a gramática é `SELECT [FIRST m] [SKIP n] [{DISTINCT | ALL}] <colunas>`. Toda consulta `Select.Distinct` com paginação neste driver era rejeitada pelo motor.
- **MSSQL, Oracle e DB2: `DISTINCT` passou a preceder a lista de colunas.** Emitiam `SELECT NOME DISTINCT FROM T`. Não dependia de paginação: `Select.Distinct` sozinho já saía assim.
- **BREAKING CHANGE (comportamento) — `TFluentSQLRegister.Functions` deixou de devolver `nil`.** Passa a levantar `EFluentSQLDriverNotRegistered` (classe nova em `FluentSQL.Interfaces.pas`). Antes, o `nil` era desreferenciado em `FluentSQL.Functions.pas` e chegava ao consumidor como `EAccessViolation` opaca. `Select` e `Serialize` passaram de `Exception` crua para a mesma classe nomeada. **Quem captura esses erros para os traduzir em erro de domínio deve rever o `try..except`.**
- `Ceil` e `Length` deixaram de ser emitidos como SQL ANSI fixo pelo núcleo e passaram a delegar ao driver. Corrige SQL inválido gerado em silêncio: `CEIL(...)` não existe em T-SQL (agora `CEILING`), e `LENGTH(...)` não existe nem em T-SQL (agora `LEN`) nem no núcleo do Firebird (agora `CHAR_LENGTH`).
- **BREAKING CHANGE (API) — `IFluentSQLSelectQualifiers` ganhou o método `RequestsZeroRows`.** Acrescentar método a interface publicada quebra quem a implementa do zero.

  **Impacto real: baixo, e provavelmente não é você.** O único implementador é `TFluentSQLSelectQualifiers`, no core, e os 9 qualificadores de driver **descendem** dela sobrescrevendo apenas `SerializePagination` — herdam o novo método de graça, e o mesmo vale para qualquer subclasse externa. Só quebra quem implementa `IFluentSQLSelectQualifiers` inteira do zero e a injeta com um `IFluentSQLSelect` próprio via `RegisterSelect`. **O que fazer nesse caso:** implementar `function RequestsZeroRows: Boolean` como `HasFirst and (First = 0)` sobre a sua coleção — ou passar a descender de `TFluentSQLSelectQualifiers`.

  Está aqui e não em *Added* porque é a régua que esta própria entrega estabelece: se ela rotula como BREAKING até a troca de classe de exceção que pede revisão de `try..except`, acrescentar método a interface publicada não pode ser rodapé.

  O método responde "o usuário pediu `First(0)`?". É pergunta sobre a coleção de qualificadores, não sobre dialeto: a **forma** de exprimir zero linhas varia (`TOP 0`, `LIMIT 0`, `FIRST 0`, pular tudo), o **pedido** é o mesmo nos sete. E não é `First = 0`, é `HasFirst and (First = 0)` — "não pediu `First`" e "pediu `First(0)`" são coisas diferentes, e só a primeira devolve o conjunto todo.

- **BREAKING CHANGE (SQL emitido) — `IFluentSQLMerge.Update`/`.Insert` passaram a parametrizar valores string.** Valores numéricos já viravam `:pN`; **strings iam verbatim para o texto do SQL**, sem aspas e sem escape. Quem compara o SQL gerado com string fixa **precisa atualizar as expectativas**:

  | Chamada | Antes | Depois |
  |---|---|---|
  | `.Update(['NOME', 'TESTE', 'VALOR', 10.5])` | `SET [NOME] = TESTE, [VALOR] = :p1` | `SET [NOME] = :p1, [VALOR] = :p2` |
  | `.Insert(['ID', 1, 'NOME', 'TESTE'])` | `VALUES (:p1, TESTE)` | `VALUES (:p1, :p2)` |

  **Isto não era só um buraco de segurança latente — era funcionalidade quebrada.** O caso benigno já não funcionava em motor nenhum: `SET [NOME] = TESTE` é `Msg 207, Invalid column name 'TESTE'` no SQL Server, e `O'Brien` dava `Msg 105, Unclosed quotation mark`. Com valor hostil, era injeção executável: medido em SQL Server 2022, `.Update(['NOME', '1; DROP TABLE USERS; --'])` **derrubou a tabela**. Depois da correção o mesmo payload chega ao banco como dado da coluna. Oráculo completo, com `docker run`, versão do motor e saída bruta antes e depois: `Test Delphi\Common_tests\test.merge.mssql.sql`.

  A regra é a que o overload tipado `SetValue(const AColumnName, AColumnValue: String)` já seguia: no array de `.Update`/`.Insert` os slots ímpares são **nomes de coluna** (identificadores, seguem literais) e os pares são **valores** (sempre `:pN`).

  A fronteira, agora que o overload `array of const` de `SetValue`/`Values` também mudou (entrada abaixo), é uma **regra**, não uma lista curta:

  - **Parametrizam string** os **quatro** pontos em que o `array of const` é comprovadamente uma lista de *valores*: `Merge.Update`, `Merge.Insert`, `SetValue(nome, [...])` e `Values(nome, [...])`. Esses quatro, e só esses, passam por `TUtils.SqlArrayOfConstToParameterizedValue`.
  - **Continuam literais** — string interpolada verbatim no texto do SQL — **todos os demais `array of const`, sem exceção**, porque todos estão em posição de *expressão*, onde a string pode legitimamente ser fragmento de SQL (identificador, operador, trecho). O critério mecânico é: passa por `TUtils.SqlArrayOfConstToParameterizedSql`. **Hoje são 17**, e a versão anterior desta entrada listava só 6 — omitia 11, entre eles `AndOpe`, que é a forma mais comum da API logo depois do `Where`. A lista completa, conferida no código e **executada** uma a uma:

  | # | Ponto de entrada | Implementado em |
  |---|---|---|
  | 1 | `IFluentSQL.Where(array)` | `FluentSQL.pas:1472` |
  | 2 | `IFluentSQL.AndOpe(array)` | `FluentSQL.pas:368` |
  | 3 | `IFluentSQL.OrOpe(array)` | `FluentSQL.pas:373` |
  | 4 | `IFluentSQL.Column(array)` | `FluentSQL.pas:686` |
  | 5 | `IFluentSQL.Having(array)` | `FluentSQL.pas:1018` |
  | 6 | `IFluentSQL.OnCond(array)` | `FluentSQL.pas:421` |
  | 7 | `IFluentSQL.CaseExpr(array)` | `FluentSQL.pas:343` |
  | 8 | `IFluentSQL.ForDialectOnly(dialeto, array)` | `FluentSQL.pas:326` |
  | 9 | `IFluentSQL.Expression(array)` | `FluentSQL.pas:922` |
  | 10 | `IFluentSQLCriteriaExpression.AndOpe(array)` | `FluentSQL.Expression.pas:261` |
  | 11 | `IFluentSQLCriteriaExpression.OrOpe(array)` | `FluentSQL.Expression.pas:344` |
  | 12 | `IFluentSQLCriteriaExpression.Ope(array)` | `FluentSQL.Expression.pas:358` |
  | 13 | `IFluentSQLCriteriaExpression.Fun(array)` | `FluentSQL.Expression.pas:318` |
  | 14 | `IFluentSQLCriteriaCase.When(array)` | `FluentSQL.Cases.pas:383` |
  | 15 | `IFluentSQLCriteriaCase.AndOpe(array)` | `FluentSQL.Cases.pas:268` |
  | 16 | `IFluentSQLCriteriaCase.OrOpe(array)` | `FluentSQL.Cases.pas:354` |
  | 17 | `IFluentSQLMerge.On(array)` | `FluentSQL.Merge.pas:376` |

  Quatro amostras do que os 11 omitidos emitem de fato, medidas com o payload `x'; DROP TABLE U; --`:

  ```
  AndOpe(array)         => SELECT * FROM T WHERE (A = :p1) AND (NOME = x'; DROP TABLE U; --)   params=1
  OrOpe(array)          => SELECT * FROM T WHERE ((A = :p1) OR (NOME = x'; DROP TABLE U; --))  params=1
  Expression(array)     => SELECT * FROM T WHERE NOME = x'; DROP TABLE U; --                   params=0
  ForDialectOnly(array) => SELECT * FROM TOPTION(x'; DROP TABLE U; --)                         params=0
  ```

  **Se você audita a fronteira, audite a regra, não a lista:** qualquer `array of const` que não seja um dos quatro slots de valor acima interpola string verbatim. **Não passe entrada não confiável por nenhum deles.** O caminho seguro para expressão está sob tarefa própria.

- **BREAKING CHANGE (SQL emitido) — `SetValue(nome, array of const)` e `Values(nome, array of const)` passaram a parametrizar valores string.** É o mesmo defeito da entrada acima, no `INSERT`/`UPDATE` comum em vez do `MERGE`, e a régua é a mesma: string deixou de ir verbatim e passou a `:pN`. Quem compara o SQL gerado com string fixa **precisa atualizar as expectativas**:

  | Chamada | Antes | Depois |
  |---|---|---|
  | `.SetValue('NOME', ['TESTE']).SetValue('NIVEL', [7])` | `VALUES (TESTE, :p1)` — 1 parâmetro | `VALUES (:p1, :p2)` — 2 parâmetros |
  | `.Values('NOME', ['ANA'])` | `VALUES (ANA)` — 0 parâmetros | `VALUES (:p1)` — 1 parâmetro |

  **A assimetria era dentro do mesmo slot:** `.Values('NIVEL', [7])` já saía como `:p1`, enquanto `.SetValue('NOME', ['TESTE'])` saía como o texto `TESTE` cru. O numérico parametrizava, a string não. E é posição de valor por construção — o próprio `_InternalSet` a afirma com `_AssertSection([secInsert, secUpdate])`, ou seja, o array é o lado direito de `COLUNA = ...` e não tem como ser fragmento de SQL.

  **Também aqui era funcionalidade quebrada, e não só risco latente.** Medido em SQL Server 2022: o caso benigno `.SetValue('NOME', ['TESTE'])` emitia `INSERT INTO USERS (NOME) VALUES (TESTE)` → `Msg 207, Invalid column name 'TESTE'`; e `O'Brien` dava `Msg 105, Unclosed quotation mark`. Com valor hostil era injeção executável — mas **o payload que funciona aqui não é o mesmo do `MERGE`**: numa lista `VALUES (...)` a aspa simples abre um literal que engole o resto do batch, então `x'; DROP TABLE USERS; --` apenas quebra o comando. O payload que executa fecha o parêntese: `.SetValue('NOME', ['1); DROP TABLE USERS; --'])` emitia `INSERT INTO USERS (NOME) VALUES (1); DROP TABLE USERS; --)`, `(1 rows affected)` sem erro, e **a tabela foi dropada**. Depois da correção o mesmo payload chega ao banco como dado da coluna. Oráculo com `docker run`, versão do motor e saída bruta antes e depois: `Test Delphi\Common_tests\test.setvalue.mssql.sql`.

  **`SetValue`/`Values` também passaram a levantar `EArgumentException` em formas que antes saíam caladas** — é a entrada irmã da do `MERGE`, logo abaixo, e vale para o `INSERT`/`UPDATE` comum, que é o caminho **mais** trafegado dos dois:

  | Chamada | Antes (emitido) | Depois |
  |---|---|---|
  | `.SetValue('NOME', [nil])` / `.Values('NOME', [nil])` — `nil` em posição de valor | `VALUES (:p1)`, com `p1 = '00000000'` | `EArgumentException` |
  | `.SetValue('X', [umObjeto])` — instância em posição de valor | `VALUES (:p1)`, com `p1` = o **`ClassName`** | `EArgumentException` |
  | `.SetValue('X', [TMinhaClasse])` — referência de classe | `VALUES (:p1)`, com `p1` = o **`ClassName`** | `EArgumentException` |
  | `.SetValue('X', [Unassigned])` — variante vazia | `VALUES (:p1)`, com `p1 = ''` (string **vazia**, não `NULL`) | `EArgumentException` |
  | `.SetValue('X', [Null])` — variante `Null` | `EVariantTypeCastError` **da RTL** | `EArgumentException` |
  | `.SetValue('X', [])` — lista vazia | `INSERT INTO T (X) VALUES ()` / `UPDATE T SET X =` | `EArgumentException` |
  | `.SetValue('D', ['CURRENT','TIMESTAMP'])` — mais de um valor | `VALUES (:p1 :p2)` — placeholders **justapostos**, sem vírgula | `EArgumentException` |

  **O `nil` não é novidade desta rodada, mas nunca tinha sido declarado nem testado neste caminho.** O ramo `vtPointer` de `TUtils._StringVarRecAsParam` é **compartilhado** pelo `MERGE` e por `SetValue`/`Values`, então a guarda introduzida para o `MERGE` já valia aqui desde então — mas a entrada do CHANGELOG falava só em "chamadas de `MERGE`", e a mutação daquele ramo só derrubava testes de `MERGE`: a guarda do caminho mais usado estava **sem oráculo nenhum**. Agora tem, em `Test Delphi\Common_tests\test.core.params.pas`.

  **As quatro linhas do meio são a mesma corrupção do `nil`, por outras portas — e essas portas estavam abertas.** Objeto, referência de classe e `Unassigned` **não levantavam nada**: `TUtils._VarRecToString` converte os três em texto plausível (`ClassName`, `ClassName`, string vazia) e o valor ia para a coluna como dado, com o SQL bem-formado e nenhum motor reclamando. O `Null` variante já falhava, mas com `EVariantTypeCastError` **da RTL**, cuja mensagem não nomeia a chamada que a causou — quem captura `EArgumentException` das demais guardas não o pegava. Os cinco passaram a levantar no mesmo lugar, `TUtils._AssertValueSlotCarriesData` (`FluentSQL.Utils.pas:192-224`). Que `nil`/`Null`/`Unassigned` devessem virar `NULL` em vez de levantar continua sendo **decisão de convenção não tomada** — os testes travam o comportamento atual, não o abençoam. **`vtInterface` ficou de fora de propósito:** já levanta hoje, em `_VarRecToString`, então não há corrupção silenciosa a fechar — só a classe e a mensagem são pobres.

  **As duas últimas são guardas de cardinalidade**, e existem porque o `CHANGELOG` afirmava que "a régua é a mesma" do `MERGE` enquanto o irmão seguia emitindo SQL inválido em silêncio. Medido em execução real, seis motores, antes de decidir a forma:

  - **Lista vazia — zero dos seis aceitam.** MSSQL 2022 `Msg 102 near ')'` / `near ';'`; PostgreSQL 16.14 `syntax error at or near ")"` / `near ";"`; Oracle Free 23 `ORA-00936: missing expression` (as duas); Firebird 5.0.4 `-104 Token unknown ')'` / `-104 Unexpected end of command`; MySQL 8.4.11 `ERROR 1136` / `ERROR 1064`; SQLite 3.53.4 `Parse error near ")"` / `near ";"`.
  - **Mais de um valor — cinco dos seis recusam, e o sexto é o motivo mais forte para a guarda.** MSSQL `Msg 102 near '@p2'`; PostgreSQL `syntax error at or near "$2"`; Firebird `-104 Token unknown '?'`; MySQL `ERROR 1064 near '?)'`; SQLite `Parse error near "?"`. **O Oracle não recusa por gramática:** ele lê `:p1 :p2` como *bind + variável indicadora* (`:host:indicator`), ou seja, **um** valor. Com duas colunas isso vira `ORA-00947: not enough values`; **com uma coluna a forma é aceita** — medido, `INSERT INTO T2 (D) VALUES (:p1 :p2)` responde `1 row created`, grava o valor de `:p1` e **descarta `:p2` sem erro nenhum**. Perda silenciosa de valor, que é pior que o erro de sintaxe dos outros cinco.

  Controle acompanhando as duas: `VALUES (:p1, :p2)` **com** vírgula executa em MSSQL, PostgreSQL, MySQL, SQLite e Oracle. **No Firebird, dito com precisão, não chega a executar:** pelo `isql` o comando atravessa a gramática e para na *ligação* dos binds — `SQLSTATE 07002`, `No SQLDA for input values provided` —, porque o `isql` não liga parâmetro. É fase diferente do `-104 Token unknown` que a forma justaposta recebe no mesmo cliente, e é justamente esse contraste que sustenta a leitura: **a recusa é da forma justaposta, e não do `INSERT`**. Saída bruta e os `docker exec` exatos em `Test Delphi\Common_tests\test.setvalue.mssql.sql`.

  **Que um motor aceite não enfraquece a guarda, é o que a justifica:** o único dialeto que não protege o consumidor pela sintaxe é justamente o que precisa da proteção na biblioteca. E a chamada que produzia isso — `.SetValue('D', ['CURRENT','TIMESTAMP'])` — **parece** correta a quem a escreve: tem parâmetros de verdade e `Params.Count = 2`.

  **O que fazer:** passe **exatamente um** valor por coluna; **omita a coluna** se ela deve ficar `NULL`; e, se o que você queria era uma expressão (`CURRENT_TIMESTAMP`, `A + 1`), veja o parágrafo seguinte — não há forma de exprimi-la em slot de valor.

  **O que fazer (parametrização):** se você dependia de passar fragmento de SQL por esse array — por exemplo `.SetValue('DATA', ['CURRENT_TIMESTAMP'])` — ele agora vira **dado**, e a coluna recebe a string `CURRENT_TIMESTAMP`. **Não há substituto hoje:** o overload tipado `SetValue(const AColumnName, AColumnValue: String)` também parametriza (`FluentSQL.pas:405-412`), e sempre parametrizou. Ou seja, o `INSERT`/`UPDATE` do FluentSQL **não exprime expressão em slot de valor** — nem antes nem depois; o que existia era um caminho que funcionava *por acidente*, e apenas quando o texto passado calhava de ser SQL válido no dialeto alvo. Isso está registrado em *Known issues* como a distinção **valor × expressão**, que é tarefa de arquitetura própria.

- **BREAKING CHANGE (comportamento) — nove formas de `MERGE` que não levantavam nada passaram a levantar `EArgumentException`.** Quase todas emitiam SQL que **nenhum motor executa**, e o faziam em silêncio: o erro só aparecia no banco do consumidor, longe da linha que o causou. *(A tabela abaixo é a lista completa; uma versão anterior desta entrada dizia "quatro" e listava cinco linhas, e a seguinte dizia "seis" antes de os irmãos do `nil` serem medidos.)*

  | Chamada | Antes (emitido) | Depois |
  |---|---|---|
  | `.Update(['NOME'])` — contagem ímpar | `SET [NOME] = ` | `EArgumentException` |
  | `.Insert(['ID', 1, 'NOME'])` — contagem ímpar | `VALUES (:p1, )` | `EArgumentException` |
  | `.Update([])` / `.Update` — lista vazia ou sem argumentos | `UPDATE SET ;` | `EArgumentException` |
  | `.Insert([])` / `.Insert` — lista vazia ou sem argumentos | `INSERT;` | `EArgumentException` |
  | `.Update(['NOME', nil])` — `nil` em posição de valor | `SET [NOME] = :p1`, com `p1 = '00000000'` | `EArgumentException` |
  | `.Update(['NOME', umObjeto])` — instância em posição de valor | `SET [NOME] = :p1`, com `p1` = o **`ClassName`** | `EArgumentException` |
  | `.Update(['NOME', TMinhaClasse])` — referência de classe | `SET [NOME] = :p1`, com `p1` = o **`ClassName`** | `EArgumentException` |
  | `.Update(['NOME', Unassigned])` / `.Update(['NOME', Null])` — variante sem dado | `:p1 = ''` no primeiro caso; `EVariantTypeCastError` **da RTL** no segundo | `EArgumentException` |
  | `.Into(…).Using(…).On(…)` **sem nenhum `WhenMatched`/`WhenNotMatched`** | `MERGE INTO [T] AS [t] USING [S] AS [s] ON (…);` — só o cabeçalho | `EArgumentException` |

  **Está aqui, e não em *Fixed*, porque é a régua que esta própria entrega estabelece:** se ela rotula como BREAKING até a troca de *classe* de exceção que pede revisão de `try..except` (`EFluentSQLDriverNotRegistered`, `EFluentSQLStatementNotSupported`), então sair de **nenhuma exceção** para **exceção lançada na chamada** — que derruba código que hoje atravessa esse caminho sem `try` nenhum — não pode ser rodapé de *Fixed*.

  **`.Update([])` e `.Update` produzem o mesmo texto** — as duas chegam ao serializador com zero pares — e por isso caem na mesma regra. **A afirmação anterior de que "contagem par, inclusive a lista vazia, continua passando" era falsa:** zero é par, mas serializa como `UPDATE SET ;`, exatamente o SQL inválido que a guarda existe para impedir. Contagem par **e não vazia** é que continua passando.

  Medido em execução real, as duas formas nuas, seis motores, **zero aceitam**: SQL Server 2022 `Msg 102`; PostgreSQL 16.14 `syntax error at or near ";"`; Oracle Free 23.26 `ORA-00921` e `ORA-00926 Missing VALUES or SET keyword`; Firebird 5.0.4 `-104 Unexpected end of command`; MySQL 8.4.11 e SQLite 3.53.4 recusam a palavra `MERGE` inteira, que não existe nesses dois. Dois controles acompanham a medição para que a leitura não ultrapasse o medido: no PostgreSQL, `INSERT DEFAULT VALUES` atravessa o parser e só falha em restrição `NOT NULL` — logo a recusa é da forma nua, não do `MERGE`; no MySQL, um `MERGE` perfeitamente válido recebe o mesmo `ERROR 1064` — logo ali a recusa é da instrução, não da forma. Saída bruta e `docker run` em `Test Delphi\Common_tests\test.merge.mssql.sql`.

  O **`MERGE` sem nenhuma cláusula `WHEN`** é a instrução pela metade: o cabeçalho sozinho não é `MERGE` em motor nenhum. Medido antes de decidir a forma, e nenhum dos que têm `MERGE` aceita: SQL Server 2022 `Msg 102, Incorrect syntax near ';'`; Oracle Free 23 `ORA-02000: missing WHEN keyword`; PostgreSQL 16.14 `syntax error at or near ";"`; Firebird 5.0.4 `-104 Unexpected end of command`. Controle acompanhando: o **mesmo** texto com `WHEN MATCHED THEN UPDATE SET D = 'z'` é aceito pelos quatro — logo a recusa é da forma sem `WHEN`, e não do `MERGE`. A guarda ficou no **núcleo** (`TFluentSQLMerge.Serialize`, `FluentSQL.Merge.pas:296`) e não no serializador do MSSQL, porque a regra é da instrução e não do dialeto.

  **Consequência de ordem, declarada de propósito:** como essa guarda roda **antes** do despacho por dialeto, um `MERGE` sem `WHEN` montado sobre um dialeto **relacional** sem serializador recebe `EArgumentException` e **não** `EFluentSQLStatementNotSupported`. As duas seriam verdadeiras; a escolhida é a que aponta a linha que o consumidor escreveu.

  Medido, dialeto por dialeto, sem `defines` extras: **Firebird, MSSQL, MySQL, SQLite, Oracle e PostgreSQL** → `EArgumentException`; **InterBase e DB2** (desligados no `.inc`) → `EFluentSQLDriverNotRegistered`, porque morrem antes, ainda em `Query()`; **MongoDB → não levanta nada**, e devolve `{}`. A enumeração fecha aqui de propósito, sem reticências: o MongoDB é contraexemplo, não caso omisso. `TFluentSQLSerializeMongoDB` sobrescreve `AsString` inteiro, então `TFluentSQLMerge.Serialize` — onde a guarda mora — nunca chega a rodar. Isso está registrado em *Known issues* como o `MERGE` que o MongoDB descarta em silêncio, e travado por `TestMerge_MongoDB_DropsMergeSilently_KnownGap`.

  O caso do **`nil` — e o dos quatro irmãos dele — é de natureza diferente e pior**: não emitia SQL inválido, emitia SQL **válido com o dado errado**. `nil` num `array of const` chega como `vtPointer` e era convertido por `IntToHex`, então a coluna recebia a string `'00000000'`. Pela **mesma** porta passavam instância (`vtObject`), referência de classe (`vtClass`) e `Unassigned`, convertidos em `ClassName`, `ClassName` e string vazia — corrupção silenciosa, sem erro em lugar nenhum, nos quatro. `Null` variante já levantava, mas `EVariantTypeCastError` da RTL. O par nome/valor não tem como exprimir `NULL`, e dar essa semântica a `nil`/`Null`/`Unassigned` é decisão de convenção que **não** foi tomada aqui.

  **O que fazer:** passe ao menos um par `('COLUNA', valor)`; use `.Delete` se a ação pretendida era outra; e **omita a coluna da lista** se ela deve ficar `NULL`. Se o seu código chamava `.Update`/`.Insert` sem argumentos, ele estava gerando SQL que o motor rejeitava — a exceção agora aponta a linha.

- **BREAKING CHANGE (comportamento) — `MERGE` em dialeto sem serializador passou de `EStackOverflow` para `EFluentSQLStatementNotSupported`.** Afeta **Firebird, MySQL, SQLite, Oracle e PostgreSQL**. `TFluentSQLSerialize.Merge` estava escrito como despachante e redelegava ao próprio dialeto, reentrando em si mesmo indefinidamente — não era erro tratável, era estouro de pilha que **matava o processo**. Só o MSSQL sobrescreve `Merge`.

  **Quem captura `EStackOverflow` para tratar isso deve trocar por `EFluentSQLStatementNotSupported`.** É a mesma régua aplicada ao `EFluentSQLDriverNotRegistered` acima: troca de classe de exceção que pede revisão de `try..except` é BREAKING.

  **`dbnMongoDB` não mudou e continua sendo lacuna conhecida** — ver *Known issues*.

- **InterBase (`dbnInterbase`, desligado por omissão) — `Length` e `Ceil` passaram a levantar `EFluentSQLFunctionNotSupported`** em vez de emitir `LENGTH(...)` / `CEIL(...)`. O InterBase divergiu do tronco comum antes de o Firebird 2.1 introduzir `CHAR_LENGTH` e `CEIL`/`CEILING`, e a forma correta para esse dialeto não foi verificada — emitir a forma do Firebird seria repetir o defeito do `CEIL` no MSSQL. Se você liga `{$DEFINE INTERBASE}` e precisa dessas duas funções, implemente-as em `FluentSQL.FunctionsInterbase.pas` e remova-as da tabela de suporte em `Test Delphi\Common_tests\test.driver.functions.matrix.pas`.

- **BREAKING CHANGE (classe de exceção, e uma chamada que antes não levantava) — as três guardas de ordem do builder deixaram de ser `Assert`.** O `Source/` inteiro tinha **exatamente dois** `Assert`, e os dois guardavam a mesma coisa: um método que só faz sentido depois de outro ter sido chamado e que, sem ele, indexa `Count-1` numa coleção vazia. `Assert` é removido pelo compilador com `{$C-}`, **que é o default de qualquer build de release** — ou seja, em produção não havia guarda nenhuma.

  | Chamada | Antes (`{$C+}`, debug) | Antes (`{$C-}`, release) | Depois (nas duas) |
  |---|---|---|---|
  | `.CaseExpr('T').IfThen('X')` sem `When` | `EAssertionFailed`: `TFluentSQLCriteriaCase.IfThen: Missing When` | `EArgumentOutOfRangeException`: `List index out of bounds (-1). TList<...IFluentSQLCaseWhenThen> is empty` | `EArgumentException` nomeando `IFluentSQLCriteriaCase.IfThen` e `When` |
  | `.CaseExpr('T').ElseIf('X')` sem `When` | **não levantava** — emitia `CASE ELSE X END` | **não levantava** — idem | `EArgumentException` nomeando `IFluentSQLCriteriaCase.ElseIf` |
  | `.OrderBy().Desc` sem coluna | `EAssertionFailed`: `TCriteria.Desc: No columns set up yet` | `EArgumentOutOfRangeException`: `List index out of bounds (-1). TList<...IFluentSQLName> is empty` | `EArgumentException` nomeando `IFluentSQL.Desc` e `ORDER BY` |

  **O `ElseIf` é o caso que muda comportamento, não só classe de exceção:** ele não tinha guarda alguma e emitia calado `CASE ELSE <valor> END`, que **nenhum motor aceita** — PostgreSQL 16.14 `ERROR: syntax error at or near "ELSE"`, SQL Server 2022 `Msg 156 Incorrect syntax near the keyword 'ELSE'`, Oracle 26ai `ORA-00923: FROM keyword not found where expected`. Saída bruta em `Test Delphi\Common_tests\test.cases.guards.matrix.sql`. É a mesma régua já publicada em `TUtils._AssertSingleValue` e em `FluentSQL.Merge.pas:297`: entre emitir SQL que o motor recusa e recusar a chamada na linha que a causou, recusa.

  **Quem captura `EAssertionFailed` (ou compila com `{$C-}` e captura `EArgumentOutOfRangeException`) para tratar esses três casos deve trocar por `EArgumentException`.** Quem chama na ordem certa não vê diferença: `IfThen`/`ElseIf` depois de `When` e `Desc` depois de `OrderBy('COLUNA')` continuam emitindo exatamente o mesmo SQL, byte a byte.

  Detalhe conferido e **não** corrigido às cegas: o `Assert` do `Desc` afirmava sobre `FAST.ASTColumns` e indexava `FAST.OrderBy.Columns`. As duas **são o mesmo objeto** enquanto a seção é `secOrderBy` — quem as liga é `_DefineSectionOrderBy` (`FluentSQL.pas:794`), e `_SetSection` não tem caminho que desfaça a ligação. A afirmação não estava medindo coleção errada na prática; era só o nome errado para ler, e passou a citar a coleção que de fato indexa. Há teste dedicado a essa porta (`TestDescComColunaNoSelectMasNenhumaNoOrderByLevanta`), porque a equivalência vale enquanto `_DefineSectionOrderBy` a mantiver.

  **Não existe `Asc` para receber a guarda equivalente.** `IFluentSQL` declara só `function Desc: IFluentSQL;` (`FluentSQL.Interfaces.pas:315`); `dirAscending` é o default de `TOrderByDirection`. Varridas as duas famílias no `Source/` inteiro: na árvore anterior (`283512c`) `Assert(` devolvia 2 ocorrências — `FluentSQL.Cases.pas:340` e `FluentSQL.pas:838`, as duas acima — e a indexação por `Count-1]` devolvia 2, **exatamente nos mesmos dois métodos** (`FluentSQL.Cases.pas:342` e `FluentSQL.pas:839`; no HEAD desta branch, `FluentSQL.Cases.pas:379` e `FluentSQL.pas:865`). No HEAD desta branch `Assert(` devolve **zero** no `Source/`. Todo o resto de `Count - 1` na biblioteca é limite de `for`. A família está fechada.

  **A fronteira publicada dos 17 `array of const` não mudou — recontada, não presumida.** O critério mecânico continua sendo "passa por `TUtils.SqlArrayOfConstToParameterizedSql`", e a contagem por chamada segue em 14 sítios / 17 pontos de entrada (os 4 de `IFluentSQLCriteriaExpression` compartilham `FluentSQL.Expression.pas:224`). Esta entrega **não acrescentou nem removeu sobrecarga `array of const`**, e **não criou slot de valor**: `IfThen`/`ElseIf` continuam com as duas sobrecargas de sempre (`String` e `Int64`), ambas em posição de expressão. Os quatro slots de valor (`SqlArrayOfConstToParameterizedValue`) também seguem quatro.

- **BREAKING CHANGE (API) — `IFluentSQLFunctions` ganhou o método `function Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType; const ALength: Integer = 0): String;`.** Acrescentar método a interface publicada quebra quem a implementa do zero. O que a sobrecarga *faz* está em *Added*, junto com a matriz medida que a justifica; o que está aqui é a quebra de compilação.

  **Impacto real: baixo, e provavelmente não é você.** No repositório o único implementador é `TFluentSQLFunctionAbstract` (`FluentSQL.FunctionsAbstract.pas`), e os **nove** drivers descendem dela — quem herda não faz nada. Só quebra quem implementa `IFluentSQLFunctions` inteira do zero e a injeta por `TFluentSQLRegister.RegisterFunctions`: esse código deixa de compilar até declarar o método (`E2291 Missing implementation of interface method`).

  **O que fazer:** passar a descender de `TFluentSQLFunctionAbstract` — que já traz a guarda de interseção — ou declarar o método e recusar o que não medir. **Ressalva de runtime para quem já descende:** o corpo herdado é o abstrato, que levanta `EAbstractError`; um driver externo que não sobrescrever a sobrecarga nova compila limpo e explode na primeira chamada. É o mesmo custo de qualquer função do padrão B.

  Está aqui e não em *Added* pela régua que esta mesma lista já aplicou a `IFluentSQLSelectQualifiers` quando ela ganhou `RequestsZeroRows`: *"acrescentar método a interface publicada não pode ser rodapé"*. A régua não muda de interface para interface.

  **O que NÃO é breaking, para o leitor não confundir:** a sobrecarga de enum **nasceu nesta mesma branch** (commit `059a0e9`) e **nunca foi publicada**. Contra `main` (`33d4391`) essa API nunca existiu, então tê-la apertado depois — de oferecer a união das células medidas para oferecer só a interseção `dftString`/`dftInteger`/`dftFloat` — **não quebra ninguém**: não havia o que quebrar. O commit `d6bbb47` traz o rótulo `refactor(cast)!` por esse aperto, e o rótulo está errado; o histórico não foi reescrito e o erro não se repete aqui. **O único BREAKING desta entrega contra `main` é o membro novo da interface** — a sobrecarga `Cast(String, String)` tem corpo com diff vazio e nenhum SQL emitido muda.

### Added

- **`IFluentSQLFunctions.Cast` ganhou sobrecarga por dialeto: `Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType; const ALength: Integer = 0)`.** `Cast` era a última função escalar no **padrão A** — o núcleo emitia `'CAST(' + AExpression + ' AS ' + ADataType + ')'` sem consultar o driver, e **nenhum** dos nove drivers a sobrescrevia. Uma grafia respondia pelos sete dialetos. É o mesmo defeito estrutural que já queimou `CEIL`/`LENGTH`, com um agravante: aqui a célula errada frequentemente **não levanta**.

  A matriz **10 tipos × 7 dialetos foi medida contra motor real** — `Test Delphi\Common_tests\test.cast.matrix.sql` traz `docker run`, versão e transcrição literal dos erros. **Das 70 células, 46 existem e 24 não.** Nenhum dialeto tem as 10; só `dftString`, `dftInteger` e `dftFloat` existem nos sete — e mesmo `dftString` sai em **seis grafias distintas**, sob **duas políticas de largura opostas**:

  | | Firebird 5.0.4 | SQL Server 2022 | MySQL 8.4.11 | SQLite 3.53.4 | Oracle 26ai | PostgreSQL 16.14 | DB2 12.1.5.0 |
  |---|---|---|---|---|---|---|---|
  | `dftString` | `VARCHAR(4000)` | `NVARCHAR(4000)` | `CHAR` | `TEXT` | `VARCHAR2(4000)` | `VARCHAR` | `VARCHAR` |
  | `dftInteger` | `INTEGER` | `INT` | `SIGNED` | `INTEGER` | `INTEGER` | `INTEGER` | `INTEGER` |
  | `dftFloat` | `DOUBLE PRECISION` | `FLOAT` | `DOUBLE` | `REAL` | `BINARY_DOUBLE` | `DOUBLE PRECISION` | `DOUBLE` |
  | `dftDate` | `DATE` | `DATE` | `DATE` | — | `DATE` | `DATE` | `DATE` |
  | `dftText` | `BLOB SUB_TYPE TEXT` | `NVARCHAR(MAX)` | `CHAR` | `TEXT` | — | `TEXT` | `CLOB` |
  | `dftDateTime` | `TIMESTAMP` | `DATETIME` | `DATETIME` | — | `TIMESTAMP` | `TIMESTAMP` | `TIMESTAMP` |
  | `dftGuid` | — | `UNIQUEIDENTIFIER` | — | — | — | `UUID` | — |
  | `dftBoolean` | `BOOLEAN` | `BIT` | — | — | `BOOLEAN` | `BOOLEAN` | `BOOLEAN` |
  | `dftArray` / `dftUnknown` | — | — | — | — | — | — | — |

  **A tabela acima é o retrato dos MOTORES, e não a lista do que a sobrecarga oferece — as duas não coincidem, e a diferença é a decisão desta entrega.** `Cast(x, ADataType: TFluentSQLDataFieldType)` é a sobrecarga **portável**, e portável quer dizer **interseção**, não união: ela aceita **exclusivamente `dftString`, `dftInteger` e `dftFloat`**, os três que existem nos sete. Os outros sete membros do enum levantam `EFluentSQLFunctionNotSupported` **em todos os dialetos, com a mesma mensagem — inclusive naquele em que a célula existe e foi medida**:

  | Tipo recusado | Existe em | Mas é negado por | Motivo medido |
  |---|---|---|---|
  | `dftDate` | 6 dos 7 | **SQLite** | `CAST('2026-08-10' AS DATE)` devolve `2026`, **sem erro** |
  | `dftDateTime` | 6 dos 7 | **SQLite** | idem, devolve `2026` |
  | `dftText` | 6 dos 7 | **Oracle** | `ORA-22849`: `CLOB` não é alvo de `CAST` (e `ERROR 1064` no MySQL) |
  | `dftBoolean` | 5 dos 7 | **MySQL** | `ERROR 1064`; e no SQLite devolve `0` calado; e na Oracle depende da **versão** do servidor |
  | `dftGuid` | 2 dos 7 | **Firebird** | `-607`; `ORA-01465` na Oracle; sem tipo em MySQL/SQLite/DB2 |
  | `dftArray` | 0 dos 7 | todos | nenhum motor aceita `ARRAY` como alvo de `CAST` |
  | `dftUnknown` | — | — | não é tipo em lugar nenhum |

  **Por que uniforme e não célula a célula.** `dftGuid` responde `UUID` no PostgreSQL e `UNIQUEIDENTIFIER` no SQL Server; oferecê-lo só ali faria a mesma chamada responder em dois motores e levantar em cinco. Isso não é "uma API portável com lacunas" — é **uma API que depende do banco**, e o programador só descobriria na migração, que é o momento mais caro possível. `dftBoolean` fecha o argumento sozinho: na Oracle a célula **só vale em 23ai+**, e o FluentSQL **não tem como saber a versão do servidor** — uma célula cuja validade depende de informação que a biblioteca não possui não é promessa, é palpite.

  **Alargar a lista depois é aditivo e barato; estreitá-la depois seria `BREAKING`.** Por isso começa apertada, enquanto nada depende dela. A lista canônica é `cFluentSQLCastPortableTypes` (`FluentSQL.Interfaces.pas`), e a matriz medida **não foi jogada fora** quando a política encolheu para três: ela é a justificativa da política e a fonte para quem for escrever a grafia à mão.

  **Três achados sustentam cada `—` da tabela, e os três foram medidos:**

  1. **A palavra sozinha não é o tipo inteiro, e o erro é silencioso.** `CAST(x AS NVARCHAR)` sem `(n)` no SQL Server **trunca calado em 30**: 40 caracteres entram, 30 saem, sem erro nem aviso. Um mapeamento ingênuo `dftString → 'NVARCHAR'` trocaria uma incoerência de API por **corrupção silenciosa de dado**. No Firebird (`-104`) e na Oracle (`ORA-00906`) a mesma forma é **erro de sintaxe**, e no PostgreSQL a largura é que **introduz** truncamento (`VARCHAR(4)` sobre 10 caracteres devolve 4, calado). Por isso a largura é decisão **por driver**, não carimbo do núcleo.
  2. **A grafia ANSI é erro de sintaxe no MySQL.** O alvo de `CAST` no MySQL é **lista fechada** na gramática: `INTEGER`, `TEXT`, `BOOLEAN` e `UUID` dão `ERROR 1064`. O núcleo emitia `CAST(x AS INTEGER)` para todos, e o próprio teste da casa exercitava essa string dando-a por boa nos sete — `test.driver.functions.matrix.pas` ainda a exercita, de propósito, porque ali o que se mede é a sobrecarga de `String`; ficou **escrito no cabeçalho e ao lado da chamada** que aquela célula verde afirma que o escape hatch responde, e **não** que o SQL roda.
  3. **O SQLite nunca recusa, e destrói o dado.** Qualquer palavra é aceita e resolvida por afinidade — inclusive `BANANA`. `CAST('2026-08-10' AS DATE)` devolve **`2026`**; `CAST('true' AS BOOLEAN)` devolve **`0`**; `CAST('6F9619FF-…' AS UUID)` devolve **`6`**. Nenhuma levanta. É o único modo de falha pior que emitir SQL inválido, e **é este dialeto que decidiu a política**: se a sobrecarga oferecesse a união, o mesmo `Cast(x, dftDate)` que roda certo no PostgreSQL chegaria aqui e devolveria `2026` — bug que não aparece em teste, aparece em relatório, meses depois.

  **A largura default é `cFluentSQLCastDefaultLength = 4000`, e não é número redondo escolhido a esmo:** é o maior valor simultaneamente legal nos dois motores mais restritivos — `VARCHAR2(4001)` dá `ORA-00910` e `NVARCHAR(4001)` dá `Msg 131 … exceeds the maximum allowed for any data type (4000)`. Está com folga sob o teto do Firebird em UTF8 (8191, medido). Quem precisar de outra passa `ALength` explícito.

  **Recusar não é bloquear: há duas portas de escape, e as duas dizem ao leitor que a portabilidade passou a ser dele.**

  | Porta | Forma | De quem é a garantia |
  |---|---|---|
  | Sobrecarga de `String` | `Cast('C', 'UNIQUEIDENTIFIER')` | **sua** — emite verbatim o que você escrever |
  | `ForDialectOnly` | registra o fragmento só no motor em que ele vale | **sua**, e a escolha fica visível na linha |
  | Sobrecarga de enum | `Cast('C', dftString)` | **do framework** — roda igual nos sete |

  **A sobrecarga `Cast(String, String)` permanece, inalterada e no padrão A.** **Nenhum SQL hoje emitido muda** — o corpo dela tem diff vazio, e há teste fixando que ela continua verbatim nos nove dialetos. Ela é a porta de escape **e a armadilha**: `Cast(x, 'INTEGER')`, a grafia que qualquer um escreve por reflexo e que o núcleo emitia para os sete até esta entrega, é **`ERROR 1064` no MySQL**. Quem usa a sobrecarga de `String` assume esse risco por contrato; quem usa `dftInteger` recebe `SIGNED` e não precisa saber que a lista existe. **A quebra de compatibilidade que esta sobrecarga traz não é rodapé desta entrada:** `IFluentSQLFunctions` ganhou membro, e isso tem entrada própria como `BREAKING CHANGE (API)` em *Changed*.

  **A recusa mora num lugar só, e isso é a política, não economia de linha.** `TFluentSQLFunctionAbstract._AssertCastTypeIsPortable` é chamada como **primeira linha** dos dez `override` de `Cast` — os nove drivers e o núcleo. Se cada driver escrevesse a própria, a mensagem derivaria e o erro viraria pista de qual dialeto está ligado: o programador leria *"o MySQL não suporta"* e concluiria, errado, que trocar de banco resolve. Em **InterBase**, que recusa *tudo* com mensagem própria de dialeto, a guarda vem **antes** do `raise` próprio — são duas causas diferentes (política de interseção × driver não medido) e a mensagem tem de dizer qual é.

  **InterBase levanta nas dez células, de propósito:** não há imagem pública do motor, nenhuma célula foi medida, e a grafia **não foi inferida do Firebird**. Esta própria matriz mostra por que a recusa não é preciosismo — Oracle e DB2 divergem em `CLOB`, Firebird e DB2 divergem na obrigatoriedade da largura. (Com a interseção estrita, medir o InterBase um dia passou a custar **três** células, não dez.)

  **Isto desbloqueia o slot de valor do `CASE`** (a lacuna declarada em *Known issues*). Firebird e DB2 recusavam `CASE WHEN c THEN :p1 ELSE :p2 END` no `PREPARE` (`-804 Data type unknown` / `SQL0418N untyped parameter marker`); medido agora com **as strings exatas que estes drivers emitem**, os dois passam do `PREPARE`: `CAST(:p1 AS VARCHAR(4000))` no Firebird e `CAST(? AS VARCHAR)` no DB2 — no DB2 o `SQL0313N` que responde é o CLP pedindo valores, ou seja o `PREPARE` passou. As duas strings estão travadas por teste; o slot de valor **não** foi implementado nesta entrega.
- Matriz `Test Delphi\Common_tests\test.cast.matrix.pas` (**9 testes**, ligada em `TestFluentSQL_Common.dpr`), declarando o **texto literal esperado** de cada célula — não "não levanta", mas a grafia exata. A comparação é **case-sensitive** de propósito (`Assert.AreEqual(..., False, ...)`), porque o default do DUnitX ignora caixa e deixaria `nvarchar` passar por `NVARCHAR`. Três testes travam a **política**, e não a grafia:

  - `TestRecusaDeTipoForaDaIntersecaoEUniforme` — para cada tipo fora da interseção, exige que **todo** dialeto registrado levante **e que a mensagem seja idêntica caractere a caractere**. É a segunda metade que tem dentes: mensagem por dialeto significa que a guarda deixou de ser a primeira linha do `Cast` naquele ponto.
  - `TestListaPortavelEExatamenteOsTresUniversais` — a lista é exatamente `dftString,dftInteger,dftFloat`, e `DataFieldTypeName` é conferido membro a membro (a tabela é **posicional**: acrescentar membro quebra a compilação com `E2072`, mas **reordenar o enum não quebra nada** — só faz a mensagem nomear o tipo errado, calada).
  - `TestMensagemDeRecusaEnsinaASaida` — a mensagem nomeia o tipo pedido, diz o que a sobrecarga aceita, diz que a recusa é de interseção e não do banco do leitor, e entrega as duas saídas com a grafia pronta.

  **O teste varre as DUAS portas que implementam `IFluentSQLFunctions`** — `TFluentSQLFunctions` (a do núcleo, que `TFluentSQL` usa) e `TFluentSQLRegister.Functions(D)` (o objeto do dialeto). A guarda do núcleo faz **curto-circuito**, então por aquela porta o `Cast` do driver nunca chega a rodar para tipo fora da interseção — sem varrer a porta do driver, as nove guardas de driver seriam decoração não observável: medido, com o teste batendo só no núcleo, fazer o **PostgreSQL responder `UUID`** para `dftGuid` passava **verde**. Varrendo as duas, essa mutação fica **vermelha**.

  **E a metade simétrica, que é preciso dizer porque é pior:** a guarda do **núcleo** também é removível sem uma linha vermelha. Apagar `_AssertCastTypeIsPortable(ADataType);` de `TFluentSQLFunctions.Cast(String, TFluentSQLDataFieldType, Integer)` deixa a suíte inteira verde nas duas configurações, porque o driver logo abaixo recusa com a **mesma** mensagem e nenhum teste consegue distinguir de onde ela veio. **Nenhuma das duas camadas é dispensável, e as duas ficam:**

  - sem a do **núcleo**, a garantia passa a depender de todo driver futuro lembrar de chamar a guarda — quem esquecer reintroduz a união **em silêncio**, que é o modo de falha que esta política existe para matar;
  - sem as dos **drivers**, a garantia passa a depender de o consumidor entrar pela porta do núcleo — e a porta do driver é **pública** (`TFluentSQLRegister.Functions(D)`, usada pela própria biblioteca), além de aberta a um `IFluentSQLFunctions` de terceiro registrado por `RegisterFunctions`.

  Manter as duas custa **uma linha por driver**, e a mensagem tem fonte única em `TFluentSQLFunctionAbstract._AssertCastTypeIsPortable`, então não pode derivar. **A redundância é deliberada e está declarada em comentário na própria linha** (`Source/Core/FluentSQL.Functions.pas`, sobre `TFluentSQLFunctions.Cast(String, TFluentSQLDataFieldType, Integer)`). **Não há teste que a cubra**, e não foi inventado nenhum: um teste que só existisse para dar cor à camada redundante seria decorativo — prefere-se a lacuna declarada.

  **Os pisos de contagem dos dois testes de matriz contam apenas os dialetos RELACIONAIS** (60 células e 84 recusas, com 6 relacionais ligados por omissão). A promessa de interseção é relacional; um piso que se apoiasse num dialeto fora dela afirmaria sobre os dialetos vivos contando com um que não vota. Os demais dialetos registrados continuam sendo varridos célula a célula, com a mesma exigência de texto — como **extra**, sem sustentar número.
- `EFluentSQLDriverNotRegistered` e `EFluentSQLFunctionNotSupported` em `FluentSQL.Interfaces.pas`, para que falhas de dialeto sejam tratáveis pelo consumidor em vez de `EAccessViolation` / `EAbstractError`.
- `EFluentSQLQualifierNotSupported` em `FluentSQL.Interfaces.pas`. Substitui oito cópias de `raise Exception.Create('... Unknown qualifier')` — quatro delas nomeando o driver errado na mensagem.
- Matriz `Test Delphi\Common_tests\test.builder.guards.pas` (11 testes, ligada em `TestFluentSQL_Common.dpr`) fixando as três guardas de ordem do builder que eram `Assert` ou não existiam — `IfThen`, `ElseIf` e `Desc`, cada uma com célula para "levanta" e célula para "a mensagem nomeia a chamada", mais dois controles de que o caminho legítimo continua emitindo o mesmo SQL. **Os testes rodam idênticos com `{$C+}` e com `-$C-`**, porque a exceção esperada é `EArgumentException`, que nenhum `Assert` produz.
- Oráculos de motor real em `Test Delphi\Common_tests\`: `test.cases.bind.matrix.sql` (parâmetro em posição de `THEN`/`ELSE` nos 7 dialetos — a medição que sustenta a lacuna declarada em *Known issues*) e `test.cases.guards.matrix.sql` (`CASE` sem nenhum `WHEN`, recusado por PostgreSQL, SQL Server e Oracle). Trazem `docker run`, versão do motor, a forma exata em que cada cliente prepara o parâmetro, e a saída bruta transcrita. O sufixo é `.matrix` e não um dialeto porque a afirmação só existe comparando os motores entre si.
- Oráculos de paginação em motor real, um por dialeto, em `Test Delphi\Common_tests\`: `test.pagination.{mssql,oracle,firebird,sqlite,mysql,postgresql}.sql` e `test.pagination.mongodb.js`. Trazem o `docker run` exato, a versão do motor e a saída bruta transcrita. Motores medidos: SQL Server 2022 (16.0.4265.3), Oracle Free 23.26.2.0.0, Firebird 5.0.4, MySQL 8.4.11, PostgreSQL 16.14, MongoDB 7.0.39, SQLite 3.50.4 (biblioteca embutida no CPython 3.14, módulo `sqlite3`).

  **Duas versões de SQLite aparecem neste CHANGELOG e as duas são medidas, não erro de digitação:** os oráculos de paginação usaram a biblioteca embutida no CPython 3.14 (**3.50.4**); o oráculo de `MERGE` usou a imagem `keinos/sqlite3:latest` (**3.53.4**). Conferido nesta rodada: `docker run --rm -i keinos/sqlite3:latest sqlite3 :memory: "select sqlite_version();"` → `3.53.4`; `python -c "import sqlite3; print(sqlite3.sqlite_version)"` → `3.50.4`. Nenhuma conclusão desta entrega depende da diferença — o SQLite não tem `MERGE` em nenhuma das duas.
- Matriz de teste `Test Delphi\Common_tests\test.pagination.filter.pas` foi de **15 para 28 testes**, e a contagem merece o detalhe porque `+13` esconde o que aconteceu: **6 removidos, 19 acrescentados**. Os 6 removidos descreviam a janela `ROW_NUMBER()` que deixou de existir, e cada um tem substituto:

  | Removido | Substituto |
  |---|---|
  | `TestMSSQLPaginacaoComFiltroEmiteWhereNaoAnd` | `TestMSSQLPaginacaoComFiltroPreservaPredicado` |
  | `TestMSSQLPaginacaoSemFiltroContinuaComWhere` | `TestSqlExatoMSSQL` + `TestFirstSozinhoEmTodoDialeto` |
  | `TestMSSQLFirstSozinhoNaoInventaLimiteInferior` | `TestFirstSozinhoEmTodoDialeto` (7 dialetos, não 1) |
  | `TestMSSQLSkipSozinhoNaoInventaLimiteSuperior` | `TestSkipSozinhoEmTodoDialeto` + `TestSqlExatoSkipSozinho` |
  | `TestMSSQLJanelaUsaOrderByDoUsuario` | `TestMSSQLOrderByDoUsuarioPrecedeOffsetFetch` |
  | `TestMSSQLJanelaSemOrderByUsaSelectNull` | `TestMSSQLSemOrderByUsaSelectNull` |

  Nenhuma regra deixou de ser verificada; três delas passaram de 1 para 7 dialetos.
- Implementações em falta de `Trim`, `LTrim`, `RTrim`, `Coalesce`, `Modulus`, `CurrentDate` e `CurrentTimestamp` nos drivers **Firebird**, **SQLite** e **Oracle**.
- Funções escalares do **MongoDB** passam a levantar `EFluentSQLFunctionNotSupported` em vez de `EAbstractError`. As agregações (`Count`, `Sum`, `Min`, `Max`, `Average`) não mudaram.
- **`EFluentSQLStatementNotSupported` em `FluentSQL.Interfaces.pas`.** Irmão de `EFluentSQLFunctionNotSupported` um nível acima: lá falta uma função escalar, aqui falta a **instrução inteira** no dialeto. Primeiro uso: `MERGE`, que só o MSSQL serializa.
- **`DriverName(ADriver: TFluentSQLDriver): String` em `FluentSQL.Interfaces.pas`.** Nome canônico do dialeto, agora **fonte única**: é a chave dos dicionários do `FluentSQL.Register.pas` e o texto das mensagens de exceção. Antes existia apenas como `const` privada `TStrDBEngineName` dentro do `Register`, o que impedia qualquer outra unit de nomear um dialeto sem duplicar a tabela. O `Register` passou a chamá-la nos 19 pontos onde indexava a `const`; as chaves dos dicionários são as mesmas strings, sem mudança de comportamento. A proteção `E2072` contra membro novo do enum foi junto com a tabela.
- Oráculo de motor real `Test Delphi\Common_tests\test.merge.mssql.sql`, medindo a injeção via `MERGE` antes e depois, em SQL Server 2022 (RTM-CU26) 16.0.4265.3. Traz o `docker run` exato, o SQL emitido pela própria biblioteca nas duas árvores, a saída bruta do motor e a seção **FRONTEIRA**, com o que a correção **não** fecha.
- Matriz `Test Delphi\Common_tests\test.merge.matrix.pas` (9 testes): uma célula por dialeto, afirmando parametrização onde há serializador e **exceção nomeada** onde não há. `Test Delphi\MSSQL_tests\test.merge.mssql.pas` foi de 5 para **34** testes — inclui 16 casos de payload hostil (aspa simples, aspa dupla, `;`, `--`, `/* */`, aspa dobrada, `UNION`), o `O'Brien` que **tem** de funcionar, as guardas de lista malformada / vazia / sem argumentos, o `nil` que não pode virar `'00000000'`, e a asserção de que a cláusula recusada **não** sobra pela metade no SQL.

  Três dos cinco testes originais desse arquivo **passavam sobre SQL inválido**: usavam `.Update`/`.Insert` sem argumentos e asseveravam com `Pos()` sobre *prefixos* — `'WHEN MATCHED THEN UPDATE'` casa em `UPDATE SET ;` tão bem quanto em `UPDATE SET [X] = :p1`. Foi essa fragilidade que deixou uma forma quebrada atravessar a suíte verde inteira e chegar ao guia como recomendação. Os três passaram a usar a forma válida e a asseverar o **SQL inteiro**, com `Assert.AreEqual` *case-sensitive* — o padrão do DUnitX é *case-insensitive*, o que numa biblioteca cujo produto é texto SQL deixa passar regressão de caixa.
- Oráculo de motor real `Test Delphi\Common_tests\test.setvalue.mssql.sql`, para o caminho de `SetValue`/`Values` (`INSERT`/`UPDATE` comum, sem `MERGE`), medido em SQL Server 2022 (RTM-CU26) 16.0.4265.3. Registra os quatro casos antes/depois — **inclusive um resultado que corrige uma suposição**: o payload com aspa não derruba a tabela nessa gramática, porque a aspa abre um literal que engole o resto do batch; o que executa é o que fecha o parêntese (`1); DROP TABLE USERS; --`).
- **Onze testes em `Test Delphi\Common_tests\test.core.params.pas`** para o slot de valor de `SetValue`/`Values(array of const)` — que até então **não tinha teste nenhum**. Rodam nos projetos **Firebird** e **MySQL**, os dois que compilam esse arquivo. São 3 de parametrização (a string vira `:pN`, inclusive o payload hostil), 3 do `nil` que levanta, e 5 de cardinalidade (lista vazia em `INSERT`, em `Values` e em `UPDATE`; mais de um valor; e a coluna recusada não sobrar pela metade no SQL).

  Os 3 do `nil` merecem nota porque **o comportamento já existia e mesmo assim não estava coberto**: a guarda é o ramo `vtPointer` compartilhado com o `MERGE`, e medindo por mutação (`vtPointer` → `if False`) o vermelho aparecia **só** em testes de `MERGE`. O caminho mais trafegado dos dois estava apoiado num oráculo que não o observava.

### Fixed

- **MSSQL — paginar descartava `UNION` e `WITH` (CTE) em silêncio.** `TFluentSQLSerializerMSSQL.AsString` remontava o corpo da consulta por conta própria em vez de delegar a `ComposeSqlCore`, e por isso o ramo do `UNION` e a CTE simplesmente não apareciam no texto emitido — SQL válido e incompleto, sem erro nenhum. Passou a delegar; as duas voltaram.
- **MSSQL — `AsString` deixou de escrever no AST.** A coluna `ROW_NUMBER() OVER(...) AS ROWNUMBER` era **injetada** em `AAST.Select.Columns` durante a serialização, então duas chamadas de `AsString` na mesma `IFluentSQL` acumulavam duas colunas `ROWNUMBER`. Com a migração para `OFFSET/FETCH` a injeção deixou de existir e `AsString` ficou idempotente. *(A não-idempotência de `AsString` por outras causas não foi investigada nesta entrega.)*
- **`Select.Distinct` levantava `Exception` crua em MSSQL, MySQL, PostgreSQL e Oracle, mesmo SEM paginação.** Os quatro tratavam `sqDistinct` como qualificador desconhecido dentro do laço de paginação, que os serializadores chamam incondicionalmente. O laço, que estava duplicado nos nove drivers, virou `TFluentSQLSelectQualifiers._Pagination`.
- **`Skip(n)` sem `First(m)` emitia SQL inválido em MSSQL, Oracle, MySQL e SQLite.** Ver a tabela em *Changed*.
- **Oracle — o embrulho `SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI ...)` acrescentava a coluna `ROWINI` ao resultado.** Uma consulta `Select.All.From('T').First(n)` devolvia uma coluna que o usuário nunca pediu. Medido: cinco valores por linha numa tabela de quatro colunas. Sem embrulho, some.
- **`MERGE` com lista de pares de contagem ímpar emitia SQL inválido em silêncio.** Ver a entrada BREAKING em *Changed* — a correção troca "não levantava nada" por "levanta `EArgumentException`", e por isso não cabe aqui.
- **Documentação — o guia `dml-merge.md` ensinava duas formas que nunca funcionaram.** O exemplo principal usava `.Update(['T.VALOR = S.VALOR', 'T.DATA = S.DATA'])`, tratando o array como lista de **fragmentos de SQL**; o array sempre foi lido como pares nome/valor, e essa chamada emite `UPDATE SET T.VALOR = S.VALOR = ...`, que o SQL Server recusa com `Msg 102, Incorrect syntax near '='`. A mesma página anunciava um overload `.Insert(['ID','VALOR'], ['S.ID','S.VALOR'])` de **dois arrays que não existe** em `IFluentSQLMergeWhenNotMatched` — copiar aquela linha dá `E2034 Too many actual parameters`. A página foi reescrita com a forma correta, com aviso explícito de que a anterior era inválida, e com a tabela de suporte por dialeto refletindo o que cada um faz hoje. O overload de dois arrays **não** foi criado: colunas e valores vão no mesmo array, alternados.

### Known issues

- **Firebird — `Union` + paginação pagina apenas o primeiro ramo.** O FluentSQL emite `SELECT FIRST 3 SKIP 20 * FROM T UNION SELECT * FROM U`; no Firebird o `FIRST`/`SKIP` escrito num ramo recorta **aquele ramo**, não o resultado do `UNION` — medido, devolve 63 linhas onde os outros seis dialetos devolvem 3. É SQL válido com semântica divergente. Não corrigido: o conserto exige embrulhar o `UNION` numa subconsulta, mudando substancialmente a forma emitida por este driver. Detalhes em `test.pagination.firebird.sql`, parte 3.
- **MSSQL — `WITH` (CTE) e `UNION` combinados com `OrderBy` do usuário geram SQL inválido, com ou sem paginação.** `FluentSQL.Serialize.pas` monta o `ORDER BY` **dentro** de `LBase` e só depois embrulha na CTE ou concatena o `UNION`, produzindo `WITH CTE AS (SELECT ... ORDER BY ...)` (`Msg 1033`) e `SELECT ... ORDER BY ... UNION SELECT ...` (`Msg 156`). É defeito de composição, independente de paginação, e não foi corrigido nesta entrega. Casos I e J de `test.pagination.mssql.sql`.

  **`First(0)` acrescenta um segundo motivo de invalidez ao mesmo caso.** Com operação de conjunto *e* `OrderBy` do usuário, o driver emite a cauda `OFFSET 9223372036854775807 ROWS` **sem** um `ORDER BY` na frente — porque o `ORDER BY` do usuário já foi consumido dentro do primeiro ramo pelo defeito acima — e o resultado é `Msg 156`. Não é regressão: a mesma combinação já era inválida antes desta entrega (pelo motivo do parágrafo anterior), e na base `79450e9` o `UNION` era descartado em silêncio. Vale registrar porque `cPULA_TUDO` (`FluentSQL.SerializeMSSQL.pas`) é **o único ponto do driver que pode sair sem `ORDER BY` na frente**: em todos os outros caminhos a cláusula é garantida por `PaginationOrderBy`. Quando o defeito de composição for corrigido, este segundo motivo desaparece junto — mas quem for mexer ali precisa saber que existem os dois.

  **Fora de escopo, confirmado pré-existente:** `First(0)` com `From(<subconsulta>)` sai como `Msg 102` (*derived table* sem alias). Independe de `First(0)` e já ocorria antes desta entrega.
- **MongoDB — `Union` levanta `EIntfCastError`,** com ou sem paginação. Não é defeito de paginação; o MongoDB não tem `UNION` e deveria recusar com exceção nomeada, como já faz para CTE (`EFluentSQLMongoDBSerialize`).
- **MongoDB — `MERGE` é descartado em silêncio.** `FluentSQL.SerializeMongoDB.pas` sobrescreve `AsString` por inteiro e nunca chega à seção de `MERGE`, então a cláusula some e a saída é `{}`. **Não vaza valor do usuário**, mas também não avisa — é o único dos nove que não levanta nem emite. Como a parametrização acontece na construção, antes da serialização, o valor ainda entra em `Params`: `Params.Count = 1` referenciado por nada no MQL. Não corrigido nesta entrega: exige decidir se o MongoDB recusa `MERGE` com exceção nomeada ou o mapeia para `$merge` do *aggregation pipeline*, e as duas são decisões de escopo próprio. Travado por `TestMerge_MongoDB_DropsMergeSilently_KnownGap`, que afirma tanto o `{}` quanto o parâmetro órfão — fechar a lacuna quebra o teste de forma visível.
- **O nome da coluna em `MERGE` continua injetável — vale para toda a biblioteca, não só para o `MERGE`.** A correção desta entrega fechou o slot de **valor**; o slot de **identificador** não pode virar parâmetro e os `QuotedName` / `Quote` dos 9 dialetos envolvem o nome no delimitador **sem duplicar o delimitador interno**. Medido em SQL Server 2022: nome de coluna `NOME] = 'x'; DROP TABLE USERS; --` emite `SET [NOME] = 'x'; DROP TABLE USERS; --] = @p1;` e **a tabela foi dropada**. Não é regressão — comportamento idêntico antes e depois. Não corrigido porque o escape de delimitador de identificador toca todos os dialetos e colide com o *passthrough* por `StartsWith`/`Contains` que hoje permite passar nome já qualificado (`[dbo].[T]`); é decisão de arquitetura própria. **Não construa nome de objeto a partir de entrada não confiável.** Detalhes e medição na seção FRONTEIRA de `test.merge.mssql.sql`.
- **`array of const` em posição de expressão continua interpolando string verbatim.** Vale para **todo** `array of const` que **não** seja um dos quatro slots de valor — hoje **17 pontos de entrada públicos**, e não os 6 que uma versão anterior desta entrada listava. São eles `Where`, `AndOpe`, `OrOpe`, `Column`, `Having`, `OnCond`, `CaseExpr`, `ForDialectOnly` e `Expression` em `IFluentSQL`; `AndOpe`, `OrOpe`, `Ope` e `Fun` em `IFluentSQLCriteriaExpression`; `When`, `AndOpe` e `OrOpe` em `IFluentSQLCriteriaCase`; e `On` em `IFluentSQLMerge`. A tabela com `arquivo:linha` de cada um está na entrada BREAKING do `MERGE`, em *Changed*.

  Em todos eles escalares numéricos viram `:pN` e strings seguem literais, por serem tratadas como fragmento de SQL (identificador, operador, trecho). `.On(['t.NOME =', 'x''; DROP...'])` emite `ON (t.NOME = x'; DROP...)`, e `.AndOpe(['NOME =', <entrada>])` faz o mesmo depois de um `Where`. **Isto não mudou nesta entrega e é intencional** — é o que permite compor expressão. Mudaram apenas os quatro pontos em que o array é comprovadamente uma lista de **valores** e o slot não tem como ser fragmento: `Merge.Update`, `Merge.Insert`, `SetValue(nome, [...])` e `Values(nome, [...])`.

  **O critério mecânico, para quem for auditar:** passa por `TUtils.SqlArrayOfConstToParameterizedSql` → literal; passa por `TUtils.SqlArrayOfConstToParameterizedValue` → parâmetro. Não há terceiro caminho. Um caminho seguro para expressão está sob tarefa própria.

  **Consequência que vale declarar:** como o `INSERT`/`UPDATE` não exprime expressão em slot de valor por nenhum overload (o tipado `SetValue(String, String)` também parametriza), **não há hoje forma suportada de escrever `SET DATA = CURRENT_TIMESTAMP` pelo construtor de valores**. A distinção entre **valor** e **expressão** que separa os dois casos está sob revisão como tarefa própria, e é ela que decidirá se esse caso ganha caminho próprio.
- **O `CASE` não tem slot de valor, e a medição de motor real mostrou por que criar um não é troca de assinatura.** `IFluentSQLCriteriaCase.IfThen`/`ElseIf` têm duas sobrecargas — `String` e `Int64` — e as duas põem o argumento verbatim no texto do SQL. A de `String` é posição de **expressão**, pela mesma regra dos 17 acima (é o que permite `IfThen('SALARIO * 1.1')`, e é como a própria suíte usa: `IfThen('''FISICA''')`, com o chamador pré-aspando). A de `Int64` passa por `IntToStr` e não pode injetar nada, mas também não vira `:pN`.

  A correção natural — fazer `THEN`/`ELSE` emitirem `:pN` — **foi medida antes de ser escrita, e dois dos sete motores recusam a forma no `PREPARE`**:

  | Motor | `CASE WHEN c THEN :p1 ELSE :p2 END` na projeção | o mesmo dentro do `WHERE` |
  |---|---|---|
  | PostgreSQL 16.14 | aceita | aceita |
  | MySQL 8.4.11 | aceita | aceita |
  | SQLite 3.53.4 | aceita | aceita |
  | SQL Server 2022 (16.0.4265.3) | aceita | aceita |
  | Oracle AI Database 26ai 23.26.2.0.0 | aceita | aceita |
  | **Firebird 5.0.4** | **`-804 Data type unknown` (SQLSTATE HY004)** | aceita |
  | **DB2 v12.1.5.0** | **`SQL0418N ... untyped parameter marker` (SQLSTATE 42610)** | **recusa também** |
  | InterBase | não medido — sem imagem de container pública | não medido |

  Isolado: no Firebird o `-804` **não é do `CASE`** — `SELECT :a FROM RDB$DATABASE` dá o mesmo erro. É o marcador sem tipo em posição onde nada lhe dá tipo. Com `CAST` nos dois ramos, os dois motores aceitam. Fazer o slot funcionar nos sete exigiria emitir `CAST(:pN AS <tipo do dialeto>)` — despacho por driver, desenho novo, e colide com a tarefa já catalogada sobre `Cast` sem despacho. **Por isso a assinatura não mudou nesta entrega**, e a escolha entre emitir `CAST` nos sete, parametrizar só onde o motor aceita, ou manter só o slot de expressão, fica para o dono. Versões, `docker run`, forma exata do `PREPARE` em cada cliente e saída bruta de cada motor em `Test Delphi\Common_tests\test.cases.bind.matrix.sql`.

  **Atualização: o bloqueio caiu, a lacuna continua.** A tarefa do `Cast` sem despacho foi feita (ver *Added*): `Cast` saiu do padrão A e cada dialeto devolve a própria grafia. Medido com **as strings exatas que os drivers hoje emitem**, os dois motores que recusavam passam do `PREPARE` — `CAST(:p1 AS VARCHAR(4000))` no Firebird devolve `yes`, e `CAST(? AS VARCHAR)` no DB2 responde `SQL0313N`, que é o CLP pedindo valores depois de preparar. Transcrição em `Test Delphi\Common_tests\test.cast.matrix.sql`. **O slot de valor do `CASE` continua não existindo** — `IfThen`/`ElseIf` seguem em posição de expressão, inalterados; o que mudou é que criá-lo deixou de depender de desenho novo. A escolha entre as três alternativas acima continua sendo do dono.

  **Atenção a quem citar a versão do Oracle:** a tag `gvenzl/oracle-free:23-slim` entrega **Oracle AI Database 26ai 23.26.2.0.0**, não 23c.
- **`FluentSQL.Select.pas` — `TFluentSQLSelect.Serialize` é código morto.** Os 9 drivers sobrescrevem `Serialize` e `FluentSQL.Ast.pas` sempre pega a instância do `Register`; reverter a linha corrigida não derruba teste algum. A forma neutra foi corrigida ali por coerência, não por efeito observável.
- **A matriz de paginação vive apenas no projeto Firebird.** `PTestFluentSQLFirebird.dpr` é o único que compila `test.pagination.filter.pas`. Consequência medida: reverter a cauda `LIMIT/OFFSET` do SQLite derruba 4 testes, **todos ali** — `SQLite_tests` não tem teste de paginação nenhum. A cobertura existe, mas mora longe do driver que protege.
- **MongoDB — `Abs`, `Cast`, `Upper`, `Lower`, `Round` e `Floor` geram MQL inválido em silêncio.** Essas seis são do "padrão A" (o núcleo emite SQL ANSI sem consultar o driver), e `FluentSQL.SerializeMongoDB.pas` só reconhece nome de campo e os prefixos de agregação (`AGG:`, `SUM(`, `COUNT(`, `MIN(`, `MAX(`, `AVG(`, `AVERAGE(`). O resultado é que a coluna é **descartada sem exceção**: `.Column(Fun.Round('v',2))` produz `{"find":"t","filter":{},"projection":{}}` — a projeção sai vazia — enquanto `.Column(Fun.Sum('v'))` produz corretamente `{"aggregate":"t","pipeline":[{"$project":{"x":1,"_id":0}}],...}`. É o mesmo modo de falha que foi corrigido para `Ceil` e `Length`, e sobrevive nestas seis. **Não corrigido nesta entrega** — o conserto exige mover as seis para o "padrão B" (implementação por driver nos 9 dialetos) ou ensinar o serializador MongoDB a montar `$project` com expressão, e nenhum dos dois cabia no escopo. Registrado como dívida; até lá, não use funções escalares na projeção com `dbnMongoDB`.

## [1.5.1] — 2026-04-20

### Fixed
- **Pipeline — Documentation Build (Issue #144):** Resolved `tsconfig.json` configuration conflict in `docs-src` related to `baseUrl` and path mapping, ensuring compatibility with Docusaurus 3.
- **Pipeline — Governance Sync (Issue #144):** Restored pipeline synchronization by resolving drift for ESP-077 (Issue #141) and finalizing governance state.

## [1.5.0] — 2026-04-20

### Added
- **DDL — Schema Support (ESP-075, issue [#142]):** `CREATE SCHEMA` and `DROP SCHEMA` support for PostgreSQL, MSSQL, and MySQL (mapped to DATABASE per ADR-075).
- **DML — MERGE Skeleton (ESP-076, issue [#142]):** Fluent API for `MERGE INTO ... USING ... ON ... WHEN MATCHED/NOT MATCHED`. Initial serialization for MSSQL.
- **DDL — Advanced Truncate Support (ESP-074, issue [#136]):**
  - Support for multi-table truncation in a single atomic command across all supported dialects.
  - PostgreSQL: added `RESTART IDENTITY`, `CONTINUE IDENTITY`, and `CASCADE` support.
  - MySQL: added `PARTITION` support for single-table truncation.
  - Consistent validation and `ENotSupportedException` for advanced options in dialects that do not support them.

## [1.4.0] — 2026-04-17

### Added
- **MongoDB — Aggregations & Joins (ESP-067, ESP-068, issues [#86], [#87]):** comprehensive SQL-to-MQL mapping for `GROUP BY`, `HAVING`, `INNER JOIN`, and `LEFT JOIN` (using `$lookup`, `$group`, `$unwind`, and `$project` stages).
- **MongoDB — DDL Extensions (ESP-065, ESP-066, issues [#83], [#84], [#85]):** added support for Capped Collections, TTL Indexes, Index Management (Create/Drop), Collection Rename and Truncate.
- **DDL — Procedural Support (ESP-070, ESP-071, issues [#134], [#135]):** added comprehensive support for Stored Procedures, Triggers, and Stored Functions across PostgreSQL, Firebird, MS SQL Server, and MySQL. Includes support for `OR REPLACE`, `IF EXISTS`, and trigger management (Enable/Disable).
- **DDL — Core Expansion (issues [#67], [#68], [#69], [#70], [#71], [#72], [#73], [#74], [#75], [#79], [#82]):**
  - Native Identity / Auto-Increment support and Advanced Identity (`ALWAYS`/`BY DEFAULT`) for PG, FB, and Oracle.
  - Alter Column and Computed Columns support.
  - Native CREATE/DROP VIEW and SEQUENCE support.
  - Table and Column Comments support.
  - Composite/Named Constraints and Alter Table constraint management.
  - Dialect-specific support for MongoDB DDL.

### Changed
- **DDL — API Refactoring (issue [#80]):** transitioned DDL API to a "context-first" pattern to improve readability and consistency across dialects.
- **Repository Strategy:** finalized test suite fragmentation to better handle dialect-specific integration tests.
- **Documentation:** updated DDL guides and README to reflect the expanded feature set and new entry points.

## [1.3.0] — 2026-04-14

### Added
- **DDL — Rename Table Support (ESP-047, issue [#65]):** added `.AlterTableRename(const AOldName, ANewName: string)` to `Schema` API, with dialect-specific serialization for Firebird, PostgreSQL, MySQL, MSSQL (using `sp_rename`), and SQLite.
- **DDL — GUID Type Support (ESP-043, issue [#63]):** centralized GUID literal translation and added support for GUID types in DDL column definitions.
- **DDL — Logic Centralization (ESP-042, issue [#60]):** mandatory identifier quoting and refactored DDL serialization logic into a robust abstract layer.
- **Core — Portability (ESP-046, issue [#64]):** removed `Winapi.Windows` dependency from `FluentSQL.DDL.pas` for better cross-platform support.

### Fixed
- **MSSQL — Boolean Serialization (issue [#62]):** fixed compatibility issues with boolean literal serialization in MSSQL environments.
- **Pipeline — Root Cleanliness (issue [#64]):** enforced "no root pollution" policy, redirecting temporary artifacts to `.local-readonly/`.

### Tests
- DUnitX: `TTestDDLAlterTableRenameTable` coverage for all 5 core dialects.
- Verified 157 passing tests in the Firebird suite.


## [1.2.0] — 2026-04-13

### Added
- **DDL — Foreign Keys (ESP-035, issue [#49]):** added `.References(const ATableName, AColumnName: string)` support for `CREATE TABLE` and `ALTER TABLE ADD COLUMN` (Firebird, PostgreSQL).
- **DDL — Advanced Constraints (ESP-034, issue [#48]):** support for `NOT NULL`, `DEFAULT`, and `PRIMARY KEY` in `CREATE TABLE` and `ALTER TABLE ADD COLUMN`.
- **Cache — Redis Provider (ESP-032, issue [#47]):** distributed SQL string caching with support for Redis as a back-end, including deterministic AST-based hashing (`TFluentSQL.AsString`) to prevent cache collisions.
- **DDL — RENAME COLUMN/TABLE (ESP-030, ESP-031, issues [#45], [#46]):** added `.RenameTo` and `RenameColumn` for PostgreSQL, Firebird, and MySQL.
- **DDL — TRUNCATE TABLE (ESP-029, issue [#44]):** fluent API for `TRUNCATE TABLE` and serialization across multiple dialects.
- **DDL — DROP INDEX improvements (ESP-025, ESP-026, ESP-027, ESP-028, issues [#40], [#41], [#42], [#43]):** added `DROP INDEX`, support for `IF EXISTS`, `CONCURRENTLY` (PostgreSQL), and `ON table` (MySQL/MariaDB).

### Changed
- **Documentation:** updated DDL guides (foreign keys, renaming, create table) and API reference. Root directory cleanup (`VISIBILIDADE-EXECUCAO.md` removed).

## [1.1.1] — 2026-04-10

### Added
- **DDL — ALTER TABLE DROP COLUMN (ESP-020, ADR-020, issue [#34](https://github.com/ModernDelphiWorks/FluentSQL/issues/34)):** `CreateFluentDDLAlterTableDropColumn`, `DDLAlterTableDropColumnSQL` e serialização Firebird/PostgreSQL; guia `ddl-alter-table-drop-column.md`.
- **DDL — CREATE [UNIQUE] INDEX (ESP-022, ADR-022, issue [#35](https://github.com/ModernDelphiWorks/FluentSQL/issues/35)):** `CreateFluentDDLCreateIndex`, `DDLCreateIndexSQL` (Firebird, PostgreSQL); guia `ddl-create-index.md`; testes DUnitX adicionais (incl. multi-coluna Firebird e nomes vazios).

### Changed
- **Documentação:** alinhamento do índice do portal e da referência de API com ESP-020/ESP-022; quadro de visibilidade de execução em `VISIBILIDADE-EXECUCAO.md` (ESP-024).

### Tests
- DUnitX: `TTestDDLAlterTableDropColumn`, `TTestDDLCreateIndex` em `Test Delphi/test.ddl.pas` (suíte Firebird).

## [1.1.0] — 2026-04-09

### Added
- **Extensão explícita por motor (ESP-016, ADR-016, issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)):** API de opt-in por dialeto (`ForDialectOnly` / serialização por motor), alinhada a `FluentSQL.Serialize.pas` e documentação em `docs-src`.
- **DDL — CREATE TABLE (ESP-017, ADR-017, issue [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28)):** API fluente e `DDLCreateTableSQL` para Firebird e PostgreSQL com `TDDLLogicalType`.
- **DDL — DROP TABLE (ESP-018, ADR-018, issues [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29) / [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30)):** API fluente e serialização de texto SQL para `DROP TABLE`.
- **DDL — ALTER TABLE ADD COLUMN (ESP-019, ADR-019, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)):** uma coluna lógica por `AsString`, reutilização do mapeamento de tipos do CREATE e paridade Firebird/PostgreSQL.
- **Documentação e CI:** portal Docusaurus em `docs-src/`, `ROADMAP.md` operacional, fluxos `.github/workflows/docs-build.yml` e `deploy-docs.yml`, e guias DDL (`ddl-create-table`, `ddl-drop-table`, `ddl-alter-table-add-column`).

### Tests
- DUnitX em `Test Delphi/test.ddl.pas` para CREATE/DROP/ALTER (matriz referida nos relatórios de review/test; execução MSBuild sujeita a caveats).

Dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

## [1.0.9] — 2026-04-08

### Added
- **INSERT em lote (ESP-015, ADR-014, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31)):** `AddRow` no fluente (contexto `Insert`) fecha a linha corrente e abre a próxima; `AsString` faz *flush* implícito da linha pendente. SQL: `VALUES (...), (...)` com placeholders na ordem linha a linha (**ADR-009**). MongoDB (`dbnMongoDB`): `insertMany` com `documents` quando há mais de uma linha; uma linha continua com `insertOne`.

### Tests
- DUnitX: `test.core.params` (Firebird + MySQL, batch parametrizado); `UTestFluentSQLFirebird` (`insertMany` Mongo).

Dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

## [1.0.8] — 2026-04-08

### Changed (breaking)
- **MongoDB (`dbnMongoDB`, ESP-014, issue [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29)):** `TFluentSQLSelectMongoDB.Serialize` deixa de emitir pseudo-SQL `colecao.find({...})` e passa a devolver o fragmento JSON **ADR-013** §2b `{"collection":"…","projection":{…}}`, partilhando a mesma lógica de projeção que `TFluentSQLSerializerMongoDB` (**2b** + **2c**). Quem dependia da string antiga deve migrar.

### Added
- **MongoDB — DML (ADR-013 Opção A):** `IFluentSQL.AsString` para `Insert` / `Update` / `Delete` em `dbnMongoDB` emite JSON mínimo e estável: `insertOne`, `updateMany` (com `filter` + `update.$set`) e `deleteMany`, com resolução de placeholders `:pN` nos documentos via `IFluentSQLParams` (sem literais `:pN` no JSON final).
- **`TFluentSQL.MongoSelectFragment`:** fragmento da secção SELECT em JSON para `dbnMongoDB` (vazio noutros dialetos); útil para testes e introspecção.
- **WHERE Mongo:** prefixo `NOT ` a nível de expressão → `{"$nor":[…]}` (um eixo de extensão do parser documentado na ESP-014).
- **Guardas:** `WITH` / `UNION` / `INTERSECT` em `dbnMongoDB` levantam `EFluentSQLMongoDBSerialize` com mensagem estável em vez de SQL inválido.

### Tests
- DUnitX em `UTestFluentSQLFirebird.pas`: DML Mongo (`insertOne` / `updateMany` / `deleteMany`), coerência `MongoSelectFragment` vs `AsString`, e `NOT` → `$nor`.

Dívida técnica pós-caveats: [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30).

## [1.0.7] — 2026-04-08

### Changed
- **Parametrização (ESP-013):** `TFluentSQL.CaseExpr(array of const)` passa a usar `SqlArrayOfConstToParameterizedSql` com `FAST.Params` (**ADR-009**, **ADR-011**, **ADR-012**). Escalares na expressão discriminante do `CASE` passam a placeholders; strings no array continuam fragmentos literais. Rastreio da entrega: esta secção **[1.0.7]** (não confundir com a issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), hoje **ESP-016** / fecho formal). Dívida técnica pós-caveats: [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28).

## [1.0.6] — 2026-04-08

### Changed
- **Parametrização (ESP-012, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25)):** `TFluentSQL.Column(array of const)` passa a usar `SqlArrayOfConstToParameterizedSql` com `FAST.Params`, alinhado a **ADR-009** / **ADR-011**; escalares na projeção viram placeholders em vez de literais concatenados. `CaseExpr(array of const)` foi migrado em **ESP-013** (ver **[1.0.7]** acima). Dívida técnica pós-caveats: [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26).

## [1.0.5] — 2026-04-08

### Changed
- **Parametrização (ESP-011, issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23)):** `TFluentSQLCriteriaExpression` usa `SqlArrayOfConstToParameterizedSql` quando associada a `IFluentSQLParams` (contexto `TFluentSQL` / `TFluentSQLCriteriaCase`); `Expression(array of const)` e `Expression(string)` no fluente recebem a coleção do AST. Sobrecargas `array of const` em joins/having/where herdam o mesmo contrato da ESP-010; **strings** em `TVarRec` continuam sem bind automático (**ADR-011**). `CaseExpr(array of const)` e `Column(array of const)` permanecem com `SqlParamsToStr`.

### Added
- Testes DUnitX em `test.core.params.pas` cobrindo critérios/expressão com `array of const` via `Where`. Dívida técnica pós-caveats: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).

## [1.0.4] — 2026-04-08

### Changed
- **Parametrização (ESP-010, issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21)):** sobrecargas com `array of const` em `Where`, `AndOpe`, `OrOpe`, `Having`, `OnCond`, `SetValue`, `Values` (`FluentSQL.pas`) e `When`, `AndOpe`, `OrOpe` em `TFluentSQLCriteriaCase` (`FluentSQL.Cases.pas`) passam a expandir **valores escalares** (inteiro, int64, extended, currency, boolean, variant numérico/data) via `IFluentSQLParams` e placeholders (`:pN` no AST); entradas **textuais** em `TVarRec` (identificadores, operadores `Char`, strings) continuam literais na expressão, alinhado a **RN-P3**. Helper novo: `TUtils.SqlArrayOfConstToParameterizedSql`. `CaseExpr(array of const)`, `Column(array of const)` e `Expression(array of const)` mantêm `SqlParamsToStr` (expressão mista / nomes).

### Added
- Testes DUnitX em `test.core.params.pas`: `Where`/`Having`/`Values`/`CASE WHEN` com `array of const` e parâmetros. Dívida técnica pós-caveats: [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22).

### Fixed
- `Test Delphi/MSSQL_tests/test.select.mssql.pas`: asserts de `WHERE` com `GreaterEqThan`/`LessEqThan` esperam `:p1`/`:p2`; `ORDER BY` espera sufixo `ASC`, coerente com a serialização atual (runner usa `CreateFluentSQL(dbnFirebird)` nestes casos).

## [1.0.3] — 2026-04-08

### Changed
- **Parametrização (ESP-009):** predicados `IN` / `NOT IN` com listas (`TArray<String>`, `TArray<Double>`) passam a emitir placeholders (`:p1`, `:p2`, …) e a preencher `IFluentSQLParams` por elemento; subconsultas em `InValues(string)` / `NotIn(string)` continuam literais entre parênteses. Operadores SQL normalizados para `IN` e `NOT IN` na concatenação. Ver issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19).
- Testes Firebird `test.operators.isin.firebird` (ligado a `PTestFluentSQLFirebird.dpr`) e suíte MySQL (`test.functions.mysql`, `test.select.mysql`) alinhados a placeholders e `ORDER BY … ASC` onde a serialização atual já produz esse formato.

### Added
- Fixture DUnitX `Test Delphi/test.core.params.pas` integrado em `PTestFluentSQLFirebird.dpr` e `TestFluentSQL_MySQL.dpr` (cenários Firebird, MySQL e PostgreSQL no runner Firebird). Dívida técnica pós-caveats: [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20).

## [1.0.2] — 2026-04-08

### Changed
- `ROADMAP.md`: encerramento da **Fase 0** no âmbito consumidor após auditoria **ESP-008**; checklist **R1–R6** com evidências citáveis; bloco **Estado atual** com próximo foco na **Fase 1** (parametrização / prepared statements). Ver issue [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17). Dívida técnica pós-caveats: [#18](https://github.com/ModernDelphiWorks/FluentSQL/issues/18).

## [1.0.1] — 2026-04-08

### Added
- `ROADMAP.md` como artefato operacional e evolutivo: política de gatilhos (`/architect`, `/sprint`, `/release`, conclusão de implementação), histórico de evolução, estado/foco ligado ao pipeline (`.claude/pipeline/`), fase **Meta — Governança do roadmap** e alinhamento checklist ↔ relatórios. Ver issue [#15](https://github.com/ModernDelphiWorks/FluentSQL/issues/15). Dívida técnica pós-caveats: [#16](https://github.com/ModernDelphiWorks/FluentSQL/issues/16).

## [1.0.0] — 2026-04-08

### Changed (breaking)
- **API:** a fábrica global `CQuery` foi substituída por `CreateFluentSQL` na unit `FluentSQL.pas`. Código que chamava `CQuery(dbn…)` deve usar `CreateFluentSQL(dbn…)`. (O nome `NewFluentSQL` do ADR foi evitado: em Delphi o token `New` pode ser interpretado como o intrínseco `New`, quebrando encadeamentos como `.&As(…)` após a chamada da fábrica.)
- **Testes / Boss / metadados:** projetos DUnitX renomeados para o prefixo `TestFluentSQL_*`; pacote Boss passa a publicar-se como **FluentSQL** (antes `CQuery4D`). Unidades e fixtures de teste deixam de usar `CQL` / `TCQL.New` em favor de `FluentSQL` / `CreateFluentSQL`.

| Antes | Depois |
|--------|--------|
| `CQuery(dbnFirebird)` | `CreateFluentSQL(dbnFirebird)` |
| `TCQL.New(dbnMSSQL)` | `CreateFluentSQL(dbnMSSQL)` |
| `TCQL.SetDatabaseDafault(...)` | `TFluentSQL.SetDatabaseDafault(...)` |
| `uses CQL, CQL.Interfaces` | `uses FluentSQL, FluentSQL.Interfaces` |
| `CQL.Q('x')` (literais em CASE) | `TFluentSQLFunctions.QFunc('x')` com `FluentSQL.Functions` em uses |

Ver issue [#13](https://github.com/ModernDelphiWorks/FluentSQL/issues/13). Dívida técnica pós-caveats: [#14](https://github.com/ModernDelphiWorks/FluentSQL/issues/14).

## [0.2.0] — 2026-04-08

### Added
- Planejamento da evolução do framework para suporte a recursos avançados de SQL (CTE, Window Functions, etc).
- Planejamento de melhorias de segurança através de Prepared Statements (Parametrização).
- Planejamento de novos serializadores (MongoDB MQL, REST API).
- Mescla ordenada de parâmetros em operações de conjunto (`UNION`, `UNION ALL`, `INTERSECT`): coleção `Params` alinhada à ordem dos placeholders na SQL final, com reindexação do ramo secundário e suporte MySQL (`?`). Ver issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11).
- Módulo `FluentSQL.Params.pas` com visão mesclada de parâmetros em queries compostas.
- Testes DUnitX (Firebird e MySQL) cobrindo parâmetros nos dois lados do conjunto.

### Changed
- Serialização de conjuntos e driver MySQL para contagem total de placeholders em `UNION`.
- Ajustes correlatos em AST, operadores, interfaces e registro de drivers (MongoDB, Firebird, SQLite) integrados à entrega revisada.

---

## [0.1.0] — 2026-04-07

### Added
- Versão inicial do projeto documentada no Ecossistema Delphi.
- Suporte básico para SELECT, INSERT, UPDATE, DELETE em múltiplos dialetos.
- Abstração via AST (Abstract Syntax Tree).
