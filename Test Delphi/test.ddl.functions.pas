unit test.ddl.functions;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLFunctions = class
  public
    [Test]
    procedure TestCreateFunction_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_MySQL_GeneratesExpected;

    [Test]
    procedure TestDropFunction_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropFunction_MySQL_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLFunctions }

procedure TTestDDLFunctions.TestCreateFunction_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL)
    .CreateFunction('FN_CALC_DISCOUNT')
    .Params('P_PRICE NUMERIC, P_PERCENT INT')
    .Returns('NUMERIC')
    .Body('BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END;')
    .OrReplace
    .AsString;

  Assert.AreEqual('CREATE OR REPLACE FUNCTION "FN_CALC_DISCOUNT"(P_PRICE NUMERIC, P_PERCENT INT) RETURNS NUMERIC LANGUAGE plpgsql AS $$ BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END; $$', LSql);
end;

procedure TTestDDLFunctions.TestCreateFunction_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird)
    .CreateFunction('FN_CALC_DISCOUNT')
    .Params('P_PRICE NUMERIC(15,2), P_PERCENT INT')
    .Returns('NUMERIC(15,2)')
    .Body('BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END;')
    .OrReplace
    .AsString;

  Assert.AreEqual('CREATE OR ALTER FUNCTION "FN_CALC_DISCOUNT" (P_PRICE NUMERIC(15,2), P_PERCENT INT) RETURNS NUMERIC(15,2) AS BEGIN RETURN P_PRICE * (P_PERCENT / 100.0); END;', LSql);
end;

procedure TTestDDLFunctions.TestCreateFunction_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL)
    .CreateFunction('FN_CALC_DISCOUNT')
    .Params('@PRICE DECIMAL(18,2), @PERCENT INT')
    .Returns('DECIMAL(18,2)')
    .Body('BEGIN RETURN @PRICE * (@PERCENT / 100.0); END;')
    .OrReplace
    .AsString;

  Assert.AreEqual('CREATE OR ALTER FUNCTION [FN_CALC_DISCOUNT] (@PRICE DECIMAL(18,2), @PERCENT INT) RETURNS DECIMAL(18,2) AS BEGIN RETURN @PRICE * (@PERCENT / 100.0); END;', LSql);
end;

procedure TTestDDLFunctions.TestCreateFunction_MySQL_GeneratesExpected;
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

procedure TTestDDLFunctions.TestDropFunction_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropFunction('FN_TEST').IfExists.AsString;
  Assert.AreEqual('DROP FUNCTION IF EXISTS "FN_TEST"', LSql);
end;

procedure TTestDDLFunctions.TestDropFunction_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).DropFunction('FN_TEST').AsString;
  Assert.AreEqual('DROP FUNCTION `FN_TEST`', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLFunctions);

end.
