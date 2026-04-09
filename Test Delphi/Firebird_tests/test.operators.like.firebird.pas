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
    procedure TestLikeFull;
    [Test]
    procedure TestLikeRight;
    [Test]
    procedure TestLikeLeft;
    [Test]
    procedure TestNotLikeFull;
    [Test]
    procedure TestNotLikeRight;
    [Test]
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE ''%VALUE%'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE ''%VALUE'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE ''VALUE%'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE ''%VALUE%'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE ''%VALUE'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
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
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE ''VALUE%'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotLikeRight('VALUE')
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsLike);

end.
