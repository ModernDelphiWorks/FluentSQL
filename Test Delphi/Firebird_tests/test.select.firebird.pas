unit test.select.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSelect = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSelectAll;
    [Test]
    procedure TestSelectAllNoSQL;
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
    procedure TestSelectPagingFirebird;
    [Test]
    procedure TestSelectPagingFirebirdDistinct;
    [Test]
    procedure TestSelectPagingOracle;
    [Test]
    procedure TestSelectPagingMySQL;
//    [Test]
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

procedure TTestFluentSQLSelect.Setup;
begin
end;

procedure TTestFluentSQLSelect.TearDown;
begin
end;

procedure TTestFluentSQLSelect.Test2SelectPagingMSSQL;
var
  LAsString: String;
begin
  // Metodo com [Test] COMENTADO - nao roda. A string foi atualizada para a forma
  // OFFSET/FETCH da T10 assim mesmo, para que a reativacao (T11) nao herde uma
  // expectativa que descreve um SQL que o driver nao emite mais.
  LAsString := 'SELECT ID_CLIENTE FROM CLIENTES AS C ORDER BY ID_CLIENTE ASC '+
               'OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                              .Select
                              .Column('ID_CLIENTE')
                              .Skip(0).First(3)
                              .From('CLIENTES', 'C')
                              .OrderBy('ID_CLIENTE')
                              .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAll;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES AS CLI';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAllNoSQL;
var
  LAsString: String;
begin
  LAsString := '{"find":"CLIENTES","filter":{},"projection":{}}';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMongoDB)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAllWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAllWhereAndAnd;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND (ID >= :p1) AND (ID <= :p2)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .AndOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectAllWhereAndOr;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND ((ID >= :p1) OR (ID <= :p2))';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .OrOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectColumns;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectColumnsCase;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ELSE ''PRODUTOR'' END) AS TIPO_PESSOA FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
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

procedure TTestFluentSQLSelect.TestSelectPagingFirebird;
var
  LAsString: String;
begin
  LAsString := 'SELECT FIRST 3 SKIP 0 * FROM CLIENTES AS CLI ORDER BY CLI.ID_CLIENTE ASC';
  TFluentSQL.SetDatabaseDafault(dbnFirebird);
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .First(3).Skip(0)
                                 .From('CLIENTES', 'CLI')
                                 .OrderBy('CLI.ID_CLIENTE')
                                 .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectPagingFirebirdDistinct;
var
  LAsString: String;
begin
  // A ordem esperada mudou na T10, e quem a mudou foi o MOTOR, nao o gosto:
  // "SELECT DISTINCT FIRST 3 SKIP 0 ..." - exatamente o que este teste
  // congelava - e RECUSADO pelo Firebird 5.0.4 com
  //   -SQL error code = -104 / -Token unknown - line 1, column 23
  // A gramatica e SELECT [FIRST m] [SKIP n] [{DISTINCT | ALL}] <columns>.
  // Medicao: Test Delphi\Common_tests\test.pagination.firebird.sql, caso V1.
  LAsString := 'SELECT FIRST 3 SKIP 0 DISTINCT CLI.ID_CLIENTE FROM CLIENTES AS CLI ORDER BY CLI.ID_CLIENTE ASC';
  TFluentSQL.SetDatabaseDafault(dbnFirebird);
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .Distinct
                                 .Column('CLI.ID_CLIENTE')
                                 .First(3).Skip(0)
                                 .From('CLIENTES', 'CLI')
                                 .OrderBy('CLI.ID_CLIENTE')
                                 .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectPagingMSSQL;
var
  LAsString: String;
begin
  // T10: ROW_NUMBER() em subconsulta -> OFFSET/FETCH. Skip(3).First(3) e a
  // segunda pagina de 3, e o OFFSET/FETCH a exprime direto, sem embrulho.
  // Medicao: Test Delphi\Common_tests\test.pagination.mssql.sql, caso 03.
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .First(3).Skip(3)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectPagingMySQL;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC LIMIT 3 OFFSET 0';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMySQL)
                                      .Select
                                      .All
                                      .First(3).Skip(0)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelect.TestSelectPagingOracle;
var
  LAsString: String;
begin
  // T10: encadeamento ROWNUM/ROWINI -> row_limiting_clause. Skip(0) e um pedido
  // legitimo e sai como "OFFSET 0 ROWS", nao some.
  // Medicao: Test Delphi\Common_tests\test.pagination.oracle.sql.
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE ASC OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
                                      .Select
                                      .All
                                      .First(3).Skip(0)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSelect);

end.

