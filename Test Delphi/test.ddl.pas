unit test.ddl;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLCreateTable = class
  public
    [Test]
    procedure TestCreateTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateTable_WithConstraints_GeneratesExpected;
    [Test]
    procedure TestLongTextAndBlob_DivergeBetweenFirebirdAndPostgreSQL;
    [Test]
    procedure TestGuidType_GeneratesExpectedPerDialect;
    [Test]
    procedure TestDateDefault_Firebird_GeneratesExpected;
  end;

  [TestFixture]
  TTestDDLConstraints = class
  public
    [Test]
    procedure TestCompositePrimaryKey_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCompositeUnique_Firebird_GeneratesExpected;
    [Test]
    procedure TestNamedInlineConstraints_MSSQL_GeneratesExpected;
    [Test]
    procedure TestNamedCheckConstraint_SQLite_GeneratesExpected;
    [Test]
    procedure TestTableLevelCheck_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestPrimaryKeyDuplicity_RaisesException;
    [Test]
    procedure TestNamedConstraint_AlterTableAdd_MSSQL_GeneratesExpected;
  end;

  [TestFixture]
  TTestDDLComputedColumns = class
  public
    [Test]
    procedure TestComputedColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_MySQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_SQLite_RaisesNotSupported;
    [Test]
    procedure TestComputedBy_AlterTableAdd_GeneratesExpected;
    [Test]
    procedure TestComputedAndDefault_AreMutuallyExclusive_RaisesException;
  end;

  [TestFixture]
  TTestDDLDropTable = class
  public
    [Test]
    procedure TestDropTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_Firebird_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLAlterTableAddColumn = class
  public
    [Test]
    procedure TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_WithReferences_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_SecondColumn_RaisesArgumentException;
    [Test]
    procedure TestAlterTableAddColumn_UnsupportedDialect_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLAlterTableDropColumn = class
  public
    [Test]
    procedure TestAlterTableDropColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_SecondDropColumn_RaisesArgumentException;
    [Test]
    procedure TestAlterTableDropColumn_UnsupportedDialect_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLAlterTableRenameColumn = class
  public
    [Test]
    procedure TestAlterTableRenameColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_TrimsIdentifiersInOutput;
    [Test]
    procedure TestAlterTableRenameColumn_EmptyTableName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameColumn_EmptyOldName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameColumn_EmptyNewName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameColumn_SameOldAndNew_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameColumn_TrimmedEqualNames_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameColumn_UnsupportedDialect_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLAlterTableRenameTable = class
  public
    [Test]
    procedure TestAlterTableRenameTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_SQLite_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_EmptyOldName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameTable_EmptyNewName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableRenameTable_SameOldAndNew_RaisesArgumentException;
  end;

  [TestFixture]
  TTestDDLCreateIndex = class
  public
    [Test]
    procedure TestCreateIndex_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Firebird_Unique_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MultiColumn_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_NoColumns_RaisesArgumentException;
    [Test]
    procedure TestCreateIndex_EmptyIndexName_RaisesArgumentException;
    [Test]
    procedure TestCreateIndex_EmptyTableName_RaisesArgumentException;
    [Test]
    procedure TestCreateIndex_EmptyColumnName_RaisesArgumentException;
    [Test]
    procedure TestCreateIndex_SecondUnique_RaisesArgumentException;
    [Test]
    procedure TestCreateIndex_UnsupportedDialect_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLDropIndex = class
  public
    [Test]
    procedure TestDropIndex_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndex_Firebird_IfExists_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_IfExists_Concurrently_SameOutput;
    [Test]
    procedure TestDropIndex_Firebird_Concurrently_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_Firebird_Concurrently_MessageReferencesESP027;
    [Test]
    procedure TestDropIndex_UnsupportedDialect_Concurrently_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_EmptyIndexName_RaisesArgumentException;
    [Test]
    procedure TestDropIndex_MySQL_WithoutOnTable_RaisesArgumentException;
    [Test]
    procedure TestDropIndex_MySQL_WithoutOnTable_MessageReferencesESP028;
    [Test]
    procedure TestDropIndex_MySQL_OnTable_GeneratesExpected;
    [Test]
    procedure TestDropIndex_MySQL_OnTable_IfExists_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_MySQL_OnTable_IfExists_MessageReferencesESP028;
    [Test]
    procedure TestDropIndex_Firebird_OnTable_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_PostgreSQL_OnTable_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_UnsupportedDialect_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLTruncateTable = class
  public
    [Test]
    procedure TestTruncateTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_RestartIdentity_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_Cascade_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_RestartIdentityAndCascade_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_CascadeThenRestartIdentity_SameOutput;
    [Test]
    procedure TestTruncateTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_Firebird_RestartIdentity_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Firebird_Cascade_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_MySQL_RestartIdentity_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_MySQL_Cascade_RaisesNotSupported;
    procedure TestTruncateTable_Firebird_Modifier_MessageReferencesESP029;
    [Test]
    procedure TestTruncateTable_UnsupportedDialect_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_EmptyTableName_RaisesArgumentException;
  end;

  [TestFixture]
  TTestDDLAlterTableAlterColumn = class
  public
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_Type_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_Nullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_Type_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_Nullability_RaisesNotSupported;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_TypeAndNullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_TypeAndNullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_SQLite_RaisesNotSupported;
    [Test]
    procedure TestAlterTableAlterColumn_EmptyTableName_RaisesArgumentException;
    [Test]
    procedure TestAlterTableAlterColumn_NoChanges_RaisesArgumentException;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_OnlyNullability_RaisesArgumentException;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_OnlyNullability_RaisesArgumentException;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_DropDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_DropDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_DropDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_DropDefault_RaisesNotSupported;
  end;

  [TestFixture]
  TTestDDLAlterTableConstraints = class
  public
    [Test]
    procedure TestAlterTableAddPrimaryKey_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddUnique_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddForeignKey_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddCheck_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropConstraint_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropConstraint_MySQL_PrimaryKey_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddConstraint_SQLite_RaisesNotSupported;
    [Test]
    procedure TestAlterTableDropConstraint_SQLite_RaisesNotSupported;
  end;
  
  [TestFixture]
  TTestDDLViews = class
  public
    [Test]
    procedure TestCreateView_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_OrReplace_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateView_OrReplace_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateView_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_SQLite_GeneratesExpected;
    [Test]
    procedure TestDropView_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropView_IfExists_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropView_EmptyName_RaisesArgumentException;
    [Test]
    procedure TestCreateView_NoQuery_RaisesArgumentException;
  end;

  [TestFixture]
  TTestDDLSQLite = class
  public
    [Test]
    procedure TestCreateTable_SQLite_GeneratesExpected;
    [Test]
    procedure TestDropTable_SQLite_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_SQLite_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_SQLite_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_SQLite_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_SQLite_GeneratesExpected;
    [Test]
    procedure TestDropIndex_SQLite_GeneratesExpected;
    [Test]
    procedure TestDropIndexIfExists_SQLite_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_SQLite_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_SQLite_GeneratesDeleteFrom;
    [Test]
    procedure TestCreateIndex_SQLite_MultiColumn_GeneratesExpected;
  end;

  [TestFixture]
  TTestDDLMySQL = class
  public
    [Test]
    procedure TestCreateIndex_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MySQL_Unique_GeneratesExpected;
  end;

  [TestFixture]
  TTestDDLMSSQL = class
  public
    [Test]
    procedure TestCreateTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndex_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndexIfExists_MSSQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestReservedWords_MSSQL;
    [Test]
    procedure TestBooleanDefault_MSSQL;
    [Test]
    procedure TestDateAndGuidDefault_MSSQL;
  end;

  [TestFixture]
  TTestDDLIdentityScope = class
  public
    [Test]
    procedure TestIdentity_PostgreSQL_Always_GeneratesExpected;
    [Test]
    procedure TestIdentity_PostgreSQL_ByDefault_GeneratesExpected;
    [Test]
    procedure TestIdentity_Firebird_Always_GeneratesExpected;
    [Test]
    procedure TestIdentity_Firebird_ByDefault_GeneratesExpected;
    [Test]
    procedure TestIdentity_MSSQL_MapsBothToNative;
    [Test]
    procedure TestIdentity_SQLite_MapsBothToNative;
    [Test]
    procedure TestIdentity_AlterTableAlter_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestIdentity_AlterTableAlter_Firebird_GeneratesExpected;
    [Test]
    procedure TestIdentity_Oracle_Always_GeneratesExpected;
    [Test]
    procedure TestIdentity_Oracle_ByDefault_GeneratesExpected;
    [Test]
    procedure TestIdentity_AlterTableAlter_Oracle_GeneratesExpected;
  end;


implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLComputedColumns }

procedure TTestDDLComputedColumns.TestComputedColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, "TOTAL" INTEGER COMPUTED BY (QTD * PRECO))', LSql);
end;

procedure TTestDDLComputedColumns.TestComputedColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, "TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PRECO) STORED)', LSql);
end;

procedure TTestDDLComputedColumns.TestComputedColumn_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE `VENDAS` (`ID` INT, `QTD` INT, `PRECO` INT, `TOTAL` INT AS (QTD * PRECO) VIRTUAL)', LSql);
end;

procedure TTestDDLComputedColumns.TestComputedColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT, [TOTAL] INT AS (QTD * PRECO))', LSql);
end;

procedure TTestDDLComputedColumns.TestComputedColumn_SQLite_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).Table('T').Create.ColumnInteger('A').ComputedBy('1').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLComputedColumns.TestComputedBy_AlterTableAdd_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VENDAS').Add
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "VENDAS" ADD "TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PRECO) STORED', LSql);
end;

procedure TTestDDLComputedColumns.TestComputedAndDefault_AreMutuallyExclusive_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Create
        .ColumnInteger('A').DefaultValue('0').ComputedBy('1')
        .AsString;
    end,
    EArgumentException);
end;

{ TTestDDLAlterTableAlterColumn }

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_PostgreSQL_Type_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Alter.Column('IDADE')
    .TypeInteger
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER COLUMN "IDADE" TYPE INTEGER', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_PostgreSQL_Nullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Alter.Column('NOME')
    .NotNull
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER COLUMN "NOME" SET NOT NULL', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_Firebird_Type_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Alter.Column('IDADE')
    .TypeInteger
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER "IDADE" TYPE INTEGER', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_Firebird_Nullability_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Alter.Column('NOME').NotNull.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MySQL_TypeAndNullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('clientes').Alter.Column('nome')
    .TypeVarchar(100)
    .NotNull
    .AsString;
  Assert.AreEqual('ALTER TABLE `clientes` MODIFY COLUMN `nome` VARCHAR(100) NOT NULL', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MSSQL_TypeAndNullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Alter.Column('NOME')
    .TypeVarchar(100)
    .Nullable
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] ALTER COLUMN [NOME] VARCHAR(100) NULL', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_SQLite_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).Table('T').Alter.Column('C').TypeInteger.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('').Alter.Column('C').TypeInteger.AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_NoChanges_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Alter.Column('C').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MySQL_OnlyNullability_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).Table('T').Alter.Column('C').NotNull.AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MSSQL_OnlyNullability_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).Table('T').Alter.Column('C').Nullable.AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_PostgreSQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER COLUMN "TOTAL" SET DEFAULT 0', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_PostgreSQL_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER COLUMN "TOTAL" DROP DEFAULT', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_Firebird_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER "TOTAL" SET DEFAULT 0', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_Firebird_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER "TOTAL" DROP DEFAULT', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MySQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE `VALORES` ALTER COLUMN `TOTAL` SET DEFAULT 0', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MySQL_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE `VALORES` ALTER COLUMN `TOTAL` DROP DEFAULT', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MSSQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE [VALORES] ADD DEFAULT 0 FOR [TOTAL]', LSql);
end;

