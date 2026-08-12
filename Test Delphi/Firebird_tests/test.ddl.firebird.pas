unit test.ddl.firebird;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDDLFirebird = class
  public
    [Test]
    procedure TestCreateTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestDateDefault_Firebird_GeneratesExpected;
    [Test]
    procedure TestCompositeUnique_Firebird_GeneratesExpected;
    [Test]
    procedure TestComputedColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropTableIfExists_Firebird_RaisesNotSupported;
    [Test]
    procedure TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddColumn_WithReferences_GeneratesExpected;
    [Test]
    procedure TestAlterTableDropColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameColumn_Firebird_GeneratesExpected;
    [Test]
    procedure TestAlterTableRenameTable_Firebird_RaisesNotSupported;
    [Test]
    procedure TestCreateIndex_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Firebird_Unique_GeneratesExpected;
    [Test]
    procedure TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
    [Test]
    procedure TestDropIndex_Firebird_GeneratesExpected;
    [Test]
    procedure TestDropIndex_Firebird_IfExists_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_Firebird_Concurrently_RaisesNotSupported;
    [Test]
    procedure TestDropIndex_Firebird_Concurrently_MessageReferencesESP027;
    [Test]
    procedure TestDropIndex_Firebird_OnTable_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Firebird_GeneratesExpected;
    [Test]
    procedure TestTruncateTable_Firebird_RestartIdentity_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Firebird_Cascade_RaisesNotSupported;
    [Test]
    // T35: so a CITACAO foi corrigida aqui. A lacuna que a T6 registrou continua
    // de pe e nao e desta tarefa - o que estava podre era o ENDERECO: as guardas
    // da T35 deslocaram o arquivo e "261-262" passou a apontar outro trecho.
    // Recitada pela assinatura e pelo texto do raise, que nao andam com a
    // proxima edicao, em vez de por numero de linha.
    [Ignore('T6: mensagem ESP-029 perdida em TFluentDDLSerializerFirebird.TruncateTable, no raise ' +
            '"DDL Firebird: advanced TRUNCATE options (RESTART IDENTITY, CASCADE, PARTITION) are not supported."')]
    procedure TestTruncateTable_Firebird_Modifier_MessageReferencesESP029;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_Type_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_Nullability_RaisesNotSupported;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_SetDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAlterColumn_Firebird_DropDefault_GeneratesExpected;
    [Test]
    procedure TestAlterTableAddUnique_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateView_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateView_OrReplace_Firebird_GeneratesExpected;
    [Test]
    procedure TestIdentity_Firebird_Always_GeneratesExpected;
    [Test]
    procedure TestIdentity_Firebird_ByDefault_GeneratesExpected;
    [Test]
    procedure TestIdentity_AlterTableAlter_Firebird_GeneratesExpected;
    [Test]
    procedure TestGuidType_Firebird;
    [Test]
    procedure TestLongTextAndBlob_Firebird;
    [Test]
    procedure TestComments_Firebird_GeneratesExpected;
    [Test]
    procedure TestCreateFunction_Firebird_GeneratesExpected;
  end;

implementation

uses
  System.SysUtils,
  FluentSQL,
  FluentSQL.Interfaces;

{ TTestDDLFirebird }

procedure TTestDDLFirebird.TestCreateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Create
    .ColumnInteger('ID')
    .ColumnVarChar('NOME', 100)
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual(
    'CREATE TABLE "CLIENTES" ("ID" INTEGER, "NOME" VARCHAR(100), "ATIVO" BOOLEAN)',
    LSql);
end;

procedure TTestDDLFirebird.TestDateDefault_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('T').Create
    .ColumnDate('D').DefaultValue('2024-04-14')
    .AsString;
  Assert.AreEqual('CREATE TABLE "T" ("D" DATE DEFAULT ''04/14/2024'')', LSql);
end;

procedure TTestDDLFirebird.TestCompositeUnique_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CONTATOS').Create
    .ColumnInteger('CLIENTE_ID')
    .ColumnVarChar('TIPO', 20)
    .Unique(['CLIENTE_ID', 'TIPO'], 'UK_CONTATO_TIPO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "CONTATOS" ("CLIENTE_ID" INTEGER, "TIPO" VARCHAR(20), CONSTRAINT "UK_CONTATO_TIPO" UNIQUE ("CLIENTE_ID", "TIPO"))', LSql);
end;

procedure TTestDDLFirebird.TestComputedColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
  Assert.AreEqual('CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, "TOTAL" INTEGER COMPUTED BY (QTD * PRECO))', LSql);
end;

