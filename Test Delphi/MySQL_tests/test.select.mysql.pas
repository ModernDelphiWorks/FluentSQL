unit test.select.mysql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSelectMySQL = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSelectAll;
    [Test]
    procedure TestSelectAllWhere;
    [Test]
    procedure TestSelectAllWhereAndOr;
    [Test]
    procedure TestSelectAllWhereAndAnd;
    [Test]
    procedure TestSelectAllOrderBy;
    [Test]
    procedure TestSelectColumns;
    [Test]
    procedure TestSelectColumnsCase;
    [Test]
    procedure TestSelectPagingMySQL;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL,
  FluentSQL.Functions;

procedure TTestFluentSQLSelectMySQL.Setup;
begin
end;

procedure TTestFluentSQLSelectMySQL.TearDown;
begin
end;

procedure TTestFluentSQLSelectMySQL.TestSelectAll;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES AS CLI';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectAllWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectAllWhereAndAnd;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND (ID >= ?) AND (ID <= ?)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .AndOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectAllWhereAndOr;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND ((ID >= ?) OR (ID <= ?))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .OrOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectColumns;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectColumnsCase;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ELSE ''PRODUTOR'' END) AS TIPO_PESSOA FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .Column('TIPO_CLIENTE')
                                      .CaseExpr
                                        .When('0').IfThen(TFluentSQLFunctions.QFunc('FISICA'))
                                        .When('1').IfThen(TFluentSQLFunctions.QFunc('JURIDICA'))
                                                  .ElseIf('''PRODUTOR''')
                                      .EndCase
                                      .Alias('TIPO_PESSOA')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMySQL.TestSelectPagingMySQL;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC LIMIT 3 OFFSET 0';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnMySQL)
                                      .Select
                                      .All
                                      .First(3)
                                      .Skip(0)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSelectMySQL);

end.
