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
  // T12 - BREAKING. Ate eb48337 este teste afirmava
  // 'SELECT * FROM CLIENTES AS CLI', e passava. O SQL que ele afirmava nao roda
  // na Oracle: medido em Oracle Free 23.9, "SELECT * FROM A AS AP" devolve
  // ORA-03048 ("SQL reserved word 'AS' is not syntactically valid following
  // 'SELECT * FROM A '"). Ver Test Delphi\Common_tests\test.alias.oracle.sql.
  //
  // O apelido de COLUNA nao mudou e continua com AS - ver TestSelectColumnsCase
  // logo abaixo, que segue afirmando ') AS TIPO_PESSOA'.
  //
  // O False fecha a comparacao para caixa: sem ele o DUnitX aceitaria 'as cli'.
  LAsString := 'SELECT * FROM CLIENTES CLI';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
                                      .Select
                                      .All
                                      .From('CLIENTES').Alias('CLI')
                                      .AsString, False);
end;

procedure TTestFluentSQLSelectOracle.TestSelectAllOrderBy;
var
  LAsString: String;
begin
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
  // ESTE TESTE CONTINUA VERMELHO, E DE PROPOSITO. Ele e um dos 8 vermelhos
  // pre-existentes deste projeto, todos da era pre-parametrizacao: espera
  // "ORDER BY ID_CLIENTE" e o framework emite "ORDER BY ID_CLIENTE ASC". Corrigir
  // isso e decisao de convencao do dono, nao da T10.
  //
  // O QUE A T10 MUDOU AQUI: so a FORMA da paginacao, de ROWNUM/ROWINI para
  // row_limiting_clause. Sem esta linha o teste passaria a falhar por DOIS
  // motivos e a ficar afirmando um SQL que o driver nao emite mais - o vermelho
  // pre-existente deixaria de ser rastreavel. Com ela, o unico motivo que resta
  // e o de sempre: o ASC.
  LAsString := 'SELECT * FROM CLIENTES ORDER BY ID_CLIENTE OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnOracle)
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
