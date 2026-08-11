{
  ------------------------------------------------------------------------------
  FluentSQL - o SLOT DE VALOR do CASE (T13)

  O QUE ESTE ARQUIVO TRAVA

  Ate a T13, IFluentSQLCriteriaCase.IfThen e .ElseIf tinham duas sobrecargas -
  String e Int64 - e as duas sao slot de EXPRESSAO: o argumento vira termo SQL
  VERBATIM. A de Int64 nao e excecao, ela chama IntToStr e cai na de String
  (FluentSQL.Cases.pas). Quem escrevia ali um valor vindo do usuario estava
  concatenando SQL - a MESMA classe de defeito que a T6a fechou em
  Merge.Update/Insert e em SetValue/Values.

  A T13 acrescenta a sobrecarga que FALTAVA:

      IfThen(AValue: Variant; ADataType: TFluentSQLDataFieldType)
      ElseIf(AValue: Variant; ADataType: TFluentSQLDataFieldType)

  e o que ela emite NAO e :pN nu - e CAST(:pN AS <tipo do dialeto>).

  POR QUE CAST, E POR QUE NOS SETE

  Parametro NU em posicao de THEN/ELSE nao passa do PREPARE em dois dos sete.
  Medido em motor real, transcricao literal em test.cases.bind.matrix.sql (que
  fica ao lado deste arquivo):

      Firebird 5.0.4     -804 / HY004      "Data type unknown"
      DB2 v12.1.5.0      SQL0418N / 42610  "untyped parameter marker"

  E nao e culpa do CASE: isolado, "SELECT :a FROM RDB$DATABASE" da o mesmo -804.
  E o marcador SEM TIPO. Com CAST nos dois ramos, os dois motores passam do
  prepare.

  O CAST sai nos SETE, e nao so nos dois que exigem, porque esta e uma sobrecarga
  NOVA: nao ha SQL emitido hoje por ela, logo nao ha oraculo a quebrar, e
  uniformizar custa zero.

  ============================================================================
  O ORACULO: SAO DOIS LADOS, E NENHUM SOZINHO BASTA
  ============================================================================

  Nao basta afirmar que "o texto mudou". O que prova parametrizacao e:

      (a) o valor NAO aparece no statement, e
      (b) existe EXATAMENTE UM bind por slot, com o DataType que o chamador
          declarou.

  Um SQL sem o valor mas com zero parametros teria PERDIDO o dado, nao ligado.

  ============================================================================
  O INVARIANTE, E POR QUE ELE TEM CELULA EM TODA CAUSA DE RECUSA
  ============================================================================

      nenhum caminho de recusa pode deixar parametro para tras,
      e nenhum termo que carrega :pN pode ser SUBSTITUIDO.

  Sao CINCO CAUSAS de recusa, fechadas por QUATRO guardas - a ultima fecha duas:

    causa                          guarda
    -----------------------------  --------------------------------------------
    1. sem When                    _AssertHaveWhen
    2. ramo ja ocupado             _AssertValueSlotFree
    3. Null / Unassigned           _AssertValueCarriesData
    4. tipo fora da intersecao     a SONDA (pre-voo do Cast)
    5. dialeto sem grafia de CAST  a SONDA (a mesma linha)

  A causa 5 e a que mais custou: o Cast do driver levanta DENTRO da chamada, ou
  seja DEPOIS de o Params.Add ja ter corrido. Medido, antes da correcao, em
  InterBase e no driver nao relacional: Params.Count=1, com o dado do usuario na
  colecao e nenhum SQL que o citasse. O controle (causa 4, no PostgreSQL) dava 0
  - ou seja o padrao existia em toda celula MENOS naquela.

  A SONDA fecha a 4 junto com a 5 porque _AssertCastTypeIsPortable e a PRIMEIRA
  linha de TFluentSQLFunctions.Cast: provocar o Cast provoca as duas. Isso foi
  MEDIDO - com a sonda no lugar, uma chamada explicita a _AssertCastTypeIsPortable
  no slot vira linha morta (move-la para depois do Params.Add nao deixa teste
  nenhum vermelho), e por isso ela nao existe.

  A causa 2 nem envolve excecao no caminho que a motivou: chamar IfThen duas
  vezes no mesmo ramo sobrescrevia o TEXTO e abandonava o :pN da primeira
  chamada. Medido, antes da correcao:

    .When('1').IfThen('A',dftString).IfThen('B',dftString)
       SQL: THEN CAST(:p2 ...)               colecao: p1=A, p2=B     p1 ORFAO
    .When('1').IfThen('A',...).ElseIf('B',...).ElseIf('C',...)
       SQL: THEN CAST(:p1) ELSE CAST(:p3)    colecao: p1,p2,p3       p2 ORFAO
    .When('1').IfThen('A',dftString).IfThen('''LITERAL''')
       SQL: THEN 'LITERAL'                   colecao: p1=A           p1 ORFAO

  POR ISSO TODA CELULA DE RECUSA DESTE ARQUIVO CONFERE A COLECAO, e nao so a
  classe da excecao. Uma celula que so confere a classe nao observa o defeito que
  mais custou aqui - e era exatamente esse o buraco: o padrao existia em todas as
  celulas MENOS nas duas em que ele quebraria.

  A FORMA da asercao e Delta = 0, e nao Total = 0, e a diferenca importa numa das
  cinco causas. Na causa 2 a PRIMEIRA chamada foi legitima e ligou :p1, que o SQL
  CITA; exigir Total = 0 ali seria exigir que um parametro REFERENCIADO fosse
  apagado. O que vale nas cinco e:

      a chamada RECUSADA nao acrescenta parametro nenhum

  Nas quatro causas em que nada legitimo veio antes, Delta = 0 e Total = 0 sao a
  mesma coisa, e as celulas conferem as duas.

  E ha ainda a asercao na forma mais pura, em celula propria
  (TestNenhumParametroFicaSemReferenciaNoSql): TODO parametro da colecao tem de
  ser CITADO pelo statement. Essa sozinha teria pego os quatro vazamentos.

  ============================================================================
  O QUE NAO ESTA AQUI, E POR QUE
  ============================================================================

  nil. Passar nil a esta sobrecarga NAO COMPILA. O erro do dcc32 36.0 e

      E2250 There is no overloaded version of 'IfThen' that can be called
            with these arguments

  e nao E2010: IfThen e SOBRECARREGADO, entao a resolucao de sobrecarga responde
  ANTES da compatibilidade de tipos. (O E2010 "Incompatible types: 'Variant' and
  'Pointer'" sai da atribuicao direta V := nil, que e outro experimento e nao
  esta chamada.) A conclusao e a mesma - a decisao "nil levanta, nao vira NULL"
  esta cumprida pelo sistema de tipos -, mas o codigo do erro foi MEDIDO, nao
  lembrado. Teste de runtime para nil seria inescrevivel.

  Null e Unassigned, esses sim, compilam e chegam - e sao recusados, com celula
  propria, sem deixar parametro para tras.
  ------------------------------------------------------------------------------
}

