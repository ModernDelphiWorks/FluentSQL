unit test.functions.interbase;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsInterbase = class
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

procedure TTestFluentSQLFunctionsInterbase.Setup;
begin

end;

procedure TTestFluentSQLFunctionsInterbase.TearDown;
begin

end;

procedure TTestFluentSQLFunctionsInterbase.TestUpper;
var
  LAsString: String;
begin
  LAsString := 'SELECT UPPER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('NOME_CLIENTE').Upper
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestYearSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(YEAR FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column.Year('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestYearWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(YEAR FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Year('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestMin;
var
  LAsString: String;
begin
  LAsString := 'SELECT MIN(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('ID_CLIENTE').Min
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestMonthWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(MONTH FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Month('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestMonthSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(MONTH FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column.Month('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestSubString;
var
  LAsString: String;
begin
  LAsString := 'SELECT SUBString(NOME_CLIENTE FROM 1 FOR 2) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('NOME_CLIENTE').SubString(1, 2)
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestLower;
var
  LAsString: String;
begin
  LAsString := 'SELECT LOWER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('NOME_CLIENTE').Lower
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestMax;
var
  LAsString: String;
begin
  LAsString := 'SELECT MAX(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('ID_CLIENTE').Max
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestConcatSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestConcatWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT ''-'' || NOME FROM CLIENTES WHERE (''-'' || NOME = ''-NOME'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .Where.Concat(['''-''', 'NOME']).Equal('''-NOME''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestCount;
var
  LAsString: String;
begin
  LAsString := 'SELECT COUNT(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column('ID_CLIENTE').Count
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestDate;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE NASCTO = ''02/11/2020''';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.Date('NASCTO').Equal.Date('''02/11/2020''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestDaySelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT EXTRACT(DAY FROM NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .Column.Day('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsInterbase.TestDayWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXTRACT(DAY FROM NASCTO) = 9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnInterbase)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Day('NASCTO').Equal('9')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsInterbase);

end.
