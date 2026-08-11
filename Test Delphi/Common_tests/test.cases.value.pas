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
  prepare (caso E5 do mesmo arquivo).

  O CAST sai nos SETE, e nao so nos dois que exigem, porque esta e uma sobrecarga
  NOVA: nao ha SQL emitido hoje por ela, logo nao ha oraculo a quebrar, e
  uniformizar custa zero. A alternativa - manter uma tabela de "quem precisa de
  tipo" - envelhece com a versao do motor, que e exatamente o modo de falha que a
  T17 documentou na matriz de CAST.

  O ORACULO QUE ESTES TESTES USAM

  Nao basta afirmar que "o texto mudou". O que prova parametrizacao e:

      (a) o valor NAO aparece no statement, e
      (b) existe EXATAMENTE UM bind por slot, com o DataType que o chamador
          declarou.

  E o mesmo oraculo que a equipe consumidora usou do lado dela e que pegou o
  defeito de verdade. Os dois lados estao aqui, e nenhum dos dois sozinho basta:
  um SQL sem o valor mas com zero parametros teria PERDIDO o dado.

  O QUE NAO ESTA AQUI, E POR QUE

  nil. Passar nil a esta sobrecarga NAO COMPILA - 'Variant' e 'Pointer' sao tipos
  incompativeis e o dcc32 recusa com E2010 antes de gerar codigo (medido). A
  decisao "nil levanta, nao vira NULL" e cumprida pelo sistema de tipos, nao por
  guarda de runtime, e um teste de runtime para nil seria inescrevivel.

  Null e Unassigned, esses sim, compilam e chegam - e sao recusados, com celula
  propria abaixo.
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
  [TestFixture]
  TTestCaseValueSlot = class
  private
    /// <summary>
    ///   CASE de dois ramos com o slot de VALOR nos dois, sobre o dialeto pedido.
    ///   Devolve a query para que o teste interrogue AsString E Params - os dois
    ///   lados do oraculo saem da MESMA construcao.
    /// </summary>
    function _CaseDeValor(const ADriver: TFluentSQLDriver; const AThen: Variant;
      const AThenType: TFluentSQLDataFieldType; const AElse: Variant;
      const AElseType: TFluentSQLDataFieldType): IFluentSQL;
    function _SoThen(const ADriver: TFluentSQLDriver; const AValue: Variant;
      const ADataType: TFluentSQLDataFieldType): IFluentSQL;
    function _ContaOcorrencias(const AHaystack, ANeedle: String): Integer;
    function _MensagemDe(const AProc: TProc): String;
    function _ClasseDe(const AProc: TProc): String;
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

    // --- guardas ------------------------------------------------------------
    [Test]
    procedure TestTipoForaDaIntersecaoLevantaEmTodosOsMembros;
    [Test]
    procedure TestTipoRecusadoNaoDeixaParametroOrfao;
    [Test]
    procedure TestVariantNullLevanta;
    [Test]
    procedure TestVariantUnassignedLevanta;
    [Test]
    procedure TestVariantNullLevantaTambemNoElseIf;
    [Test]
    procedure TestVariantNullRecusadoNaoDeixaParametroOrfao;
    [Test]
    procedure TestSlotDeValorSemWhenLevantaNoIfThen;
    [Test]
    procedure TestSlotDeValorSemWhenLevantaNoElseIf;
    [Test]
    procedure TestSlotDeValorSemWhenNaoGravaParametro;
    [Test]
    procedure TestSlotDeValorSemWhenNoElseIfNaoGravaParametro;

    // --- controles: o que NAO pode ter mudado -------------------------------
    [Test]
    procedure TestSobrecargaDeStringContinuaVerbatim;
    [Test]
    procedure TestSobrecargaDeInt64ContinuaVerbatim;
    [Test]
    procedure TestSlotDeValorConviveComOSlotDeExpressaoNaNumeracao;
  end;

implementation

const
  /// O mesmo payload que derrubou a tabela no oraculo de MERGE (test.merge.mssql.sql).
  cPAYLOAD = '1; DROP TABLE USERS; --';

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

