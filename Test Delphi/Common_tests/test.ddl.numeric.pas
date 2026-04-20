unit test.ddl.numeric;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLNumeric = class
  public
    [Test]
    procedure TestCreateTable_PostgreSQL_Numeric_GeneratesExpected;
    [Test]
    procedure TestCreateTable_Firebird_Numeric_GeneratesExpected;
    [Test]
    procedure TestCreateTable_MySQL_Decimal_GeneratesExpected;
    [Test]
    procedure TestCreateTable_MSSQL_Numeric_GeneratesExpected;
    [Test]
    procedure TestCreateTable_SQLite_Numeric_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddNumeric_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterNumeric_MySQL_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLNumeric }

procedure TTestDDLNumeric.TestCreateTable_PostgreSQL_Numeric_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PRODUTOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnNumeric('PRECO', 10, 2)
    .ColumnNumeric('PESO', 8)
    .ColumnNumeric('INDICE')
    .AsString;
  Assert.AreEqual('CREATE TABLE "PRODUTOS" ("ID" INTEGER PRIMARY KEY, "PRECO" NUMERIC(10,2), "PESO" NUMERIC(8), "INDICE" NUMERIC)', LSql);
end;

procedure TTestDDLNumeric.TestCreateTable_Firebird_Numeric_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('PRODUTOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnNumeric('PRECO', 12, 4)
    .AsString;
  Assert.AreEqual('CREATE TABLE "PRODUTOS" ("ID" INTEGER PRIMARY KEY, "PRECO" NUMERIC(12,4))', LSql);
end;

procedure TTestDDLNumeric.TestCreateTable_MySQL_Decimal_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('PRODUTOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnDecimal('PRECO', 10, 2)
    .AsString;
  Assert.AreEqual('CREATE TABLE `PRODUTOS` (`ID` INT PRIMARY KEY, `PRECO` DECIMAL(10,2))', LSql);
end;

procedure TTestDDLNumeric.TestCreateTable_MSSQL_Numeric_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('PRODUTOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnNumeric('PRECO', 18, 2)
    .AsString;
  Assert.AreEqual('CREATE TABLE [PRODUTOS] ([ID] INT PRIMARY KEY, [PRECO] NUMERIC(18,2))', LSql);
end;

procedure TTestDDLNumeric.TestCreateTable_SQLite_Numeric_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('PRODUTOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnNumeric('PRECO', 10, 2)
    .AsString;
  Assert.AreEqual('CREATE TABLE `PRODUTOS` (`ID` INTEGER PRIMARY KEY, `PRECO` NUMERIC(10,2))', LSql);
end;

procedure TTestDDLNumeric.TestAlterTableAddNumeric_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Add
    .ColumnNumeric('DESCONTO', 5, 2)
    .AsString;
  Assert.AreEqual('ALTER TABLE "PEDIDOS" ADD "DESCONTO" NUMERIC(5,2)', LSql);
end;

procedure TTestDDLNumeric.TestAlterTableAlterNumeric_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  // ESP-073 Requirement: propagation of precision/scale in ALTER COLUMN
  LSql := FluentSQL.Schema(dbnMySQL).Table('PEDIDOS').Alter
    .Column('DESCONTO').TypeNumeric(10, 2)
    .AsString;
  Assert.AreEqual('ALTER TABLE `PEDIDOS` MODIFY COLUMN `DESCONTO` DECIMAL(10,2) NULL', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLNumeric);

end.