unit test.cases.value;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  Variants,
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Interfaces;

type
  /// <summary>
  ///   O que uma chamada RECUSADA deixou para tras. Nao so a classe, porque o
  ///   defeito que esta entrega mais repetiu foi justamente o parametro que
  ///   sobrava numa recusa correta.
  ///
  ///   O campo que importa e o DELTA, e nao o total. "Params.Count = 0 depois de
  ///   toda recusa" seria forte demais e ERRADO numa das cinco causas: na causa 2
  ///   (ramo ja ocupado) a PRIMEIRA chamada foi legitima e ligou :p1, que o SQL
  ///   CITA. Exigir zero ali seria exigir que um parametro referenciado fosse
  ///   apagado. O invariante certo e o que vale nas cinco:
  ///
  ///       a chamada RECUSADA nao acrescenta parametro nenhum (Delta = 0)
  ///
  ///   e para as quatro causas em que nada legitimo veio antes, Delta = 0 e
  ///   Total = 0 sao a mesma coisa - e as celulas conferem os dois.
  /// </summary>
  TRecusaObservada = record
    Classe: String;
    Msg: String;
    Antes: Integer;
    Params: Integer;
    function Delta: Integer;
  end;

  [TestFixture]
  TTestCaseValueSlot = class
  private
    function _CaseDeValor(const ADriver: TFluentSQLDriver; const AThen: Variant;
      const AThenType: TFluentSQLDataFieldType; const AElse: Variant;
      const AElseType: TFluentSQLDataFieldType): IFluentSQL;
    function _SoThen(const ADriver: TFluentSQLDriver; const AValue: Variant;
      const ADataType: TFluentSQLDataFieldType): IFluentSQL;
    /// <summary>
    ///   Monta o CASE com APreparo (que TEM de passar), anota o tamanho da
    ///   colecao, e so entao executa AOfensa - a chamada que deve ser recusada.
    ///   E o unico caminho pelo qual as celulas de recusa deste arquivo passam,
    ///   exatamente para que nenhuma possa "esquecer" de conferir o orfao.
    ///
    ///   Sao dois closures e nao um porque IFluentSQL.CaseExpr constroi um CASE
    ///   NOVO a cada chamada: preparo e ofensa precisam falar com o MESMO
    ///   IFluentSQLCriteriaCase, e nao so com a mesma query.
    /// </summary>
    function _Recusa(const ADriver: TFluentSQLDriver;
      const APreparo: TFunc<IFluentSQL, IFluentSQLCriteriaCase>;
      const AOfensa: TProc<IFluentSQLCriteriaCase>): TRecusaObservada;
    procedure _AssertRecusa(const ARecusa: TRecusaObservada;
      const AClasseEsperada, ATrechoDaMsg, AContexto: String);
    /// <summary>
    ///   O detector de orfao na forma mais pura: TODO parametro da colecao tem
    ///   de ser CITADO pelo statement. E a asercao que teria pego os quatro
    ///   vazamentos desta entrega de uma vez.
    /// </summary>
    procedure _AssertSemParametroOrfao(const AQuery: IFluentSQL;
      const AContexto: String);
    function _ContaOcorrencias(const AHaystack, ANeedle: String): Integer;
  public
    // --- (a) o valor nao aparece no statement -------------------------------
    [Test]
    procedure TestIfThenNaoDeixaOValorNoStatement;
    [Test]
    procedure TestElseIfNaoDeixaOValorNoStatement;
    [Test]
    procedure TestPayloadHostilNaoChegaAoTextoDoSql;

    // --- (b) exatamente um bind por slot ------------------------------------
    [Test]
    procedure TestIfThenGeraExatamenteUmBind;
    [Test]
    procedure TestElseIfGeraExatamenteUmBind;
    [Test]
    procedure TestDoisRamosGeramDoisBindsDistintos;
    [Test]
    procedure TestPlaceholderApareceUmaVezSoNoStatement;
    [Test]
    procedure TestDataTypeDeclaradoChegaAoParametro;

    // --- matriz: a grafia do CAST por dialeto -------------------------------
    [Test]
    procedure TestCastDeStringNosSeisDialetosAtivos;
    [Test]
    procedure TestCastDeInteiroNosSeisDialetosAtivos;
    [Test]
    procedure TestCastDeFloatNosSeisDialetosAtivos;
    [Test]
    procedure TestMongoDBLevantaPelaMesmaPortaDoCastPortavel;
    {$IFDEF DB2}
    [Test]
    procedure TestDB2NaoImpoeLarguraAoVarchar;
    {$ENDIF}
    {$IFDEF INTERBASE}
    [Test]
    procedure TestInterbaseLevantaPelaMesmaPortaDoCastPortavel;
    {$ENDIF}

    // --- o invariante: NENHUMA recusa deixa parametro -----------------------
    [Test]
    procedure TestNenhumaCausaDeRecusaDeixaParametro;
    [Test]
    procedure TestNenhumParametroFicaSemReferenciaNoSql;
    [Test]
    procedure TestTipoForaDaIntersecaoLevantaEmTodosOsMembros;
    [Test]
    procedure TestVariantNullLevanta;
    [Test]
    procedure TestVariantUnassignedLevanta;
    [Test]
    procedure TestVariantNullLevantaTambemNoElseIf;
    [Test]
    procedure TestSlotDeValorSemWhenLevantaNoIfThen;
    [Test]
    procedure TestSlotDeValorSemWhenLevantaNoElseIf;
    [Test]
    procedure TestSondaRecusaExatamenteComoAChamadaReal;

    // --- o invariante: nenhum termo com :pN pode ser SUBSTITUIDO ------------
    [Test]
    procedure TestIfThenDuasVezesNoMesmoRamoLevanta;
    [Test]
    procedure TestElseIfDuasVezesLevanta;
    [Test]
    procedure TestSobrecargaDeStringNaoSobrescreveSlotDeValorNoThen;
    [Test]
    procedure TestSobrecargaDeStringNaoSobrescreveSlotDeValorNoElse;
    [Test]
    procedure TestWhenNovoLiberaOSlotDeThen;
    [Test]
    procedure TestSlotDeValorDepoisDeStringContinuaPermitido;

    // --- controles: o que NAO pode ter mudado -------------------------------
    [Test]
    procedure TestSobrecargaDeStringContinuaVerbatim;
    [Test]
    procedure TestSobrecargaDeInt64ContinuaVerbatim;
    [Test]
    procedure TestSobrescreverRamoComStringContinuaPermitido;
    [Test]
    procedure TestSlotDeValorConviveComOSlotDeExpressaoNaNumeracao;
  end;

