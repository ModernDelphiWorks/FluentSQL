unit test.functions.oracle;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsOracle = class
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

procedure TTestFluentSQLFunctionsOracle.Setup;
begin

end;

procedure TTestFluentSQLFunctionsOracle.TearDown;
begin

end;

procedure TTestFluentSQLFunctionsOracle.TestUpper;
var
  LAsString: String;
begin
  LAsString := 'SELECT UPPER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('NOME_CLIENTE').Upper
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestYearSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(YEAR FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column.Year('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestYearWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(YEAR FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Year('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestMin;
var
  LAsString: String;
begin
  LAsString := 'SELECT MIN(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('ID_CLIENTE').Min
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestMonthWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(MONTH FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Month('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestMonthSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(MONTH FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column.Month('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestSubString;
var
  LAsString: String;
begin
  LAsString := 'SELECT SUBSTR(NOME_CLIENTE, 1, 2) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('NOME_CLIENTE').SubString(1, 2)
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestLower;
var
  LAsString: String;
begin
  LAsString := 'SELECT LOWER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('NOME_CLIENTE').Lower
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestMax;
var
  LAsString: String;
begin
  LAsString := 'SELECT MAX(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('ID_CLIENTE').Max
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestConcatSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestConcatWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES WHERE (''-'' || NOME = ''-NOME'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                 .Select
                                 .Column.Concat(['''-''','NOME'])
                                 .From('CLIENTES')
                                 .Where.Concat(['''-''', 'NOME']).Equal('''-NOME''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestCount;
var
  LAsString: String;
begin
  LAsString := 'SELECT COUNT(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('ID_CLIENTE').Count
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestDate;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE TO_DATE(NASCTO, ''dd/MM/yyyy'') = TO_DATE(''02/11/2020'', ''dd/MM/yyyy'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.Date('NASCTO').Equal.Date('''02/11/2020''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestDaySelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(DAY FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column.Day('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsOracle.TestDayWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(DAY FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Day('NASCTO').Equal('9')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsOracle);

end.
