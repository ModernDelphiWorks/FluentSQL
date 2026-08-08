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
  // T10: ROW_NUMBER() em subconsulta -> OFFSET/FETCH, a forma canonica do
  // SQL Server 2012+. Medida em Test Delphi\Common_tests\test.pagination.mssql.sql.
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY';
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
  // Metodo com [Test] COMENTADO (linha 33) - nao roda. A string foi atualizada
  // para a forma OFFSET/FETCH da T10 assim mesmo, para que a reativacao (T11)
  // nao herde uma expectativa que descreve um SQL que o driver nao emite mais.
  LAsString := 'SELECT ID_CLIENTE FROM CLIENTES AS C ORDER BY ID_CLIENTE ASC '+
               'OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY';
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