procedure TTestDDLAlterTableAlterColumn.TestAlterTableAlterColumn_MSSQL_DropDefault_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).Table('T').Alter.Column('C').DropDefault.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLCreateTable.TestCreateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE "CLIENTES" ("ID" INTEGER, "NOME" VARCHAR(100), "ATIVO" BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE "CLIENTES" ("ID" INTEGER, "NOME" VARCHAR(100), "ATIVO" BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE `CLIENTES` (`ID` INT, `NOME` VARCHAR(100), `ATIVO` BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_WithConstraints_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('USUARIOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnVarChar('EMAIL', 255).Unique
    .ColumnInteger('IDADE').Check('IDADE > 0')
    .ColumnVarChar('STATUS', 20).DefaultValue('''ACTIVE''')
    .ColumnInteger('PERFIL_ID').References('PERFIS', 'ID')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE "USUARIOS" ("ID" INTEGER PRIMARY KEY, "NOME" VARCHAR(100) NOT NULL, "EMAIL" VARCHAR(255) UNIQUE, "IDADE" INTEGER CHECK (IDADE > 0), "STATUS" VARCHAR(20) DEFAULT ''ACTIVE'', "PERFIL_ID" INTEGER REFERENCES "PERFIS"("ID"))',
    LSql);
end;

procedure TTestDDLCreateTable.TestLongTextAndBlob_DivergeBetweenFirebirdAndPostgreSQL;
var
  LFirebirdSql, LPostgreSql: string;
begin
  LFirebirdSql := FluentSQL.Schema(dbnFirebird).Table('DOC').Create
    .ColumnLongText('BODY')
    .ColumnBlob('RAW')
    .AsString;
  LPostgreSql := FluentSQL.Schema(dbnPostgreSQL).Table('DOC').Create
    .ColumnLongText('BODY')
    .ColumnBlob('RAW')
    .AsString;

  Assert.AreNotEqual(LFirebirdSql, LPostgreSql);
  Assert.IsTrue(Pos('BLOB SUB_TYPE 1', LFirebirdSql) > 0);
  Assert.IsTrue(Pos('BLOB SUB_TYPE 0', LFirebirdSql) > 0);
  Assert.IsTrue(Pos('TEXT', LPostgreSql) > 0);
  Assert.IsTrue(Pos('BYTEA', LPostgreSql) > 0);
end;

procedure TTestDDLDropTable.TestDropTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLDropTable.TestDropTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop.IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS "CLIENTES"', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop.IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Add
    .ColumnInteger('NOVO_ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "NOVO_ID" INTEGER', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Add
    .ColumnVarChar('NOME', 80)
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "NOME" VARCHAR(80)', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Add
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "ATIVO" BOOLEAN', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_WithReferences_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('PEDIDOS').Add
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE "PEDIDOS" ADD "CLIENTE_ID" INTEGER REFERENCES "CLIENTES"("ID")', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_SecondColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Add
        .ColumnInteger('A')
        .ColumnInteger('B')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnDB2).Table('T').Add
        .ColumnInteger('C')
        .AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" DROP "LEGADO"', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" DROP COLUMN "LEGADO"', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_SecondDropColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Drop
        .Column('A')
        .Column('B')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnDB2).Table('T').Drop
        .Column('C')
        .AsString;
    end,
    ENotSupportedException);
end;



procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Rename.Column('LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" RENAME COLUMN "LEGADO" TO "NOVO_NOME"', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('pedidos').Rename.Column('status_id', 'status_ref')
    .AsString;
  Assert.AreEqual('ALTER TABLE `pedidos` RENAME COLUMN `status_id` TO `status_ref`', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Rename.Column('LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER "LEGADO" TO "NOVO_NOME"', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_TrimsIdentifiersInOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('  T  ').Rename.Column('  a  ', '  b  ')
    .AsString;
  Assert.AreEqual('ALTER TABLE "T" RENAME COLUMN "a" TO "b"', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('').Rename.Column('A', 'B').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyOldName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Rename.Column('  ', 'B').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyNewName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Rename.Column('A', '').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_SameOldAndNew_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Rename.Column('X', 'X').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_TrimmedEqualNames_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Rename.Column('X', '  X  ').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnDB2).Table('T').Rename.Column('A', 'B').AsString;
    end,
    ENotSupportedException);
end;

{ TTestDDLAlterTableRenameTable }

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" RENAME TO "TAB_B"', LSql);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" TO "TAB_B"', LSql);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE `TAB_A` RENAME TO `TAB_B`', LSql);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE `TAB_A` RENAME TO `TAB_B`', LSql);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('EXEC sp_rename ''TAB_A'', ''TAB_B''', LSql);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_EmptyOldName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('').Rename('B').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_EmptyNewName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('A').Rename('').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameTable.TestAlterTableRenameTable_SameOldAndNew_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('A').Rename('A').AsString;
    end,
    EArgumentException);
end;



procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX "IX_CLI_NOME" ON "CLIENTES" ("NOME")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('UQ_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX "UQ_CLI_EMAIL" ON "CLIENTES" ("EMAIL")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_EVT', 'EVENTS')
    .Column('TENANT_ID')
    .Column('CREATED_AT')
    .AsString;
  Assert.AreEqual('CREATE INDEX "IX_EVT" ON "EVENTS" ("TENANT_ID", "CREATED_AT")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('ix_orders_status', 'orders')
    .Column('status')
    .AsString;
  Assert.AreEqual('CREATE INDEX "ix_orders_status" ON "orders" ("status")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('uq_orders_code', 'orders')
    .Unique
    .Column('code')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX "uq_orders_code" ON "orders" ("code")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('ix_evt', 'events')
    .Column('tenant_id')
    .Column('created_at')
    .AsString;
  Assert.AreEqual('CREATE INDEX "ix_evt" ON "events" ("tenant_id", "created_at")', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_NoColumns_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).CreateIndex('IX_X', 'T').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_EmptyIndexName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).CreateIndex('', 'T')
        .Column('A')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).CreateIndex('IX_X', '')
        .Column('A')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_EmptyColumnName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).CreateIndex('IX_X', 'T')
        .Column('')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_SecondUnique_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).CreateIndex('IX_X', 'T')
        .Unique
        .Unique
        .Column('A')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnDB2).CreateIndex('IX_X', 'T')
        .Column('A')
        .AsString;
    end,
    ENotSupportedException);
end;



procedure TTestDDLDropIndex.TestDropIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').AsString;
  Assert.AreEqual('DROP INDEX "IX_CLI_NOME"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').AsString;
  Assert.AreEqual('DROP INDEX "ix_orders_status"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS "IX_CLI_NOME"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS "ix_orders_status"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY "ix_orders_status"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').Concurrently.IfExists.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS "ix_orders_status"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_Concurrently_SameOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').IfExists.Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS "ix_orders_status"', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_Concurrently_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').Concurrently.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_Concurrently_MessageReferencesESP027;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').Concurrently.AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-027', LMsg) > 0);
end;

procedure TTestDDLDropIndex.TestDropIndex_UnsupportedDialect_Concurrently_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').OnTable('T').Concurrently.AsString;
    end,
    ENotSupportedException);
end;



procedure TTestDDLDropIndex.TestDropIndex_EmptyIndexName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('   ').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_WithoutOnTable_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_WithoutOnTable_MessageReferencesESP028;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').AsString;
  except
    on E: EArgumentException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-028', LMsg) > 0);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_OnTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).DropIndex('ix_orders_status').OnTable('orders').AsString;
  Assert.AreEqual('DROP INDEX `ix_orders_status` ON `orders`', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_OnTable_IfExists_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').OnTable('T').IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_OnTable_IfExists_MessageReferencesESP028;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').OnTable('T').IfExists.AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-028', LMsg) > 0);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_OnTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_OnTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').OnTable('orders').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnOracle).DropIndex('IX_X').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_RestartIdentity_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('logs').RestartIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE "logs" RESTART IDENTITY', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_Cascade_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').Cascade.AsString;
  Assert.AreEqual('TRUNCATE TABLE "orders" CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_RestartIdentityAndCascade_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').RestartIdentity.Cascade.AsString;
  Assert.AreEqual('TRUNCATE TABLE "orders" RESTART IDENTITY CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_CascadeThenRestartIdentity_SameOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').Cascade.RestartIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE "orders" RESTART IDENTITY CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE `CLIENTES`', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_RestartIdentity_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).TruncateTable('T').RestartIdentity.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_Cascade_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).TruncateTable('T').Cascade.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_RestartIdentity_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable('T').RestartIdentity.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_Cascade_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable('T').Cascade.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_Modifier_MessageReferencesESP029;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnFirebird).TruncateTable('T').RestartIdentity.AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-029', LMsg) > 0);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnOracle).TruncateTable('T').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).TruncateTable('   ').AsString;
    end,
    EArgumentException);
end;

{ TTestDDLSQLite }

procedure TTestDDLSQLite.TestCreateTable_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE `CLIENTES` (`ID` INTEGER PRIMARY KEY, `NOME` TEXT NOT NULL, `ATIVO` BOOLEAN)',
    LSql);
end;

procedure TTestDDLSQLite.TestDropTable_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE `CLIENTES`', LSql);
end;

procedure TTestDDLSQLite.TestDropTableIfExists_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Drop.IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS `CLIENTES`', LSql);
end;

procedure TTestDDLSQLite.TestAlterTableAddColumn_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Add
    .ColumnVarChar('EMAIL', 150)
    .AsString;
  Assert.AreEqual('ALTER TABLE `CLIENTES` ADD COLUMN `EMAIL` TEXT', LSql);
end;

procedure TTestDDLSQLite.TestAlterTableRenameColumn_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Rename.Column('NOME', 'RAZAO_SOCIAL')
    .AsString;
  Assert.AreEqual('ALTER TABLE `CLIENTES` RENAME COLUMN `NOME` TO `RAZAO_SOCIAL`', LSql);
end;

procedure TTestDDLSQLite.TestCreateIndex_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX `IX_CLI_NOME` ON `CLIENTES` (`NOME`)', LSql);
end;

procedure TTestDDLSQLite.TestDropIndex_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).DropIndex('IX_CLI_NOME').AsString;
  Assert.AreEqual('DROP INDEX `IX_CLI_NOME`', LSql);
end;

procedure TTestDDLSQLite.TestDropIndexIfExists_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).DropIndex('IX_CLI_NOME').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS `IX_CLI_NOME`', LSql);
end;

procedure TTestDDLSQLite.TestAlterTableRenameTable_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('TAB_OLD').Rename('TAB_NEW').AsString;
  Assert.AreEqual('ALTER TABLE `TAB_OLD` RENAME TO `TAB_NEW`', LSql);
end;

procedure TTestDDLSQLite.TestTruncateTable_SQLite_GeneratesDeleteFrom;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('DELETE FROM `CLIENTES`', LSql);
end;

{ TTestDDLMSSQL }

procedure TTestDDLMSSQL.TestCreateTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .ColumnDateTime('CRIADO_EM')
    .ColumnLongText('BIO')
    .ColumnBlob('FOTO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE [CLIENTES] ([ID] INT, [NOME] VARCHAR(100), [ATIVO] BIT, [CRIADO_EM] DATETIME2, [BIO] VARCHAR(MAX), [FOTO] VARBINARY(MAX))',
    LSql);
end;

procedure TTestDDLMSSQL.TestDropTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestDropTableIfExists_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop.IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableAddColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Add
    .ColumnVarChar('EMAIL', 150)
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] ADD [EMAIL] VARCHAR(150)', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableDropColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] DROP COLUMN [LEGADO]', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableRenameColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Rename.Column('NOME', 'RAZAO_SOCIAL')
    .AsString;
  Assert.AreEqual('EXEC sp_rename ''[CLIENTES].[NOME]'', ''RAZAO_SOCIAL'', ''COLUMN''', LSql);
end;

procedure TTestDDLMSSQL.TestCreateIndex_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX [IX_CLI_NOME] ON [CLIENTES] ([NOME])', LSql);
end;

procedure TTestDDLMSSQL.TestDropIndex_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').AsString;
  Assert.AreEqual('DROP INDEX [IX_CLI_NOME] ON [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestDropIndexIfExists_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS [IX_CLI_NOME] ON [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestReservedWords_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('User').Create
    .ColumnInteger('Order')
    .ColumnVarChar('Table', 10)
    .AsString;
  Assert.AreEqual('CREATE TABLE [User] ([Order] INT, [Table] VARCHAR(10))', LSql);
end;

procedure TTestDDLMSSQL.TestBooleanDefault_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CONFIGS').Create
    .ColumnBoolean('ENABLED').DefaultValue('True')
    .ColumnBoolean('ACTIVE').DefaultValue('False')
    .ColumnBoolean('LEGACY_T').DefaultValue('T')
    .ColumnBoolean('LEGACY_F').DefaultValue('F')
    .AsString;
  Assert.AreEqual('CREATE TABLE [CONFIGS] ([ENABLED] BIT DEFAULT 1, [ACTIVE] BIT DEFAULT 0, [LEGACY_T] BIT DEFAULT 1, [LEGACY_F] BIT DEFAULT 0)', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableRenameTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('OLD_NAME').Rename('NEW_NAME').AsString;
  Assert.AreEqual('EXEC sp_rename ''OLD_NAME'', ''NEW_NAME''', LSql);
end;

procedure TTestDDLMSSQL.TestTruncateTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE [CLIENTES]', LSql);
end;


procedure TTestDDLCreateTable.TestGuidType_GeneratesExpectedPerDialect;
begin
  Assert.AreEqual('CREATE TABLE [T] ([G] UNIQUEIDENTIFIER)', 
    FluentSQL.Schema(dbnMSSQL).Table('T').Create.ColumnGuid('G').AsString);
    
  Assert.AreEqual('CREATE TABLE "T" ("G" CHAR(16) CHARACTER SET OCTETS)', 
    FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnGuid('G').AsString);
    
  Assert.AreEqual('CREATE TABLE "T" ("G" UUID)', 
    FluentSQL.Schema(dbnPostgreSQL).Table('T').Create.ColumnGuid('G').AsString);
    
  Assert.AreEqual('CREATE TABLE `T` (`G` GUID)', 
    FluentSQL.Schema(dbnSQLite).Table('T').Create.ColumnGuid('G').AsString);
    
  Assert.AreEqual('CREATE TABLE `T` (`G` CHAR(36))', 
    FluentSQL.Schema(dbnMySQL).Table('T').Create.ColumnGuid('G').AsString);
end;

procedure TTestDDLCreateTable.TestDateDefault_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  // Firebird uses mm/dd/yyyy in this framework's Utils for historical reasons
  LSql := FluentSQL.Schema(dbnFirebird).Table('T').Create
    .ColumnDate('D').DefaultValue('2024-04-14')
    .AsString;
  Assert.AreEqual('CREATE TABLE "T" ("D" DATE DEFAULT ''04/14/2024'')', LSql);
end;

procedure TTestDDLMSSQL.TestDateAndGuidDefault_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('T').Create
    .ColumnDate('D').DefaultValue('2024-04-14')
    .ColumnGuid('G').DefaultValue('{00000000-0000-0000-0000-000000000000}')
    .AsString;
  Assert.AreEqual('CREATE TABLE [T] ([D] DATE DEFAULT ''2024-04-14'', [G] UNIQUEIDENTIFIER DEFAULT ''{00000000-0000-0000-0000-000000000000}'')', LSql);
end;

{ TTestDDLViews }

procedure TTestDDLViews.TestCreateView_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateView('VW_CLIENTES')
    .&As(FluentSQL.Query(dbnPostgreSQL).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW "VW_CLIENTES" AS SELECT "ID", "NOME" FROM "CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestCreateView_OrReplace_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnPostgreSQL).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR REPLACE VIEW "VW_CLIENTES" AS SELECT "ID", "NOME" FROM "CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestCreateView_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateView('VW_CLIENTES')
    .&As(FluentSQL.Query(dbnFirebird).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW "VW_CLIENTES" AS SELECT "ID", "NOME" FROM "CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestCreateView_OrReplace_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnFirebird).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR ALTER VIEW "VW_CLIENTES" AS SELECT "ID", "NOME" FROM "CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestCreateView_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnMySQL).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR REPLACE VIEW `VW_CLIENTES` AS SELECT `ID`, `NOME` FROM `CLIENTES`', LSql);
end;

procedure TTestDDLViews.TestCreateView_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnMSSQL).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR ALTER VIEW [VW_CLIENTES] AS SELECT [ID], [NOME] FROM [CLIENTES]', LSql);
end;

procedure TTestDDLViews.TestCreateView_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).CreateView('VW_CLIENTES')
    .&As(FluentSQL.Query(dbnSQLite).Select.Column(['ID', 'NOME']).From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW `VW_CLIENTES` AS SELECT `ID`, `NOME` FROM `CLIENTES`', LSql);
end;

procedure TTestDDLViews.TestDropView_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropView('VW_CLIENTES').AsString;
  Assert.AreEqual('DROP VIEW "VW_CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestDropView_IfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropView('VW_CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP VIEW IF EXISTS "VW_CLIENTES"', LSql);
end;

procedure TTestDDLViews.TestDropView_EmptyName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).DropView('').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLViews.TestCreateView_NoQuery_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).CreateView('V').AsString;
    end,
    EArgumentException);
end;

{ TTestDDLConstraints }

procedure TTestDDLConstraints.TestCompositePrimaryKey_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('ITEM_PEDIDO').Create
    .ColumnInteger('PEDIDO_ID')
    .ColumnInteger('ITEM_ID')
    .PrimaryKey(['PEDIDO_ID', 'ITEM_ID'], 'PK_ITEM_PEDIDO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "ITEM_PEDIDO" ("PEDIDO_ID" INTEGER, "ITEM_ID" INTEGER, CONSTRAINT "PK_ITEM_PEDIDO" PRIMARY KEY ("PEDIDO_ID", "ITEM_ID"))', LSql);
end;

procedure TTestDDLConstraints.TestCompositeUnique_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CONTATOS').Create
    .ColumnInteger('CLIENTE_ID')
    .ColumnVarChar('TIPO', 20)
    .Unique(['CLIENTE_ID', 'TIPO'], 'UK_CONTATO_TIPO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "CONTATOS" ("CLIENTE_ID" INTEGER, "TIPO" VARCHAR(20), CONSTRAINT "UK_CONTATO_TIPO" UNIQUE ("CLIENTE_ID", "TIPO"))', LSql);
end;

procedure TTestDDLConstraints.TestNamedInlineConstraints_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('USUARIOS').Create
    .ColumnInteger('ID').PrimaryKey('PK_USUARIOS')
    .ColumnVarChar('EMAIL', 255).Unique('UK_USUARIOS_EMAIL')
    .ColumnInteger('IDADE').Check('IDADE >= 18', 'CK_USUARIOS_IDADE')
    .AsString;
  Assert.AreEqual('CREATE TABLE [USUARIOS] ([ID] INT CONSTRAINT [PK_USUARIOS] PRIMARY KEY, [EMAIL] VARCHAR(255) CONSTRAINT [UK_USUARIOS_EMAIL] UNIQUE, [IDADE] INT CONSTRAINT [CK_USUARIOS_IDADE] CHECK (IDADE >= 18))', LSql);
end;

procedure TTestDDLConstraints.TestNamedCheckConstraint_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('PRODUTOS').Create
    .ColumnInteger('ID')
    .ColumnInteger('PRECO').Check('PRECO > 0', 'CK_PRECO_POSITIVO')
    .AsString;
  // SQLite supports: col TYPE CONSTRAINT name CHECK (...)
  Assert.AreEqual('CREATE TABLE `PRODUTOS` (`ID` INTEGER, `PRECO` INTEGER CONSTRAINT `CK_PRECO_POSITIVO` CHECK (PRECO > 0))', LSql);
end;

procedure TTestDDLConstraints.TestTableLevelCheck_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  // Check literal table-level (without specific column)
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('SALDOS').Create
    .ColumnInteger('DEBITO')
    .ColumnInteger('CREDITO')
    .Check('DEBITO <= CREDITO', 'CK_SALDO_VALIDO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "SALDOS" ("DEBITO" INTEGER, "CREDITO" INTEGER, CONSTRAINT "CK_SALDO_VALIDO" CHECK (DEBITO <= CREDITO))', LSql);
end;

procedure TTestDDLConstraints.TestPrimaryKeyDuplicity_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).Table('T').Create
        .ColumnInteger('ID').PrimaryKey
        .PrimaryKey(['A', 'B']) // Should raise
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLConstraints.TestNamedConstraint_AlterTableAdd_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('USUARIOS').Add
    .ColumnVarChar('LOGIN', 50).Unique('UK_USUARIOS_LOGIN')
    .AsString;
  Assert.AreEqual('ALTER TABLE [USUARIOS] ADD [LOGIN] VARCHAR(50) CONSTRAINT [UK_USUARIOS_LOGIN] UNIQUE', LSql);
