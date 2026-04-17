unit test.dml.mongodb;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDMLMongoDB = class
  public
    [Test]
    procedure TestSimpleGroup_GeneratesAggregate;
    [Test]
    procedure TestGroupWithCount_GeneratesAggregate;
    [Test]
    procedure TestGroupWithMultipleAggregates_GeneratesAggregate;
    [Test]
    procedure TestAggregateWithoutGroup_GeneratesGroupWithIdNull;
    [Test]
    procedure TestAggregateWithWhere_GeneratesMatchBeforeGroup;
    [Test]
    procedure TestAggregateWithHaving_GeneratesMatchAfterGroup;
    [Test]
    procedure TestFullAnalyticalQuery_GeneratesCompletePipeline;
    [Test]
    procedure TestMultipleGroupFields_GeneratesObjectId;
    [Test]
    procedure TestPaginationWithAggregate_GeneratesSkipLimitStages;
    [Test]
    procedure TestInnerJoin_GeneratesLookupAndUnwind;
    [Test]
    procedure TestLeftJoin_GeneratesLookupAndUnwindWithPreserveNulls;
    [Test]
    procedure TestMultipleJoins_GeneratesMultipleLookupStages;
    [Test]
    procedure TestChainedJoin_PreservesAliasInLocalField;
    [Test]
    procedure TestSimpleSelectRegression_ReturnsFindCommand;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDMLMongoDB }

procedure TTestDMLMongoDB.TestSimpleGroup_GeneratesAggregate;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('city')
    .From('users')
    .GroupBy('city')
    .AsString;

  Assert.Contains(LResult, '"aggregate":"users"');
  Assert.Contains(LResult, '"$group":{"_id":"$city"');
end;

procedure TTestDMLMongoDB.TestGroupWithCount_GeneratesAggregate;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('city')
    .Select('id').Count.Alias('total')
    .From('users')
    .GroupBy('city')
    .AsString;

  Assert.Contains(LResult, '"$group":{"_id":"$city","total":{"$sum":1}}');
end;

procedure TTestDMLMongoDB.TestGroupWithMultipleAggregates_GeneratesAggregate;
var
  LSQL: IFluentSQL;
  LResult: string;
begin
  LSQL := CreateFluentSQL(dbnMongoDB);
  LResult := LSQL
    .Select('department')
    .Column(LSQL.AsFun.Sum('salary')).Alias('total_salary')
    .Column(LSQL.AsFun.Average('salary')).Alias('avg_salary')
    .Column('salary').Min.Alias('min_salary')
    .Column('salary').Max.Alias('max_salary')
    .From('employees')
    .GroupBy('department')
    .AsString;

  Assert.Contains(LResult, '"total_salary":{"$sum":"$salary"}');
  Assert.Contains(LResult, '"avg_salary":{"$avg":"$salary"}');
  Assert.Contains(LResult, '"min_salary":{"$min":"$salary"}');
  Assert.Contains(LResult, '"max_salary":{"$max":"$salary"}');
end;

procedure TTestDMLMongoDB.TestAggregateWithoutGroup_GeneratesGroupWithIdNull;
var
  LSQL: IFluentSQL;
  LResult: string;
begin
  LSQL := CreateFluentSQL(dbnMongoDB);
  LResult := LSQL
    .Select(LSQL.AsFun.Sum('total')).Alias('grand_total')
    .From('orders')
    .AsString;

  Assert.Contains(LResult, '"$group":{"_id":null,"grand_total":{"$sum":"$total"}}');
end;

procedure TTestDMLMongoDB.TestAggregateWithWhere_GeneratesMatchBeforeGroup;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('category')
    .Select('*').Count.Alias('qty')
    .From('products')
    .Where('status').Equal('active')
    .GroupBy('category')
    .AsString;

  // Pipeline order: match, group
  Assert.Contains(LResult, '"pipeline":[{"$match":{"status":"active"}},{"$group"');
end;

procedure TTestDMLMongoDB.TestAggregateWithHaving_GeneratesMatchAfterGroup;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('category')
    .Select('*').Count.Alias('qty')
    .From('products')
    .GroupBy('category')
    .Having('qty').GreaterThan(10)
    .AsString;

  // Pipeline order: group, match (having)
  Assert.Contains(LResult, '{"$group"');
  Assert.Contains(LResult, '{"$match":{"qty":{"$gt":10}}}');
end;

procedure TTestDMLMongoDB.TestFullAnalyticalQuery_GeneratesCompletePipeline;
var
  LSQL: IFluentSQL;
  LResult: string;
