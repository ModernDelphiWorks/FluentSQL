unit test.delete.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLDelete = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDeleteFirebird;
    [Test]
    procedure TestDeleteWhereFirebird;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLDelete.Setup;
begin

end;

procedure TTestFluentSQLDelete.TearDown;
begin

end;

procedure TTestFluentSQLDelete.TestDeleteFirebird;
var
  LAsString: String;
begin
  LAsString := 'DELETE FROM CLIENTES';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                      .Delete
                                      .From('CLIENTES')
                                      .AsString);
end;

procedure TTestFluentSQLDelete.TestDeleteWhereFirebird;
var
  LAsString: String;
begin
  LAsString := 'DELETE FROM CLIENTES WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                      .Delete
                                      .From('CLIENTES')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLDelete);

end.
