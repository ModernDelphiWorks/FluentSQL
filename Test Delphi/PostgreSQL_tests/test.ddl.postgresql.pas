unit test.ddl.postgresql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLPostgreSQL = class
  public
    [Test]
    procedure TestCreateTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCompositePrimaryKey_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestTableLevelCheck_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_WithReferences_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
    [Test]
    procedure TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_RestartIdentity_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_Cascade_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_PostgreSQL_MultiTable_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_Type_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_Nullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_PostgreSQL_DropDefault_GeneratesExpected;
    [Test]
    procedure TestCreateView_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_OrReplace_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestIdentity_PostgreSQL_Always_GeneratesExpected;
    [Test]
    procedure TestIdentity_PostgreSQL_ByDefault_GeneratesExpected;
    [Test]
    procedure TestComments_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestDropFunction_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_ColumnLevel_PostgreSQL_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLPostgreSQL }

procedure TTestDDLPostgreSQL.TestCreateTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE "CLIENTES" ("ID" INTEGER, "NOME" VARCHAR(100), "ATIVO" BOOLEAN)',
    LSql);
end;

procedure TTestDDLPostgreSQL.TestCompositePrimaryKey_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDO_ITENS').Create
    .ColumnInteger('PEDIDO_ID')
    .ColumnInteger('ITEM_ID')
    .ColumnInteger('QTD')
    .PrimaryKey(['PEDIDO_ID', 'ITEM_ID'])
    .AsString;
  Assert.AreEqual('CREATE TABLE "PEDIDO_ITENS" ("PEDIDO_ID" INTEGER, "ITEM_ID" INTEGER, "QTD" INTEGER, PRIMARY KEY ("PEDIDO_ID", "ITEM_ID"))', LSql);
end;

procedure TTestDDLPostgreSQL.TestTableLevelCheck_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PRODUTOS').Create
    .ColumnInteger('ID')
    .ColumnInteger('PRECO_MIN')
    .ColumnInteger('PRECO_MAX')
    .Check('PRECO_MAX > PRECO_MIN')
    .AsString;
  Assert.AreEqual('CREATE TABLE "PRODUTOS" ("ID" INTEGER, "PRECO_MIN" INTEGER, "PRECO_MAX" INTEGER, CHECK (PRECO_MAX > PRECO_MIN))', LSql);
end;

procedure TTestDDLPostgreSQL.TestComputedColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, "TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PRECO) STORED)', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropTableIfExists_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop.IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS "CLIENTES"', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAddColumn_PostgreSQL_VarChar_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Add
    .ColumnVarChar('NOME', 80)
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "NOME" VARCHAR(80)', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAddColumn_WithReferences_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Add
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE "PEDIDOS" ADD "CLIENTE_ID" INTEGER REFERENCES "CLIENTES"("ID")', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableDropColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" DROP COLUMN "LEGADO"', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableRenameColumn_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Rename.Column('LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" RENAME COLUMN "LEGADO" TO "NOVO_NOME"', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableRenameTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('TAB_A').Rename('TAB_B').AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" RENAME TO "TAB_B"', LSql);
end;

procedure TTestDDLPostgreSQL.TestCreateIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX "IX_CLI_NOME" ON "CLIENTES" ("NOME")', LSql);
end;

procedure TTestDDLPostgreSQL.TestCreateIndex_PostgreSQL_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateIndex('UK_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX "UK_CLI_EMAIL" ON "CLIENTES" ("EMAIL")', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropIndex_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('IX_NOME').AsString;
  Assert.AreEqual('DROP INDEX "IX_NOME"', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropIndex_PostgreSQL_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('IX_NOME').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS "IX_NOME"', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropIndex_PostgreSQL_Concurrently_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('IX_NOME').Concurrently.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY "IX_NOME"', LSql);
end;

procedure TTestDDLPostgreSQL.TestDropIndex_PostgreSQL_Concurrently_IfExists_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropIndex('IX_NOME').Concurrently.IfExists.AsString;
  Assert.AreEqual('DROP INDEX CONCURRENTLY IF EXISTS "IX_NOME"', LSql);
end;

procedure TTestDDLPostgreSQL.TestTruncateTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLPostgreSQL.TestTruncateTable_PostgreSQL_RestartIdentity_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('CLIENTES').RestartIdentity.AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES" RESTART IDENTITY', LSql);
end;

procedure TTestDDLPostgreSQL.TestTruncateTable_PostgreSQL_Cascade_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable('CLIENTES').Cascade.AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES" CASCADE', LSql);
end;

procedure TTestDDLPostgreSQL.TestTruncateTable_PostgreSQL_MultiTable_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).TruncateTable(['T1', 'T2']).AsString;
  Assert.AreEqual('TRUNCATE TABLE "T1", "T2"', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAlterColumn_PostgreSQL_Type_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Alter.Column('IDADE')
    .TypeInteger
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER COLUMN "IDADE" TYPE INTEGER', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAlterColumn_PostgreSQL_Nullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('CLIENTES').Alter.Column('NOME')
    .NotNull
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER COLUMN "NOME" SET NOT NULL', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAlterColumn_PostgreSQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER COLUMN "TOTAL" SET DEFAULT 0', LSql);
end;

procedure TTestDDLPostgreSQL.TestAlterTableAlterColumn_PostgreSQL_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER COLUMN "TOTAL" DROP DEFAULT', LSql);
end;

procedure TTestDDLPostgreSQL.TestCreateView_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateView('VW_CLI')
    .&As(FluentSQL.Query(dbnPostgreSQL).Select.Column('ID').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW "VW_CLI" AS SELECT ID FROM CLIENTES', LSql);
end;

procedure TTestDDLPostgreSQL.TestCreateView_OrReplace_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateView('VW_CLI').OrReplace
    .&As(FluentSQL.Query(dbnPostgreSQL).Select.Column('ID').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR REPLACE VIEW "VW_CLI" AS SELECT ID FROM CLIENTES', LSql);
end;

procedure TTestDDLPostgreSQL.TestIdentity_PostgreSQL_Always_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED ALWAYS AS IDENTITY)', LSql);
end;

procedure TTestDDLPostgreSQL.TestIdentity_PostgreSQL_ByDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

procedure TTestDDLPostgreSQL.TestComments_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).CreateTable('Users')
    .Description('Application users table')
    .ColumnInteger('ID').PrimaryKey.Description('Internal ID')
    .ColumnVarChar('Name', 100).NotNull.Description('Full legal name')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE "Users" ("ID" INTEGER PRIMARY KEY, "Name" VARCHAR(100) NOT NULL); ' +
    'COMMENT ON TABLE "Users" IS ''Application users table''; ' +
    'COMMENT ON COLUMN "Users"."ID" IS ''Internal ID''; ' +
    'COMMENT ON COLUMN "Users"."Name" IS ''Full legal name''',
    LSql);
end;

procedure TTestDDLPostgreSQL.TestCreateFunction_PostgreSQL_GeneratesExpected;
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

procedure TTestDDLPostgreSQL.TestDropFunction_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).DropFunction('FN_TEST').IfExists.AsString;
  Assert.AreEqual('DROP FUNCTION IF EXISTS "FN_TEST"', LSql);
end;

procedure TTestDDLPostgreSQL.TestFKActions_ColumnLevel_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID').OnDelete(raCascade)
    .AsString;
  Assert.AreEqual('CREATE TABLE "PEDIDOS" ("ID" INTEGER PRIMARY KEY, "CLIENTE_ID" INTEGER REFERENCES "CLIENTES"("ID") ON DELETE CASCADE)', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLPostgreSQL);

end.
