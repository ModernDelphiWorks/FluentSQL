unit test.ddl.comments;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLComments = class
  public
    [Test]
    procedure TestComments_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestComments_Firebird_GeneratesExpected;
    [Test]
    procedure TestComments_MySQL_GeneratesExpected;
    [Test]
    procedure TestComments_MSSQL_GeneratesExpected;
    [Test]
    procedure TestComments_AlterTableAdd_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLComments }

procedure TTestDDLComments.TestComments_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateTable('Users')
    .Description('Application users table')
    .ColumnInteger('ID').PrimaryKey.Description('Internal ID')
    .ColumnVarChar('Name', 100).NotNull.Description('Full legal name')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE "Users" ("ID" INTEGER PRIMARY KEY, "Name" VARCHAR(100) NOT NULL); ' +
    'COMMENT ON TABLE "Users" IS ''Application users table''; ' +
    'COMMENT ON COLUMN "Users"."ID" IS ''Internal ID''; ' +
    'COMMENT ON COLUMN "Users"."Name" IS ''Full legal name''',
    LSql);
end;

procedure TTestDDLComments.TestComments_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateTable('Users')
    .Description('Application users table')
    .ColumnInteger('ID').PrimaryKey.Description('Internal ID')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE "Users" ("ID" INTEGER PRIMARY KEY); ' +
    'COMMENT ON TABLE "Users" IS ''Application users table''; ' +
    'COMMENT ON COLUMN "Users"."ID" IS ''Internal ID''',
    LSql);
end;

procedure TTestDDLComments.TestComments_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateTable('Users')
    .Description('Application users table')
    .ColumnInteger('ID').PrimaryKey.Description('Internal ID')
    .ColumnVarChar('Name', 100).Description('Full name')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE `Users` (`ID` INT PRIMARY KEY COMMENT ''Internal ID'', `Name` VARCHAR(100) COMMENT ''Full name'') ' +
    'COMMENT = ''Application users table''',
    LSql);
end;

procedure TTestDDLComments.TestComments_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateTable('Users')
    .Description('App users table')
    .ColumnInteger('ID').Description('Internal ID')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE [Users] ([ID] INT); ' +
    'EXEC sp_addextendedproperty @name = N''MS_Description'', @value = N''App users table'', @level0type = N''SCHEMA'', @level0name = N''dbo'', @level1type = N''TABLE'', @level1name = N''Users''; ' +
    'EXEC sp_addextendedproperty @name = N''MS_Description'', @value = N''Internal ID'', @level0type = N''SCHEMA'', @level0name = N''dbo'', @level1type = N''TABLE'', @level1name = N''Users'', @level2type = N''COLUMN'', @level2name = N''ID''',
    LSql);
end;

procedure TTestDDLComments.TestComments_AlterTableAdd_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).AlterTableAdd('Users')
    .ColumnVarChar('Bio', 500).Description('User biography')
    .AsString;
    
  Assert.AreEqual(
    'ALTER TABLE "Users" ADD "Bio" VARCHAR(500); ' +
    'COMMENT ON COLUMN "Users"."Bio" IS ''User biography''',
    LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLComments);

end.
