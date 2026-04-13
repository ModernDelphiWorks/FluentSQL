unit test.operators.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLOperators = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWhereIsNull;
    [Test]
    procedure TestOrIsNull;
    [Test]
    procedure TestAndIsNull;

    [Test]
    procedure TestWhereIsNotNull;
    [Test]
    procedure TestOrIsNotNull;
    [Test]
    procedure TestAndIsNotNull;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperators.Setup;
begin

end;

procedure TTestFluentSQLOperators.TearDown;
begin

end;

procedure TTestFluentSQLOperators.TestAndIsNotNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (1 = 1) AND (NOME IS NOT NULL)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('1 = 1')
                                 .AndOpe('NOME').IsNotNull
                                 .AsString);
end;

procedure TTestFluentSQLOperators.TestAndIsNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (1 = 1) AND (NOME IS NULL)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('1 = 1')
                                 .AndOpe('NOME').IsNull
                                 .AsString);
end;

procedure TTestFluentSQLOperators.TestOrIsNotNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ((1 = 1) OR (NOME IS NOT NULL))';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('1 = 1')
                                 .OrOpe('NOME').IsNotNull
                                 .AsString);
end;

procedure TTestFluentSQLOperators.TestOrIsNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE ((1 = 1) OR (NOME IS NULL))';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('1 = 1')
                                 .OrOpe('NOME').IsNull
                                 .AsString);
end;

procedure TTestFluentSQLOperators.TestWhereIsNotNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME IS NOT NULL)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').IsNotNull
                                 .AsString);
end;

procedure TTestFluentSQLOperators.TestWhereIsNull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME IS NULL)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').IsNull
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperators);

end.
