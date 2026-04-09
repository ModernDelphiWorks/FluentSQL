unit test.operators.equal.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLOperatorsEqual = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestEqualIntegerField;
    [Test]
    procedure TestEqualFloatField;
    [Test]
    procedure TestEqualStringField;
    [Test]
    procedure TestEqualDateField;
    [Test]
    procedure TestEqualDateTimeField;
    [Test]
    procedure TestNotEqualIntegerField;
    [Test]
    procedure TestNotEqualFloatField;
    [Test]
    procedure TestNotEqualStringField;
    [Test]
    procedure TestNotEqualDateField;
    [Test]
    procedure TestNotEqualDateTimeField;
   end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestFluentSQLOperatorsEqual.Setup;
begin

end;

procedure TTestFluentSQLOperatorsEqual.TearDown;
begin

end;


procedure TTestFluentSQLOperatorsEqual.TestEqualDateField;
var
  LAsString : String;
  LDate: TDate;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DATA_CADASTRO = ''12/31/2021'')';
  LDate := EncodeDate(2021, 12, 31);
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('DATA_CADASTRO').Equal(LDate)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestEqualDateTimeField;
var
  LAsString : String;
  LDateTime: TDateTime;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DATA_CADASTRO = ''12/31/2021 23:59:59'')';
  LDateTime := EncodeDate(2021, 12, 31)+EncodeTime(23, 59, 59, 0);
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('DATA_CADASTRO').Equal(LDateTime)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestEqualFloatField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR = 10.9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').Equal(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestEqualIntegerField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR = 10)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').Equal(10)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestEqualStringField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME = ''VALUE'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').Equal('''VALUE''')
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestNotEqualDateField;
var
  LAsString : String;
  LDate: TDate;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DATA_CADASTRO <> ''12/31/2021'')';
  LDate := EncodeDate(2021, 12, 31);
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('DATA_CADASTRO').NotEqual(LDate)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestNotEqualDateTimeField;
var
  LAsString : String;
  LDateTime: TDateTime;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (DATA_CADASTRO <> ''12/31/2021 23:59:59'')';
  LDateTime := EncodeDate(2021, 12, 31)+EncodeTime(23, 59, 59, 0);
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('DATA_CADASTRO').NotEqual(LDateTime)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestNotEqualFloatField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR <> 10.9)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').NotEqual(10.9)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestNotEqualIntegerField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (VALOR <> 10)';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('VALOR').NotEqual(10)
                                 .AsString);
end;

procedure TTestFluentSQLOperatorsEqual.TestNotEqualStringField;
var
  LAsString : String;
begin
  LAsString := 'SELECT * FROM CLIENTES WHERE (NOME <> ''VALUE'')';
  Assert.AreEqual(LAsString, CreateFluentSQL(dbnFirebird)
                                 .Select
                                 .All
                                 .From('CLIENTES')
                                 .Where('NOME').NotEqual('''VALUE''')
                                 .AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLOperatorsEqual);

end.