function TTestCaseValueSlot._MensagemDe(const AProc: TProc): String;
begin
  Result := '';
  try
    AProc;
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

function TTestCaseValueSlot._ClasseDe(const AProc: TProc): String;
begin
  Result := '';
  try
    AProc;
  except
    on E: Exception do
      Result := E.ClassName;
  end;
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
  // Consequencia HERDADA da porta unica do Cast portavel, e nao regra escrita
  // duas vezes: em MongoDB o Cast(TFluentSQLDataFieldType) levanta, logo o slot
  // de valor levanta. Erro nomeado, e nao MQL indefensavel.
  Assert.AreEqual('EFluentSQLFunctionNotSupported',
    _ClasseDe(procedure begin _SoThen(dbnMongoDB, 'X', dftString) end),
    False,
    'O slot de valor em MongoDB tem de levantar pela mesma porta do Cast portavel');
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
  // Mesma razao do MongoDB, motivo diferente: a matriz de CAST do InterBase nao
  // foi medida (nao ha imagem publica do motor) e NAO foi inferida do Firebird.
  Assert.AreEqual('EFluentSQLFunctionNotSupported',
    _ClasseDe(procedure begin _SoThen(dbnInterbase, 'X', dftString) end),
    False,
    'O slot de valor em InterBase tem de levantar pela mesma porta do Cast portavel');
end;
{$ENDIF}

{ --- guardas --------------------------------------------------------------- }

procedure TTestCaseValueSlot.TestTipoForaDaIntersecaoLevantaEmTodosOsMembros;
var
  LType: TFluentSQLDataFieldType;
  LAtual: TFluentSQLDataFieldType;
  LClasse: String;
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
    LClasse := _ClasseDe(procedure begin _SoThen(dbnPostgreSQL, 'X', LAtual) end);
    Assert.AreEqual('EFluentSQLFunctionNotSupported', LClasse, False,
      'O membro ' + DataFieldTypeName(LAtual) + ' esta fora da intersecao e tem ' +
      'de ser recusado pelo slot de valor; recebido: ' + LClasse);
    Inc(LVistos);
  end;
  // Trava o TAMANHO da recusa: se alguem alargar cFluentSQLCastPortableTypes sem
  // passar por aqui, este numero cai e o teste diz onde olhar.
  Assert.AreEqual(7, LVistos,
    'O enum tem 10 membros e a intersecao tem 3, logo 7 tem de ser recusados');
end;

procedure TTestCaseValueSlot.TestTipoRecusadoNaoDeixaParametroOrfao;
var
  LQuery: IFluentSQL;
begin
  // A guarda de tipo roda ANTES de Params.Add. Se rodasse depois, a chamada
  // recusada deixaria :p1 na colecao e a numeracao seguinte teria um buraco.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select.Column('ID').Column('TIPO');
  try
    LQuery.CaseExpr.When('1').IfThen('X', dftGuid);
  except
    on E: Exception do ;
  end;
  Assert.AreEqual(0, LQuery.Params.Count,
    'Chamada recusada pela guarda de tipo nao pode deixar parametro na colecao');
end;

procedure TTestCaseValueSlot.TestVariantNullLevanta;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(procedure begin _SoThen(dbnFirebird, Null, dftString) end);
  Assert.AreEqual('EArgumentException',
    _ClasseDe(procedure begin _SoThen(dbnFirebird, Null, dftString) end), False,
    'Variant Null no slot de valor tem de levantar EArgumentException');
  Assert.Contains(LMsg, 'IfThen', False,
    'A mensagem tem de nomear a chamada que causou o erro. Recebido: ' + LMsg);
end;

procedure TTestCaseValueSlot.TestVariantUnassignedLevanta;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(procedure begin _SoThen(dbnFirebird, Unassigned, dftString) end);
  Assert.AreEqual('EArgumentException',
    _ClasseDe(procedure begin _SoThen(dbnFirebird, Unassigned, dftString) end), False,
    'Variant Unassigned no slot de valor tem de levantar EArgumentException');
  Assert.Contains(LMsg, 'Unassigned', False,
    'A mensagem tem de dizer QUAL variant chegou. Recebido: ' + LMsg);
