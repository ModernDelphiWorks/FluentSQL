unit test.update.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLUpdate = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUpdateFirebird;
    [Test]
    procedure TestUpdateWhereFirebird;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLUpdate.Setup;
begin

end;

procedure TTestFluentSQLUpdate.TearDown;
begin

end;

procedure TTestFluentSQLUpdate.TestUpdateFirebird;
var
  LAsString: String;
  LDate: TDate;
  LDateTime: TDateTime;
begin
  LAsString := 'UPDATE CLIENTES SET ID_CLIENTE = :p1, NOME_CLIENTE = :p2, DATA_CADASTRO = :p3, DATA_ALTERACAO = :p4';
  LDate := EncodeDate(2021, 12, 31);
  LDateTime := EncodeDate(2021, 12, 31)+EncodeTime(23, 59, 59, 0);
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Update('CLIENTES')
                                      .SetValue('ID_CLIENTE', '1')
                                      .SetValue('NOME_CLIENTE', 'MyName')
                                      .SetValue('DATA_CADASTRO', LDate)
                                      .SetValue('DATA_ALTERACAO', LDateTime)
                                      .AsString);
end;

procedure TTestFluentSQLUpdate.TestUpdateWhereFirebird;
var
  LAsString: String;
begin
  LAsString := 'UPDATE CLIENTES SET ID_CLIENTE = :p1, NOME_CLIENTE = :p2 WHERE ID_CLIENTE = 1';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                      .Update('CLIENTES')
                                      .SetValue('ID_CLIENTE', 1)
                                      .SetValue('NOME_CLIENTE', 'MyName')
                                      .Where('ID_CLIENTE = 1')
                                      .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLUpdate);

end.
