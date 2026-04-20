unit test.select.mssql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSelectMSSQL = class
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
    procedure TestSelectPagingMSSQL;
//    [Test]
    procedure Test2SelectPagingMSSQL;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL,
  FluentSQL.Functions;

procedure TTestFluentSQLSelectMSSQL.Setup;
begin
end;

procedure TTestFluentSQLSelectMSSQL.TearDown;
begin
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectAll;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES AS CLI';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectAllWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectAllWhereAndAnd;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND (ID >= :p1) AND (ID <= :p2)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .AndOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectAllWhereAndOr;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND ((ID >= :p1) OR (ID <= :p2))';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .OrOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectColumns;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.TestSelectColumnsCase;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ELSE ''PRODUTOR'' END) AS TIPO_PESSOA FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
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

procedure TTestFluentSQLSelectMSSQL.TestSelectPagingMSSQL;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS ROWNUMBER FROM CLIENTES) AS CLIENTES WHERE (ROWNUMBER > 3 AND ROWNUMBER <= 6) ORDER BY ID_CLIENTE ASC';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .First(3)
                                      .Skip(3)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelectMSSQL.Test2SelectPagingMSSQL;
var
  LAsString: String;
begin
  LAsString := 'SELECT * '+
               'FROM (SELECT ID_CLIENTE, '+
               'ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS ROWNUMBER '+
               'FROM CLIENTES AS C) AS CLIENTES '+
               'WHERE (ROWNUMBER > 0 AND ROWNUMBER <= 3) '+
               'ORDER BY ID_CLIENTE';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                              .Select
                              .Column('ID_CLIENTE')
                              .Skip(0)
                              .First(3)
                              .From('CLIENTES', 'C')
                              .OrderBy('ID_CLIENTE')
                              .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSelectMSSQL);

end.
