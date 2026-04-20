unit test.ddl.sequences;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLSequences = class
  public
    [Test]
    procedure TestCreateSequence_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateSequence_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateSequence_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateSequence_MySQL_RaisesNotSupported;
    [Test]
    procedure TestCreateSequence_SQLite_RaisesNotSupported;
    
    [Test]
    procedure TestDropSequence_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropSequence_IfExists_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropSequence_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropSequence_IfExists_Firebird_RaisesNotSupported;
    [Test]
    procedure TestDropSequence_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropSequence_IfExists_MSSQL_GeneratesExpected;
    
    [Test]
    procedure TestSequence_EmptyName_RaisesArgumentException;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLSequences }

procedure TTestDDLSequences.TestCreateSequence_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('CREATE SEQUENCE "SEQ_CLIENTES"', LSql);
end;

procedure TTestDDLSequences.TestCreateSequence_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('CREATE SEQUENCE "SEQ_CLIENTES"', LSql);
end;

procedure TTestDDLSequences.TestCreateSequence_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('CREATE SEQUENCE [SEQ_CLIENTES]', LSql);
end;

procedure TTestDDLSequences.TestCreateSequence_MySQL_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).CreateSequence('S').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLSequences.TestCreateSequence_SQLite_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).CreateSequence('S').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLSequences.TestDropSequence_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('DROP SEQUENCE "SEQ_CLIENTES"', LSql);
end;

procedure TTestDDLSequences.TestDropSequence_IfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropSequence('SEQ_CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP SEQUENCE IF EXISTS "SEQ_CLIENTES"', LSql);
end;

procedure TTestDDLSequences.TestDropSequence_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('DROP SEQUENCE "SEQ_CLIENTES"', LSql);
end;

procedure TTestDDLSequences.TestDropSequence_IfExists_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropSequence('S').IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLSequences.TestDropSequence_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropSequence('SEQ_CLIENTES').AsString;
  Assert.AreEqual('DROP SEQUENCE [SEQ_CLIENTES]', LSql);
end;

procedure TTestDDLSequences.TestDropSequence_IfExists_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropSequence('SEQ_CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP SEQUENCE IF EXISTS [SEQ_CLIENTES]', LSql);
end;

procedure TTestDDLSequences.TestSequence_EmptyName_RaisesArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).CreateSequence('').AsString;
    end,
    EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLSequences);

end.