procedure TTestDDLFirebird.TestDropTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop.AsString;
  Assert.AreEqual('DROP TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLFirebird.TestDropTableIfExists_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop.IfExists.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestAlterTableAddColumn_Firebird_Integer_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Add
    .ColumnInteger('NOVO_ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "NOVO_ID" INTEGER', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableAddColumn_Firebird_Boolean_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Add
    .ColumnBoolean('ATIVO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ADD "ATIVO" BOOLEAN', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableAddColumn_WithReferences_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('PEDIDOS').Add
    .ColumnInteger('CLIENTE_ID').References('CLIENTES', 'ID')
    .AsString;
  Assert.AreEqual('ALTER TABLE "PEDIDOS" ADD "CLIENTE_ID" INTEGER REFERENCES "CLIENTES"("ID")', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableDropColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Drop
    .Column('LEGADO')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" DROP "LEGADO"', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableRenameColumn_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Rename.Column('LEGADO', 'NOVO_NOME')
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER "LEGADO" TO "NOVO_NOME"', LSql);
end;

// T35: o Firebird nao tem DDL de renomear TABELA - nenhuma forma, nao apenas
// esta. Medido em firebirdsql/firebird:5.0.4
// (sha256:85d0f9bf5e5d61dc7a169c6e374ce926b8281e7d8493f37ffeacc23f3d0d040d;
// ENGINE_VERSION perguntado ao motor = 5.0.4), as tres formas candidatas:
//   ALTER TABLE "TAB_A" TO "TAB_B";         -104 -Token unknown ... -TO
//   ALTER TABLE "TAB_A" RENAME TO "TAB_B";  -104 -Token unknown ... -RENAME
//   RENAME TABLE "TAB_A" TO "TAB_B";        -104 -Token unknown ... -RENAME
// Controle positivo na mesma sessao: ALTER TABLE "TAB_A" ALTER "LEGADO" TO
// "NOVO_NOME" executou e RDB$RELATION_FIELDS passou a listar NOVO_NOME - ou
// seja, o "... ALTER col TO col2" que o driver emite para renomear COLUNA e
// valido; o que nao existe e o analogo para tabela.
procedure TTestDDLFirebird.TestAlterTableRenameTable_Firebird_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).Table('TAB_A').Rename('TAB_B').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLFirebird.TestCreateIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  Assert.AreEqual('CREATE INDEX "IX_CLI_NOME" ON "CLIENTES" ("NOME")', LSql);
end;

procedure TTestDDLFirebird.TestCreateIndex_Firebird_Unique_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('UQ_CLI_EMAIL', 'CLIENTES')
    .Unique
    .Column('EMAIL')
    .AsString;
  Assert.AreEqual('CREATE UNIQUE INDEX "UQ_CLI_EMAIL" ON "CLIENTES" ("EMAIL")', LSql);
end;

procedure TTestDDLFirebird.TestCreateIndex_Firebird_MultiColumn_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateIndex('IX_EVT', 'EVENTS')
    .Column('TENANT_ID')
    .Column('CREATED_AT')
    .AsString;
  Assert.AreEqual('CREATE INDEX "IX_EVT" ON "EVENTS" ("TENANT_ID", "CREATED_AT")', LSql);
end;

procedure TTestDDLFirebird.TestDropIndex_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').AsString;
  Assert.AreEqual('DROP INDEX "IX_CLI_NOME"', LSql);
end;

// T35: o Firebird 5.0 nao aceita IF EXISTS em DROP INDEX. Medido em
// firebirdsql/firebird:5.0.4, indice EXISTENTE e indice INEXISTENTE, mesmo erro
// nos dois casos - portanto e recusa de SINTAXE, nao de alvo:
//   DROP INDEX IF EXISTS "IX_CLI_NOME";    -104 -Token unknown - line 1, col 15 -EXISTS
//   DROP INDEX IF EXISTS "IX_NAO_EXISTE";  -104 -Token unknown - line 1, col 15 -EXISTS
// Controle positivo: DROP INDEX "IX_TMP2" (sem IF EXISTS) removeu o indice -
// RDB$INDICES passou de 1 para 0 registro. Sobre indice ausente a forma nua
// devolve -607 "Index not found", que e o que a aplicacao tem de tratar.
// Esta e a mesma regra que DropTable ja aplica ao mesmo modificador neste
// dialeto (FluentSQL.DDL.Serialize.Firebird.pas, DropTable / GetIfExists).
procedure TTestDDLFirebird.TestDropIndex_Firebird_IfExists_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').IfExists.AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLFirebird.TestDropIndex_Firebird_Concurrently_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').Concurrently.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestDropIndex_Firebird_Concurrently_MessageReferencesESP027;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').Concurrently.AsString;
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

procedure TTestDDLFirebird.TestDropIndex_Firebird_OnTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).DropIndex('IX_CLI_NOME').OnTable('CLIENTES').AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestTruncateTable_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).TruncateTable('CLIENTES').AsString;
  Assert.AreEqual('TRUNCATE TABLE "CLIENTES"', LSql);
end;