end;

procedure TTestCaseValueSlot.TestVariantNullLevantaTambemNoElseIf;
var
  LMsg: String;
begin
  // Celula PROPRIA, e nao redundante com a de IfThen: sao DOIS sitios de chamada
  // da guarda (FluentSQL.Cases.pas, IfThen(Variant) e ElseIf(Variant)). Sem esta
  // celula, apagar a linha do ElseIf nao deixaria teste nenhum vermelho, porque
  // a de IfThen continuaria verde.
  LMsg := _MensagemDe(procedure begin
    FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('TIPO')
      .CaseExpr.When('1').IfThen('''X''').ElseIf(Null, dftString) end);
  Assert.Contains(LMsg, 'ElseIf', False,
    'Variant Null no slot de ELSE tem de levantar nomeando ElseIf. Recebido: ' + LMsg);
end;

procedure TTestCaseValueSlot.TestVariantNullRecusadoNaoDeixaParametroOrfao;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('TIPO');
  try
    LQuery.CaseExpr.When('1').IfThen(Null, dftString);
  except
    on E: Exception do ;
  end;
  Assert.AreEqual(0, LQuery.Params.Count,
    'Chamada recusada pela guarda de nulidade nao pode deixar parametro na colecao');
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenLevantaNoIfThen;
var
  LMsg: String;
begin
  // A guarda estrutural da T14 vale para a sobrecarga nova tambem - ela nao
  // pode ter aberto uma terceira porta para "CASE THEN <x> END".
  LMsg := _MensagemDe(procedure begin
    FluentSQL.Query(dbnFirebird).Select.Column('ID').CaseExpr.IfThen('X', dftString) end);
  Assert.Contains(LMsg, 'IfThen', False,
    'IfThen(Variant) antes de When tem de cair na mesma guarda. Recebido: ' + LMsg);
  Assert.AreEqual('EArgumentException',
    _ClasseDe(procedure begin
      FluentSQL.Query(dbnFirebird).Select.Column('ID').CaseExpr.IfThen('X', dftString) end),
    False);
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenLevantaNoElseIf;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(procedure begin
    FluentSQL.Query(dbnFirebird).Select.Column('ID').CaseExpr.ElseIf('X', dftString) end);
  Assert.Contains(LMsg, 'ElseIf', False,
    'A mensagem tem de nomear ElseIf, nao IfThen. Recebido: ' + LMsg);
  Assert.AreEqual('EArgumentException',
    _ClasseDe(procedure begin
      FluentSQL.Query(dbnFirebird).Select.Column('ID').CaseExpr.ElseIf('X', dftString) end),
    False);
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenNaoGravaParametro;
var
  LQuery: IFluentSQL;
begin
  // A ordem das guardas: a ESTRUTURAL vem antes de qualquer efeito colateral.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('TIPO');
  try
    LQuery.CaseExpr.IfThen('X', dftString);
  except
    on E: Exception do ;
  end;
  Assert.AreEqual(0, LQuery.Params.Count,
    'IfThen sem When e recusado ANTES de gravar o parametro');
end;

procedure TTestCaseValueSlot.TestSlotDeValorSemWhenNoElseIfNaoGravaParametro;
var
  LQuery: IFluentSQL;
begin
  // Sitio proprio, mesma razao da celula de Null no ElseIf: sem esta, apagar o
  // _AssertHaveWhen de ElseIf(Variant) continuaria levantando (a sobrecarga de
  // String re-assere) e nenhum teste veria o parametro orfao que sobrou.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('TIPO');
  try
    LQuery.CaseExpr.ElseIf('X', dftString);
  except
    on E: Exception do ;
  end;
  Assert.AreEqual(0, LQuery.Params.Count,
    'ElseIf sem When e recusado ANTES de gravar o parametro');
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
