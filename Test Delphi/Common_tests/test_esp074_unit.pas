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
    procedure TestTruncateTable_MySQL_MultiTable_RaisesNotSupported;
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
    // T35: as cinco abaixo travam o contrato que esta rodada TORNOU
    // significativo - "PARTITION e so do MySQL". Antes delas, o modificador nao
    // produzia SQL valido em lugar nenhum e o comportamento dos outros cinco
    // dialetos era indiferente; agora um dialeto emite de verdade, e o que os
    // outros fazem passou a ser contrato. Nenhuma celula travava isso: provado
    // por mutacao - trocar o raise do PostgreSQL por uma emissao de
    // ' PARTITION (...)' passava pela suite inteira sem derrubar nada.
    [Test]
    procedure TestTruncateTable_PostgreSQL_Partition_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Firebird_Partition_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_MSSQL_Partition_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_Oracle_Partition_RaisesNotSupported;
    [Test]
    procedure TestTruncateTable_SQLite_Partition_RaisesNotSupported;
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

// T35: 'TRUNCATE TABLE `T1`, `T2`' NAO e MySQL. Medido em mysql:8.4
// (sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb,
// VERSION() = 8.4.11): ERROR 1064 (42000) ... near ', `T2`'. A lista de tabelas
// e exclusividade do PostgreSQL entre os 6 relacionais; as celulas
// TTestDDLTruncateTable.TestTruncateTable_MSSQL_MultiTable_RaisesNotSupported e
// TTestDDLTruncateTable.TestTruncateTable_Oracle_MultiTable_RaisesNotSupported,
// nesta mesma fixture, ja recusam a mesma construcao desde o ESP-074. O MySQL
// conhecia a regra e nao a aplicava a si.
//
// Citadas por ASSINATURA, e nao por numero de linha, porque a versao anterior
// deste comentario citava "linha 200" e "linha 180" e as duas ja nasceram
// erradas - endereco em comentario apodrece na primeira edicao do arquivo, e
// esta e a citacao que sustenta a tese "a convencao ja existia": quem a
// conferisse abriria no lugar errado e nao acharia convencao nenhuma.
procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_MultiTable_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMySQL).TruncateTable(['T1', 'T2']).AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

// T35: 'TRUNCATE TABLE `logs` PARTITION (p2023)' e sintaxe Oracle, e o MySQL a
// recusa - medido em mysql:8.4 (VERSION() = 8.4.11):
//   ERROR 1064 (42000) ... near 'PARTITION (p2023)' at line 1
// A UNICA forma que o MySQL tem para a operacao e ALTER TABLE ... TRUNCATE
// PARTITION, verificada ponta a ponta numa tabela particionada por RANGE: a
// particao p2023 foi de 1 para 0 linhas e a pmax ficou intacta com 1. Por ser a
// unica forma, nao ha desvio de semantica a declarar.
procedure TTestDDLTruncateTable.TestTruncateTable_MySQL_Partition_GeneratesExpected;
var
  LSql: string;
begin
  LSql := FluentSQL.Schema(dbnMySQL).TruncateTable('logs').Partition('p2023').AsString;
  Assert.AreEqual('ALTER TABLE `logs` TRUNCATE PARTITION `p2023`', LSql);
end;

// T35, HONESTIDADE SOBRE ESTA CELULA: ela levanta, e sempre levantou, mas desde
// que a guarda de multi-tabela entrou (o MySQL nao aceita lista de tabelas) e
// essa guarda que a atende - a de PARTITION nao e mais alcancada por ela. Isto
// e, esta celula passou a ser uma SEGUNDA medicao da guarda de multi-tabela, e
// nao uma medicao da combinacao "multi-tabela COM particao". Provado por
// mutacao: remover a guarda de multi-tabela mata esta celula junto com
// TestTruncateTable_MySQL_MultiTable_RaisesNotSupported; mexer no ramo de
// PARTITION nao a toca. Fica declarada assim em vez de ser reescrita para
// parecer o que nao e - e nao foi desligada, porque o que ela afirma continua
// verdadeiro: a chamada levanta.
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

{ T35 - AS CINCO GUARDAS DE PARTICAO.

  Por que existem, e por que so agora: ate esta rodada o .Partition(...) nao
  produzia SQL valido em dialeto NENHUM - o MySQL emitia sintaxe Oracle, que o
  motor recusa com ERROR 1064, e os outros cinco levantavam. Nesse mundo, o que
  os cinco faziam era indiferente. Esta rodada fez o MySQL emitir a forma que o
  motor aceita (ALTER TABLE t TRUNCATE PARTITION p, verificada ponta a ponta), e
  com isso nasceu um CONTRATO: particao e so do MySQL. Guarda de contrato que
  ninguem mede e guarda que alguem remove por acidente.

  Que nao havia medicao nenhuma foi provado por mutacao, nao suposto: trocar o
  raise do PostgreSQL por 'Result := Result + '' PARTITION ('' + ...' passava
  pela suite INTEIRA sem derrubar uma celula. Os unicos usos de .Partition( na
  suite eram os tres do MySQL.

  Estas cinco asserem a CLASSE da excecao, nao a mensagem - de proposito, e no
  padrao das celulas de multi-tabela logo acima. Mensagem nao e contrato aqui. }

procedure TTestDDLTruncateTable.TestTruncateTable_PostgreSQL_Partition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnPostgreSQL).TruncateTable('logs').Partition('p2023').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_Firebird_Partition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnFirebird).TruncateTable('logs').Partition('p2023').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_MSSQL_Partition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnMSSQL).TruncateTable('logs').Partition('p2023').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

// O Oracle TEM a construcao - ALTER TABLE t TRUNCATE PARTITION p - e mesmo
// assim o serializador recusa. Esta celula NAO afirma que o dialeto nao sabe
// particionar: afirma o que o build ENTREGA hoje, que e recusa, e recusa nao
// produz texto invalido. Se essa lacuna de CAPACIDADE deve ser preenchida e
// decisao de produto, catalogada e fora desta tarefa; no dia em que for, e esta
// celula que avisa que o contrato mudou.
procedure TTestDDLTruncateTable.TestTruncateTable_Oracle_Partition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnOracle).TruncateTable('logs').Partition('p2023').AsString;
    end,
    System.SysUtils.ENotSupportedException);
end;

procedure TTestDDLTruncateTable.TestTruncateTable_SQLite_Partition_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Schema(dbnSQLite).TruncateTable('logs').Partition('p2023').AsString;
    end,
    System.SysUtils.ENotSupportedException);
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
