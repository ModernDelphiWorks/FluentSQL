unit test.ddl.schemas;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestDDLSchemas = class
  public
    [Test]
    procedure TestCreateSchema_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropSchema_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateSchema_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateSchema_MySQL_GeneratesExpected;
    [Test]
    procedure TestCreateSchema_SQLite_RaisesNotSupported;
  end;

implementation

uses
  System.SysUtils;

procedure TTestDDLSchemas.TestCreateSchema_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Schema('MY_SCHEMA').Create.AsString;
  Assert.AreEqual('CREATE SCHEMA "MY_SCHEMA"', LSql);
end;

procedure TTestDDLSchemas.TestDropSchema_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Schema('MY_SCHEMA').Drop.AsString;
  Assert.AreEqual('DROP SCHEMA "MY_SCHEMA"', LSql);
end;

procedure TTestDDLSchemas.TestCreateSchema_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Schema('MY_SCHEMA').Create.AsString;
  Assert.AreEqual('CREATE SCHEMA [MY_SCHEMA]', LSql);
end;

procedure TTestDDLSchemas.TestCreateSchema_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  // MySQL maps Schema to Database per ADR-075
  LSql := FluentSQL.Schema(dbnMySQL).Schema('MY_SCHEMA').Create.AsString;
  Assert.AreEqual('CREATE DATABASE `MY_SCHEMA`', LSql);
end;

procedure TTestDDLSchemas.TestCreateSchema_SQLite_RaisesNotSupported;
begin
  try
    FluentSQL.Schema(dbnSQLite).Schema('MY_SCHEMA').Create.AsString;
    Assert.Fail('Should have raised ENotSupportedException');
  except
    on E: Exception do
    begin
      if not E.ClassNameIs('ENotSupportedException') then
        raise;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLSchemas);
end.