implementation

const
  /// O mesmo payload que derrubou a tabela no oraculo de MERGE (test.merge.mssql.sql).
  cPAYLOAD = '1; DROP TABLE USERS; --';
  cNAO_PORTAVEL = 'EFluentSQLFunctionNotSupported';
  cRECUSA_DE_USO = 'EArgumentException';

{ helpers }

function TTestCaseValueSlot._CaseDeValor(const ADriver: TFluentSQLDriver;
  const AThen: Variant; const AThenType: TFluentSQLDataFieldType;
  const AElse: Variant; const AElseType: TFluentSQLDataFieldType): IFluentSQL;
begin
  Result := FluentSQL.Query(ADriver)
    .Select
    .Column('ID')
    .Column('TIPO')
    .CaseExpr
      .When('1').IfThen(AThen, AThenType)
      .ElseIf(AElse, AElseType)
    .EndCase
    .Alias('R')
    .From('T');
end;

function TTestCaseValueSlot._SoThen(const ADriver: TFluentSQLDriver;
  const AValue: Variant; const ADataType: TFluentSQLDataFieldType): IFluentSQL;
begin
  Result := FluentSQL.Query(ADriver)
    .Select
    .Column('ID')
    .Column('TIPO')
    .CaseExpr
      .When('1').IfThen(AValue, ADataType)
    .EndCase
    .Alias('R')
    .From('T');
end;

function TRecusaObservada.Delta: Integer;
begin
  Result := Params - Antes;
end;

function TTestCaseValueSlot._Recusa(const ADriver: TFluentSQLDriver;
  const APreparo: TFunc<IFluentSQL, IFluentSQLCriteriaCase>;
  const AOfensa: TProc<IFluentSQLCriteriaCase>): TRecusaObservada;
var
  LQuery: IFluentSQL;
  LCase: IFluentSQLCriteriaCase;
begin
  LQuery := FluentSQL.Query(ADriver).Select.Column('ID').Column('TIPO');
  LCase := APreparo(LQuery);
  Result.Classe := '';
  Result.Msg := '';
  Result.Antes := LQuery.Params.Count;
  try
    AOfensa(LCase);
  except
    on E: Exception do
    begin
      Result.Classe := E.ClassName;
      Result.Msg := E.Message;
    end;
  end;
  Result.Params := LQuery.Params.Count;
