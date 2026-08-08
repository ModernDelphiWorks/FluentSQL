unit test.merge.mssql;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestMergeMSSQL = class
  private
    /// <summary>
    ///   Devolve o valor do parametro de nome APlaceholder (':p1', ':p2', ...) ou
    ///   levanta se nao existir. Usado para provar que o valor do usuario foi
    ///   PARAR na lista de parametros, e nao no texto do SQL.
    /// </summary>
    function ParamValue(const AQuery: IFluentSQL; const APlaceholder: string): string;
    /// <summary>
    ///   Monta MERGE ... WHEN MATCHED THEN UPDATE(['NOME', AValue]) no dialeto MSSQL.
    /// </summary>
    function MergeUpdateWith(const AValue: string; out ASql: string): IFluentSQL;
    /// <summary>
    ///   Monta MERGE ... WHEN NOT MATCHED THEN INSERT(['NOME', AValue]) no dialeto MSSQL.
    /// </summary>
    function MergeInsertWith(const AValue: string; out ASql: string): IFluentSQL;
  public
    [Test]
    procedure TestMerge_BasicSyntax_GeneratesMSSQL;
    [Test]
    procedure TestMerge_WithArrayOfConstCondition_GeneratesExpected;
    [Test]
    procedure TestMerge_WithSourceQuery_GeneratesMSSQL;
    [Test]
    procedure TestMerge_UpdateWithValues_GeneratesMSSQL;
    [Test]
    procedure TestMerge_InsertWithValues_GeneratesMSSQL;

    { ---- Injecao: o valor do usuario NUNCA pode virar texto no SQL ---- }

    // Separador '|' (e nao a virgula padrao) porque varios payloads CONTEM virgula.
    [Test]
    [TestCase('AspaSimples',      'x'' OR ''1''=''1', '|')]
    [TestCase('DropTable',        'x''; DROP TABLE USERS; --', '|')]
    [TestCase('AspaDupla',        'x" OR "1"="1', '|')]
    [TestCase('PontoEVirgula',    'a; DELETE FROM USERS', '|')]
    [TestCase('TracoTraco',       'a -- comentario', '|')]
    [TestCase('ComentarioBloco',  'a /* bloco */ b', '|')]
    [TestCase('AspaDobrada',      'a'''' b', '|')]
    [TestCase('UnionSelect',      'a'' UNION SELECT NULL, NULL --', '|')]
    procedure TestMerge_UpdateHostileValue_NeverReachesSqlText(const AValue: string);

    [Test]
    [TestCase('AspaSimples',      'x'' OR ''1''=''1', '|')]
    [TestCase('DropTable',        'x''; DROP TABLE USERS; --', '|')]
    [TestCase('AspaDupla',        'x" OR "1"="1', '|')]
    [TestCase('PontoEVirgula',    'a; DELETE FROM USERS', '|')]
    [TestCase('TracoTraco',       'a -- comentario', '|')]
    [TestCase('ComentarioBloco',  'a /* bloco */ b', '|')]
    [TestCase('AspaDobrada',      'a'''' b', '|')]
    [TestCase('UnionSelect',      'a'' UNION SELECT NULL, NULL --', '|')]
    procedure TestMerge_InsertHostileValue_NeverReachesSqlText(const AValue: string);

    [Test]
    procedure TestMerge_LegitApostrophe_OBrien_RoundTripsIntact;
    [Test]
    procedure TestMerge_MixedTypes_AllValuesParameterizedInOrder;
    [Test]
    procedure TestMerge_ColumnNamesStayLiteral_OnlyValuesBecomeParams;

    { ---- Lista de pares malformada: falhar alto, nao emitir SQL quebrado ---- }

    [Test]
    procedure TestMerge_UpdateOddArray_RaisesInsteadOfEmittingBrokenSql;
    [Test]
    procedure TestMerge_InsertOddArray_RaisesInsteadOfEmittingBrokenSql;
    [Test]
    procedure TestMerge_EvenArray_DoesNotRaise;
  end;

implementation

uses
  System.SysUtils,
  System.Variants;

{ TTestMergeMSSQL }

function TTestMergeMSSQL.ParamValue(const AQuery: IFluentSQL;
  const APlaceholder: string): string;
var
  I: Integer;
  LName: string;
