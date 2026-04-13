unit test.functions.db2;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsDB2 = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCount;
    [Test]
    procedure TestLower;
    [Test]
    procedure TestUpper;
    [Test]
    procedure TestMax;
    [Test]
    procedure TestMin;
    [Test]
    procedure TestSubString;
    [Test]
    procedure TestMonthWhere;
    [Test]
    procedure TestMonthSelect;
    [Test]
    procedure TestDayWhere;
    [Test]
    procedure TestDaySelect;
    [Test]
    procedure TestYearWhere;
    [Test]
    procedure TestYearSelect;
    [Test]
    procedure TestDate;
    [Test]
    procedure TestConcatSelect;
    [Test]
    procedure TestConcatWhere;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLFunctionsDB2.Setup;
begin

end;

procedure TTestFluentSQLFunctionsDB2.TearDown;
begin

end;

procedure TTestFluentSQLFunctionsDB2.TestUpper;
var
  LAsString: String;
begin
  LAsString := 'SELECT UPPER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('NOME_CLIENTE').Upper
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestYearSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(YEAR FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column.Year('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestYearWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(YEAR FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Year('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestMin;
var
  LAsString: String;
begin
  LAsString := 'SELECT MIN(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('ID_CLIENTE').Min
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestMonthWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(MONTH FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Month('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestMonthSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(MONTH FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column.Month('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestSubString;
var
  LAsString: String;
begin
  LAsString := 'SELECT SUBString(NOME_CLIENTE FROM 1 FOR 2) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('NOME_CLIENTE').SubString(1, 2)
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestLower;
var
  LAsString: String;
begin
  LAsString := 'SELECT LOWER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('NOME_CLIENTE').Lower
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestMax;
var
  LAsString: String;
begin
  LAsString := 'SELECT MAX(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('ID_CLIENTE').Max
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestConcatSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestConcatWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES WHERE (''-'' || NOME = ''-NOME'')';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .Where.Concat(['''-''', 'NOME']).Equal('''-NOME''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestCount;
var
  LAsString: String;
begin
  LAsString := 'SELECT COUNT(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('ID_CLIENTE').Count
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestDate;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE TO_DATE(NASCTO, ''dd/MM/yyyy'') = TO_DATE(''02/11/2020'', ''dd/MM/yyyy'')';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.Date('NASCTO').Equal.Date('''02/11/2020''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestDaySelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(DAY FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column.Day('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsDB2.TestDayWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(DAY FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Day('NASCTO').Equal('9')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsDB2);

end.