end;

procedure TTestCaseValueSlot._AssertRecusa(const ARecusa: TRecusaObservada;
  const AClasseEsperada, ATrechoDaMsg, AContexto: String);
begin
  Assert.AreEqual(AClasseEsperada, ARecusa.Classe, False,
    AContexto + ': classe de excecao. Mensagem recebida: ' + ARecusa.Msg);
  if ATrechoDaMsg <> '' then
    Assert.Contains(ARecusa.Msg, ATrechoDaMsg, False,
      AContexto + ': a mensagem tem de nomear a chamada. Recebido: ' + ARecusa.Msg);
  // O LADO QUE JA FALTOU: recusa correta que deixa parametro para tras.
  Assert.AreEqual(0, ARecusa.Delta,
    AContexto + ': a chamada RECUSADA nao pode acrescentar parametro (tinha ' +
    IntToStr(ARecusa.Antes) + ', ficou com ' + IntToStr(ARecusa.Params) + '). ' +
    'Um :pN que o SQL nao cita desloca tudo para quem liga por posicao');
end;

procedure TTestCaseValueSlot._AssertSemParametroOrfao(const AQuery: IFluentSQL;
  const AContexto: String);
var
  LSql: String;
  LFor: Integer;
  LNome: String;
begin
  LSql := AQuery.AsString;
  for LFor := 0 to AQuery.Params.Count - 1 do
  begin
    LNome := AQuery.Params[LFor].Name;
    // O MySQL reescreve :pN -> ?; por isso a busca aceita as duas formas.
    if (Pos(':' + LNome, LSql) > 0) or (Pos('?', LSql) > 0) then
      Continue;
    Assert.Fail(AContexto + ': o parametro ' + LNome + ' esta na colecao mas o ' +
      'statement nao o cita - e um ORFAO. SQL: ' + LSql);
  end;
end;

function TTestCaseValueSlot._ContaOcorrencias(const AHaystack, ANeedle: String): Integer;
var
  LPos: Integer;
  LFrom: Integer;
begin
  Result := 0;
  LFrom := 1;
  repeat
    LPos := Pos(ANeedle, AHaystack, LFrom);
    if LPos = 0 then
      Break;
    Inc(Result);
    LFrom := LPos + Length(ANeedle);
  until False;
end;

{ --- (a) o valor nao aparece no statement ---------------------------------- }

procedure TTestCaseValueSlot.TestIfThenNaoDeixaOValorNoStatement;
var
  LSql: String;
begin
  LSql := _SoThen(dbnFirebird, 'SEGREDO', dftString).AsString;
  Assert.IsFalse(Pos('SEGREDO', LSql) > 0,
    'O valor do slot de THEN nao pode aparecer no texto do SQL - se aparece, ' +
    'ele foi interpolado e nao ligado. Recebido: ' + LSql);
end;

procedure TTestCaseValueSlot.TestElseIfNaoDeixaOValorNoStatement;
var
  LSql: String;
begin
  LSql := _CaseDeValor(dbnFirebird, 'AAA', dftString, 'SEGREDO', dftString).AsString;
  Assert.IsFalse(Pos('SEGREDO', LSql) > 0,
    'O valor do slot de ELSE nao pode aparecer no texto do SQL. Recebido: ' + LSql);
end;

procedure TTestCaseValueSlot.TestPayloadHostilNaoChegaAoTextoDoSql;
var
  LQuery: IFluentSQL;
begin
  LQuery := _SoThen(dbnMSSQL, cPAYLOAD, dftString);
  Assert.IsFalse(Pos('DROP TABLE', LQuery.AsString) > 0,
    'Payload hostil no slot de valor nao pode chegar ao texto do SQL. ' +
    'Recebido: ' + LQuery.AsString);
  // ... e nao pode ter sido PERDIDO no caminho: tem de estar ligado como dado.
  Assert.AreEqual(1, LQuery.Params.Count,
    'O payload sumiu do texto mas nao virou parametro - isso seria perda de dado, ' +
    'nao parametrizacao');
  Assert.AreEqual(cPAYLOAD, String(LQuery.Params[0].Value), False,
    'O parametro tem de carregar o valor original, byte a byte');
end;

{ --- (b) exatamente um bind por slot --------------------------------------- }

procedure TTestCaseValueSlot.TestIfThenGeraExatamenteUmBind;
var
  LQuery: IFluentSQL;
begin
  LQuery := _SoThen(dbnFirebird, 'SEGREDO', dftString);
  Assert.AreEqual(1, LQuery.Params.Count,
    'Um slot de valor tem de gerar UM bind - nem zero (valor perdido ou ' +
    'interpolado) nem dois (dado duplicado na colecao)');
  Assert.AreEqual('p1', LQuery.Params[0].Name, False);
  Assert.AreEqual('SEGREDO', String(LQuery.Params[0].Value), False);
end;

procedure TTestCaseValueSlot.TestElseIfGeraExatamenteUmBind;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .Column('ID')
    .Column('TIPO')
    .CaseExpr
      .When('1').IfThen('''FISICA''')       // slot de EXPRESSAO, nao gera bind
      .ElseIf('SEGREDO', dftString)         // slot de VALOR, gera UM bind
    .EndCase
    .Alias('R')
    .From('T');
  Assert.AreEqual(1, LQuery.Params.Count,
    'So o ramo ELSE usou o slot de valor, logo a colecao tem de ter um unico bind');
  Assert.AreEqual('SEGREDO', String(LQuery.Params[0].Value), False);
