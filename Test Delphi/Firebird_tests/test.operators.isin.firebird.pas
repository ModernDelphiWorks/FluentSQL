unit test.operators.isin.firebird;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestFluentSQLOperatorsIN = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInInteger;
    [Test]
    procedure TestInFloat;
    [Test]
    procedure TestInString;
    [Test]
    procedure TestInSubQuery;
    [Test]
    procedure TestNotInInteger;
    [Test]
    procedure TestNotInFloat;
    [Test]
    procedure TestNotInString;
    [Test]
    procedure TestNotInSubQuery;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperatorsIN.Setup;
begin
end;

procedure TTestFluentSQLOperatorsIN.TearDown;
begin
end;


procedure TTestFluentSQLOperatorsIN.TestInFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').InValues([1.5, 2.7, 3])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestInInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').InValues([1, 2, 3])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestInString;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').InValues(['VALUE.1', 'VALUE,2', 'VALUE3'])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestInSubQuery;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID IN (SELECT IDCLIENTE FROM PEDIDOS))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('ID').InValues(CreateFluentSQL(dbnFirebird)
                                                        .Select
                                                        .Column('IDCLIENTE')
                                                        .From('PEDIDOS').AsString)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestNotInFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR NOT IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').NotIn([1.5, 2.7, 3])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestNotInInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR NOT IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').NotIn([1, 2, 3])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestNotInString;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR NOT IN (:p1, :p2, :p3))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').NotIn(['VALUE.1', 'VALUE,2', 'VALUE3'])
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsIN.TestNotInSubQuery;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (ID NOT IN (SELECT IDCLIENTE FROM PEDIDOS))';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('ID').NotIn( CreateFluentSQL(dbnFirebird)
                                                        .Select
                                                        .Column('IDCLIENTE')
                                                        .From('PEDIDOS').AsString)
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsIN);
end.