begin
  LName := APlaceholder;
  if LName.StartsWith(':') then
    LName := LName.Substring(1);
  for I := 0 to AQuery.Params.Count - 1 do
    if AQuery.Params[I].Name = LName then
      Exit(VarToStrDef(AQuery.Params[I].Value, ''));
  raise Exception.CreateFmt('Parametro "%s" nao existe na lista (Count=%d).',
    [LName, AQuery.Params.Count]);
end;

function TTestMergeMSSQL.MergeUpdateWith(const AValue: string;
  out ASql: string): IFluentSQL;
begin
  Result := FluentSQL.Query(dbnMSSQL);
  Result.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', AValue]);
  ASql := Result.AsString;
end;

function TTestMergeMSSQL.MergeInsertWith(const AValue: string;
  out ASql: string): IFluentSQL;
begin
  Result := FluentSQL.Query(dbnMSSQL);
  Result.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['NOME', AValue]);
  ASql := Result.AsString;
end;

procedure TTestMergeMSSQL.TestMerge_BasicSyntax_GeneratesMSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using('SOURCE', 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update
      .WhenNotMatched
        .Insert
    .AsString;

  Assert.IsTrue(Pos('MERGE INTO [TARGET] AS [t]', LSql) > 0, 'Should contain MERGE INTO TARGET');
  Assert.IsTrue(Pos('USING [SOURCE] AS [s]', LSql) > 0, 'Should contain USING SOURCE');
  Assert.IsTrue(Pos('ON (t.ID = s.ID)', LSql) > 0, 'Should contain ON condition');
  Assert.IsTrue(Pos('WHEN MATCHED THEN UPDATE', LSql) > 0, 'Should contain WHEN MATCHED');
  Assert.IsTrue(Pos('WHEN NOT MATCHED THEN INSERT', LSql) > 0, 'Should contain WHEN NOT MATCHED');
  Assert.IsTrue(LSql.EndsWith(';'), 'Should end with semicolon');
end;

procedure TTestMergeMSSQL.TestMerge_WithArrayOfConstCondition_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET')
      .Using('SOURCE')
      .On(['ID =', 100])
      .WhenMatched
        .Update
    .AsString;

  Assert.IsTrue(Pos('ON (ID = :p1)', LSql) > 0, 'Should contain formatted ON condition');
end;

procedure TTestMergeMSSQL.TestMerge_WithSourceQuery_GeneratesMSSQL;
var
  LSource: IFluentSQL;
  LSql: string;
begin
  LSource := FluentSQL.Query(dbnMSSQL).Select('ID').Column('NOME').From('PESSOAS');

  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using(LSource, 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update
      .WhenNotMatched
        .Insert
    .AsString;
  Assert.IsTrue(Pos('USING (SELECT ID, NOME FROM PESSOAS) AS [s]', LSql) > 0, 'Should contain subquery in USING clause');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateWithValues_GeneratesMSSQL;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', 'TESTE', 'VALOR', 10.5]);
  LSql := LQuery.AsString;

  Assert.IsTrue(Pos('WHEN MATCHED THEN UPDATE SET [NOME] = :p1, [VALOR] = :p2', LSql) > 0,
    'Should contain UPDATE SET with parameters. SQL=' + LSql);
  Assert.AreEqual('TESTE', ParamValue(LQuery, ':p1'), False, 'p1 deve carregar o valor string');
  Assert.AreEqual(2, LQuery.Params.Count, 'string e numero, dois parametros');
end;

procedure TTestMergeMSSQL.TestMerge_InsertWithValues_GeneratesMSSQL;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 1, 'NOME', 'TESTE']);
  LSql := LQuery.AsString;

  Assert.IsTrue(Pos('WHEN NOT MATCHED THEN INSERT ([ID], [NOME]) VALUES (:p1, :p2)', LSql) > 0,
    'Should contain INSERT with parameters. SQL=' + LSql);
  Assert.AreEqual('1', ParamValue(LQuery, ':p1'), False, 'p1 = 1');
  Assert.AreEqual('TESTE', ParamValue(LQuery, ':p2'), False, 'p2 = TESTE');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateHostileValue_NeverReachesSqlText(
  const AValue: string);
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := MergeUpdateWith(AValue, LSql);

  Assert.IsFalse(LSql.Contains(AValue),
    'O valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('[NOME] = :p1'),
    'A coluna deve receber placeholder, nao literal. SQL=' + LSql);
  Assert.AreEqual(1, LQuery.Params.Count, 'exatamente um parametro');
  Assert.AreEqual(AValue, ParamValue(LQuery, ':p1'), False,
    'o valor tem de chegar INTACTO na lista de parametros');
