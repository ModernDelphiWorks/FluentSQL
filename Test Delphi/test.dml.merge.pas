unit test.dml.merge;

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
  TTestDMLMerge = class
  public
    [Test]
    procedure TestMerge_BasicSyntax_GeneratesMSSQL;
    [Test]
    procedure TestMerge_WithArrayOfConstCondition_GeneratesExpected;
    [Test]
    procedure TestMerge_WithSourceQuery_GeneratesMSSQL;
  end;

implementation

uses
  System.SysUtils;

procedure TTestDMLMerge.TestMerge_BasicSyntax_GeneratesMSSQL;
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

procedure TTestDMLMerge.TestMerge_WithArrayOfConstCondition_GeneratesExpected;
var
  LSql: string;
begin
  // We use values that TUtils will process. 
  // In this library, SqlArrayOfConstToParameterizedSql often returns the string with values replaced 
  // or parameters added depending on the implementation.
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

procedure TTestDMLMerge.TestMerge_WithSourceQuery_GeneratesMSSQL;
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

initialization
  TDUnitX.RegisterTestFixture(TTestDMLMerge);
end.
