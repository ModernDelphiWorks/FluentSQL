{
  ------------------------------------------------------------------------------
  FluentSQL - matriz do SLOT DE EXPRESSAO de Exists/NotExists por dialeto (T32)

  POR QUE ESTE ARQUIVO EXISTE

  Ate a T32, IFluentSQL.Exists(const ASubQuery: String) PARAMETRIZAVA o
  argumento. O texto da subconsulta virava VALOR DE BIND:

      Delete.From('A','X').Where('').Exists('SELECT 1 FROM B AS Y WHERE ...')

      dbnMSSQL -> DELETE X FROM A AS X WHERE (exists :p1)
      dbnMySQL -> DELETE FROM A AS X WHERE (exists ?)

  "WHERE (exists :p1)" nao e SQL valido em motor nenhum dos sete - e, mesmo que
  algum parser o aceitasse, o que chegaria ao motor seria a subconsulta como
  STRING, nao como consulta.

  A GRAVIDADE: o PR #162 publicou, no CHANGELOG e na propria mensagem de
  EFluentSQLConstructNotSupported de DELETE multi-relacao, que a saida e
  "restrinja a unica relacao alvo pelo WHERE - inclusive com subconsulta, que e
  portavel nos sete". Essa saida NAO EXISTIA: pela porta natural (Exists) ela
  emitia SQL que nenhum motor executa. O framework documentava um caminho que
  nao abria.

  MEDIDO EM MOTOR REAL, nao deduzido. Transcricao literal, com docker run,
  digest da imagem e versao perguntada AO MOTOR, em test.exists.subquery.sql
  nesta mesma pasta. Resumo - controle NEGATIVO (o que a base emitia) e
  controle POSITIVO (o que o HEAD emite), com massa e contagem antes/depois:

    PostgreSQL 16.14   (exists $1)   -> syntax error at or near "$1"     RECUSA
                       (exists '...')-> syntax error at or near "'SELECT..." RECUSA
                       (exists (SELECT ...)) -> DELETE 3, sobrevivem 4 e 5   OK
    MySQL 8.4.11       (exists ?)    -> ERROR 1064                       RECUSA
                       (exists '...')-> ERROR 1064                       RECUSA
                       (exists (SELECT ...)) -> sobrevivem 4 e 5             OK
    SQL Server 2022    (exists @p1)  -> Msg 102                          RECUSA
      16.0.4265.3      (exists '...')-> Msg 102                          RECUSA
                       (exists (SELECT ...)) -> 3 rows affected, sobrevivem 4 e 5 OK
    Firebird 5.0.4     (exists ?)    -> SQL error code = -104            RECUSA
                       (exists '...')-> SQL error code = -104            RECUSA
                       (exists (SELECT ...)) -> sobrevivem 4 e 5             OK
    SQLite 3.53.4      (exists :p1)  -> near ":p1": syntax error         RECUSA
                       (exists '...')-> near "'SELECT ...": syntax error RECUSA
                       (exists (SELECT ...)) -> sobrevivem 4 e 5             OK
    Oracle / DB2       ver test.exists.subquery.sql
    InterBase          NAO MEDIDO - nao existe imagem publica. Nenhuma afirmacao
                       sobre este dialeto e feita a partir de motor.

  A verificacao nao parou em "o parser aceitou": em cada motor foram criadas as
  relacoes A (5 linhas) e B (3 linhas apontando para 1,2,3), contada a massa
  antes, submetido VERBATIM o enunciado que o HEAD emite, e conferido que
  sobraram exatamente as linhas 4 e 5 (Exists) e 1,2,3 (NotExists).

  ONDE A REGRA MORA

  Em TFluentSQLOperator.GetCompareValue (FluentSQL.Operators.pas), numa guarda
  de TIPO no topo do metodo:

      if FDataType = dftText then
      begin
        Result := '(' + VarToStr(FValue) + ')';
        Exit;
      end;

  dftText e o slot de EXPRESSAO. A guarda ja existia - mas ANINHADA dentro do
  ramo fcIn/fcNotIn, valendo so para eles. Por isso InValues(String) e
  NotIn(String) SEMPRE emitiram a subconsulta verbatim e Exists/NotExists nao:
  eles caiam no "else" que chama FParams.Add. O conserto foi hospedar a regra no
  TIPO em vez de no OPERADOR - que e tambem o que faz os dois caminhos (com e
  sem colecao de parametros) dizerem a mesma coisa, ja que o caminho inline
  tratava dftText assim desde sempre.

  NAO HOUVE MAQUINA NOVA: os unicos produtores de dftText sao IsIn, IsNotIn,
  IsExists e IsNotExists (todos na sobrecarga String), entao subir a guarda nao
  alcanca operador algum alem desses quatro.

  ESTE TESTE E ANTI-COLATERAL, E ELE CAI DE VERDADE

  Falsificado por mutacao dirigida, nao deduzido - a tabela completa esta no
  relatorio da tarefa:
    * remover a guarda de dftText do topo derruba as celulas de Exists/NotExists
      deste arquivo (volta a :p1) E as de InValues(String)/NotIn(String);
    * fazer a guarda emitir sem parenteses derruba as celulas de forma exata;
    * fazer dftString cair na guarda de expressao derruba
      TestSlotDeValorContinuaParametrizando.
  Ou seja: a matriz separa slot de VALOR de slot de EXPRESSAO. Um teste que so
  olhasse Exists passaria com a mutacao que desparametriza Equal e Like.

  CAIXA: todo Assert.AreEqual daqui passa False em IgnoreCase. O default do
  DUnitX ignora maiuscula/minuscula, e numa biblioteca cujo produto E texto SQL
  isso deixaria "exists" passar por "EXISTS".
  ------------------------------------------------------------------------------
}

