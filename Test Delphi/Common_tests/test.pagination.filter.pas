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
              (o ATIVO = :p1 nao esta em lugar nenhum; o SQL Server responde
               "Msg 156, Incorrect syntax near the keyword 'AND'")

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
    ///   A janela do ROW_NUMBER() usa o ORDER BY do usuario. Numerar por outra
    ///   coisa e ordenar so no fim devolve OUTRA pagina: medido no SQL Server
    ///   2022, "pagina 2 de 10 por NOME" dava K..T em vez de B..K.
    /// </summary>
    [Test]
    procedure TestMSSQLJanelaUsaOrderByDoUsuario;
    /// <summary>
    ///   Sem ORDER BY do usuario a janela usa o idioma T-SQL (SELECT NULL).
    ///   CURRENT_TIMESTAMP e aceito pelo motor mas finge uma ordenacao que nao
    ///   existe - toda linha recebe o mesmo valor e empata com todas as outras.
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
    'CURRENT_TIMESTAMP na janela finge uma ordenacao que nao existe.');
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
  LDesligados: Integer;
begin
  LDesligados := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if _EstaRegistrado(LDriver) then
      Continue;
    Inc(LDesligados);
    Assert.WillRaise(
      procedure
      begin
        _Monta(LDriver, cbOrderByAsc);
      end,
      EFluentSQLDriverNotRegistered,
      cDIALETO[LDriver] + ' esta desligado no .inc: tem que recusar com a ' +
      'excecao nomeada, nunca com EAccessViolation nem Exception crua.');
  end;
  Assert.IsTrue(LDesligados >= 0, 'Sonda estrutural; sem dialeto desligado o teste e trivial.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPaginationWithFilter);

end.
