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
    [Test]
    procedure TestAlterTableDropColumn_UnsupportedDialect_MessageReferencesESP020;
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
    [Test]
    procedure TestAlterTableRenameColumn_UnsupportedDialect_MessageReferencesESP030;
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
    [Test]
    procedure TestCreateIndex_UnsupportedDialect_MessageReferencesESP022;
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
    procedure TestDropIndex_UnsupportedDialect_Concurrently_MessageReferencesESP027;
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
    [Test]
    procedure TestTruncateTable_Firebird_Modifier_MessageReferencesESP029;
    [Test]
    procedure TestTruncateTable_UnsupportedDialect_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_EmptyTableName_RaisesArgumentException;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

procedure TTestDDLCreateTable.TestCreateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateTable('CLIENTES')
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE CLIENTES (ID INTEGER, NOME VARCHAR(100), ATIVO BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateTable('CLIENTES')
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE CLIENTES (ID INTEGER, NOME VARCHAR(100), ATIVO BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).CreateTable('CLIENTES')
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE CLIENTES (ID INT, NOME VARCHAR(100), ATIVO BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestCreateTable_WithConstraints_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnVarChar('EMAIL', 255).Unique
    .ColumnInteger('IDADE').Check('IDADE > 0')
    .ColumnVarChar('STATUS', 20).DefaultValue('''ACTIVE''')
    .ColumnInteger('PERFIL_ID').References('PERFIS', 'ID')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE USUARIOS (ID INTEGER PRIMARY KEY, NOME VARCHAR(100) NOT NULL, EMAIL VARCHAR(255) UNIQUE, IDADE INTEGER CHECK (IDADE > 0), STATUS VARCHAR(20) DEFAULT ''ACTIVE'', PERFIL_ID INTEGER REFERENCES PERFIS(ID))',
    LSql);
end;

procedure TTestDDLCreateTable.TestLongTextAndBlob_DivergeBetweenFirebirdAndPostgreSQL;
var
  LFirebirdSql, LPostgreSql: string;
begin
  LFirebirdSql := FluentSQL.Schema(dbnFirebird).CreateTable('DOC')
    .ColumnLongText('BODY')
    .ColumnBlob('RAW')
    .AsString;
  LPostgreSql := FluentSQL.Schema(dbnPostgreSQL).CreateTable('DOC')
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
  LSql := FluentSQL.Schema(dbnFirebird).DropTable('CLIENTES').AsString;
  Assert.AreEqual('DROP TABLE CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropTable('CLIENTES').AsString;
  Assert.AreEqual('DROP TABLE CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropTable('CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropTable('CLIENTES').IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).AlterTableAdd('CLIENTES')
    .ColumnInteger('NOVO_ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD NOVO_ID INTEGER', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).AlterTableAdd('CLIENTES')
    .ColumnVarChar('NOME', 80)
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD NOME VARCHAR(80)', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).AlterTableAdd('CLIENTES')
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD ATIVO BOOLEAN', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_WithReferences_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).AlterTableAdd('PEDIDOS')
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE PEDIDOS ADD CLIENTE_ID INTEGER REFERENCES CLIENTES(ID)', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_SecondColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableAdd('T')
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
      FluentSQL.Schema(dbnMSSQL).AlterTableAdd('T') // MSSQL is still unsupported in DDL
        .ColumnInteger('C')
        .AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).AlterTableDrop('CLIENTES')
    .DropColumn('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES DROP LEGADO', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).AlterTableDrop('CLIENTES')
    .DropColumn('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES DROP COLUMN LEGADO', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_SecondDropColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableDrop('T')
        .DropColumn('A')
        .DropColumn('B')
        .AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).AlterTableDrop('T')
        .DropColumn('C')
        .AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_UnsupportedDialect_MessageReferencesESP020;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMySQL).AlterTableDrop('T').DropColumn('C').AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-020', LMsg) > 0);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('CLIENTES', 'LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES RENAME COLUMN LEGADO TO NOVO_NOME', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).AlterTableRename('pedidos', 'status_id', 'status_ref')
    .AsString;
  Assert.AreEqual('ALTER TABLE pedidos RENAME COLUMN status_id TO status_ref', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).AlterTableRename('CLIENTES', 'LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ALTER LEGADO TO NOVO_NOME', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_TrimsIdentifiersInOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('  T  ', '  a  ', '  b  ')
    .AsString;
  Assert.AreEqual('ALTER TABLE T RENAME COLUMN a TO b', LSql);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('', 'A', 'B').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyOldName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('T', '  ', 'B').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_EmptyNewName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('T', 'A', '').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_SameOldAndNew_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('T', 'X', 'X').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_TrimmedEqualNames_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).AlterTableRename('T', 'X', '  X  ').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).AlterTableRename('T', 'A', 'B').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableRenameColumn.TestAlterTableRenameColumn_UnsupportedDialect_MessageReferencesESP030;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMSSQL).AlterTableRename('T', 'A', 'B').AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-030', LMsg) > 0);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX IX_CLI_NOME ON CLIENTES (NOME)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('UQ_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX UQ_CLI_EMAIL ON CLIENTES (EMAIL)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_EVT', 'EVENTS')
    .Column('TENANT_ID')
    .Column('CREATED_AT')
    .AsString;
  Assert.AreEqual('CREATE INDEX IX_EVT ON EVENTS (TENANT_ID, CREATED_AT)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('ix_orders_status', 'orders')
    .Column('status')
    .AsString;
  Assert.AreEqual('CREATE INDEX ix_orders_status ON orders (status)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('uq_orders_code', 'orders')
    .Unique
    .Column('code')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX uq_orders_code ON orders (code)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('ix_evt', 'events')
    .Column('tenant_id')
    .Column('created_at')
    .AsString;
  Assert.AreEqual('CREATE INDEX ix_evt ON events (tenant_id, created_at)', LSql);
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
      FluentSQL.Schema(dbnMSSQL).CreateIndex('IX_X', 'T')
        .Column('A')
        .AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_UnsupportedDialect_MessageReferencesESP022;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMySQL).CreateIndex('IX_X', 'T').Column('A').AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-022', LMsg) > 0);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').AsString;
  Assert.AreEqual('DROP INDEX IX_CLI_NOME', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').AsString;
  Assert.AreEqual('DROP INDEX ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS IX_CLI_NOME', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').Concurrently.IfExists.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_Concurrently_SameOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('ix_orders_status').IfExists.Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS ix_orders_status', LSql);
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
      FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').Concurrently.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_UnsupportedDialect_Concurrently_MessageReferencesESP027;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnMySQL).DropIndex('IX_X').Concurrently.AsString;
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
  Assert.AreEqual('DROP INDEX ix_orders_status ON orders', LSql);
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
  Assert.AreEqual('TRUNCATE TABLE CLIENTES', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_RestartIdentity_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('logs').RestartIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE logs RESTART IDENTITY', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_Cascade_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').Cascade.AsString;
  Assert.AreEqual('TRUNCATE TABLE orders CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_RestartIdentityAndCascade_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').RestartIdentity.Cascade.AsString;
  Assert.AreEqual('TRUNCATE TABLE orders RESTART IDENTITY CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_CascadeThenRestartIdentity_SameOutput;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('orders').Cascade.RestartIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE orders RESTART IDENTITY CASCADE', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE CLIENTES', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE CLIENTES', LSql);
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

end.
