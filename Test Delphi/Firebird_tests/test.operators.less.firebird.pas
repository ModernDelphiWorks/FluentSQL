unit test.operators.less.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLOperatorsLess = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLessThanFloat;
    [Test]
    procedure TestLessThanInteger;
    [Test]
    procedure TestLessEqualThanFloat;
    [Test]
    procedure TestLessEqualThanInteger;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperatorsLess.Setup;
begin

end;

procedure TTestFluentSQLOperatorsLess.TearDown;
begin

end;

procedure TTestFluentSQLOperatorsLess.TestLessEqualThanFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR <= 10.9)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').LessEqThan(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLess.TestLessEqualThanInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR <= 10)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').LessEqThan(10)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLess.TestLessThanFloat;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR < 10.9)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').LessThan(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLess.TestLessThanInteger;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR < 10)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').LessThan(10)
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsLess);

end.

