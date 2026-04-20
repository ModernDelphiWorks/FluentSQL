unit test.functions.postgresql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsPostgreSQL = class
  public
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
    [Test]
    procedure TestCurrentTimestamp;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLFunctionsPostgreSQL.TestRound;
var
  LAsString: String;
begin
  LAsString := 'SELECT ROUND(PRECO, 2) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.Round('PRECO', 2)
                                      .From('PRODUTOS')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsPostgreSQL.TestFloor;
var
  LAsString: String;
begin
  LAsString := 'SELECT FLOOR(PRECO) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.Floor('PRECO')
                                      .From('PRODUTOS')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsPostgreSQL.TestCeil;
var
  LAsString: String;
begin
  LAsString := 'SELECT CEIL(PRECO) FROM PRODUTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.Ceil('PRECO')
                                      .From('PRODUTOS')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsPostgreSQL.TestAbs;
var
  LAsString: String;
begin
  LAsString := 'SELECT ABS(VALOR) FROM LANCAMENTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.Abs('VALOR')
                                      .From('LANCAMENTOS')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsPostgreSQL.TestModulus;
var
  LAsString: String;
begin
  LAsString := 'SELECT MOD(VALOR, 2) FROM LANCAMENTOS';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.Modulus('VALOR', '2')
                                      .From('LANCAMENTOS')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsPostgreSQL.TestCurrentTimestamp;
var
  LAsString: String;
begin
  LAsString := 'SELECT CURRENT_TIMESTAMP';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnPostgreSQL)
                                      .Select
                                      .Column.CurrentTimestamp
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsPostgreSQL);

end.
