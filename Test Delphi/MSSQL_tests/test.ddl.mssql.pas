unit test.ddl.mssql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLMSSQL = class
  public
    [Test]
    procedure TestCreateTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndex_MSSQL_GeneratesExpected;
    [Test]
    procedure TestDropIndexIfExists_MSSQL_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_MSSQL_GeneratesExpected;
    [Test]
    procedure TestReservedWords_MSSQL;
    [Test]
    procedure TestBooleanDefault_MSSQL;
    [Test]
    procedure TestDateAndGuidDefault_MSSQL;
    [Test]
    procedure TestNamedInlineConstraints_MSSQL_GeneratesExpected;
    [Test]
    procedure TestNamedConstraint_AlterTableAdd_MSSQL_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_MSSQL_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_TypeAndNullability_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_MSSQL_DropDefault_RaisesNotSupported;
    [Test]
    procedure TestAlterTableAddForeignKey_MSSQL_GeneratesExpected;
    [Test]
    procedure TestCreateView_MSSQL_GeneratesExpected;
    [Test]
    procedure TestIdentity_MSSQL_MapsBothToNative;
    [Test]
    procedure TestGuidType_MSSQL;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLMSSQL }

procedure TTestDDLMSSQL.TestCreateTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .ColumnDateTime('CRIADO_EM')
    .ColumnLongText('BIO')
    .ColumnBlob('FOTO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE [CLIENTES] ([ID] INT, [NOME] VARCHAR(100), [ATIVO] BIT, [CRIADO_EM] DATETIME2, [BIO] VARCHAR(MAX), [FOTO] VARBINARY(MAX))',
    LSql);
end;

procedure TTestDDLMSSQL.TestDropTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestDropTableIfExists_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop.IfExists.AsString;
  Assert.AreEqual('DROP TABLE IF EXISTS [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableAddColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Add
    .ColumnVarChar('EMAIL', 150)
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] ADD [EMAIL] VARCHAR(150)', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableDropColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] DROP COLUMN [LEGADO]', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableRenameColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Rename.Column('NOME', 'RAZAO_SOCIAL')
    .AsString;
  Assert.AreEqual('EXEC sp_rename ''[CLIENTES].[NOME]'', ''RAZAO_SOCIAL'', ''COLUMN''', LSql);
end;

procedure TTestDDLMSSQL.TestCreateIndex_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX [IX_CLI_NOME] ON [CLIENTES] ([NOME])', LSql);
end;

