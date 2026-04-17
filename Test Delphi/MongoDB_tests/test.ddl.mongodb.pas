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
    [Test]
    procedure TestCreateIndex_SingleColumn_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Compound_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Unique_GeneratesExpected;
    [Test]
    procedure TestDropIndex_GeneratesExpected;
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

procedure TTestDDLMongoDB.TestCreateIndex_SingleColumn_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB)
    .CreateIndex('idx_email', 'customers')
    .Column('email')
    .AsString;
  Assert.AreEqual('{"createIndexes":"customers","indexes":[{"key":{"email":1},"name":"idx_email"}]}', LResult);
end;

procedure TTestDDLMongoDB.TestCreateIndex_Compound_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB)
    .CreateIndex('idx_name_age', 'customers')
    .Column('name')
    .Column('age')
    .AsString;
  Assert.AreEqual('{"createIndexes":"customers","indexes":[{"key":{"name":1,"age":1},"name":"idx_name_age"}]}', LResult);
end;

procedure TTestDDLMongoDB.TestCreateIndex_Unique_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB)
    .CreateIndex('idx_unique_code', 'products')
    .Column('code')
    .Unique
    .AsString;
  Assert.AreEqual('{"createIndexes":"products","indexes":[{"key":{"code":1},"name":"idx_unique_code","unique":true}]}', LResult);
end;

procedure TTestDDLMongoDB.TestDropIndex_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB)
    .DropIndex('idx_email')
    .OnTable('customers')
    .AsString;
  Assert.AreEqual('{"dropIndexes":"customers","index":"idx_email"}', LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLMongoDB);

end.
