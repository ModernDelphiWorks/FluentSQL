{
  ------------------------------------------------------------------------------
  FluentSQL - blindagem da intersecao paginacao x filtro (T9)

  Este arquivo existe porque a arvore tinha as duas features testadas ISOLADAS e
  nenhum teste na intersecao. Os testes de paginacao paginavam sempre sem filtro
  (test.select.firebird.pas:76,204,220,234,248,262 e
  DB2_tests/test.select.firebird.pas:160) e os testes de Where nunca paginavam.
  No vao entre os dois morava o defeito: no MSSQL,
  Where(...).First(n).Skip(m) DESCARTAVA o predicado do usuario e ainda trocava
  a palavra WHERE por AND.

    ce9efd0:  ... FROM T) AS T AND (ROWNUMBER > 20 AND ROWNUMBER <= 30)
              (o ATIVO = :p1 nao esta em lugar nenhum)

  ONDE CONFERIR O QUE O MOTOR REALMENTE FAZ: test.pagination.filter.mssql.sql,
  nesta mesma pasta. Este arquivo .pas afirma coisas sobre o comportamento do
  SQL Server - que forma ele recusa, que forma devolve a pagina certa - e
  afirmacao dessas nao pode viver so no comentario de quem mediu. O .sql traz o
  docker run exato (nao exige SQL Server instalado), o SQL submetido e a saida
  bruta transcrita, para qualquer um repetir ou contestar.

  REGRA QUE ESTE ARQUIVO TRAVA: consulta filtrada e paginada preserva o filtro.
  Vale para TODO dialeto, em TODA combinacao de First/Skip/OrderBy. Nao e uma
  regra de nenhum consumidor especifico - e do proprio framework: paginar e
  recortar um conjunto, nunca redefini-lo.

  DUAS CAMADAS DE ASSERCAO, de proposito:

    1. MATRIZ - dialeto x combinacao, afirmando so que o predicado SOBREVIVE.
       Larga e resistente a mudanca de forma do SQL: continua valida se o
       dialeto reescrever a paginacao.
    2. STRING EXATA por dialeto, com comparacao SENSIVEL A CAIXA. Estreita e
       fragil de proposito: e o que pega regressao de forma e de caixa. Repare
       no terceiro parametro False dos Assert.AreEqual - o padrao do DUnitX e
       ignoreCase = TRUE, e numa biblioteca cujo produto E texto SQL isso deixa
       passar 'select' virando 'SELECT'.

  O SQLite fica de fora da camada 2 de proposito. Ele emite
  "SELECT LIMIT 10 OFFSET 20 * FROM T", que nao e SQL valido em SQLite algum
  (LIMIT/OFFSET vao no fim, nao entre SELECT e a lista de colunas). Congelar
  essa string aqui seria abencoar o defeito; ele esta catalogado como achado
  separado. O SQLite continua coberto pela camada 1, que e a regra desta tarefa.

  Dialetos desligados no FluentSQL.inc entram na matriz assim mesmo, exigindo a
  excecao NOMEADA EFluentSQLDriverNotRegistered - nao [Ignore] silencioso. Ligar
  um driver no .inc passa a cobra-lo pela regra, que e o comportamento desejado.

  ------------------------------------------------------------------------------
  ORDENACAO E PAGINACAO: o que este arquivo trava, e o que NAO promete

  Um teste que congela SQL de paginacao convida a leitura de que a paginacao
  ficou estavel. Nao ficou, e a distincao importa mais que o teste.

  COM OrderBy do usuario, a janela do ROW_NUMBER() usa ESSE OrderBy. Essa e a
  correcao de verdade: sem ela o MSSQL numerava por outra coisa e so ordenava no
  fim, devolvendo OUTRA pagina - SQL valido, dado errado, calado. Travado por
  TestMSSQLJanelaUsaOrderByDoUsuario.

    RESSALVA, e ela e do framework inteiro, nao so do MSSQL: a doc da Microsoft
    condiciona a estabilidade a coluna UNICA -

      "There is no guarantee that the rows returned by a query using
       ROW_NUMBER() will be ordered exactly the same with each execution unless
       [...] Values of the ORDER BY columns are unique."
      https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql

      "The ORDER BY clause contains a column or combination of columns that are
       guaranteed to be unique."
      https://learn.microsoft.com/en-us/sql/t-sql/queries/select-order-by-clause-transact-sql

    O FluentSQL NAO impoe unicidade, por decisao de projeto. Ordenar por coluna
    com valores repetidos deixa as linhas empatadas dentro do grupo e a fronteira
    entre paginas pode variar entre execucoes. Quem precisa de estabilidade
    ordena por chave unica ou acrescenta uma como desempate.

  SEM OrderBy do usuario sai ORDER BY (SELECT NULL). Isso NAO e conserto de
  determinismo e o arquivo nao deve ser lido como se fosse. E preenchimento
  exigido pela GRAMATICA: no OVER o order_by_clause "is required", e
  <offset_fetch> so existe como sub-clausula do ORDER BY - nao ha como emitir
  nada. Entre os preenchimentos possiveis, (SELECT NULL) e o unico medido que
  nao acrescenta operador Sort ao plano. CURRENT_TIMESTAMP, a forma anterior,
  produz PLANO IDENTICO a (SELECT NULL) - os dois empatam todas as linhas
  igualmente; a troca foi de idioma, nao de comportamento. NEWID() foi
  descartado por ser avaliado por linha e custar um Sort sem comprar unicidade.
  Medido no caso P de test.pagination.filter.mssql.sql, com os planos das quatro
  formas lado a lado.

  PAGINAR SEM NENHUMA ORDENACAO devolve um subconjunto arbitrario. Isso e
  semantica do SQL e vale nos 7 dialetos, nao e defeito a corrigir aqui:

    "This is not a bug; it is an inherent consequence of the fact that SQL does
     not promise to deliver the results of a query in any particular order
     unless ORDER BY is used."
    https://www.postgresql.org/docs/current/queries-limit.html

  E por isso que o FluentSQL NAO exige OrderBy para paginar: 6 dos 7 dialetos
  aceitam paginar sem ordenacao, e exigir seria inventar restricao que os bancos
  nao tem.
  ------------------------------------------------------------------------------
}