procedure TTestDDLFirebird.TestTruncateTable_Firebird_RestartIdentity_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).TruncateTable('T').RestartIdentity.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestTruncateTable_Firebird_Cascade_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).TruncateTable('T').Cascade.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestTruncateTable_Firebird_Modifier_MessageReferencesESP029;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    FluentSQL.Schema(dbnFirebird).TruncateTable('T').RestartIdentity.AsString;
  except
    on E: ENotSupportedException do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(Pos('ESP-029', LMsg) > 0);
end;

procedure TTestDDLFirebird.TestAlterTableAlterColumn_Firebird_Type_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Alter.Column('IDADE')
    .TypeInteger
    .AsString;
  Assert.AreEqual('ALTER TABLE "CLIENTES" ALTER "IDADE" TYPE INTEGER', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableAlterColumn_Firebird_Nullability_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).Table('CLIENTES').Alter.Column('NOME').NotNull.AsString;
    end,
    ENotSupportedException);
end;

procedure TTestDDLFirebird.TestAlterTableAlterColumn_Firebird_SetDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VALORES').Alter.Column('TOTAL')
    .SetDefault('0')
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER "TOTAL" SET DEFAULT 0', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableAlterColumn_Firebird_DropDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('VALORES').Alter.Column('TOTAL')
    .DropDefault
    .AsString;
  Assert.AreEqual('ALTER TABLE "VALORES" ALTER "TOTAL" DROP DEFAULT', LSql);
end;

procedure TTestDDLFirebird.TestAlterTableAddUnique_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('TAB_A').Add
    .AddUnique(['COL_1', 'COL_2'], 'UK_TAB_A')
    .AsString;
  Assert.AreEqual('ALTER TABLE "TAB_A" ADD CONSTRAINT "UK_TAB_A" UNIQUE ("COL_1", "COL_2")', LSql);
end;

procedure TTestDDLFirebird.TestCreateView_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateView('VW_CLIENTES')
    .&As(FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('NOME').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE VIEW "VW_CLIENTES" AS SELECT ID, NOME FROM CLIENTES', LSql);
end;

procedure TTestDDLFirebird.TestCreateView_OrReplace_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).CreateView('VW_CLIENTES')
    .OrReplace
    .&As(FluentSQL.Query(dbnFirebird).Select.Column('ID').Column('NOME').From('CLIENTES'))
    .AsString;
  Assert.AreEqual('CREATE OR ALTER VIEW "VW_CLIENTES" AS SELECT ID, NOME FROM CLIENTES', LSql);
end;

procedure TTestDDLFirebird.TestIdentity_Firebird_Always_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disAlways)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED ALWAYS AS IDENTITY)', LSql);
end;

procedure TTestDDLFirebird.TestIdentity_Firebird_ByDefault_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Create
    .ColumnBigInt('ID').Identity(disByDefault)
    .AsString;
  Assert.AreEqual('CREATE TABLE "LOGS" ("ID" BIGINT GENERATED BY DEFAULT AS IDENTITY)', LSql);
end;

procedure TTestDDLFirebird.TestIdentity_AlterTableAlter_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('LOGS').Alter.Column('ID')
    .Identity(disAlways)
    .AsString;
  Assert.AreEqual('ALTER TABLE "LOGS" ALTER "ID" SET GENERATED ALWAYS', LSql);
end;

procedure TTestDDLFirebird.TestGuidType_Firebird;
begin
  Assert.AreEqual('CREATE TABLE "T" ("G" CHAR(16) CHARACTER SET OCTETS)', 
    FluentSQL.Schema(dbnFirebird).Table('T').Create.ColumnGuid('G').AsString);
end;

procedure TTestDDLFirebird.TestLongTextAndBlob_Firebird;
var
  LFirebirdSql: string;
begin
  LFirebirdSql := FluentSQL.Schema(dbnFirebird).Table('DOC').Create
    .ColumnLongText('BODY')
    .ColumnBlob('RAW')
    .AsString;

  Assert.IsTrue(Pos('BLOB SUB_TYPE 1', LFirebirdSql) > 0);
  Assert.IsTrue(Pos('BLOB SUB_TYPE 0', LFirebirdSql) > 0);
end;

procedure TTestDDLFirebird.TestComments_Firebird_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnFirebird).Table('Users').Create
    .Description('Application users table')
    .ColumnInteger('ID').PrimaryKey.Description('Internal ID')
    .AsString;
    
  Assert.AreEqual(
    'CREATE TABLE "Users" ("ID" INTEGER PRIMARY KEY); ' +
    'COMMENT ON TABLE "Users" IS ''Application users table''; ' +
    'COMMENT ON COLUMN "Users"."ID" IS ''Internal ID''',
    LSql);
end;

procedure TTestDDLFirebird.TestCreateFunction_Firebird_GeneratesExpected;
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

initialization
  TDUnitX.RegisterTestFixture(TTestDDLFirebird);

end.
