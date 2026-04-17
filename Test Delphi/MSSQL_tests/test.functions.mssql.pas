unit test.functions.mssql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLFunctionsMSSQL = class
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

procedure TTestFluentSQLFunctionsMSSQL.Setup;
begin

end;

procedure TTestFluentSQLFunctionsMSSQL.TearDown;
begin

end;

procedure TTestFluentSQLFunctionsMSSQL.TestUpper;
var
  LAsString: String;
begin
  LAsString := 'SELECT UPPER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('NOME_CLIENTE').Upper
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestYearSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT YEAR(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column.Year('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestYearWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (YEAR(NASCTO) = :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Year('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestMin;
var
  LAsString: String;
begin
  LAsString := 'SELECT MIN(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('ID_CLIENTE').Min
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestMonthWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (MONTH(NASCTO) = :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Month('NASCTO').Equal('9')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestMonthSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT MONTH(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column.Month('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestSubString;
var
  LAsString: String;
begin
  LAsString := 'SELECT SUBString(NOME_CLIENTE, 1, 2) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('NOME_CLIENTE').SubString(1, 2)
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestLower;
var
  LAsString: String;
begin
  LAsString := 'SELECT LOWER(NOME_CLIENTE) AS NOME FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('NOME_CLIENTE').Lower
                                      .Alias('NOME')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestMax;
var
  LAsString: String;
begin
  LAsString := 'SELECT MAX(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('ID_CLIENTE').Max
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestConcatSelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT CONCAT(''-'', NOME) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestConcatWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT CONCAT(''-'', NOME) FROM CLIENTES WHERE (CONCAT(''-'', NOME) = :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                 .Select
                                 .Column.Concat(['''-''', 'NOME'])
                                 .From('CLIENTES')
                                 .Where.Concat(['''-''', 'NOME']).Equal('''-NOME''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestCount;
var
  LAsString: String;
begin
  LAsString := 'SELECT COUNT(ID_CLIENTE) AS IDCOUNT FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('ID_CLIENTE').Count
                                      .Alias('IDCOUNT')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestDate;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NASCTO = :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.Date('NASCTO').Equal('''02/11/2020''')
                                 .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestDaySelect;
var
  LAsString: String;
begin
  LAsString := 'SELECT DAY(NASCTO) FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column.Day('NASCTO')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLFunctionsMSSQL.TestDayWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DAY(NASCTO) = :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where.Day('NASCTO').Equal('9')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFunctionsMSSQL);

end.