unit test.pagination.filter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestPaginationWithFilter = class
  public
    /// <summary>
    ///   Camada 1: para cada dialeto e cada combinacao de First/Skip/OrderBy, o
    ///   predicado do usuario tem que aparecer no texto emitido.
    /// </summary>
    [Test]
    procedure TestPredicadoSobreviveEmTodaCombinacaoDeTodoDialeto;
    /// <summary>
    ///   O defeito exato do MSSQL, isolado: com filtro a clausula tem que
    ///   comecar em WHERE. "AS T AND (" e o SQL que o motor recusa.
    /// </summary>
    [Test]
    procedure TestMSSQLPaginacaoComFiltroEmiteWhereNaoAnd;
    /// <summary>
    ///   Sem filtro o MSSQL ja acertava; fica travado para a correcao do caso
    ///   com filtro nao quebrar o caso sem filtro.
    /// </summary>
    [Test]
    procedure TestMSSQLPaginacaoSemFiltroContinuaComWhere;
    /// <summary>
    ///   A assimetria que denunciou o defeito: o bind ficou na lista de params
    ///   enquanto o predicado sumia do SQL. Params e texto tem que concordar.
    /// </summary>
    [Test]
    procedure TestBindEPredicadoNaoDivergem;
    /// <summary>
    ///   First sozinho e Skip sozinho. Antes da T9 o limite que nao foi pedido
    ///   saia com lixo de pilha (ROWNUMBER > 4910988), variando a cada execucao;
    ///   estes dois asserts nao podiam nem ser escritos.
    /// </summary>
    [Test]
    procedure TestMSSQLFirstSozinhoNaoInventaLimiteInferior;
    [Test]
    procedure TestMSSQLSkipSozinhoNaoInventaLimiteSuperior;
    /// <summary>
    ///   A CORRECAO DE VERDADE: dado um OrderBy, a janela numera por ele.
    ///   Numerar por outra coisa e ordenar so no fim nao embaralha a pagina -
    ///   devolve OUTRA pagina, porque o recorte sai de um conjunto que nao e o
    ///   que o usuario ordenou. Medido em test.pagination.filter.mssql.sql,
    ///   casos D2/D2b/D2c, com gabarito independente via OFFSET/FETCH nativo.
    ///
    ///   Nao promete estabilidade entre execucoes: para isso a doc da Microsoft
    ///   exige coluna UNICA, e o framework nao impoe unicidade. Ver o cabecalho.
    /// </summary>
    [Test]
    procedure TestMSSQLJanelaUsaOrderByDoUsuario;
    /// <summary>
    ///   Sem OrderBy do usuario sai ORDER BY (SELECT NULL) - preenchimento
    ///   exigido pela gramatica do T-SQL, ja que o order_by_clause do OVER "is
    ///   required". NAO e conserto de determinismo: (SELECT NULL) e
    ///   CURRENT_TIMESTAMP empatam todas as linhas igualmente e dao o MESMO
    ///   plano, sem Sort (caso P do .sql). O criterio de escolha entre os dois
    ///   e idioma, e entre eles e NEWID() e custo - NEWID() acrescenta Sort sem
    ///   comprar unicidade.
    ///
    ///   O assert prende a forma emitida, nao uma promessa de ordem.
    /// </summary>
    [Test]
    procedure TestMSSQLJanelaSemOrderByUsaSelectNull;
    /// <summary>Camada 2, string exata e sensivel a caixa, um metodo por dialeto.</summary>
    [Test]
    procedure TestSqlExatoMSSQL;
    [Test]
    procedure TestSqlExatoFirebird;
    [Test]
    procedure TestSqlExatoMySQL;
    [Test]
    procedure TestSqlExatoOracle;
    [Test]
    procedure TestSqlExatoPostgreSQL;
    [Test]
    procedure TestSqlExatoMongoDB;
    /// <summary>
    ///   Dialeto desligado no .inc recusa com excecao NOMEADA. Se o dono ligar o
    ///   driver, este teste fica vermelho e cobra a linha na matriz - que e o
    ///   ponto: nao existe dialeto fora da regra, so dialeto ainda nao ligado.
    /// </summary>
    [Test]
    procedure TestDialetoDesligadoRecusaComExcecaoNomeada;
  end;