begin
  LSQL := CreateFluentSQL(dbnMongoDB);
  LResult := LSQL
    .Select('store_id')
    .Select(LSQL.AsFun.Sum('total')).Alias('revenue')
    .From('sales')
    .Where('date').GreaterEqThan('2026-01-01')
    .GroupBy('store_id')
    .Having('revenue').GreaterEqThan(5000)
    .OrderBy('revenue').Desc
    .AsString;

  Assert.Contains(LResult, '"$match":{"date":{"$gte":"2026-01-01"}}');
  Assert.Contains(LResult, '"$group":{"_id":"$store_id","revenue":{"$sum":"$total"}}');
  Assert.Contains(LResult, '"$match":{"revenue":{"$gte":5000}}');
  Assert.Contains(LResult, '"$sort":{"revenue":-1}');
end;

procedure TTestDMLMongoDB.TestMultipleGroupFields_GeneratesObjectId;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('year')
    .Select('month')
    .Select('*').Count.Alias('total')
    .From('reports')
    .GroupBy('year')
    .GroupBy('month')
    .AsString;

  Assert.Contains(LResult, '"$group":{"_id":{"year":"$year","month":"$month"}');
end;

procedure TTestDMLMongoDB.TestPaginationWithAggregate_GeneratesSkipLimitStages;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('id')
    .Select('*').Count.Alias('c')
    .From('items')
    .GroupBy('id')
    .Skip(10)
    .First(5)
    .AsString;

  Assert.Contains(LResult, '{"$skip":10}');
  Assert.Contains(LResult, '{"$limit":5}');
end;

procedure TTestDMLMongoDB.TestInnerJoin_GeneratesLookupAndUnwind;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('o.id')
    .Select('u.name')
    .From('orders', 'o')
    .InnerJoin('users', 'u').OnCond('o.userId = u.id')
    .AsString;

  Assert.Contains(LResult, '"aggregate":"orders"');
  Assert.Contains(LResult, '"$lookup":{"from":"users","localField":"userId","foreignField":"id","as":"u"}');
  Assert.Contains(LResult, '"$unwind":{"path":"$u","preserveNullAndEmptyArrays":false}');
  Assert.Contains(LResult, '"$project":{"id":1,"name":"$u.name","_id":0}');
end;

procedure TTestDMLMongoDB.TestLeftJoin_GeneratesLookupAndUnwindWithPreserveNulls;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('p.name')
    .Select('c.title')
    .From('products', 'p')
    .LeftJoin('categories', 'c').OnCond('p.categoryId = c.id')
    .AsString;

  Assert.Contains(LResult, '"$unwind":{"path":"$c","preserveNullAndEmptyArrays":true}');
end;

procedure TTestDMLMongoDB.TestMultipleJoins_GeneratesMultipleLookupStages;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('o.id')
    .Select('u.name')
    .Select('p.name').Alias('product_name')
    .From('orders', 'o')
    .InnerJoin('users', 'u').OnCond('o.userId = u.id')
    .InnerJoin('products', 'p').OnCond('o.productId = p.id')
    .AsString;

  Assert.Contains(LResult, '"$lookup":{"from":"users"');
  Assert.Contains(LResult, '"$lookup":{"from":"products"');
  Assert.Contains(LResult, '"$project":{"id":1,"name":"$u.name","product_name":"$p.name","_id":0}');
end;

procedure TTestDMLMongoDB.TestChainedJoin_PreservesAliasInLocalField;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('o.id')
    .Select('p.name')
    .From('orders', 'o')
    .InnerJoin('users', 'u').OnCond('o.userId = u.id')
    .InnerJoin('profiles', 'p').OnCond('u.profileId = p.id')
    .AsString;

  // First join localField: userId (stripped 'o.')
  Assert.Contains(LResult, '"$lookup":{"from":"users","localField":"userId","foreignField":"id","as":"u"}');
  // Second join localField: u.profileId (preserved 'u.')
  Assert.Contains(LResult, '"$lookup":{"from":"profiles","localField":"u.profileId","foreignField":"id","as":"p"}');
end;

procedure TTestDMLMongoDB.TestSimpleSelectRegression_ReturnsFindCommand;
var
  LResult: string;
begin
  LResult := CreateFluentSQL(dbnMongoDB)
    .Select('name')
    .From('users')
    .Where('id').Equal(1)
    .AsString;

  Assert.Contains(LResult, '"find":"users"');
  Assert.Contains(LResult, '"filter":{"id":1}');
  Assert.Contains(LResult, '"projection":{"name":1}');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDMLMongoDB);

end.
