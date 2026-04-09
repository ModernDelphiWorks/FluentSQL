unit test.functions.mysql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsMySQL = class
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

procedure TTestFluentSQLFunctionsMySQL.Setup;
begin

end;

procedure TTestFluentSQLFunctionsMySQL.TearDown;
begin

end;

procedure TTestFluentSQLFunctionsMySQL.TestUpper;
var
  LAsString: String;
begin
  LAsString := 'SELECT UPPER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('NOME_CLIENTE').Upper
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestYearSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT YEAR(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column.Year('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestYearWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (YEAR(NASCTO) = ?)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Year('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestMin;
var
  LAsString: String;
begin
  LAsString := 'SELECT MIN(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('ID_CLIENTE').Min
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestMonthWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (MONTH(NASCTO) = ?)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Month('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestMonthSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT MONTH(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column.Month('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestSubString;
var
  LAsString: String;
begin
  LAsString := 'SELECT SUBString(NOME_CLIENTE, 1, 2) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('NOME_CLIENTE').SubString(1, 2)
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestLower;
var
  LAsString: String;
begin
  LAsString := 'SELECT LOWER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('NOME_CLIENTE').Lower
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestMax;
var
  LAsString: String;
begin
  LAsString := 'SELECT MAX(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('ID_CLIENTE').Max
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestConcatSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT CONCAT(''-'', NOME) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestConcatWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT CONCAT(''-'', NOME) FROM CLIENTES WHERE (CONCAT(''-'', NOME) = ?)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .Where.Concat(['''-''', 'NOME']).Equal('''-NOME''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestCount;
var
  LAsString: String;
begin
  LAsString := 'SELECT COUNT(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('ID_CLIENTE').Count
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestDate;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE DATE_FORMAT(NASCTO, ''yyyy-MM-dd'') = DATE_FORMAT(''2020/11/02'', ''yyyy-MM-dd'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('DATE_FORMAT(NASCTO, ''yyyy-MM-dd'') = DATE_FORMAT(''2020/11/02'', ''yyyy-MM-dd'')')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestDaySelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT DAY(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column.Day('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMySQL.TestDayWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DAY(NASCTO) = ?)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Day('NASCTO').Equal('9')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsMySQL);

end.
