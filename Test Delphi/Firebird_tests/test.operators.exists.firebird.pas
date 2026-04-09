unit test.operators.exists.firebird;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestFluentSQLExists = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestExistsSubQuery;
    [Test]
    procedure TestNotExistsSubQuery;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLExists.Setup;
begin
end;

procedure TTestFluentSQLExists.TearDown;
begin
end;

procedure TTestFluentSQLExists.TestExistsSubQuery;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (EXISTS (SELECT IDCLIENTE FROM PEDIDOS WHERE (PEDIDOS.IDCLIENTE = CLIENTES.IDCLIENTE)))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.Exists( CreateFluentSQL(dbnFirebird)
                                                        .Select
                                                        .Column('IDCLIENTE')
                                                        .From('PEDIDOS')
                                                        .Where('PEDIDOS.IDCLIENTE').Equal('CLIENTES.IDCLIENTE')
                                                        .AsString)
                                 .AsString);
end;

procedure TTestFluentSQLExists.TestNotExistsSubQuery;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOT EXISTS (SELECT IDCLIENTE FROM PEDIDOS WHERE (PEDIDOS.IDCLIENTE = CLIENTES.IDCLIENTE)))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where.NotExists( CreateFluentSQL(dbnFirebird)
                                                        .Select
                                                        .Column('IDCLIENTE')
                                                        .From('PEDIDOS')
                                                        .Where('PEDIDOS.IDCLIENTE').Equal('CLIENTES.IDCLIENTE')
                                                        .AsString)
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLExists);

end.