end;

procedure TTestCaseValueSlot.TestDoisRamosGeramDoisBindsDistintos;
var
  LQuery: IFluentSQL;
begin
  LQuery := _CaseDeValor(dbnFirebird, 'AAA', dftString, 'BBB', dftString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name, False);
  Assert.AreEqual('AAA', String(LQuery.Params[0].Value), False);
  Assert.AreEqual('p2', LQuery.Params[1].Name, False);
  Assert.AreEqual('BBB', String(LQuery.Params[1].Value), False);
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR(4000)) ' +
    'ELSE CAST(:p2 AS VARCHAR(4000)) END) AS R FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseValueSlot.TestPlaceholderApareceUmaVezSoNoStatement;
var
  LSql: String;
begin
  LSql := _CaseDeValor(dbnFirebird, 'AAA', dftString, 'BBB', dftString).AsString;
  Assert.AreEqual(1, _ContaOcorrencias(LSql, ':p1'),
    ':p1 tem de aparecer exatamente uma vez - repetido, o driver ligaria o mesmo ' +
    'valor em dois lugares. Recebido: ' + LSql);
  Assert.AreEqual(1, _ContaOcorrencias(LSql, ':p2'),
    ':p2 tem de aparecer exatamente uma vez. Recebido: ' + LSql);
end;

procedure TTestCaseValueSlot.TestDataTypeDeclaradoChegaAoParametro;
var
  LQuery: IFluentSQL;
begin
  // O DataType nao e enfeite: e ele que permite ao driver DECLARAR o tipo do bind,
  // que e o que salva Firebird e DB2 (ver test.cases.bind.matrix.sql).
  LQuery := _CaseDeValor(dbnFirebird, 'AAA', dftString, Int64(7), dftInteger);
  Assert.AreEqual(Ord(dftString), Ord(LQuery.Params[0].DataType),
    'O tipo declarado no slot de THEN tem de chegar ao parametro');
  Assert.AreEqual(Ord(dftInteger), Ord(LQuery.Params[1].DataType),
    'O tipo declarado no slot de ELSE tem de chegar ao parametro');
end;

{ --- matriz: a grafia do CAST por dialeto ---------------------------------- }

procedure TTestCaseValueSlot.TestCastDeStringNosSeisDialetosAtivos;
begin
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR(4000)) END) AS R FROM T',
    _SoThen(dbnFirebird, 'X', dftString).AsString, False, 'Firebird');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS NVARCHAR(4000)) END) AS R FROM T',
    _SoThen(dbnMSSQL, 'X', dftString).AsString, False, 'SQL Server');
  // MySQL reescreve :pN -> ? no serializador (FluentSQL.SerializeMySQL.pas).
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(? AS CHAR) END) AS R FROM T',
    _SoThen(dbnMySQL, 'X', dftString).AsString, False, 'MySQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR2(4000)) END) AS R FROM T',
    _SoThen(dbnOracle, 'X', dftString).AsString, False, 'Oracle');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR) END) AS R FROM T',
    _SoThen(dbnPostgreSQL, 'X', dftString).AsString, False, 'PostgreSQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS TEXT) END) AS R FROM T',
    _SoThen(dbnSQLite, 'X', dftString).AsString, False, 'SQLite');
end;

procedure TTestCaseValueSlot.TestCastDeInteiroNosSeisDialetosAtivos;
begin
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS INTEGER) END) AS R FROM T',
    _SoThen(dbnFirebird, Int64(7), dftInteger).AsString, False, 'Firebird');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS INT) END) AS R FROM T',
    _SoThen(dbnMSSQL, Int64(7), dftInteger).AsString, False, 'SQL Server');
  // SIGNED, e nao INTEGER: o alvo de CAST do MySQL e lista fechada (ERROR 1064).
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(? AS SIGNED) END) AS R FROM T',
    _SoThen(dbnMySQL, Int64(7), dftInteger).AsString, False, 'MySQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS INTEGER) END) AS R FROM T',
    _SoThen(dbnOracle, Int64(7), dftInteger).AsString, False, 'Oracle');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS INTEGER) END) AS R FROM T',
    _SoThen(dbnPostgreSQL, Int64(7), dftInteger).AsString, False, 'PostgreSQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS INTEGER) END) AS R FROM T',
    _SoThen(dbnSQLite, Int64(7), dftInteger).AsString, False, 'SQLite');
end;

procedure TTestCaseValueSlot.TestCastDeFloatNosSeisDialetosAtivos;
begin
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS DOUBLE PRECISION) END) AS R FROM T',
    _SoThen(dbnFirebird, Double(1.5), dftFloat).AsString, False, 'Firebird');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS FLOAT) END) AS R FROM T',
    _SoThen(dbnMSSQL, Double(1.5), dftFloat).AsString, False, 'SQL Server');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(? AS DOUBLE) END) AS R FROM T',
    _SoThen(dbnMySQL, Double(1.5), dftFloat).AsString, False, 'MySQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS BINARY_DOUBLE) END) AS R FROM T',
    _SoThen(dbnOracle, Double(1.5), dftFloat).AsString, False, 'Oracle');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS DOUBLE PRECISION) END) AS R FROM T',
    _SoThen(dbnPostgreSQL, Double(1.5), dftFloat).AsString, False, 'PostgreSQL');
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS REAL) END) AS R FROM T',
    _SoThen(dbnSQLite, Double(1.5), dftFloat).AsString, False, 'SQLite');
