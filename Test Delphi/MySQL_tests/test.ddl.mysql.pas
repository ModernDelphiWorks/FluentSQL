unit test.ddl.mysql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLMySQL = class
  public
    [Test]
    procedure TestCreateTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MySQL_Unique_GeneratesExpected;
    [Test]
    procedure TestDropIndex_MySQL_OnTable_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_MultiTable_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_Partition_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_TypeAndNullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MySQL_DropDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddCheck_MySQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropConstraint_MySQL_PrimaryKey_GeneratesExpected;
    [Test]
    procedure TestCreateView_MySQL_GeneratesExpected;
    [Test]
    procedure TestComments_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_MySQL_GeneratesExpected;
    [Test]
    procedure TestDropFunction_MySQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_MultipleActions_MySQL_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLMySQL }

procedure TTestDDLMySQL.TestCreateTable_MySQL_GeneratesExpected;
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

procedure TTestDDLMySQL.TestComputedColumn_MySQL_GeneratesExpected;
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

procedure TTestDDLMySQL.TestAlterTableRenameColumn_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('pedidos').Rename.Column('status_id', 'status_ref')
    .AsString;
  Assert.AreEqual('ALTER TABLE `pedidos` RENAME COLUMN `status_id` TO `status_ref`', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableRenameTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE `TAB_A` RENAME TO `TAB_B`', LSql);
end;

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

procedure TTestDDLMySQL.TestDropIndex_MySQL_OnTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).DropIndex('IX_NOME').OnTable('T').AsString;
  Assert.AreEqual('ALTER TABLE `T` DROP INDEX `IX_NOME`', LSql);
end;

procedure TTestDDLMySQL.TestTruncateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE `CLIENTES`', LSql);
end;

procedure TTestDDLMySQL.TestTruncateTable_MySQL_MultiTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable(['T1', 'T2']).AsString;
  Assert.AreEqual('TRUNCATE TABLE `T1`, `T2`', LSql);
end;

procedure TTestDDLMySQL.TestTruncateTable_MySQL_Partition_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('T1').Partition('p1').AsString;
  Assert.AreEqual('ALTER TABLE `T1` TRUNCATE PARTITION `p1`', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableAlterColumn_MySQL_TypeAndNullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('clientes').Alter.Column('nome')
    .TypeVarchar(100)
    .NotNull
    .AsString;
  Assert.AreEqual('ALTER TABLE `clientes` MODIFY COLUMN `nome` VARCHAR(100) NOT NULL', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableAlterColumn_MySQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE `VALORES` ALTER COLUMN `TOTAL` SET DEFAULT 0', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableAlterColumn_MySQL_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE `VALORES` ALTER COLUMN `TOTAL` DROP DEFAULT', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableAddCheck_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('T').Add
    .Check('A > 0', 'CK_A')
    .AsString;
  Assert.AreEqual('ALTER TABLE `T` ADD CONSTRAINT `CK_A` CHECK (A > 0)', LSql);
end;

procedure TTestDDLMySQL.TestAlterTableDropConstraint_MySQL_PrimaryKey_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('T').Drop.PrimaryKey.AsString;
  Assert.AreEqual('ALTER TABLE `T` DROP PRIMARY KEY', LSql);
end;

procedure TTestDDLMySQL.TestCreateView_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateView('VW_CLI')
    .&As(FluentSQL.Query(dbnMySQL).Select.Column('ID').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW `VW_CLI` AS SELECT ID FROM CLIENTES', LSql);
end;

procedure TTestDDLMySQL.TestComments_MySQL_GeneratesExpected;
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

procedure TTestDDLMySQL.TestCreateFunction_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL)
    .CreateFunction('FN_CALC_DISCOUNT')
    .Params('P_PRICE DECIMAL(18,2), P_PERCENT INT')
    .Returns('DECIMAL(18,2)')
    .Body('DETERMINISTIC BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END;')
    .AsString;

  Assert.AreEqual('CREATE FUNCTION `FN_CALC_DISCOUNT`(P_PRICE DECIMAL(18,2), P_PERCENT INT) RETURNS DECIMAL(18,2) DETERMINISTIC BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END;', LSql);
end;

procedure TTestDDLMySQL.TestDropFunction_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).DropFunction('FN_TEST').AsString;
  Assert.AreEqual('DROP FUNCTION `FN_TEST`', LSql);
end;

procedure TTestDDLMySQL.TestFKActions_MultipleActions_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('orders').Create
    .ColumnInteger('id').PrimaryKey
    .ColumnInteger('vendor_id').References('vendors', 'id')
      .OnDelete(raCascade)
      .OnUpdate(raSetNull)
    .AsString;
  Assert.AreEqual('CREATE TABLE `orders` (`id` INT PRIMARY KEY, `vendor_id` INT REFERENCES `vendors`(`id`) ON DELETE CASCADE ON UPDATE SET NULL)', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLMySQL);

end.
