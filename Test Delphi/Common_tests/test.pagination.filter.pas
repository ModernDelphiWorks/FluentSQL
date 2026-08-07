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

  O SQLite ficava de fora da camada 2 porque emitia
  "SELECT LIMIT 10 OFFSET 20 * FROM T", que nao e SQL valido em SQLite algum, e
  congelar essa string seria abencoar o defeito. A T10 corrigiu a posicao, e o
  SQLite entrou na camada 2 como todo mundo (TestSqlExatoSQLite).

  Dialetos desligados no FluentSQL.inc entram na matriz assim mesmo, exigindo a
  excecao NOMEADA EFluentSQLDriverNotRegistered - nao [Ignore] silencioso. Ligar
  um driver no .inc passa a cobra-lo pela regra, que e o comportamento desejado.

  ------------------------------------------------------------------------------
  T10: A FORMA MUDOU EM SEIS DIALETOS. O QUE ESTE ARQUIVO PROMETE, NAO.

  A camada 1 sobreviveu inteira a T10 sem uma linha alterada - era exatamente
  para isso que ela existia separada. Foi a camada 2 que teve de ser reescrita,
  porque e ela que congela forma.

  Formas canonicas por dialeto, todas MEDIDAS em motor real (os .sql desta
  mesma pasta trazem docker run, versao do motor e saida bruta):

    MSSQL       [ORDER BY x |ORDER BY (SELECT NULL)|ORDER BY 1]
                OFFSET n ROWS [FETCH NEXT m ROWS ONLY]
    Oracle      [ORDER BY x] [OFFSET n ROWS] [FETCH NEXT m ROWS ONLY]
    PostgreSQL  [ORDER BY x] [LIMIT m] [OFFSET n]
    MySQL       [ORDER BY x] LIMIT m [OFFSET n]  - Skip sozinho usa
                LIMIT 18446744073709551615, receita do manual
    SQLite      [ORDER BY x] LIMIT m [OFFSET n]  - Skip sozinho usa LIMIT -1,
                "no upper bound" documentado
    Firebird    SELECT [FIRST m] [SKIP n] [DISTINCT] <colunas> ...
    MongoDB     campos "limit"/"skip" no comando find; estagio $skip ANTES do
                estagio $limit no pipeline (trocar a ordem devolve conjunto
                vazio, medido)

  ONDE OS DIALETOS DIVERGEM, E POR QUE ISSO E LEGITIMO:

  - Skip SEM First. So o PostgreSQL tem OFFSET como clausula independente. No
    MySQL e no SQLite "OFFSET n" solto e erro de sintaxe, medido nos dois, e por
    isso os dois emitem um teto. No SQL Server o FETCH exige OFFSET (Msg 153),
    na Oracle nao. Isso e variacao de SINTAXE, nao de existencia - a API e a
    mesma nos sete.

  - A clausula ORDER BY do MSSQL. O <offset_fetch> so existe dentro dela
    (Msg 102 sem ela). Sem OrderBy do usuario entra preenchimento, e ele NAO e
    um so: (SELECT NULL) e o preferido por nao custar Sort, mas o motor o recusa
    sob DISTINCT (Msg 145) e sob UNION (Msg 104), porque nesses casos o item do
    ORDER BY precisa estar na lista de selecao. So ai entra ORDER BY 1, que E
    aceito nos dois e CUSTA um Sort. Os dois planos medidos lado a lado estao em
    test.pagination.mssql.sql, caso S.

  O QUE ESTE ARQUIVO NAO PROMETE, e a distincao importa mais que o teste:

  A paginacao NAO ficou estavel entre execucoes, e nenhum assert aqui deve ser
  lido como se tivesse ficado. A doc da Microsoft condiciona a estabilidade a
  coluna UNICA, tanto em ROW_NUMBER quanto em OFFSET/FETCH:

    "The ORDER BY clause contains a column or combination of columns that are
     guaranteed to be unique."
    https://learn.microsoft.com/en-us/sql/t-sql/queries/select-order-by-clause-transact-sql

  O FluentSQL NAO impoe unicidade, por decisao de projeto. Ordenar por coluna
  com valores repetidos deixa linhas empatadas e a fronteira entre paginas pode
  variar. Quem precisa de estabilidade ordena por chave unica.

  PAGINAR SEM NENHUMA ORDENACAO devolve subconjunto arbitrario. Isso e semantica
  do SQL, vale nos 7, e foi MEDIDO: no PostgreSQL,
  "SELECT DISTINCT NOME FROM T LIMIT 3 OFFSET 20" devolveu N043/N060/N009, e nao
  N021/N022/N023; no MongoDB, duas rodadas do mesmo pipeline devolveram trios
  diferentes.

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
    ///   O defeito exato da T9, isolado: com filtro o predicado tem que
    ///   sobreviver, e nao pode sobrar um AND pendurado sem WHERE. A T10 trocou
    ///   a paginacao de predicado para cauda, entao a forma "AS T AND (" nem
    ///   existe mais - o assert continua valendo e agora e trivialmente
    ///   verdadeiro, o que e o desfecho certo de um defeito eliminado pela raiz.
    /// </summary>
    [Test]
    procedure TestMSSQLPaginacaoComFiltroPreservaPredicado;
    /// <summary>
    ///   A assimetria que denunciou o defeito: o bind ficou na lista de params
    ///   enquanto o predicado sumia do SQL. Params e texto tem que concordar.
    /// </summary>
    [Test]
    procedure TestBindEPredicadoNaoDivergem;
    /// <summary>
    ///   First sozinho e Skip sozinho, nos SETE dialetos. Antes da T9 o limite
    ///   nao pedido saia com lixo de pilha; depois da T10 cada dialeto tem uma
    ///   forma diferente para "sem teto", porque a gramatica de cada um e
    ///   diferente. Isto trava as duas coisas.
    /// </summary>
    [Test]
    procedure TestFirstSozinhoEmTodoDialeto;
    [Test]
    procedure TestSkipSozinhoEmTodoDialeto;
    /// <summary>
    ///   O ORDER BY do usuario vai para a cauda, e o OFFSET/FETCH vem DEPOIS
    ///   dele - que e a unica posicao valida no T-SQL. Com OrderBy nao entra
    ///   preenchimento nenhum.
    /// </summary>
    [Test]
    procedure TestMSSQLOrderByDoUsuarioPrecedeOffsetFetch;
    /// <summary>
    ///   Sem OrderBy do usuario sai ORDER BY (SELECT NULL): preenchimento
    ///   exigido pela gramatica, ja que "SELECT ID FROM T OFFSET 20 ROWS FETCH
    ///   NEXT 3 ROWS ONLY" e Msg 102. NAO e conserto de determinismo. Foi
    ///   escolhido por nao acrescentar operador Sort ao plano - medido no caso S
    ///   de test.pagination.mssql.sql.
    /// </summary>
    [Test]
    procedure TestMSSQLSemOrderByUsaSelectNull;
    /// <summary>
    ///   E onde (SELECT NULL) e RECUSADO pelo motor - sob DISTINCT (Msg 145) e
    ///   sob UNION (Msg 104) - entra ORDER BY 1. Este teste existe porque a
    ///   escolha do preenchimento e a unica decisao de projeto da T10 que nao
    ///   deriva direto da gramatica: deriva de DUAS medicoes conflitantes.
    /// </summary>
    [Test]
    procedure TestMSSQLDistinctEUnionUsamOrdinalPorqueSelectNullERecusado;
    /// <summary>
    ///   Paginar nao pode DESCARTAR clausula nenhuma. No MSSQL, antes da T10,
    ///   Union sumia com o ramo inteiro e WithAlias sumia com a CTE - em
    ///   silencio, gerando SQL valido e incompleto. Vale para os 7 dialetos que
    ///   suportam a clausula; onde o dialeto nao suporta, exige excecao NOMEADA.
    /// </summary>
    [Test]
    procedure TestPaginacaoNaoDescartaUnion;
    [Test]
    procedure TestPaginacaoNaoDescartaCTE;
    /// <summary>
    ///   Distinct + paginacao. Levantava Exception CRUA em MSSQL, MySQL,
    ///   PostgreSQL e Oracle; no Firebird emitia a ordem que o motor recusa com
    ///   -104. Nenhum dialeto pode recusar esta combinacao.
    /// </summary>
    [Test]
    procedure TestDistinctComPaginacaoEmTodoDialeto;
    /// <summary>
    ///   Distinct SOZINHO, sem paginacao nenhuma. Nao e teste de paginacao - e a
    ///   prova de que o defeito era do laco de paginacao e nao da combinacao:
    ///   os mesmos quatro dialetos explodiam sem que houvesse First ou Skip.
    /// </summary>
    [Test]
    procedure TestDistinctSozinhoNaoExplodeEmDialetoNenhum;
    /// <summary>GroupBy + paginacao, nos 7.</summary>
    [Test]
    procedure TestGroupByComPaginacaoEmTodoDialeto;
    /// <summary>
    ///   Nenhum dialeto pode recusar paginacao com Exception CRUA. Se recusar,
    ///   tem que ser com classe NOMEADA - "Exception" pelado nao e contrato,
    ///   nao ha o que capturar.
    /// </summary>
    [Test]
    procedure TestNenhumDialetoRecusaComExcecaoCrua;
    /// <summary>
    ///   AsString chamado duas vezes na MESMA IFluentSQL tem que devolver o
    ///   mesmo texto. O MSSQL injetava a coluna ROW_NUMBER() no AST durante a
    ///   serializacao, entao a segunda chamada acumulava uma segunda ROWNUMBER.
    ///   Sem a injecao, o defeito morreu.
    /// </summary>
    [Test]
    procedure TestAsStringRepetidoNaoDuplicaNadaEmDialetoNenhum;
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
    procedure TestSqlExatoSQLite;
    [Test]
    procedure TestSqlExatoMongoDB;
    /// <summary>
    ///   Camada 2 do caso que mais quebrou: Skip SEM First, string exata, um
    ///   dialeto por linha. E aqui que os tetos do MySQL e do SQLite ficam
    ///   travados - trocar 18446744073709551615 por outro numero, ou -1 por 0,
    ///   passa a devolver zero linhas em vez de todas.
    /// </summary>
    [Test]
    procedure TestSqlExatoSkipSozinho;
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
  /// <summary>
  ///   As combinacoes que a matriz percorre. As seis primeiras sao da T9 e tem
  ///   SEMPRE filtro - e o filtro que a camada 1 verifica. As cinco ultimas
  ///   entraram na T10 para fechar a classe Take/Skip x Distinct/Union/GroupBy/
  ///   CTE; essas nao levam Where, porque o que elas verificam e a preservacao da
  ///   OUTRA clausula.
  /// </summary>
  TCombinacao = (cbFirst, cbSkip, cbFirstSkip, cbOrderByAsc, cbOrderByDesc,
                 cbDoisTermos, cbDistinct, cbDistinctSemPaginacao, cbGroupBy,
                 cbUnion, cbWith);

