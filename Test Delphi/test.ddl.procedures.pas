unit test.ddl.procedures;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLProcedures = class
  public
    [Test]
    procedure TestCreateProcedure_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateProcedure_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateProcedure_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateProcedure_MySQL_GeneratesExpected;

    [Test]
    procedure TestDropProcedure_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropProcedure_Firebird_GeneratesExpected;

    [Test]
    procedure TestCreateTrigger_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateTrigger_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateTrigger_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateTrigger_MySQL_GeneratesExpected;

    [Test]
    procedure TestDropTrigger_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropTrigger_Firebird_GeneratesExpected;

    [Test]
    procedure TestManageTrigger_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestManageTrigger_Firebird_GeneratesExpected;
    [Test]
    procedure TestManageTrigger_MSSQL_GeneratesExpected;
    [Test]
    procedure TestManageTrigger_MySQL_GeneratesExpected;
    
    [Test]
    procedure TestTableEnableTrigger_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLProcedures }

procedure TTestDDLProcedures.TestCreateProcedure_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL)
    .CreateProcedure('SP_UPDATE_STOCK')
    .Params('P_ID INT, P_QTY INT')
    .Body('BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = P_ID; END;')
    .OrReplace
    .AsString;
    
  Assert.AreEqual('CREATE OR REPLACE PROCEDURE "SP_UPDATE_STOCK"(P_ID INT, P_QTY INT) LANGUAGE plpgsql AS $$ BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = P_ID; END; $$', LSql);
end;

procedure TTestDDLProcedures.TestCreateProcedure_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird)
    .CreateProcedure('SP_UPDATE_STOCK')
    .Params('P_ID INT, P_QTY INT')
    .Body('BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = :P_ID; END;')
    .OrReplace
    .AsString;
    
  Assert.AreEqual('CREATE OR ALTER PROCEDURE "SP_UPDATE_STOCK" (P_ID INT, P_QTY INT) AS BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = :P_ID; END;', LSql);
end;

procedure TTestDDLProcedures.TestCreateProcedure_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL)
    .CreateProcedure('SP_UPDATE_STOCK')
    .Params('@ID INT, @QTY INT')
    .Body('BEGIN UPDATE STOCK SET QTY = QTY + @QTY WHERE ID = @ID; END;')
    .OrReplace
    .AsString;
    
  Assert.AreEqual('CREATE OR ALTER PROCEDURE [SP_UPDATE_STOCK] @ID INT, @QTY INT AS BEGIN UPDATE STOCK SET QTY = QTY + @QTY WHERE ID = @ID; END;', LSql);
end;

procedure TTestDDLProcedures.TestCreateProcedure_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL)
    .CreateProcedure('SP_UPDATE_STOCK')
    .Params('P_ID INT, P_QTY INT')
    .Body('BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = P_ID; END;')
    .AsString;
    
  Assert.AreEqual('CREATE PROCEDURE `SP_UPDATE_STOCK`(P_ID INT, P_QTY INT) BEGIN UPDATE STOCK SET QTY = QTY + P_QTY WHERE ID = P_ID; END;', LSql);
end;

procedure TTestDDLProcedures.TestDropProcedure_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropProcedure('SP_TEST').IfExists.AsString;
  Assert.AreEqual('DROP PROCEDURE IF EXISTS "SP_TEST"', LSql);
end;

procedure TTestDDLProcedures.TestDropProcedure_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropProcedure('SP_TEST').AsString;
  Assert.AreEqual('DROP PROCEDURE "SP_TEST"', LSql);
end;

procedure TTestDDLProcedures.TestCreateTrigger_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL)
    .CreateTrigger('TRG_STOCK_LOG')
    .Table('STOCK')
    .After
    .OnUpdate
    .Body('EXECUTE FUNCTION log_stock_change()')
    .AsString;
    
  Assert.AreEqual('CREATE TRIGGER "TRG_STOCK_LOG" AFTER UPDATE ON "STOCK" FOR EACH ROW EXECUTE FUNCTION log_stock_change()', LSql);
end;

procedure TTestDDLProcedures.TestCreateTrigger_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird)
    .CreateTrigger('TRG_STOCK_LOG')
    .Table('STOCK')
    .Before
    .OnInsert
    .Body('BEGIN NEW.ID = NEXT VALUE FOR SEQ_STOCK; END;')
    .AsString;
    
  Assert.AreEqual('CREATE TRIGGER "TRG_STOCK_LOG" FOR "STOCK" BEFORE INSERT AS BEGIN NEW.ID = NEXT VALUE FOR SEQ_STOCK; END;', LSql);
end;

procedure TTestDDLProcedures.TestCreateTrigger_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL)
    .CreateTrigger('TRG_STOCK_LOG')
    .Table('STOCK')
    .After
    .OnInsert
    .Body('BEGIN INSERT INTO LOG ... END;')
    .AsString;
    
  Assert.AreEqual('CREATE TRIGGER [TRG_STOCK_LOG] ON [STOCK] AFTER INSERT AS BEGIN INSERT INTO LOG ... END;', LSql);
end;

procedure TTestDDLProcedures.TestCreateTrigger_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL)
    .CreateTrigger('TRG_STOCK_LOG')
    .Table('STOCK')
    .Before
    .OnDelete
    .Body('BEGIN SIGNAL SQLSTATE ''45000'' ... END;')
    .AsString;
    
  Assert.AreEqual('CREATE TRIGGER `TRG_STOCK_LOG` BEFORE DELETE ON `STOCK` FOR EACH ROW BEGIN SIGNAL SQLSTATE ''45000'' ... END;', LSql);
end;

procedure TTestDDLProcedures.TestDropTrigger_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropTrigger('TRG_TEST').OnTable('STOCK').IfExists.AsString;
  Assert.AreEqual('DROP TRIGGER IF EXISTS "TRG_TEST" ON "STOCK"', LSql);
end;

procedure TTestDDLProcedures.TestDropTrigger_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropTrigger('TRG_TEST').AsString;
  Assert.AreEqual('DROP TRIGGER "TRG_TEST"', LSql);
end;

procedure TTestDDLProcedures.TestManageTrigger_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DisableTrigger('STOCK', 'TRG_TEST').AsString;
  Assert.AreEqual('ALTER TABLE "STOCK" DISABLE TRIGGER "TRG_TEST"', LSql);
end;

procedure TTestDDLProcedures.TestManageTrigger_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).EnableTrigger('STOCK', 'TRG_TEST').AsString;
  Assert.AreEqual('ALTER TRIGGER "TRG_TEST" ACTIVE', LSql);
end;

procedure TTestDDLProcedures.TestManageTrigger_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DisableTrigger('STOCK', 'TRG_TEST').AsString;
  Assert.AreEqual('ALTER TABLE [STOCK] DISABLE TRIGGER [TRG_TEST]', LSql);
end;

procedure TTestDDLProcedures.TestManageTrigger_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).EnableTrigger('STOCK', 'TRG_TEST').AsString;
  Assert.AreEqual('-- MySQL: Direct trigger management is MariaDB-specific. Standard MySQL does not support ENABLE/DISABLE TRIGGER.' + sLineBreak + 'ALTER TRIGGER `TRG_TEST` ENABLE', LSql);
end;

procedure TTestDDLProcedures.TestTableEnableTrigger_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('STOCK').EnableTrigger('TRG_TEST').AsString;
  Assert.AreEqual('ALTER TABLE "STOCK" ENABLE TRIGGER "TRG_TEST"', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLProcedures);

end.
