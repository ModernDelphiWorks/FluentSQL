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

    // Estes seis usam Assert.AreEqual(string, string), que e CASE-INSENSITIVE por
    // default no DUnitX (DUnitX.Assert.pas:1294-1296 delega a fIgnoreCaseDefault,
    // inicializado true em :1366-1369). Logo cobrem ESTRUTURA e SEMANTICA do
    // operador (LIKE vs NOT LIKE, valor parametrizado), nao a caixa. Passam hoje.
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

    // A caixa do operador exige comparacao case-sensitive explicita. Estes dois
    // sao os unicos que caem com o defeito de caixa -- e por isso os unicos [Ignore].
    [Test]
    [Ignore('T6: o operador LIKE e emitido em minusculo (NOME like :p1).')]
    procedure TestLikeFull_CaseSensitive_EmitsUppercaseLIKE;
    [Test]
    [Ignore('T6: o operador NOT LIKE e emitido em minusculo (NOME not like :p1).')]
    procedure TestNotLikeFull_CaseSensitive_EmitsUppercaseNOTLIKE;

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

procedure TTestFluentSQLOperatorsLike.TestLikeFull_CaseSensitive_EmitsUppercaseLIKE;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME LIKE :p1)';
  // ignoreCase = False: unico assert da suite que trava a CAIXA do operador.
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').LikeFull('VALUE')
                                 .AsString, False);
end;

procedure TTestFluentSQLOperatorsLike.TestNotLikeFull_CaseSensitive_EmitsUppercaseNOTLIKE;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME NOT LIKE :p1)';
  Assert.AreEqual(LAsString, FluentSQL.Query(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotLikeFull('VALUE')
                                 .AsString, False);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsLike);

end.