const
  cCOMBINACAO: array[TCombinacao] of String = (
    'Where + First',
    'Where + Skip',
    'Where + First + Skip',
    'Where + OrderBy ASC + First + Skip',
    'Where + OrderBy DESC + First + Skip',
    'Where AND Where + First + Skip',
    'Distinct + First + Skip',
    'Distinct SEM paginacao',
    'GroupBy + First + Skip',
    'Union + First + Skip',
    'WithAlias + First + Skip'
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
    cbDistinct:
      Result := Query(ADriver).Select.Distinct.Column('NOME').From('T')
                  .First(10).Skip(20).AsString;
    cbDistinctSemPaginacao:
      Result := Query(ADriver).Select.Distinct.Column('NOME').From('T').AsString;
    cbGroupBy:
      Result := Query(ADriver).Select.Column('NOME').From('T')
                  .GroupBy('NOME').First(10).Skip(20).AsString;
    cbUnion:
      Result := Query(ADriver).Select.All.From('T')
                  .Union(Query(ADriver).Select.All.From('U'))
                  .First(10).Skip(20).AsString;
    cbWith:
      Result := Query(ADriver).Select.All.From('T')
                  .WithAlias('CTE').First(10).Skip(20).AsString;
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
    // So as combinacoes COM filtro. As da T10 (cbDistinct em diante) nao levam
    // Where de proposito: o que elas verificam e a preservacao de OUTRA
    // clausula, e cada uma tem seu proprio teste.
    for LComb := cbFirst to cbDoisTermos do
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

procedure TTestPaginationWithFilter.TestMSSQLPaginacaoComFiltroPreservaPredicado;
var
  LSql: String;
begin
  LSql := Query(dbnMSSQL).Select.All.From('T')
            .Where('ATIVO').Equal(1).First(10).Skip(20).AsString;
  Assert.Contains(LSql, 'WHERE (ATIVO = :p1)', False,
    'O predicado do usuario tem que sobreviver a paginacao. Era exatamente ele ' +
    'que sumia antes da T9.');
  Assert.DoesNotContain(LSql, ' AND (ROWNUMBER', False,
    'A T10 apagou o predicado ROWNUMBER: a paginacao virou cauda OFFSET/FETCH. ' +
    'Se ROWNUMBER reaparecer, o driver voltou a subconsulta com ROW_NUMBER().');
  Assert.Contains(LSql, 'OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY', False);
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

/// <summary>
///   O que cada dialeto emite para First(10) SOZINHO e para Skip(20) SOZINHO,
///   sempre com o filtro. As duas tabelas sao a forma canonica medida em motor
///   real; qualquer alteracao aqui tem que vir com uma medicao nova nos .sql.
/// </summary>
const
  cFIRST_SOZINHO: array[TFluentSQLDriver] of String = (
    {dbnMSSQL}      'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY',
    {dbnMySQL}      'SELECT * FROM T WHERE (ATIVO = ?) LIMIT 10',
    {dbnFirebird}   'SELECT FIRST 10 * FROM T WHERE (ATIVO = :p1)',
    {dbnSQLite}     'SELECT * FROM T WHERE (ATIVO = :p1) LIMIT 10',
    {dbnInterbase}  '',
    {dbnDB2}        '',
    {dbnOracle}     'SELECT * FROM T WHERE (ATIVO = :p1) FETCH NEXT 10 ROWS ONLY',
    {dbnPostgreSQL} 'SELECT * FROM T WHERE (ATIVO = :p1) LIMIT 10',
    {dbnMongoDB}    '{"find":"T","filter":{"ATIVO":1},"projection":{},"limit":10}'
  );

  cSKIP_SOZINHO: array[TFluentSQLDriver] of String = (
    // MSSQL: OFFSET sem FETCH e valido; e o FETCH que exigiria OFFSET, nao o contrario.
    {dbnMSSQL}      'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY (SELECT NULL) OFFSET 20 ROWS',
    // MySQL: "OFFSET 20" solto e ERROR 1064. O teto e 2^64-1, o maior aceito.
    {dbnMySQL}      'SELECT * FROM T WHERE (ATIVO = ?) LIMIT 18446744073709551615 OFFSET 20',
    {dbnFirebird}   'SELECT SKIP 20 * FROM T WHERE (ATIVO = :p1)',
    // SQLite: "OFFSET 20" solto e syntax error. LIMIT negativo = sem teto.
    {dbnSQLite}     'SELECT * FROM T WHERE (ATIVO = :p1) LIMIT -1 OFFSET 20',
    {dbnInterbase}  '',
    {dbnDB2}        '',
    {dbnOracle}     'SELECT * FROM T WHERE (ATIVO = :p1) OFFSET 20 ROWS',
    // PostgreSQL: o unico com OFFSET como clausula independente. Sem teto.
    {dbnPostgreSQL} 'SELECT * FROM T WHERE (ATIVO = :p1) OFFSET 20',
    {dbnMongoDB}    '{"find":"T","filter":{"ATIVO":1},"projection":{},"skip":20}'
  );

/// <summary>Percorre os dialetos registrados comparando string exata, com caixa.</summary>
procedure _ConfereTabela(const ATabela: array of String; const ACombinacao: TCombinacao;
  const AMensagem: String);
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LObtido: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    Assert.AreNotEqual('', ATabela[Ord(LDriver)],
      cDIALETO[LDriver] + ' esta registrado mas nao tem linha na tabela: ' +
      'ligar um driver no .inc passa a cobra-lo por esta regra.');
    try
      LObtido := _Monta(LDriver, ACombinacao);
    except
      on E: Exception do
      begin
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] + ' -> levantou ' +
          E.ClassName + ': ' + E.Message;
        Continue;
      end;
    end;
    // Comparacao SENSIVEL A CAIXA feita na mao: Assert.AreEqual do DUnitX
    // ignora caixa por padrao, e numa biblioteca cujo produto E texto SQL isso
    // deixa 'select' passar por 'SELECT'.
    if LObtido <> ATabela[Ord(LDriver)] then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        sLineBreak + '    esperado: ' + ATabela[Ord(LDriver)] +
        sLineBreak + '    obtido  : ' + LObtido;
  end;
  Assert.AreEqual('', LFalhas, AMensagem + LFalhas);