end;

procedure TTestMergeMSSQL.TestMerge_InsertHostileValue_NeverReachesSqlText(
  const AValue: string);
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := MergeInsertWith(AValue, LSql);

  Assert.IsFalse(LSql.Contains(AValue),
    'O valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('VALUES (:p1)'),
    'O VALUES deve conter placeholder, nao literal. SQL=' + LSql);
  Assert.AreEqual(1, LQuery.Params.Count, 'exatamente um parametro');
  Assert.AreEqual(AValue, ParamValue(LQuery, ':p1'), False,
    'o valor tem de chegar INTACTO na lista de parametros');
end;

procedure TTestMergeMSSQL.TestMerge_LegitApostrophe_OBrien_RoundTripsIntact;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // Aspa legitima: tem que FUNCIONAR, nao ser mutilada por escape.
  LQuery := MergeInsertWith('O''Brien', LSql);

  Assert.IsFalse(LSql.Contains('O''Brien'),
    'Nome legitimo tambem nao pode virar texto no SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('VALUES (:p1)'), 'placeholder esperado. SQL=' + LSql);
  Assert.AreEqual('O''Brien', ParamValue(LQuery, ':p1'), False,
    'O''Brien tem de sair do outro lado exatamente igual, sem aspa dobrada');
end;

procedure TTestMergeMSSQL.TestMerge_MixedTypes_AllValuesParameterizedInOrder;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 7, 'NOME', 'ANA', 'SALARIO', 1234.56, 'ATIVO', True]);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('([ID], [NOME], [SALARIO], [ATIVO]) VALUES (:p1, :p2, :p3, :p4)'),
    'todos os quatro valores viram placeholders, na ordem. SQL=' + LSql);
  Assert.AreEqual(4, LQuery.Params.Count, 'quatro parametros');
  Assert.AreEqual('7', ParamValue(LQuery, ':p1'), False);
  Assert.AreEqual('ANA', ParamValue(LQuery, ':p2'), False);
end;

procedure TTestMergeMSSQL.TestMerge_ColumnNamesStayLiteral_OnlyValuesBecomeParams;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // O nome da coluna e identificador: continua literal (delimitado), nunca parametro.
  // Se o nome virasse :pN o SQL seria sintaticamente invalido.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', 'ANA', 'IDADE', 30]);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('UPDATE SET [NOME] = :p1, [IDADE] = :p2'),
    'nomes literais, valores parametrizados. SQL=' + LSql);
  Assert.AreEqual(2, LQuery.Params.Count, 'so os dois VALORES viram parametro');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateOddArray_RaisesInsteadOfEmittingBrokenSql;
begin
  // Antes: .Update(['NOME']) emitia "UPDATE SET [NOME] = ;", que o SQL Server 2022
  // recusa com Msg 102, Incorrect syntax near ';'. Falha longe da linha que a
  // causou. Agora falha na chamada.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenMatched
            .Update(['NOME']);
    end,
    EArgumentException,
    'Lista de pares com contagem impar tem de levantar, nao emitir SET [NOME] = ;');
end;

procedure TTestMergeMSSQL.TestMerge_InsertOddArray_RaisesInsteadOfEmittingBrokenSql;
begin
  // Antes: .Insert(['ID', 1, 'NOME']) emitia "VALUES (:p1, )", recusado com
  // Msg 102, Incorrect syntax near ')'.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenNotMatched
            .Insert(['ID', 1, 'NOME']);
    end,
    EArgumentException,
    'Lista de pares com contagem impar tem de levantar, nao emitir VALUES (:p1, )');
end;

procedure TTestMergeMSSQL.TestMerge_EvenArray_DoesNotRaise;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // A guarda so pode pegar contagem IMPAR. Contagem par - inclusive a lista
  // vazia, que equivale a .Update sem argumentos - tem de passar limpo.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 1, 'NOME', 'ana']);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('([ID], [NOME]) VALUES (:p1, :p2)'),
    'contagem par continua serializando normalmente. SQL=' + LSql);
  Assert.AreEqual(2, LQuery.Params.Count, 'dois valores, dois parametros');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMergeMSSQL);
end.
