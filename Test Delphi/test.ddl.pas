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

end.