implementation

uses
  SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

type
  /// <summary>As combinacoes de paginacao que a matriz percorre, sempre COM filtro.</summary>
  TCombinacao = (cbFirst, cbSkip, cbFirstSkip, cbOrderByAsc, cbOrderByDesc, cbDoisTermos);

const
  cCOMBINACAO: array[TCombinacao] of String = (
    'Where + First',
    'Where + Skip',
    'Where + First + Skip',
    'Where + OrderBy ASC + First + Skip',
    'Where + OrderBy DESC + First + Skip',
    'Where AND Where + First + Skip'
  );

  cDIALETO: array[TFluentSQLDriver] of String = (
    'dbnMSSQL', 'dbnMySQL', 'dbnFirebird', 'dbnSQLite', 'dbnInterbase',
    'dbnDB2', 'dbnOracle', 'dbnPostgreSQL', 'dbnMongoDB'
  );

/// <summary>Monta a consulta da celula (dialeto, combinacao). Sempre com filtro.</summary>
function _Monta(const ADriver: TFluentSQLDriver; const ACombinacao: TCombinacao): String;
begin
  case ACombinacao of
    cbFirst:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).First(10).AsString;
    cbSkip:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).Skip(20).AsString;
    cbFirstSkip:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).First(10).Skip(20).AsString;
    cbOrderByAsc:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).OrderBy('NOME').First(10).Skip(20).AsString;
    cbOrderByDesc:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).OrderBy('NOME').Desc.First(10).Skip(20).AsString;
    cbDoisTermos:
      Result := Query(ADriver).Select.All.From('T')
                  .Where('ATIVO').Equal(1).AndOpe('IDADE').GreaterThan(18)
                  .First(10).Skip(20).AsString;
  else
    raise Exception.Create('Combinacao sem montagem em _Monta. ' +
      'Toda combinacao de TCombinacao precisa estar coberta pela matriz.');
  end;