end;

procedure TTestCaseValueSlot.TestMongoDBLevantaPelaMesmaPortaDoCastPortavel;
begin
  // Consequencia HERDADA da porta unica do Cast portavel: onde o Cast levanta, o
  // slot de valor levanta. E ESTA e a celula da PORTA 5 - a recusa nasce dentro
  // do Cast do driver, DEPOIS de ele ser chamado, e por isso ela e a que deixava
  // parametro orfao. Params = 0 aqui e o que a sonda comprou.
  _AssertRecusa(
    _Recusa(dbnMongoDB,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end),
    cNAO_PORTAVEL, '', 'causa 5 (dialeto sem grafia de CAST)');
end;

{$IFDEF DB2}
procedure TTestCaseValueSlot.TestDB2NaoImpoeLarguraAoVarchar;
begin
  // Medido na T17: no DB2, CAST(REPEAT('x',300) AS VARCHAR) devolve 300. Impor
  // 4000 aqui criaria um teto que o motor nao tem. A celula vale AQUI tambem.
  Assert.AreEqual('SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR) END) AS R FROM T',
    _SoThen(dbnDB2, 'X', dftString).AsString, False, 'DB2');
end;
{$ENDIF}

{$IFDEF INTERBASE}
procedure TTestCaseValueSlot.TestInterbaseLevantaPelaMesmaPortaDoCastPortavel;
begin
  // O InterBase e RELACIONAL e sofre a causa 5 igual: a matriz de CAST dele nao
  // foi medida (nao ha imagem publica do motor) e NAO foi inferida do Firebird.
  // Esta celula media Params=1 antes da sonda.
  _AssertRecusa(
    _Recusa(dbnInterbase,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end),
    cNAO_PORTAVEL, '', 'causa 5 em dialeto RELACIONAL (InterBase)');
end;
{$ENDIF}

{ --- o invariante: NENHUMA recusa deixa parametro -------------------------- }

procedure TTestCaseValueSlot.TestNenhumaCausaDeRecusaDeixaParametro;
begin
  // A celula GUARDA-CHUVA do invariante. As cinco causas numa varredura so, para
  // que acrescentar uma causa nova sem celula propria ainda assim tropece aqui.
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end),
    cRECUSA_DE_USO, 'antes de When', 'causa 1 (sem When)');

  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('A', dftString) end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('B', dftString) end),
    cRECUSA_DE_USO, 'IfThen', 'causa 2 (ramo ja ocupado)');

  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen(Null, dftString) end),
    cRECUSA_DE_USO, 'IfThen', 'causa 3 (Null)');

  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftGuid) end),
    cNAO_PORTAVEL, '', 'causa 4 (tipo fora da intersecao)');

  _AssertRecusa(
    _Recusa(dbnMongoDB,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end),
    cNAO_PORTAVEL, '', 'causa 5 (dialeto sem grafia)');
end;

procedure TTestCaseValueSlot.TestNenhumParametroFicaSemReferenciaNoSql;
begin
  // O invariante na forma mais PURA, e a celula que sozinha teria pego os quatro
  // vazamentos desta entrega: todo :pN da colecao tem de ser citado pelo
  // statement. Nao depende de saber QUAIS sao as causas - so de o resultado
  // final ser coerente.
  _AssertSemParametroOrfao(
    _SoThen(dbnFirebird, 'A', dftString), 'um ramo so');
  _AssertSemParametroOrfao(
    _CaseDeValor(dbnFirebird, 'A', dftString, 'B', dftString), 'dois ramos');
  _AssertSemParametroOrfao(
    FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('TIPO')
      .CaseExpr.When([0]).IfThen('A', dftString).When([1]).IfThen('B', dftString)
      .ElseIf('C', dftString).EndCase.Alias('R').From('T'),
    'dois When com valor, mais ELSE, misturado com When(array)');
  _AssertSemParametroOrfao(
    FluentSQL.Query(dbnPostgreSQL).Select.Column('ID').Column('TIPO')
      .CaseExpr.When('1').IfThen('''A''').IfThen('B', dftString)
      .EndCase.Alias('R').From('T'),
    'String antes do slot de valor no mesmo ramo');
end;

procedure TTestCaseValueSlot.TestTipoForaDaIntersecaoLevantaEmTodosOsMembros;
var
  LType: TFluentSQLDataFieldType;
  LAtual: TFluentSQLDataFieldType;
  LVistos: Integer;