end;

procedure TTestPaginationWithFilter.TestFirstSozinhoEmTodoDialeto;
begin
  _ConfereTabela(cFIRST_SOZINHO, cbFirst,
    'First(10) sem Skip mudou de forma em algum dialeto:');
end;

procedure TTestPaginationWithFilter.TestSkipSozinhoEmTodoDialeto;
begin
  _ConfereTabela(cSKIP_SOZINHO, cbSkip,
    'Skip(20) sem First mudou de forma em algum dialeto. Este e o caso que ' +
    'estava quebrado em MSSQL, Oracle, MySQL e SQLite ao mesmo tempo:');
end;

procedure TTestPaginationWithFilter.TestSqlExatoSkipSozinho;
begin
  // Mesma tabela do teste acima, exposta como caso proprio da camada 2 porque e
  // aqui que os TETOS ficam presos. Trocar 18446744073709551615 por qualquer
  // outro numero, ou -1 por 0, faz a consulta devolver ZERO linhas em vez de
  // todas a partir do deslocamento - sem erro nenhum do motor.
  Assert.AreEqual('SELECT * FROM T WHERE (ATIVO = ?) LIMIT 18446744073709551615 OFFSET 20',
    _Monta(dbnMySQL, cbSkip), False,
    'O teto do MySQL e 2^64-1: medido, 2^64 e recusado com ERROR 1064.');
  Assert.AreEqual('SELECT * FROM T WHERE (ATIVO = :p1) LIMIT -1 OFFSET 20',
    _Monta(dbnSQLite, cbSkip), False,
    'LIMIT negativo e o "no upper bound" documentado do SQLite. LIMIT 0 ' +
    'devolveria conjunto vazio.');
  Assert.AreEqual('SELECT * FROM T WHERE (ATIVO = :p1) OFFSET 20',
    _Monta(dbnPostgreSQL, cbSkip), False,
    'O PostgreSQL NAO leva teto: e o unico em que OFFSET e clausula independente.');
