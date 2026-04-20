unit test_esp074_unit;

interface

uses
  DUnitX.TestFramework, System.SysUtils, FluentSQL, FluentSQL.Interfaces;

type
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
    procedure TestTruncateTable_MySQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_MultiTable_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_ContinueIdentity_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_MultiTable_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_Partition_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MySQL_MultiTableWithPartition_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_MySQL_RestartIdentity_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_MySQL_Cascade_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_UnsupportedDialect_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_EmptyTableName_RaisesArgumentException;
    [Test]
    procedure TestTruncateTable_MSSQL_MultiTable_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Oracle_SingleTable_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_Oracle_MultiTable_RaisesNotSupported;
  end;

implementation

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

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE `CLIENTES`', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_MultiTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable(['T1', 'T2', 'T3']).AsString;
  Assert.AreEqual('TRUNCATE TABLE "T1", "T2", "T3"', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_ContinueIdentity_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('logs').ContinueIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE "logs" CONTINUE IDENTITY', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_MultiTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable(['T1', 'T2']).AsString;
  Assert.AreEqual('TRUNCATE TABLE `T1`, `T2`', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_Partition_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('logs').Partition('p2023').AsString;
  Assert.AreEqual('TRUNCATE TABLE `logs` PARTITION (p2023)', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_MultiTableWithPartition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable(['T1', 'T2']).Partition('p1').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_RestartIdentity_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable('T').RestartIdentity.AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_Cascade_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable('T').Cascade.AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_UnsupportedDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnDB2).TruncateTable('T').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Oracle_SingleTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnOracle).TruncateTable('TABLE_A').AsString;
  Assert.AreEqual('TRUNCATE TABLE "TABLE_A"', LSql);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Oracle_MultiTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnOracle).TruncateTable(['T1', 'T2']).AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_EmptyTableName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).TruncateTable('   ').AsString;
    end,
    System.SysUtils.EArgumentException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MSSQL_MultiTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).TruncateTable(['T1', 'T2']).AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLTruncateTable);

end.
