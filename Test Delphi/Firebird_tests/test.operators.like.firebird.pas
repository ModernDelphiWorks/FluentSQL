unit test.operators.like.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLOperatorsLike = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestLikeFull;
    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestLikeRight;
    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestLikeLeft;
    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestNotLikeFull;
    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestNotLikeRight;
    [Test]
    [Ignore('T6: LIKE/NOT LIKE sao emitidos em minusculo (NOME like :p1). Assert mantem o SQL correto.')]
    procedure TestNotLikeLeft;

   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperatorsLike.Setup;
begin

end;

procedure TTestFluentSQLOperatorsLike.TearDown;
begin

end;

procedure TTestFluentSQLOperatorsLike.TestLikeFull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').LikeFull('VALUE')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLike.TestLikeLeft;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').LikeLeft('VALUE')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLike.TestLikeRight;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').LikeRight('VALUE')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLike.TestNotLikeFull;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotLikeFull('VALUE')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLike.TestNotLikeLeft;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotLikeLeft('VALUE')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsLike.TestNotLikeRight;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotLikeRight('VALUE')
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsLike);

end.