begin
  // A intersecao e cFluentSQLCastPortableTypes = [dftString, dftInteger, dftFloat].
  // Todo o RESTO do enum e recusado, e uniformemente - inclusive onde a celula
  // existiria no dialeto (dftGuid no PostgreSQL, dftBoolean no SQL Server).
  LVistos := 0;
  for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
  begin
    if LType in cFluentSQLCastPortableTypes then
      Continue;
    LAtual := LType;  // copia local: Delphi nao captura a variavel de controle do for
    _AssertRecusa(
      _Recusa(dbnPostgreSQL,
        function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
        procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', LAtual) end),
      cNAO_PORTAVEL, '', 'tipo ' + DataFieldTypeName(LAtual));
    Inc(LVistos);
  end;
  // Trava o TAMANHO da recusa: se alguem alargar cFluentSQLCastPortableTypes sem
  // passar por aqui, este numero cai e o teste diz onde olhar.
  Assert.AreEqual(7, LVistos,
    'O enum tem 10 membros e a intersecao tem 3, logo 7 tem de ser recusados');
end;

procedure TTestCaseValueSlot.TestVariantNullLevanta;
begin
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen(Null, dftString) end),
    cRECUSA_DE_USO, 'IfThen', 'Variant Null no slot de THEN');
end;

procedure TTestCaseValueSlot.TestVariantUnassignedLevanta;
var
  LRecusa: TRecusaObservada;
begin
  LRecusa := _Recusa(dbnFirebird,
    function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
    procedure(C: IFluentSQLCriteriaCase) begin C.IfThen(Unassigned, dftString) end);
  _AssertRecusa(LRecusa, cRECUSA_DE_USO, 'IfThen', 'Variant Unassigned');
  Assert.Contains(LRecusa.Msg, 'Unassigned', False,
    'A mensagem tem de dizer QUAL variant chegou. Recebido: ' + LRecusa.Msg);
end;

procedure TTestCaseValueSlot.TestVariantNullLevantaTambemNoElseIf;
begin
  // Celula PROPRIA, e nao redundante com a de IfThen: sao DOIS sitios de chamada
  // da guarda. Sem esta celula, apagar a linha do ElseIf nao deixaria teste
  // nenhum vermelho, porque a de IfThen continuaria verde.
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('''X''') end,
      procedure(C: IFluentSQLCriteriaCase) begin C.ElseIf(Null, dftString) end),
    cRECUSA_DE_USO, 'ElseIf', 'Variant Null no slot de ELSE');
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenLevantaNoIfThen;
begin
  // A guarda estrutural da T14 vale para a sobrecarga nova tambem - ela nao pode
  // ter aberto uma terceira porta para "CASE THEN <x> END".
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end),
    cRECUSA_DE_USO, 'antes de When', 'IfThen(Variant) antes de When');
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenLevantaNoElseIf;
begin
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr end,
      procedure(C: IFluentSQLCriteriaCase) begin C.ElseIf('X', dftString) end),
    cRECUSA_DE_USO, 'antes de When', 'ElseIf(Variant) antes de When');
end;

procedure TTestCaseValueSlot.TestSondaRecusaExatamenteComoAChamadaReal;
var
  LDaSonda: String;
  LDaReal: String;
begin
  // A sonda (causas 4 e 5) so e equivalente a chamada real porque a recusa do Cast
  // depende de (dialeto, tipo) e NAO da expressao. Isso foi conferido lendo os
  // nove drivers, mas leitura envelhece: esta celula compara as DUAS recusas.
  // Se um driver futuro passar a recusar por expressao, a sonda deixa de valer
  // e este teste vermelha em vez de o defeito voltar calado.
  LDaSonda := _Recusa(dbnMongoDB,
    function(Q: IFluentSQL): IFluentSQLCriteriaCase begin Result := Q.CaseExpr.When('1') end,
    procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('X', dftString) end).Msg;
  LDaReal := '';
  try
    FluentSQL.Func(dbnMongoDB).Cast(':p1', dftString);
  except
    on E: Exception do LDaReal := E.Message;
  end;
  Assert.AreEqual(LDaReal, LDaSonda, False,
    'A recusa que a sonda provoca tem de ser a MESMA que a chamada real ' +
    'provocaria - se divergirem, a sonda esta medindo outra coisa');
end;

{ --- o invariante: nenhum termo com :pN pode ser SUBSTITUIDO --------------- }

procedure TTestCaseValueSlot.TestIfThenDuasVezesNoMesmoRamoLevanta;
begin
  // Antes desta guarda: SQL com CAST(:p2), colecao com p1=A e p2=B. p1 ORFAO,
  // e sem excecao nenhuma para o chamador perceber.
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('A', dftString) end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('B', dftString) end),
    cRECUSA_DE_USO, 'THEN', 'IfThen duas vezes no mesmo ramo');
end;

procedure TTestCaseValueSlot.TestElseIfDuasVezesLevanta;
begin
  // Antes desta guarda: SQL com :p1 e :p3, colecao com p1,p2,p3. p2 ORFAO.
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('''X''').ElseIf('B', dftString) end,
      procedure(C: IFluentSQLCriteriaCase) begin C.ElseIf('C', dftString) end),
    cRECUSA_DE_USO, 'ELSE', 'ElseIf duas vezes');
end;

procedure TTestCaseValueSlot.TestSobrecargaDeStringNaoSobrescreveSlotDeValorNoThen;
begin
  // O PIOR dos tres casos medidos: o SQL fica sem :p1 nenhum, e o dado do
  // usuario continua na colecao, FORA do statement. A guarda vale nas
  // sobrecargas antigas por causa DESTE caso - e nao quebra codigo anterior a
  // esta entrega, porque para o slot estar ocupado alguem tem de ter chamado a
  // sobrecarga de Variant, que nasceu aqui.
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('A', dftString) end,
      procedure(C: IFluentSQLCriteriaCase) begin C.IfThen('''LITERAL''') end),
    cRECUSA_DE_USO, 'THEN', 'String sobrescrevendo slot de valor no THEN');
