unit test.insert.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLInsert = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInsertFirebird;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLInsert.Setup;
begin

end;

procedure TTestFluentSQLInsert.TearDown;
begin

end;

procedure TTestFluentSQLInsert.TestInsertFirebird;
var
  LAsString: String;
begin
  LAsString := 'INSERT INTO CLIENTES (ID_CLIENTE, NOME_CLIENTE) VALUES (1, ''MyName'')';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Insert
                                      .Into('CLIENTES')
                                      .SetValue('ID_CLIENTE', 1)
                                      .SetValue('NOME_CLIENTE', 'MyName')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLInsert);

end.