end;

procedure TTestPaginationWithFilter.TestMSSQLOrderByDoUsuarioPrecedeOffsetFetch;
begin
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    _Monta(dbnMSSQL, cbOrderByAsc), False,
    'O ORDER BY do usuario tem que vir imediatamente antes do OFFSET/FETCH: ' +
    'e a unica posicao valida da sub-clausula no T-SQL.');
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME DESC OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    _Monta(dbnMSSQL, cbOrderByDesc), False,
    'DESC do usuario tem que chegar inteiro; e ele que define o que e a pagina 2.');
  Assert.DoesNotContain(_Monta(dbnMSSQL, cbOrderByAsc), '(SELECT NULL)', False,
    'Com OrderBy do usuario nao entra preenchimento nenhum.');
end;

procedure TTestPaginationWithFilter.TestMSSQLSemOrderByUsaSelectNull;
var
  LSql: String;
begin
  LSql := _Monta(dbnMSSQL, cbFirstSkip);
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY (SELECT NULL) OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    LSql, False);
  Assert.DoesNotContain(LSql, 'CURRENT_TIMESTAMP', False,
    'CURRENT_TIMESTAMP sugere uma ordenacao que nao existe.');
  Assert.DoesNotContain(LSql, 'NEWID', False,
    'NEWID() e avaliado por linha e custa um Sort sem comprar unicidade.');