end;

procedure TTestCaseValueSlot.TestSobrecargaDeStringNaoSobrescreveSlotDeValorNoElse;
begin
  _AssertRecusa(
    _Recusa(dbnFirebird,
      function(Q: IFluentSQL): IFluentSQLCriteriaCase begin
        Result := Q.CaseExpr.When('1').IfThen('''X''').ElseIf('A', dftString) end,
      procedure(C: IFluentSQLCriteriaCase) begin C.ElseIf('''LITERAL''') end),
    cRECUSA_DE_USO, 'ELSE', 'String sobrescrevendo slot de valor no ELSE');
end;

procedure TTestCaseValueSlot.TestWhenNovoLiberaOSlotDeThen;
var
  LQuery: IFluentSQL;
begin
  // CONTROLE da guarda de substituicao: cada WHEN tem o SEU ramo THEN. Por isso
  // o registro e o INDICE do When, e nao um Boolean - com Boolean, este caso
  // legitimo passaria a ser recusado.
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr
      .When('1').IfThen('A', dftString)
      .When('2').IfThen('B', dftString)
      .ElseIf('C', dftString)
    .EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR(4000)) ' +
    'WHEN 2 THEN CAST(:p2 AS VARCHAR(4000)) ' +
    'ELSE CAST(:p3 AS VARCHAR(4000)) END) AS R FROM T',
    LQuery.AsString, False);
  Assert.AreEqual(3, LQuery.Params.Count);
end;

procedure TTestCaseValueSlot.TestSlotDeValorDepoisDeStringContinuaPermitido;
var
  LQuery: IFluentSQL;
begin
  // CONTROLE: a ORDEM inversa e legitima e continua passando. String primeiro
  // nao prende :pN nenhum ao ramo, entao o slot esta livre.
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr.When('1').IfThen('''A''').IfThen('B', dftString)
    .EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN CAST(:p1 AS VARCHAR(4000)) END) AS R FROM T',
    LQuery.AsString, False);
  Assert.AreEqual(1, LQuery.Params.Count);
end;

{ --- controles: o que NAO pode ter mudado ---------------------------------- }

procedure TTestCaseValueSlot.TestSobrecargaDeStringContinuaVerbatim;
var
  LQuery: IFluentSQL;
begin
  // A sobrecarga antiga NAO mudou de comportamento. Ela e slot de EXPRESSAO e
  // continua sendo: quem passa termo SQL por ali continua podendo.
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr.When('1').IfThen('''FISICA''').EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN ''FISICA'' END) AS R FROM T',
    LQuery.AsString, False);
  Assert.AreEqual(0, LQuery.Params.Count,
    'A sobrecarga de String nao parametriza - se passou a parametrizar, isto e ' +
    'BREAKING nao declarado');
end;

procedure TTestCaseValueSlot.TestSobrecargaDeInt64ContinuaVerbatim;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr.When('1').IfThen(Int64(42)).EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN 42 END) AS R FROM T',
    LQuery.AsString, False);
  Assert.AreEqual(0, LQuery.Params.Count,
    'A sobrecarga de Int64 continua virando texto - e o defeito que a sobrecarga ' +
    'nova existe para dar alternativa, nao para apagar em silencio');
end;

procedure TTestCaseValueSlot.TestSobrescreverRamoComStringContinuaPermitido;
var
  LQuery: IFluentSQL;
begin
  // CONTROLE que delimita o alcance da guarda nova: String sobre String continua
  // permitido e continua nao vazando, porque ali nao ha :pN envolvido. E a prova
  // de que a guarda NAO quebra codigo anterior a esta entrega.
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr.When('1').IfThen('''A''').IfThen('''B''')
      .ElseIf('''C''').ElseIf('''D''')
    .EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN ''B'' ELSE ''D'' END) AS R FROM T',
    LQuery.AsString, False,
    'Sobrescrever ramo com a sobrecarga de String e comportamento anterior a ' +
    'esta entrega e tem de continuar valendo');
  Assert.AreEqual(0, LQuery.Params.Count);
end;

procedure TTestCaseValueSlot.TestSlotDeValorConviveComOSlotDeExpressaoNaNumeracao;
var
  LQuery: IFluentSQL;
begin
  // When([...]) ja parametriza escalares desde a ESP-010. O slot de valor entra
  // na MESMA colecao, e a ordem tem de ser a ordem de construcao.
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select.Column('ID').Column('TIPO')
    .CaseExpr
      .When([0]).IfThen('FISICA', dftString)
      .ElseIf('OUTRO', dftString)
    .EndCase
    .Alias('R')
    .From('T');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN :p1 THEN CAST(:p2 AS VARCHAR(4000)) ' +
    'ELSE CAST(:p3 AS VARCHAR(4000)) END) AS R FROM T',
    LQuery.AsString, False);
  Assert.AreEqual(3, LQuery.Params.Count);
  Assert.AreEqual(0, Integer(LQuery.Params[0].Value));
  Assert.AreEqual('FISICA', String(LQuery.Params[1].Value), False);
  Assert.AreEqual('OUTRO', String(LQuery.Params[2].Value), False);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCaseValueSlot);

end.
