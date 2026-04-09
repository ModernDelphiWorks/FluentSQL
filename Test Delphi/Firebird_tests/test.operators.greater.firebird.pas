unit test.operators.greater.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLOperatorsGreater = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGreaterThanFloat;
    [Test]
    procedure TestGreaterThanInteger;
    [Test]
    procedure TestGreaterEqualThanFloat;
    [Test]
    procedure TestGreaterEqualThanInteger;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperatorsGreater.Setup;
begin

end;

procedure TTestFluentSQLOperatorsGreater.TearDown;
begin

end;

procedure TTestFluentSQLOperatorsGreater.TestGreaterEqualThanFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR >= 10.9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').GreaterEqThan(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsGreater.TestGreaterEqualThanInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR >= 10)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').GreaterEqThan(10)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsGreater.TestGreaterThanFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR > 10.9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').GreaterThan(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsGreater.TestGreaterThanInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR > 10)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').GreaterThan(10)
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsGreater);

end.