end;

procedure TTestDDLSQLite.TestCreateIndex_SQLite_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).CreateIndex('IX_CLI_MULTI', 'CLIENTES')
    .Column('NOME')
    .Column('DATA_NASCIMENTO')
    .AsString;
  Assert.AreEqual('CREATE INDEX `IX_CLI_MULTI` ON `CLIENTES` (`NOME`, `DATA_NASCIMENTO`)', LSql);
end;

{ TTestDDLMySQL }

procedure TTestDDLMySQL.TestCreateIndex_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX `IX_CLI_NOME` ON `CLIENTES` (`NOME`)', LSql);
end;

procedure TTestDDLMySQL.TestCreateIndex_MySQL_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateIndex('UK_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX `UK_CLI_EMAIL` ON `CLIENTES` (`EMAIL`)', LSql);
end;



{ TTestDDLAlterTableConstraints }

procedure TTestDDLAlterTableConstraints.TestAlterTableAddPrimaryKey_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('TAB_A').Add
    .AddPrimaryKey(['COL_1'], 'PK_TAB_A')
    .AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" ADD CONSTRAINT "PK_TAB_A" PRIMARY KEY ("COL_1")', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableAddUnique_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('TAB_A').Add
    .AddUnique(['COL_1', 'COL_2'], 'UK_TAB_A')
    .AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" ADD CONSTRAINT "UK_TAB_A" UNIQUE ("COL_1", "COL_2")', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableAddForeignKey_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('TAB_SALARY').Add
    .AddForeignKey('EMP_ID', 'EMPLOYEES', 'ID', 'FK_SAL_EMP')
    .AsString;
  Assert.AreEqual('ALTER TABLE [TAB_SALARY] ADD CONSTRAINT [FK_SAL_EMP] FOREIGN KEY ([EMP_ID]) REFERENCES [EMPLOYEES]([ID])', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableAddCheck_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('TAB_DATA').Add
    .AddCheck('VAL > 0', 'CK_VAL_POSITIVE')
    .AsString;
  Assert.AreEqual('ALTER TABLE `TAB_DATA` ADD CONSTRAINT `CK_VAL_POSITIVE` CHECK (VAL > 0)', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableDropConstraint_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('TAB_A').Drop
    .Constraint('UK_TAB_A')
    .AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" DROP CONSTRAINT "UK_TAB_A"', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableDropConstraint_MySQL_PrimaryKey_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('TAB_A').Drop
    .Constraint('PRIMARY')
    .AsString;
  Assert.AreEqual('ALTER TABLE `TAB_A` DROP PRIMARY KEY', LSql);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableAddConstraint_SQLite_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).Table('TAB_A').Add.AddCheck('V > 0').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableConstraints.TestAlterTableDropConstraint_SQLite_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).Table('TAB_A').Drop.Constraint('ANY').AsString;
    end,
    ENotSupportedException);
