unit test.ddl.constraints;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLFKActions = class
  public
    [Test]
    procedure TestFKActions_ColumnLevel_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_TableLevel_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_AlterTable_PostgreSQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_AllStandardActions_Firebird_GeneratesExpected;
    [Test]
    procedure TestFKActions_MultipleActions_MySQL_GeneratesExpected;
    [Test]
    procedure TestFKActions_SQLite_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLFKActions }

procedure TTestDDLFKActions.TestFKActions_ColumnLevel_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID').OnDelete(raCascade)
    .AsString;
  Assert.AreEqual('CREATE TABLE "PEDIDOS" ("ID" INTEGER PRIMARY KEY, "CLIENTE_ID" INTEGER REFERENCES "CLIENTES"("ID") ON DELETE CASCADE)', LSql);
end;

procedure TTestDDLFKActions.TestFKActions_TableLevel_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Create
    .ColumnInteger('ID').PrimaryKey
    .ColumnInteger('CLIENTE_ID')
    .ForeignKey('CLIENTE_ID', 'CLIENTES', 'ID', 'FK_PEDIDOS_CLIENTES')
      .OnDelete(raSetNull)
      .OnUpdate(raCascade)
    .AsString;
  Assert.AreEqual('CREATE TABLE "PEDIDOS" ("ID" INTEGER PRIMARY KEY, "CLIENTE_ID" INTEGER, CONSTRAINT "FK_PEDIDOS_CLIENTES" FOREIGN KEY ("CLIENTE_ID") REFERENCES "CLIENTES"("ID") ON DELETE SET NULL ON UPDATE CASCADE)', LSql);
end;

procedure TTestDDLFKActions.TestFKActions_AlterTable_PostgreSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnPostgreSQL).Table('PEDIDOS').Add
    .AddForeignKey('CLIENTE_ID', 'CLIENTES', 'ID', 'FK_PEDIDOS_CLIENTES')
      .OnDelete(raRestrict)
    .AsString;
  Assert.AreEqual('ALTER TABLE "PEDIDOS" ADD CONSTRAINT "FK_PEDIDOS_CLIENTES" FOREIGN KEY ("CLIENTE_ID") REFERENCES "CLIENTES"("ID") ON DELETE RESTRICT', LSql);
end;

procedure TTestDDLFKActions.TestFKActions_AllStandardActions_Firebird_GeneratesExpected;
var
  LBase: IFluentDDLBuilder;
begin
  LBase := FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnInteger('P').PrimaryKey;

  Assert.AreEqual('CREATE TABLE "T" ("P" INTEGER PRIMARY KEY, "F" INTEGER REFERENCES "P"("ID") ON DELETE CASCADE)', 
    LBase.ColumnInteger('F').References('P', 'ID').OnDelete(raCascade).AsString);

  // Reset and try others
  LBase := FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnInteger('P').PrimaryKey;
  Assert.AreEqual('CREATE TABLE "T" ("P" INTEGER PRIMARY KEY, "F" INTEGER REFERENCES "P"("ID") ON DELETE SET NULL)', 
    LBase.ColumnInteger('F').References('P', 'ID').OnDelete(raSetNull).AsString);

  LBase := FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnInteger('P').PrimaryKey;
  Assert.AreEqual('CREATE TABLE "T" ("P" INTEGER PRIMARY KEY, "F" INTEGER REFERENCES "P"("ID") ON DELETE SET DEFAULT)', 
    LBase.ColumnInteger('F').References('P', 'ID').OnDelete(raSetDefault).AsString);

  LBase := FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnInteger('P').PrimaryKey;
  Assert.AreEqual('CREATE TABLE "T" ("P" INTEGER PRIMARY KEY, "F" INTEGER REFERENCES "P"("ID") ON DELETE RESTRICT)', 
    LBase.ColumnInteger('F').References('P', 'ID').OnDelete(raRestrict).AsString);
end;

procedure TTestDDLFKActions.TestFKActions_MultipleActions_MySQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).Table('orders').Create
    .ColumnInteger('id').PrimaryKey
    .ColumnInteger('vendor_id').References('vendors', 'id')
      .OnDelete(raCascade)
      .OnUpdate(raSetNull)
    .AsString;
  Assert.AreEqual('CREATE TABLE `orders` (`id` INT PRIMARY KEY, `vendor_id` INT REFERENCES `vendors`(`id`) ON DELETE CASCADE ON UPDATE SET NULL)', LSql);
end;

procedure TTestDDLFKActions.TestFKActions_SQLite_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnSQLite).Table('details').Create
    .ColumnInteger('id').PrimaryKey
    .ColumnInteger('master_id').References('master', 'id').OnDelete(raCascade)
    .AsString;
  Assert.AreEqual('CREATE TABLE `details` (`id` INTEGER PRIMARY KEY, `master_id` INTEGER REFERENCES `master`(`id`) ON DELETE CASCADE)', LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLFKActions);

end.