unit test.exists.subquery.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestExistsSubQueryMatrix = class
  public
    /// <summary>Exists emite a subconsulta VERBATIM e nao cria bind algum.</summary>
    [Test]
    procedure TestExistsEmiteSubconsultaVerbatimEmTodoDialeto;
    /// <summary>NotExists idem.</summary>
    [Test]
    procedure TestNotExistsEmiteSubconsultaVerbatimEmTodoDialeto;
    /// <summary>SQL exato, byte a byte, da saida que o PR #162 documenta.</summary>
    [Test]
    procedure TestSqlExatoDoDeleteComSubconsultaPorDialeto;
    /// <summary>Anti-colateral: o slot de VALOR continua parametrizando.</summary>
    [Test]
    procedure TestSlotDeValorContinuaParametrizando;
    /// <summary>Anti-colateral: InValues/NotIn com String ja eram verbatim e seguem.</summary>
    [Test]
    procedure TestInValuesENotInComStringSeguemVerbatim;
  end;

implementation

uses
  SysUtils,
  StrUtils,
  FluentSQL.Interfaces,
  FluentSQL;

const
  cDIALETO: array[TFluentSQLDriver] of String = (
    'dbnMSSQL', 'dbnMySQL', 'dbnFirebird', 'dbnSQLite', 'dbnInterbase',
    'dbnDB2', 'dbnOracle', 'dbnPostgreSQL', 'dbnMongoDB'
  );

  /// <summary>
  ///   Os dialetos RELACIONAIS. MongoDB esta fora da promessa por decisao de
  ///   projeto - la nao ha WHERE nem subconsulta SQL para medir.
  /// </summary>
  cRELACIONAIS: array[0..7] of TFluentSQLDriver = (
    dbnMSSQL, dbnMySQL, dbnFirebird, dbnSQLite, dbnInterbase, dbnDB2,
    dbnOracle, dbnPostgreSQL
  );

  cSUB = 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID';