end;

{ TTestDDLIdentityScope }

procedure TTestDDLIdentityScope.TestIdentity_PostgreSQL_Always_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED ALWAYS AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_PostgreSQL_ByDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_Firebird_Always_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED ALWAYS AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_Firebird_ByDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_MSSQL_MapsBothToNative;
var
  LSqlAlways, LSqlByDefault: string;
begin
  LSqlAlways := FluentSQL.Schema(dbnMSSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  LSqlByDefault := FluentSQL.Schema(dbnMSSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;

  Assert.AreEqual('CREATE TABLE [LOGS] ([ID] BIGINT IDENTITY(1,1))', LSqlAlways);
  Assert.AreEqual(LSqlAlways, LSqlByDefault);
end;

procedure TTestDDLIdentityScope.TestIdentity_SQLite_MapsBothToNative;
var
  LSqlAlways, LSqlByDefault: string;
begin
  LSqlAlways := FluentSQL.Schema(dbnSQLite).Table('LOGS').Create
    .ColumnInteger('ID').PrimaryKey.Identity(disAlways)
    .AsString;
  LSqlByDefault := FluentSQL.Schema(dbnSQLite).Table('LOGS').Create
    .ColumnInteger('ID').PrimaryKey.Identity(disByDefault)
    .AsString;

  Assert.AreEqual('CREATE TABLE `LOGS` (`ID` INTEGER PRIMARY KEY AUTOINCREMENT)', LSqlAlways);
  Assert.AreEqual(LSqlAlways, LSqlByDefault);
end;

procedure TTestDDLIdentityScope.TestIdentity_AlterTableAlter_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('LOGS').Alter.Column('ID')
    .Identity(disByDefault)
    .AsString;
  Assert.AreEqual('ALTER TABLE "LOGS" ALTER COLUMN "ID" SET GENERATED BY DEFAULT', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_AlterTableAlter_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Alter.Column('ID')
    .Identity(disAlways)
    .AsString;
  Assert.AreEqual('ALTER TABLE "LOGS" ALTER "ID" SET GENERATED ALWAYS', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_Oracle_Always_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnOracle).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" NUMBER(19) GENERATED ALWAYS AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_Oracle_ByDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnOracle).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" NUMBER(19) GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

procedure TTestDDLIdentityScope.TestIdentity_AlterTableAlter_Oracle_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnOracle).Table('LOGS').Alter.Column('ID')
    .Identity(disByDefault)
    .AsString;
  Assert.AreEqual('ALTER TABLE "LOGS" MODIFY ("ID" GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLCreateTable);
  TDUnitX.RegisterTestFixture(TTestDDLConstraints);
  TDUnitX.RegisterTestFixture(TTestDDLComputedColumns);
  TDUnitX.RegisterTestFixture(TTestDDLDropTable);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableAddColumn);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableDropColumn);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableRenameColumn);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableRenameTable);
  TDUnitX.RegisterTestFixture(TTestDDLCreateIndex);
  TDUnitX.RegisterTestFixture(TTestDDLDropIndex);
  TDUnitX.RegisterTestFixture(TTestDDLTruncateTable);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableAlterColumn);
  TDUnitX.RegisterTestFixture(TTestDDLAlterTableConstraints);
  TDUnitX.RegisterTestFixture(TTestDDLViews);
  TDUnitX.RegisterTestFixture(TTestDDLSQLite);
  TDUnitX.RegisterTestFixture(TTestDDLMySQL);
  TDUnitX.RegisterTestFixture(TTestDDLMSSQL);
  TDUnitX.RegisterTestFixture(TTestDDLIdentityScope);

end.
