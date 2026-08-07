unit test.select.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSelectDB2 = class
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
    procedure TestSelectPagingDB2;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL,
  FluentSQL.Functions;

procedure TTestFluentSQLSelectDB2.Setup;
begin
end;

procedure TTestFluentSQLSelectDB2.TearDown;
begin
end;

procedure TTestFluentSQLSelectDB2.TestSelectAll;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES AS CLI';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectAllWhere;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectAllWhereAndAnd;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND (ID >= 10) AND (ID <= 20)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .AndOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectAllWhereAndOr;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID_CLIENTE = 1) AND ((ID >= 10) OR (ID <= 20))';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .All
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AndOpe('ID').GreaterEqThan(10)
                                      .OrOpe('ID').LessEqThan(20)
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectColumns;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
                                      .Select
                                      .Column('ID_CLIENTE')
                                      .Column('NOME_CLIENTE')
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLSelectDB2.TestSelectColumnsCase;
var
  LAsString: String;
begin
  LAsString := 'SELECT ID_CLIENTE, NOME_CLIENTE, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ELSE ''PRODUTOR'' END) AS TIPO_PESSOA FROM CLIENTES';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnDB2)
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

procedure TTestFluentSQLSelectDB2.TestSelectPagingDB2;
var
  LAsString: String;
begin
  // ESTE TESTE CONTINUA VERMELHO, E DE PROPOSITO - mesmo tratamento dado ao
  // TestSelectPagingOracle de Oracle_tests\test.select.Oracle.pas, e pelo mesmo
  // motivo. Ele e um dos 23 vermelhos pre-existentes deste projeto: espera
  // "ORDER BY ID_CLIENTE" e o framework emite "ORDER BY ID_CLIENTE ASC", assert
  // da era pre-parametrizacao. Corrigir isso e decisao de convencao do dono.
  //
  // (O nome diz DB2 mas a consulta e montada com dbnMSSQL - a divergencia entre
  // nome e dialeto ja existia e nao foi tocada aqui.)
  //
  // O QUE A T10 MUDOU: so a FORMA da paginacao, ROW_NUMBER() -> OFFSET/FETCH.
  // Sem atualizar esta linha o teste passaria a falhar por DOIS motivos e o
  // vermelho pre-existente deixaria de ser rastreavel; com ela, o unico motivo
  // que resta e o de sempre, o ASC.
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnMSSQL)
                                      .Select
                                      .All
                                      .First(3).Skip(3)
                                      .From('CLIENTES')
                                      .OrderBy('ID_CLIENTE')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSelectDB2);

end.