/// <summary>
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.alias.matrix.pas. Sem isto a matriz
///   passaria a MEDIR MENOS conforme os defines, calada, que e exatamente o
///   modo de falha que esta fila ja pagou caro.
/// </summary>
function _EstaRegistrado(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    Query(ADriver).Select.All.From('A').AsString;
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
  end;
end;

procedure TTestExistsSubQueryMatrix.TestExistsEmiteSubconsultaVerbatimEmTodoDialeto;
var
  LFor: Integer;
  LDriver: TFluentSQLDriver;
  LQuery: IFluentSQL;
  LSql: String;
begin
  for LFor := Low(cRELACIONAIS) to High(cRELACIONAIS) do
  begin
    LDriver := cRELACIONAIS[LFor];
    if not _EstaRegistrado(LDriver) then
      Continue;

    LQuery := Query(LDriver).Delete.From('A', 'X').Where('').Exists(cSUB);
    LSql := LQuery.AsString;

    // 1) A subconsulta esta LA, inteira, entre parenteses.
    Assert.IsTrue(ContainsStr(LSql, '(exists (' + cSUB + '))'),
      cDIALETO[LDriver] + ': a subconsulta tem de sair verbatim entre ' +
      'parenteses. Emitido: ' + LSql);

    // 2) E o que mais importa: NAO virou bind. Zero parametros criados. Esta e
    //    a asserção que cai na base - la Params.Count valia 1, com o texto da
    //    subconsulta como VALOR.
    Assert.AreEqual(0, LQuery.Params.Count,
      cDIALETO[LDriver] + ': Exists nao pode criar parametro algum - o ' +
      'argumento e EXPRESSAO, nao valor. Emitido: ' + LSql);

    // 3) Nenhum marcador de bind sobrou no enunciado, em nenhuma das duas
    //    grafias (:pN nos seis, ? no MySQL).
    Assert.AreEqual(False, ContainsStr(LSql, ':p'),
      cDIALETO[LDriver] + ': sobrou marcador :p no enunciado: ' + LSql);
    Assert.AreEqual(False, ContainsStr(LSql, '?'),
      cDIALETO[LDriver] + ': sobrou marcador ? no enunciado: ' + LSql);
  end;
end;

procedure TTestExistsSubQueryMatrix.TestNotExistsEmiteSubconsultaVerbatimEmTodoDialeto;
var
  LFor: Integer;
  LDriver: TFluentSQLDriver;
  LQuery: IFluentSQL;
  LSql: String;
begin
  for LFor := Low(cRELACIONAIS) to High(cRELACIONAIS) do
  begin
    LDriver := cRELACIONAIS[LFor];
    if not _EstaRegistrado(LDriver) then
      Continue;

    LQuery := Query(LDriver).Delete.From('A', 'X').Where('').NotExists(cSUB);
    LSql := LQuery.AsString;

    Assert.IsTrue(ContainsStr(LSql, '(not exists (' + cSUB + '))'),
      cDIALETO[LDriver] + ': a subconsulta tem de sair verbatim entre ' +
      'parenteses. Emitido: ' + LSql);
    Assert.AreEqual(0, LQuery.Params.Count,
      cDIALETO[LDriver] + ': NotExists nao pode criar parametro algum. ' +
      'Emitido: ' + LSql);
    Assert.AreEqual(False, ContainsStr(LSql, ':p'),
      cDIALETO[LDriver] + ': sobrou marcador :p no enunciado: ' + LSql);
    Assert.AreEqual(False, ContainsStr(LSql, '?'),
      cDIALETO[LDriver] + ': sobrou marcador ? no enunciado: ' + LSql);
  end;
end;

/// <summary>
///   O enunciado EXATO, byte a byte. Cada linha desta tabela foi submetida ao
///   motor correspondente e EXECUTOU, apagando exatamente as linhas certas - a
///   transcricao esta em test.exists.subquery.sql. A forma do DELETE varia por
///   dialeto por conta da T12/T18 (palavra do apelido) e nao por conta desta
///   tarefa: MSSQL poe o apelido como alvo, Oracle recusa o AS.
/// </summary>
procedure TTestExistsSubQueryMatrix.TestSqlExatoDoDeleteComSubconsultaPorDialeto;

  procedure _Celula(const ADriver: TFluentSQLDriver; const AEsperado: String);
  begin
    if not _EstaRegistrado(ADriver) then
      Exit;
    Assert.AreEqual(AEsperado,
      Query(ADriver).Delete.From('A', 'X').Where('').Exists(cSUB).AsString,
      False, cDIALETO[ADriver]);
  end;

begin
  // MEDIDO: SQL Server 2022 16.0.4265.3 -> "(3 rows affected)", sobrevivem 4 e 5.
  _Celula(dbnMSSQL,
    'DELETE X FROM A AS X WHERE (exists (' + cSUB + '))');
  // MEDIDO: MySQL 8.4.11 -> sobrevivem 4 e 5.
  _Celula(dbnMySQL,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
  // MEDIDO: PostgreSQL 16.14 -> "DELETE 3", sobrevivem 4 e 5.
  _Celula(dbnPostgreSQL,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
  // MEDIDO: Firebird 5.0.4 -> sobrevivem 4 e 5.
  _Celula(dbnFirebird,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
  // MEDIDO: SQLite 3.53.4 -> sobrevivem 4 e 5.
  _Celula(dbnSQLite,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
  // MEDIDO: Oracle - a Oracle recusa o AS no apelido de DELETE (T18/ORA-03048),
  // por isso a forma sem AS. Ver test.exists.subquery.sql.
  _Celula(dbnOracle,
    'DELETE FROM A X WHERE (exists (' + cSUB + '))');
  // MEDIDO: DB2 12.1.5.0 - ver test.exists.subquery.sql.
  _Celula(dbnDB2,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
  // InterBase: NAO MEDIDO em motor (nao ha imagem publica). A celula fixa a
  // FORMA que o driver emite, herdada do Firebird, e nao afirma aceitacao pelo
  // motor. Declarado, nao suposto.
  _Celula(dbnInterbase,
    'DELETE FROM A AS X WHERE (exists (' + cSUB + '))');
end;

/// <summary>
///   ANTI-COLATERAL. A guarda que subiu no GetCompareValue e de TIPO (dftText).
///   Se ela alcancasse tipo demais, valor de usuario deixaria de ser
///   parametrizado - trocando um defeito de SQL invalido por um defeito de
///   INJECAO. Esta celula e a que impede isso, e ela cai de verdade: basta
///   fazer dftString entrar na guarda para derruba-la.
/// </summary>
procedure TTestExistsSubQueryMatrix.TestSlotDeValorContinuaParametrizando;
var
  LFor: Integer;
  LDriver: TFluentSQLDriver;
  LQuery: IFluentSQL;
begin
  for LFor := Low(cRELACIONAIS) to High(cRELACIONAIS) do
  begin
    LDriver := cRELACIONAIS[LFor];
    if not _EstaRegistrado(LDriver) then
      Continue;

    // Igualdade com inteiro: um bind.
    LQuery := Query(LDriver).Select.All.From('A', 'X').Where('ID').Equal(7);
    Assert.AreEqual(1, LQuery.Params.Count,
      cDIALETO[LDriver] + ': Equal(Integer) tem de parametrizar. Emitido: ' +
      LQuery.AsString);
    Assert.AreEqual(7, Integer(LQuery.Params[0].Value),
      cDIALETO[LDriver] + ': o valor tem de estar no bind, nao no texto.');
    Assert.AreEqual(False, ContainsStr(LQuery.AsString, '= 7'),
      cDIALETO[LDriver] + ': o literal 7 nao pode aparecer no SQL. Emitido: ' +
      LQuery.AsString);

    // Igualdade com String: um bind, e a string NAO entra no texto.
    LQuery := Query(LDriver).Select.All.From('A', 'X').Where('N').Equal('zz');
    Assert.AreEqual(1, LQuery.Params.Count,
      cDIALETO[LDriver] + ': Equal(String) tem de parametrizar. Emitido: ' +
      LQuery.AsString);
    Assert.AreEqual(False, ContainsStr(LQuery.AsString, 'zz'),
      cDIALETO[LDriver] + ': a string nao pode aparecer no SQL. Emitido: ' +
      LQuery.AsString);

    // Like: um bind.
    LQuery := Query(LDriver).Select.All.From('A', 'X').Where('N').Like('zz');
    Assert.AreEqual(1, LQuery.Params.Count,
      cDIALETO[LDriver] + ': Like tem de parametrizar. Emitido: ' +
      LQuery.AsString);
    Assert.AreEqual(False, ContainsStr(LQuery.AsString, 'zz'),
      cDIALETO[LDriver] + ': a string nao pode aparecer no SQL. Emitido: ' +
      LQuery.AsString);

    // InValues com ARRAY: um bind POR ELEMENTO. Este e o vizinho mais proximo
    // do slot de expressao - mesma funcao, mesmo operador, tipo diferente.
    LQuery := Query(LDriver).Select.All.From('A', 'X').Where('ID').InValues(['a', 'b']);
    Assert.AreEqual(2, LQuery.Params.Count,
      cDIALETO[LDriver] + ': InValues(array) tem de parametrizar cada ' +
      'elemento. Emitido: ' + LQuery.AsString);
    Assert.AreEqual(False, ContainsStr(LQuery.AsString, '''a'''),
      cDIALETO[LDriver] + ': elemento do array nao pode aparecer no SQL. ' +
      'Emitido: ' + LQuery.AsString);
  end;
end;

/// <summary>
///   ANTI-COLATERAL do outro lado: InValues(String) e NotIn(String) JA eram o
///   slot de expressao antes da T32 - eram, alias, a unica porta publica que
///   emitia subconsulta sem parametrizar, e foi o modelo que o conserto seguiu.
///   Esta celula trava que a reorganizacao da guarda nao os mudou.
/// </summary>
procedure TTestExistsSubQueryMatrix.TestInValuesENotInComStringSeguemVerbatim;
var
  LFor: Integer;
  LDriver: TFluentSQLDriver;
  LQuery: IFluentSQL;
begin
  for LFor := Low(cRELACIONAIS) to High(cRELACIONAIS) do
  begin
    LDriver := cRELACIONAIS[LFor];
    if not _EstaRegistrado(LDriver) then
      Continue;

    LQuery := Query(LDriver).Select.All.From('A', 'X')
                .Where('ID').InValues('SELECT AID FROM B');
    Assert.IsTrue(ContainsStr(LQuery.AsString, 'IN (SELECT AID FROM B)'),
      cDIALETO[LDriver] + ': InValues(String) tem de sair verbatim. ' +
      'Emitido: ' + LQuery.AsString);
    Assert.AreEqual(0, LQuery.Params.Count,
      cDIALETO[LDriver] + ': InValues(String) nao cria parametro. Emitido: ' +
      LQuery.AsString);

    LQuery := Query(LDriver).Select.All.From('A', 'X')
                .Where('ID').NotIn('SELECT AID FROM B');
    Assert.IsTrue(ContainsStr(LQuery.AsString, 'NOT IN (SELECT AID FROM B)'),
      cDIALETO[LDriver] + ': NotIn(String) tem de sair verbatim. Emitido: ' +
      LQuery.AsString);
    Assert.AreEqual(0, LQuery.Params.Count,
      cDIALETO[LDriver] + ': NotIn(String) nao cria parametro. Emitido: ' +
      LQuery.AsString);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestExistsSubQueryMatrix);

end.
