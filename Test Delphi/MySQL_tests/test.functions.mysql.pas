unit test.functions.mysql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsMySQL = class
  public
  // T5: Round/Floor/Ceil/Abs/Modulus nao sao alcancaveis pela cadeia .Select.Column;
  // exigem expandir IFluentSQL. Guardado por T5_COLUMN_MATH_FUNCTIONS ate a T5 entregar.
{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
    [Test]
    procedure TestRound;
    [Test]
    procedure TestFloor;
    [Test]
    procedure TestCeil;
    [Test]
    procedure TestAbs;
    [Test]
    procedure TestModulus;
{$ENDIF}
  // T5: CurrentTimestamp nao e alcancavel pela cadeia .Select.Column;
  // exige expandir IFluentSQL. Guardado por T5_COLUMN_MATH_FUNCTIONS ate a T5 entregar.
{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
    [Test]
    procedure TestCurrentTimestamp;
{$ENDIF}
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestRound;
var
  LAsString: String;
begin
  LAsString := 'SELECT ROUND(PRECO, 2) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.Round('PRECO', 2)
                                      .From('PRODUTOS')
                                      .AsString);
end;
{$ENDIF}

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestFloor;
var
  LAsString: String;
begin
  LAsString := 'SELECT FLOOR(PRECO) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.Floor('PRECO')
                                      .From('PRODUTOS')
                                      .AsString);
end;
{$ENDIF}

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestCeil;
var
  LAsString: String;
begin
  LAsString := 'SELECT CEIL(PRECO) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.Ceil('PRECO')
                                      .From('PRODUTOS')
                                      .AsString);
end;
{$ENDIF}

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestAbs;
var
  LAsString: String;
begin
  LAsString := 'SELECT ABS(VALOR) FROM LANCAMENTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.Abs('VALOR')
                                      .From('LANCAMENTOS')
                                      .AsString);
end;
{$ENDIF}

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestModulus;
var
  LAsString: String;
begin
  LAsString := 'SELECT (VALOR % 2) FROM LANCAMENTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.Modulus('VALOR', '2')
                                      .From('LANCAMENTOS')
                                      .AsString);
end;
{$ENDIF}

{$IFDEF T5_COLUMN_MATH_FUNCTIONS}
procedure TTestFluentSQLFunctionsMySQL.TestCurrentTimestamp;
var
  LAsString: String;
begin
  LAsString := 'SELECT NOW()';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .Column.CurrentTimestamp
                                      .AsString);
end;
{$ENDIF}

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsMySQL);

end.
