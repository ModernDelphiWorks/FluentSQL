unit test.ddl.sqlite;

interface

uses
  DUnitX.TestFramework;

type
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
    [Test]
    procedure TestIdentity_SQLite_MapsBothToNative;
    [Test]
    procedure TestFKActions_SQLite_GeneratesExpected;
    [Test]
    procedure TestCreateView_SQLite_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLSQLite }

procedure TTestDDLSQLite.TestCreateTable_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE `CLIENTES` (`ID` INTEGER, `NOME` TEXT, `ATIVO` INTEGER)',
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
  LSql := FluentSQL.Schema(dbnSQLite).Table('OLD_NAME').Rename('NEW_NAME').AsString;
  Assert.AreEqual('ALTER TABLE `OLD_NAME` RENAME TO `NEW_NAME`', LSql);
end;

procedure TTestDDLSQLite.TestTruncateTable_SQLite_GeneratesDeleteFrom;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('DELETE FROM `CLIENTES`', LSql);
end;

procedure TTestDDLSQLite.TestCreateIndex_SQLite_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).CreateIndex('IX_EVT', 'EVENTS')
    .Column('TENANT_ID')
    .Column('CREATED_AT')
    .AsString;
  Assert.AreEqual('CREATE INDEX `IX_EVT` ON `EVENTS` (`TENANT_ID`, `CREATED_AT`)', LSql);
end;

procedure TTestDDLSQLite.TestIdentity_SQLite_MapsBothToNative;
var
  LSqlAlways, LSqlByDefault: string;
begin
  LSqlAlways := FluentSQL.Schema(dbnSQLite).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  LSqlByDefault := FluentSQL.Schema(dbnSQLite).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;

  Assert.AreEqual('CREATE TABLE `LOGS` (`ID` INTEGER PRIMARY KEY AUTOINCREMENT)', LSqlAlways);
  Assert.AreEqual(LSqlAlways, LSqlByDefault);
end;

procedure TTestDDLSQLite.TestFKActions_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('details').Create
    .ColumnInteger('id').PrimaryKey
    .ColumnInteger('master_id').References('master', 'id').OnDelete(raCascade)
    .AsString;
  Assert.AreEqual('CREATE TABLE `details` (`id` INTEGER PRIMARY KEY, `master_id` INTEGER REFERENCES `master`(`id`) ON DELETE CASCADE)', LSql);
end;

procedure TTestDDLSQLite.TestCreateView_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).CreateView('VW_CLI')
    .&As(FluentSQL.Query(dbnSQLite).Select.Column('ID').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW `VW_CLI` AS SELECT ID FROM CLIENTES', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLSQLite);

end.