end;

procedure TTestPaginationWithFilter.TestMSSQLDistinctEUnionUsamOrdinalPorqueSelectNullERecusado;
var
  LDistinct: String;
  LUnion: String;
begin
  LDistinct := Query(dbnMSSQL).Select.Distinct.Column('NOME').From('T')
                 .First(10).Skip(20).AsString;
  LUnion := Query(dbnMSSQL).Select.All.From('T')
              .Union(Query(dbnMSSQL).Select.All.From('U'))
              .First(10).Skip(20).AsString;

  Assert.AreEqual('SELECT DISTINCT NOME FROM T ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    LDistinct, False,
    'Sob DISTINCT o SQL Server recusa ORDER BY (SELECT NULL) com Msg 145 ' +
    '("ORDER BY items must appear in the select list"). O ordinal e o unico ' +
    'item que sempre esta na lista de selecao.');
  Assert.AreEqual('SELECT * FROM T UNION SELECT * FROM U ORDER BY 1 OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    LUnion, False,
    'Sob UNION o SQL Server recusa ORDER BY (SELECT NULL) com Msg 104, pela ' +
    'mesma regra.');

  // E o contrapeso: fora desses dois casos o ordinal NAO entra, porque ele custa
  // um operador Sort e (SELECT NULL) nao custa (caso S de test.pagination.mssql.sql).
  Assert.DoesNotContain(_Monta(dbnMSSQL, cbFirstSkip), 'ORDER BY 1', False,
    'ORDER BY 1 fora de DISTINCT/UNION acrescentaria um Sort ao plano de toda ' +
    'consulta paginada sem OrderBy. So entra onde (SELECT NULL) e recusado.');
