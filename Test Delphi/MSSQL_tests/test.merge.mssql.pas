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
  end;

implementation

uses
  System.SysUtils;

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
  LSql: string;
begin
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using('SOURCE', 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update(['NOME', 'TESTE', 'VALOR', 10.5])
    .AsString;
  
  Assert.IsTrue(Pos('WHEN MATCHED THEN UPDATE SET [NOME] = :p1, [VALOR] = :p2', LSql) > 0, 'Should contain UPDATE SET with parameters');
end;

procedure TTestMergeMSSQL.TestMerge_InsertWithValues_GeneratesMSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using('SOURCE', 's')
      .On('t.ID = s.ID')
      .WhenNotMatched
        .Insert(['ID', 1, 'NOME', 'TESTE'])
    .AsString;
  
  Assert.IsTrue(Pos('WHEN NOT MATCHED THEN INSERT ([ID], [NOME]) VALUES (:p1, :p2)', LSql) > 0, 'Should contain INSERT with parameters');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMergeMSSQL);
end.
