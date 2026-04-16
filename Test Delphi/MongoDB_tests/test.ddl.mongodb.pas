unit test.ddl.mongodb;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLMongoDB = class
  public
    [Test]
    procedure TestCreateCollection_GeneratesExpected;
    [Test]
    procedure TestDropCollection_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLMongoDB }

procedure TTestDDLMongoDB.TestCreateCollection_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB).Table('customers').Create.AsString;
  Assert.AreEqual('{"create":"customers"}', LResult);
end;

procedure TTestDDLMongoDB.TestDropCollection_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB).Table('customers').Drop.AsString;
  Assert.AreEqual('{"drop":"customers"}', LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLMongoDB);

end.