end;

/// <summary>
///   Nome da classe de excecao que o dialeto levantou para a consulta dada, ou
///   '' se nao levantou. Uma excecao NOMEADA e resposta aceitavel; "Exception"
///   pelado nao e - nao ha o que capturar nem o que distinguir.
/// </summary>
function _ClasseDaExcecao(const ADriver: TFluentSQLDriver;
  const ACombinacao: TCombinacao): String;
begin
  Result := '';
  try
    _Monta(ADriver, ACombinacao);
  except
    on E: Exception do
      Result := E.ClassName;
  end;
end;

procedure TTestPaginationWithFilter.TestDistinctComPaginacaoEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LClasse: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    LClasse := _ClasseDaExcecao(LDriver, cbDistinct);
    if LClasse <> '' then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> levantou ' + LClasse;
  end;
  Assert.AreEqual('', LFalhas,
    'Distinct + paginacao levantava Exception CRUA em MSSQL, MySQL, PostgreSQL ' +
    'e Oracle (os quatro tratavam sqDistinct como qualificador desconhecido ' +
    'dentro do laco de paginacao). Nenhum dialeto pode recusar esta combinacao:' +
    LFalhas);
end;

procedure TTestPaginationWithFilter.TestDistinctSozinhoNaoExplodeEmDialetoNenhum;
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LClasse: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    LClasse := _ClasseDaExcecao(LDriver, cbDistinctSemPaginacao);
    if LClasse <> '' then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> levantou ' + LClasse;
  end;
  Assert.AreEqual('', LFalhas,
    'Select.Distinct SEM First nem Skip. Isto nao e paginacao - e a prova de que ' +
    'o defeito morava no laco de paginacao e vazava para quem nunca paginou:' +
    LFalhas);
  // E a forma tambem estava errada, em tres dialetos, sem paginacao nenhuma:
  // "SELECT NOME DISTINCT FROM T", com o DISTINCT DEPOIS da lista de colunas.
  Assert.AreEqual('SELECT DISTINCT NOME FROM T',
    _Monta(dbnMSSQL, cbDistinctSemPaginacao), False);
  Assert.AreEqual('SELECT DISTINCT NOME FROM T',
    _Monta(dbnOracle, cbDistinctSemPaginacao), False);