end;

/// <summary>
///   Como o predicado ATIVO = 1 se escreve em cada dialeto. O MySQL troca :pN
///   por ? na serializacao e o MongoDB nao e SQL - dai a tabela em vez de uma
///   string unica.
/// </summary>
function _Predicado(const ADriver: TFluentSQLDriver): String;
begin
  case ADriver of
    dbnMySQL:   Result := '(ATIVO = ?)';
    dbnMongoDB: Result := '"ATIVO":1';
  else
    Result := '(ATIVO = :p1)';
  end;
end;

/// <summary>
///   O dialeto tem driver registrado nesta build? Depende dos {$DEFINE} de
///   FluentSQL.inc, entao e detectado em runtime e nao assumido.
/// </summary>
function _EstaRegistrado(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    Query(ADriver).Select.All.From('T').AsString;
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
  end;
end;

procedure TTestPaginationWithFilter.TestPredicadoSobreviveEmTodaCombinacaoDeTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LComb: TCombinacao;
  LSql: String;
  LFalhas: String;
  LCelulas: Integer;
begin
  LFalhas := '';
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    for LComb := Low(TCombinacao) to High(TCombinacao) do
    begin
      Inc(LCelulas);
      try
        LSql := _Monta(LDriver, LComb);
      except
        on E: Exception do
        begin
          LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] + ' / ' +
            cCOMBINACAO[LComb] + ' -> levantou ' + E.ClassName + ': ' + E.Message;
          Continue;
        end;
      end;
      if Pos(_Predicado(LDriver), LSql) = 0 then
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] + ' / ' +
          cCOMBINACAO[LComb] + ' -> perdeu ' + _Predicado(LDriver) + ' em: ' + LSql;
    end;
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhuma celula percorrida: a matriz nao esta medindo nada.');
  Assert.AreEqual('', LFalhas,
    'Consulta filtrada e paginada perdeu o filtro em ' + IntToStr(LCelulas) +
    ' celulas percorridas:' + LFalhas);
end;

procedure TTestPaginationWithFilter.TestMSSQLPaginacaoComFiltroEmiteWhereNaoAnd;
var
  LSql: String;
begin
  LSql := Query(dbnMSSQL).Select.All.From('T')
            .Where('ATIVO').Equal(1).First(10).Skip(20).AsString;
  Assert.Contains(LSql, ') AS T WHERE (ATIVO = :p1) AND (ROWNUMBER', False,
    'O predicado do usuario tem que abrir a clausula WHERE da consulta externa.');
  Assert.DoesNotContain(LSql, ') AS T AND (', False,
    'AND sem WHERE na consulta externa: o SQL Server recusa com Msg 156.');
end;

procedure TTestPaginationWithFilter.TestMSSQLPaginacaoSemFiltroContinuaComWhere;
var
  LSql: String;
begin
  LSql := Query(dbnMSSQL).Select.All.From('T').First(10).Skip(20).AsString;
  Assert.Contains(LSql, ') AS T WHERE (ROWNUMBER > 20 AND ROWNUMBER <= 30)', False,
    'Paginacao sem filtro ja funcionava; a correcao do caso com filtro nao pode quebra-la.');
end;

procedure TTestPaginationWithFilter.TestBindEPredicadoNaoDivergem;
var
  LQuery: IFluentSQL;
  LSql: String;
begin
  LQuery := Query(dbnMSSQL).Select.All.From('T')
              .Where('ATIVO').Equal(1).First(10).Skip(20);
  LSql := LQuery.AsString;
  Assert.AreEqual(1, LQuery.Params.Count,
    'O filtro registrou exatamente um bind.');
  Assert.Contains(LSql, ':p1', False,
    'O bind existe na lista de params mas o texto nao o referencia: ' +
    'foi exatamente assim que o defeito passou despercebido.');
