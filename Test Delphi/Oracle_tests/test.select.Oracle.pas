unit test.select.Oracle;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSelectOracle = class
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
    procedure TestSelectPagingOracle;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL,
  FluentSQL.Functions;

procedure TTestFluentSQLSelectOracle.Setup;
begin
end;

procedure TTestFluentSQLSelectOracle.TearDown;
begin
end;

procedure TTestFluentSQLSelectOracle.TestSelectAll;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES AS CLI';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectAllWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectAllWhereAndAnd;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND (ID >= 10) AND (ID <= 20)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .AndOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectAllWhereAndOr;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND ((ID >= 10) OR (ID <= 20))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .OrOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectColumns;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelectOracle.TestSelectColumnsCase;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ELSE ''PRODUTOR'' END) AS TIPO_PESSOA FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
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

procedure TTestFluentSQLSelectOracle.TestSelectPagingOracle;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM (SELECT * FROM CLIENTES ORDER BY ID_CLIENTE) T) WHERE ROWNUM <= 3 AND ROWINI > 0';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnOracle)
                                      .Select
                                      .All
                                      .First(3).Skip(0)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSelectOracle);

end.