end;

procedure TTestPaginationWithFilter.TestGroupByComPaginacaoEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LSql: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    try
      LSql := _Monta(LDriver, cbGroupBy);
    except
      on E: Exception do
      begin
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
          ' -> levantou ' + E.ClassName + ': ' + E.Message;
        Continue;
      end;
    end;
    // O MongoDB agrupa via pipeline ($group), nao via a palavra GROUP BY.
    if LDriver = dbnMongoDB then
    begin
      if Pos('"$group"', LSql) = 0 then
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
          ' -> perdeu o estagio $group em: ' + LSql;
    end
    else if Pos('GROUP BY NOME', LSql) = 0 then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> perdeu o GROUP BY em: ' + LSql;
  end;
  Assert.AreEqual('', LFalhas,
    'Paginar nao pode descartar o agrupamento:' + LFalhas);
end;

procedure TTestPaginationWithFilter.TestPaginacaoNaoDescartaUnion;
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LSql: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    // O MongoDB nao tem UNION; ele recusa, e a recusa dele nao e materia deste
    // teste - e do TestNenhumDialetoRecusaComExcecaoCrua.
    if LDriver = dbnMongoDB then
      Continue;
    try
      LSql := _Monta(LDriver, cbUnion);
    except
      on E: Exception do
      begin
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
          ' -> levantou ' + E.ClassName + ': ' + E.Message;
        Continue;
      end;
    end;
    if Pos('UNION', LSql) = 0 then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> perdeu o UNION em: ' + LSql;
    if Pos('FROM U', LSql) = 0 then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> perdeu o ramo direito do UNION em: ' + LSql;
  end;
  Assert.AreEqual('', LFalhas,
    'No MSSQL, ate a T10, paginar DESCARTAVA o UNION e o ramo inteiro EM ' +
    'SILENCIO: o SQL saia valido e incompleto, sem erro nenhum. A causa era ' +
    'TFluentSQLSerializerMSSQL.AsString remontar o corpo por conta propria em ' +
    'vez de delegar a ComposeSqlCore:' + LFalhas);
end;