end;

procedure TTestPaginationWithFilter.TestMSSQLFirstSozinhoNaoInventaLimiteInferior;
begin
  Assert.AreEqual(
    'SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER ' +
    'FROM T) AS T WHERE (ATIVO = :p1) AND (ROWNUMBER <= 10)',
    _Monta(dbnMSSQL, cbFirst), False);
end;

procedure TTestPaginationWithFilter.TestMSSQLSkipSozinhoNaoInventaLimiteSuperior;
begin
  Assert.AreEqual(
    'SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER ' +
    'FROM T) AS T WHERE (ATIVO = :p1) AND (ROWNUMBER > 20)',
    _Monta(dbnMSSQL, cbSkip), False);
end;

procedure TTestPaginationWithFilter.TestMSSQLJanelaUsaOrderByDoUsuario;
begin
  Assert.Contains(_Monta(dbnMSSQL, cbOrderByAsc),
    'ROW_NUMBER() OVER(ORDER BY NOME ASC) AS ROWNUMBER', False,
    'A janela tem que numerar pela ordenacao do usuario; e ela que define a pagina.');
  Assert.Contains(_Monta(dbnMSSQL, cbOrderByDesc),
    'ROW_NUMBER() OVER(ORDER BY NOME DESC) AS ROWNUMBER', False,
    'DESC do usuario tem que chegar na janela, nao so no ORDER BY externo.');
end;

procedure TTestPaginationWithFilter.TestMSSQLJanelaSemOrderByUsaSelectNull;
var
  LSql: String;
begin
  LSql := _Monta(dbnMSSQL, cbFirstSkip);
  Assert.Contains(LSql, 'ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ROWNUMBER', False);
  Assert.DoesNotContain(LSql, 'CURRENT_TIMESTAMP', False,
    'CURRENT_TIMESTAMP na janela sugere uma ordenacao que nao existe. Nao e ' +
    'pior que (SELECT NULL) em comportamento - o plano e o mesmo -, e pior em ' +
    'leitura, e e so isso que este assert prende.');
end;

procedure TTestPaginationWithFilter.TestSqlExatoMSSQL;
begin
  Assert.AreEqual(
    'SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY NOME ASC) AS ROWNUMBER ' +
    'FROM T) AS T WHERE (ATIVO = :p1) AND (ROWNUMBER > 20 AND ROWNUMBER <= 30) ' +
    'ORDER BY NOME ASC',
    _Monta(dbnMSSQL, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoFirebird;
begin
  Assert.AreEqual(
    'SELECT FIRST 10 SKIP 20 * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC',
    _Monta(dbnFirebird, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoMySQL;
begin
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = ?) ORDER BY NOME ASC LIMIT 10 OFFSET 20',
    _Monta(dbnMySQL, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoOracle;
begin
  Assert.AreEqual(
    'SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM ' +
    '(SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC) T) ' +
    'WHERE ROWNUM <= 10 AND ROWINI > 20',
    _Monta(dbnOracle, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoPostgreSQL;
begin
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC LIMIT 10 OFFSET 20',
    _Monta(dbnPostgreSQL, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoMongoDB;
begin
  Assert.AreEqual(
    '{"find":"T","filter":{"ATIVO":1},"projection":{},"sort":{"NOME":1},' +
    '"limit":10,"skip":20}',
    _Monta(dbnMongoDB, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestDialetoDesligadoRecusaComExcecaoNomeada;
var
  LDriver: TFluentSQLDriver;
begin
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if _EstaRegistrado(LDriver) then
      Continue;
    Assert.WillRaise(
      procedure
      begin
        _Monta(LDriver, cbOrderByAsc);
      end,
      EFluentSQLDriverNotRegistered,
      cDIALETO[LDriver] + ' esta desligado no .inc: tem que recusar com a ' +
      'excecao nomeada, nunca com EAccessViolation nem Exception crua.');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaginationWithFilter);

end.
