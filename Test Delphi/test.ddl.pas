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

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

procedure TTestDDLCreateTable.TestCreateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLTable(dbnFirebird, 'CLIENTES')
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
  LSql := CreateFluentDDLTable(dbnPostgreSQL, 'CLIENTES')
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE CLIENTES (ID INTEGER, NOME VARCHAR(100), ATIVO BOOLEAN)',
    LSql);
end;

procedure TTestDDLCreateTable.TestLongTextAndBlob_DivergeBetweenFirebirdAndPostgreSQL;
var
  LFirebirdSql, LPostgreSql: string;
begin
  LFirebirdSql := CreateFluentDDLTable(dbnFirebird, 'DOC')
    .ColumnLongText('BODY')
    .ColumnBlob('RAW')
    .AsString;
  LPostgreSql := CreateFluentDDLTable(dbnPostgreSQL, 'DOC')
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
  LSql := CreateFluentDDLDropTable(dbnFirebird, 'CLIENTES').AsString;
  Assert.AreEqual('DROP TABLE CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropTable(dbnPostgreSQL, 'CLIENTES').AsString;
  Assert.AreEqual('DROP TABLE CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropTable(dbnPostgreSQL, 'CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS CLIENTES', LSql);
end;

procedure TTestDDLDropTable.TestDropTableIfExists_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropTable(dbnFirebird, 'CLIENTES').IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableAddColumn(dbnFirebird, 'CLIENTES')
    .ColumnInteger('NOVO_ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD NOVO_ID INTEGER', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableAddColumn(dbnPostgreSQL, 'CLIENTES')
    .ColumnVarChar('NOME', 80)
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD NOME VARCHAR(80)', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableAddColumn(dbnFirebird, 'CLIENTES')
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES ADD ATIVO BOOLEAN', LSql);
end;

procedure TTestDDLAlterTableAddColumn.TestAlterTableAddColumn_SecondColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLAlterTableAddColumn(dbnPostgreSQL, 'T')
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
      CreateFluentDDLAlterTableAddColumn(dbnMySQL, 'T')
        .ColumnInteger('C')
        .AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableDropColumn(dbnFirebird, 'CLIENTES')
    .DropColumn('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES DROP LEGADO', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLAlterTableDropColumn(dbnPostgreSQL, 'CLIENTES')
    .DropColumn('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE CLIENTES DROP COLUMN LEGADO', LSql);
end;

procedure TTestDDLAlterTableDropColumn.TestAlterTableDropColumn_SecondDropColumn_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLAlterTableDropColumn(dbnPostgreSQL, 'T')
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
      CreateFluentDDLAlterTableDropColumn(dbnMySQL, 'T')
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
    CreateFluentDDLAlterTableDropColumn(dbnMySQL, 'T').DropColumn('C').AsString;
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

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnFirebird, 'IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX IX_CLI_NOME ON CLIENTES (NOME)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnFirebird, 'UQ_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX UQ_CLI_EMAIL ON CLIENTES (EMAIL)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnFirebird, 'IX_EVT', 'EVENTS')
    .Column('TENANT_ID')
    .Column('CREATED_AT')
    .AsString;
  Assert.AreEqual('CREATE INDEX IX_EVT ON EVENTS (TENANT_ID, CREATED_AT)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnPostgreSQL, 'ix_orders_status', 'orders')
    .Column('status')
    .AsString;
  Assert.AreEqual('CREATE INDEX ix_orders_status ON orders (status)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnPostgreSQL, 'uq_orders_code', 'orders')
    .Unique
    .Column('code')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX uq_orders_code ON orders (code)', LSql);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnPostgreSQL, 'ix_evt', 'events')
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
      CreateFluentDDLCreateIndex(dbnFirebird, 'IX_X', 'T').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLCreateIndex.TestCreateIndex_EmptyIndexName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLCreateIndex(dbnFirebird, '', 'T')
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
      CreateFluentDDLCreateIndex(dbnFirebird, 'IX_X', '')
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
      CreateFluentDDLCreateIndex(dbnFirebird, 'IX_X', 'T')
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
      CreateFluentDDLCreateIndex(dbnFirebird, 'IX_X', 'T')
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
      CreateFluentDDLCreateIndex(dbnMySQL, 'IX_X', 'T')
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
    CreateFluentDDLCreateIndex(dbnMySQL, 'IX_X', 'T').Column('A').AsString;
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
  LSql := CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').AsString;
  Assert.AreEqual('DROP INDEX IX_CLI_NOME', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').AsString;
  Assert.AreEqual('DROP INDEX ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS IX_CLI_NOME', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').Concurrently.IfExists.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_IfExists_Concurrently_SameOutput;
var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').IfExists.Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS ix_orders_status', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_Firebird_Concurrently_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').Concurrently.AsString;
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
    CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').Concurrently.AsString;
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
      CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').Concurrently.AsString;
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
    CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').Concurrently.AsString;
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
      CreateFluentDDLDropIndex(dbnFirebird, '   ').AsString;
    end,
    EArgumentException);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_WithoutOnTable_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').AsString;
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
    CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').AsString;
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
  LSql := CreateFluentDDLDropIndex(dbnMySQL, 'ix_orders_status').OnTable('orders').AsString;
  Assert.AreEqual('DROP INDEX ix_orders_status ON orders', LSql);
end;

procedure TTestDDLDropIndex.TestDropIndex_MySQL_OnTable_IfExists_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').OnTable('T').IfExists.AsString;
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
    CreateFluentDDLDropIndex(dbnMySQL, 'IX_X').OnTable('T').IfExists.AsString;
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
      CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').OnTable('CLIENTES').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_PostgreSQL_OnTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_orders_status').OnTable('orders').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLDropIndex.TestDropIndex_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      CreateFluentDDLDropIndex(dbnOracle, 'IX_X').AsString;
    end,
    ENotSupportedException);
end;

end.