procedure TTestPaginationWithFilter.TestPaginacaoNaoDescartaCTE;
var
  LDriver: TFluentSQLDriver;
  LFalhas: String;
  LSql: String;
  LClasse: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    if LDriver = dbnMongoDB then
    begin
      // O MongoDB nao tem CTE. Aqui a regra nao e "preserve", e "recuse com
      // classe NOMEADA" - e ele ja recusa assim.
      LClasse := _ClasseDaExcecao(LDriver, cbWith);
      if (LClasse = '') or (LClasse = 'Exception') then
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
          ' -> deveria recusar CTE com excecao nomeada, mas devolveu "' + LClasse + '"';
      Continue;
    end;
    try
      LSql := _Monta(LDriver, cbWith);
    except
      on E: Exception do
      begin
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
          ' -> levantou ' + E.ClassName + ': ' + E.Message;
        Continue;
      end;
    end;
    if Pos('WITH CTE AS (', LSql) = 0 then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        ' -> perdeu a CTE em: ' + LSql;
  end;
  Assert.AreEqual('', LFalhas,
    'No MSSQL, ate a T10, paginar DESCARTAVA a CTE EM SILENCIO, pela mesma ' +
    'causa do UNION:' + LFalhas);
end;

procedure TTestPaginationWithFilter.TestNenhumDialetoRecusaComExcecaoCrua;
var
  LDriver: TFluentSQLDriver;
  LComb: TCombinacao;
  LFalhas: String;
  LClasse: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    for LComb := Low(TCombinacao) to High(TCombinacao) do
    begin
      LClasse := _ClasseDaExcecao(LDriver, LComb);
      if LClasse = 'Exception' then
        LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] + ' / ' +
          cCOMBINACAO[LComb] + ' -> Exception crua';
    end;
  end;
  Assert.AreEqual('', LFalhas,
    'Exception pelado nao e contrato: o consumidor nao tem o que capturar nem ' +
    'como distinguir de qualquer outra falha. Se um dialeto nao suporta uma ' +
    'combinacao, tem que dizer isso com classe NOMEADA:' + LFalhas);
end;

procedure TTestPaginationWithFilter.TestAsStringRepetidoNaoDuplicaNadaEmDialetoNenhum;
var
  LDriver: TFluentSQLDriver;
  LQuery: IFluentSQL;
  LPrimeira: String;
  LSegunda: String;
  LFalhas: String;
begin
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _EstaRegistrado(LDriver) then
      Continue;
    LQuery := Query(LDriver).Select.All.From('T')
                .Where('ATIVO').Equal(1).First(10).Skip(20);
    LPrimeira := LQuery.AsString;
    LSegunda := LQuery.AsString;
    if LPrimeira <> LSegunda then
      LFalhas := LFalhas + sLineBreak + '  ' + cDIALETO[LDriver] +
        sLineBreak + '    1a: ' + LPrimeira +
        sLineBreak + '    2a: ' + LSegunda;
  end;
  Assert.AreEqual('', LFalhas,
    'AsString escreveu no AST. No MSSQL a coluna ROW_NUMBER() era INJETADA em ' +
    'AAST.Select.Columns durante a serializacao, entao a segunda chamada ' +
    'acumulava uma segunda ROWNUMBER. Sem a injecao o defeito morreu no MSSQL; ' +
    'este teste cobre os sete para que ninguem o reintroduza em outro driver:' +
    LFalhas);
end;

procedure TTestPaginationWithFilter.TestSqlExatoMSSQL;
begin
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC ' +
    'OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
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
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC ' +
    'OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY',
    _Monta(dbnOracle, cbOrderByAsc), False);
end;

procedure TTestPaginationWithFilter.TestSqlExatoSQLite;
begin
  // O SQLite estava FORA da camada 2 ate a T10, porque a string que ele emitia
  // ("SELECT LIMIT 10 OFFSET 20 * FROM T") nao e SQL valido e congela-la seria
  // abencoar o defeito. Entrou agora.
  Assert.AreEqual(
    'SELECT * FROM T WHERE (ATIVO = :p1) ORDER BY NOME ASC LIMIT 10 OFFSET 20',
    _Monta(dbnSQLite, cbOrderByAsc), False);
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