procedure TTestDDLMSSQL.TestDropIndex_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').AsString;
  Assert.AreEqual('DROP INDEX [IX_CLI_NOME] ON [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestDropIndexIfExists_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').IfExists.AsString;
  Assert.AreEqual('DROP INDEX IF EXISTS [IX_CLI_NOME] ON [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestReservedWords_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('User').Create
    .ColumnInteger('Order')
    .ColumnVarChar('Table', 10)
    .AsString;
  Assert.AreEqual('CREATE TABLE [User] ([Order] INT, [Table] VARCHAR(10))', LSql);
end;

procedure TTestDDLMSSQL.TestBooleanDefault_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CONFIGS').Create
    .ColumnBoolean('ENABLED').DefaultValue('True')
    .ColumnBoolean('ACTIVE').DefaultValue('False')
    .ColumnBoolean('LEGACY_T').DefaultValue('T')
    .ColumnBoolean('LEGACY_F').DefaultValue('F')
    .AsString;
  Assert.AreEqual('CREATE TABLE [CONFIGS] ([ENABLED] BIT DEFAULT 1, [ACTIVE] BIT DEFAULT 0, [LEGACY_T] BIT DEFAULT 1, [LEGACY_F] BIT DEFAULT 0)', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableRenameTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('OLD_NAME').Rename('NEW_NAME').AsString;
  Assert.AreEqual('EXEC sp_rename ''OLD_NAME'', ''NEW_NAME''', LSql);
end;

procedure TTestDDLMSSQL.TestTruncateTable_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE [CLIENTES]', LSql);
end;

procedure TTestDDLMSSQL.TestDateAndGuidDefault_MSSQL;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('T').Create
    .ColumnDate('D').DefaultValue('2024-04-14')
    .ColumnGuid('G').DefaultValue('{00000000-0000-0000-0000-000000000000}')
    .AsString;
  Assert.AreEqual('CREATE TABLE [T] ([D] DATE DEFAULT ''2024-04-14'', [G] UNIQUEIDENTIFIER DEFAULT ''{00000000-0000-0000-0000-000000000000}'')', LSql);
end;

procedure TTestDDLMSSQL.TestNamedInlineConstraints_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('USUARIOS').Create
    .ColumnInteger('ID').PrimaryKey('PK_USUARIOS')
    .ColumnVarChar('EMAIL', 255).Unique('UK_USUARIOS_EMAIL')
    .ColumnInteger('IDADE').Check('IDADE >= 18', 'CK_USUARIOS_IDADE')
    .AsString;
  Assert.AreEqual('CREATE TABLE [USUARIOS] ([ID] INT CONSTRAINT [PK_USUARIOS] PRIMARY KEY, [EMAIL] VARCHAR(255) CONSTRAINT [UK_USUARIOS_EMAIL] UNIQUE, [IDADE] INT CONSTRAINT [CK_USUARIOS_IDADE] CHECK (IDADE >= 18))', LSql);
end;

procedure TTestDDLMSSQL.TestNamedConstraint_AlterTableAdd_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('USUARIOS').Add
    .ColumnVarChar('LOGIN', 50).Unique('UK_USUARIOS_LOGIN')
    .AsString;
  Assert.AreEqual('ALTER TABLE [USUARIOS] ADD [LOGIN] VARCHAR(50) CONSTRAINT [UK_USUARIOS_LOGIN] UNIQUE', LSql);
end;

procedure TTestDDLMSSQL.TestComputedColumn_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT, [TOTAL] INT AS (QTD * PRECO))', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableAlterColumn_MSSQL_TypeAndNullability_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('CLIENTES').Alter.Column('NOME')
    .TypeVarchar(100)
    .Nullable
    .AsString;
  Assert.AreEqual('ALTER TABLE [CLIENTES] ALTER COLUMN [NOME] VARCHAR(100) NULL', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableAlterColumn_MSSQL_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE [VALORES] ADD DEFAULT 0 FOR [TOTAL]', LSql);
end;

procedure TTestDDLMSSQL.TestAlterTableAlterColumn_MSSQL_DropDefault_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).Table('T').Alter.Column('C').DropDefault.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLMSSQL.TestAlterTableAddForeignKey_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).Table('TAB_SALARY').Add
    .AddForeignKey('EMP_ID', 'EMPLOYEES', 'ID', 'FK_SAL_EMP')
    .AsString;
  Assert.AreEqual('ALTER TABLE [TAB_SALARY] ADD CONSTRAINT [FK_SAL_EMP] FOREIGN KEY ([EMP_ID]) REFERENCES [EMPLOYEES]([ID])', LSql);
end;

procedure TTestDDLMSSQL.TestCreateView_MSSQL_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMSSQL).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnMSSQL).Select.Column('ID').Column('NOME').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR ALTER VIEW [VW_CLIENTES] AS SELECT ID, NOME FROM CLIENTES', LSql);
end;

procedure TTestDDLMSSQL.TestIdentity_MSSQL_MapsBothToNative;
var
  LSqlAlways, LSqlByDefault: string;
begin
  LSqlAlways := FluentSQL.Schema(dbnMSSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  LSqlByDefault := FluentSQL.Schema(dbnMSSQL).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;

  Assert.AreEqual('CREATE TABLE [LOGS] ([ID] BIGINT IDENTITY(1,1))', LSqlAlways);
  Assert.AreEqual(LSqlAlways, LSqlByDefault);
end;

procedure TTestDDLMSSQL.TestGuidType_MSSQL;
begin
  Assert.AreEqual('CREATE TABLE [T] ([G] UNIQUEIDENTIFIER)', 
    FluentSQL.Schema(dbnMSSQL).Table('T').Create.ColumnGuid('G').AsString);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDDLMSSQL);

end.
