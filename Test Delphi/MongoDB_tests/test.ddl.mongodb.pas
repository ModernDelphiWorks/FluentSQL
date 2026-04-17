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
    [Test]
    procedure TestRenameCollection_GeneratesExpected;
    [Test]
    procedure TestTruncateCollection_GeneratesExpected;
    [Test]
    procedure TestCreateCollection_EmptyName_RaisesError;
    [Test]
    procedure TestDropCollection_EmptyName_RaisesError;
    [Test]
    procedure TestCreateIndex_EmptyNames_RaisesError;
    [Test]
    procedure TestDropIndex_EmptyNames_RaisesError;
    [Test]
    procedure TestRenameCollection_EmptyNames_RaisesError;
    [Test]
    procedure TestTruncateCollection_EmptyName_RaisesError;
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

procedure TTestDDLMongoDB.TestRenameCollection_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB).Table('old_customers').Rename('new_customers').AsString;
  Assert.AreEqual('{"renameCollection":"old_customers","to":"new_customers"}', LResult);
end;

procedure TTestDDLMongoDB.TestTruncateCollection_GeneratesExpected;
var
  LResult: string;
begin
  LResult := FluentSQL.Schema(dbnMongoDB).TruncateTable('customers').AsString;
  Assert.AreEqual('{"delete":"customers","deletes":[{"q":{},"limit":0}]}', LResult);
end;

procedure TTestDDLMongoDB.TestCreateCollection_EmptyName_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).Table('').Create.AsString;
    end,
    EArgumentException
  );
end;

procedure TTestDDLMongoDB.TestDropCollection_EmptyName_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).Table(' ').Drop.AsString;
    end,
    EArgumentException
  );
end;

procedure TTestDDLMongoDB.TestCreateIndex_EmptyNames_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).CreateIndex('', 'customers').Column('col').AsString;
    end,
    EArgumentException
  );
end;

procedure TTestDDLMongoDB.TestDropIndex_EmptyNames_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).DropIndex('idx').OnTable('').AsString;
    end,
    EArgumentException
  );
end;

procedure TTestDDLMongoDB.TestRenameCollection_EmptyNames_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).Table('old').Rename('').AsString;
    end,
    EArgumentException
  );
end;

procedure TTestDDLMongoDB.TestTruncateCollection_EmptyName_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMongoDB).TruncateTable('').AsString;
    end,
    EArgumentException
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLMongoDB);

end.
