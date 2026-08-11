{
  ------------------------------------------------------------------------------
  FluentSQL - matriz do LITERAL DE DATA em DEFAULT de coluna, por dialeto (T19)

  POR QUE ESTE ARQUIVO EXISTE

  TUtils.DateToSQLFormat emitia, para dbnOracle, o literal CRU entre aspas:

      "D" DATE DEFAULT '2024-04-14'

  e o Oracle RECUSA esse texto. Medido em Oracle AI Database 26ai Free Release
  23.26.2.0.0 (gvenzl/oracle-free:23-slim), sessao com o NLS_DATE_FORMAT DE
  FABRICA (DD-MON-RR):

      D DATE DEFAULT '2026-08-10'          -> ORA-01861 literal does not match
                                              format string
      D DATE DEFAULT DATE '2026-08-10'     -> Table created, e o INSERT devolve
                                              2026-08-10
      D TIMESTAMP DEFAULT '2026-08-10 12:34:56'
                                           -> ORA-01843 invalid month
      D TIMESTAMP DEFAULT TIMESTAMP '2026-08-10 12:34:56'
                                           -> Table created, e o INSERT devolve
                                              2026-08-10 12:34:56

  O literal cru so funciona no Oracle quando NLS_DATE_FORMAT ja e ISO - medido
  tambem: apos ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD' a MESMA sentenca
  passa a criar a tabela. Ou seja, o texto antigo nao estava "quase certo": ele
  dependia de configuracao de sessao que o framework nao controla. O literal
  ANSI tipado nao depende de NLS nenhum.

  A PERGUNTA QUE DECIDIU O DESENHO: EXISTE UMA FORMA SO?

  Nao. Medido nos sete, na posicao DEFAULT de coluna:

    dialeto           '2026-08-10' cru      DATE '2026-08-10'
    ----------------------------------------------------------------------
    Oracle 23ai       ORA-01861 RECUSA      aceita
    PostgreSQL 16.14  aceita                aceita
    Firebird 5.0.4    aceita                aceita
    DB2 12.1.5.0      aceita                aceita
    MySQL 8.4         aceita                ERRO 1067 RECUSA (so entre
                                            parenteses, e ai vira expressao)
    SQLite 3.53.4     aceita                parse error RECUSA (nem entre
                                            parenteses)
    SQL Server 2022   aceita                Msg 128 RECUSA ("The name DATE is
                                            not permitted in this context")
    InterBase         NAO MEDIDO - nao existe imagem publica.

  Nao ha interseccao: a forma que o Oracle EXIGE e recusada por tres dos outros
  seis, e a forma que os outros seis aceitam e a que o Oracle recusa. Por isso a
  correcao e um RAMO DE DIALETO em TUtils.DateToSQLFormat /
  TUtils.DateTimeToSQLFormat, e nao uma troca no caminho comum. Quem nao e
  dbnOracle continua emitindo byte a byte o que emitia.

  ESTE TESTE E ANTI-COLATERAL, E ELE CAI DE VERDADE

  Falsificado por mutacao dirigida, nao deduzido - ver a tabela de mutacoes no
  relatorio da T19:
    * estender o ramo do Oracle a dbnMSSQL derruba a celula do MSSQL daqui e
      TestDateAndGuidDefault_MSSQL de test.ddl.mssql.pas;
    * estender o ramo a dbnPostgreSQL/dbnMySQL/dbnSQLite/dbnFirebird derruba as
      celulas correspondentes daqui;
    * remover o ramo do Oracle (voltar ao texto antigo) derruba as duas celulas
      de Oracle daqui.

  CAIXA: todo Assert.AreEqual daqui passa False em IgnoreCase. O default do
  DUnitX ignora maiuscula/minuscula, e numa biblioteca cujo produto E texto SQL
  isso deixaria "date" passar por "DATE".

  A TRANSCRICAO LITERAL de cada submissao, com digest de imagem, versao
  perguntada ao motor e controle positivo/negativo, esta em
  Test Delphi\Common_tests\test.date.literal.matrix.sql.
  ------------------------------------------------------------------------------
}

unit test.date.literal.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDateLiteralMatrix = class
  public
    /// <summary>Oracle: DEFAULT de coluna DATE sai como literal ANSI tipado.</summary>
    [Test]
    procedure TestOracleEmiteLiteralAnsiDeData;
    /// <summary>Oracle: DEFAULT de coluna TIMESTAMP sai como literal ANSI tipado.</summary>
    [Test]
    procedure TestOracleEmiteLiteralAnsiDeTimestamp;
    /// <summary>Anti-colateral: os demais dialetos seguem com o literal cru.</summary>
    [Test]
    procedure TestDemaisDialetosSeguemComLiteralCru;
    /// <summary>Anti-colateral do DATETIME nos demais dialetos.</summary>
    [Test]
    procedure TestDemaisDialetosSeguemComLiteralCruNoTimestamp;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

/// <summary>
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.computed.column.matrix.pas. Sem isto
///   a matriz passaria a MEDIR MENOS conforme os defines, calada.
/// </summary>
function _EstaRegistrado(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    FluentSQL.Schema(ADriver).Table('T').Create.ColumnInteger('A').AsString;
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
    on E: ENotSupportedException do
    begin
      // So a ausencia de registro tira o dialeto da matriz. Qualquer outro
      // ENotSupportedException e defeito e tem de continuar subindo.
      if Pos('DDL serialize', E.Message) = 0 then
        raise;
      Result := False;
    end;
  end;
end;

function _DefaultDeData(const ADriver: TFluentSQLDriver): String;
begin
  Result := FluentSQL.Schema(ADriver).Table('T').Create
    .ColumnDate('D').DefaultValue('2024-04-14')
    .AsString;
end;

function _DefaultDeTimestamp(const ADriver: TFluentSQLDriver): String;
begin
  Result := FluentSQL.Schema(ADriver).Table('T').Create
    .ColumnDateTime('D').DefaultValue('2024-04-14 12:34:56')
    .AsString;
end;

procedure TTestDateLiteralMatrix.TestOracleEmiteLiteralAnsiDeData;
var
  LSql: String;
begin
  if not _EstaRegistrado(dbnOracle) then
    Assert.Fail('dbnOracle nao registrado: esta celula nao mede nada sem ele.');
  LSql := _DefaultDeData(dbnOracle);
  Assert.AreEqual(
    'CREATE TABLE "T" ("D" DATE DEFAULT DATE ''2024-04-14'')',
    LSql, False,
    'Oracle: literal ANSI tipado - o cru devolve ORA-01861 com o ' +
    'NLS_DATE_FORMAT de fabrica.');
  // A forma exata que o motor recusou, travada como texto proibido: se alguem
  // reintroduzir o literal cru por outro caminho, esta linha cai mesmo que a de
  // cima tenha sido reescrita junto.
  Assert.DoesNotContain(LSql, 'DEFAULT ''2024-04-14''', False,
    'ORA-01861 no Oracle 23ai: literal cru em DEFAULT de coluna DATE.');
end;

procedure TTestDateLiteralMatrix.TestOracleEmiteLiteralAnsiDeTimestamp;
var
  LSql: String;
begin
  if not _EstaRegistrado(dbnOracle) then
    Assert.Fail('dbnOracle nao registrado: esta celula nao mede nada sem ele.');
  LSql := _DefaultDeTimestamp(dbnOracle);
  Assert.AreEqual(
    'CREATE TABLE "T" ("D" TIMESTAMP DEFAULT TIMESTAMP ''2024-04-14 12:34:56'')',
    LSql, False,
    'Oracle: literal ANSI tipado - o cru devolve ORA-01843.');
  Assert.DoesNotContain(LSql, 'DEFAULT ''2024-04-14 12:34:56''', False,
    'ORA-01843 no Oracle 23ai: literal cru em DEFAULT de coluna TIMESTAMP.');
end;

procedure TTestDateLiteralMatrix.TestDemaisDialetosSeguemComLiteralCru;
var
  LCelulas: Integer;
begin
  // O CONTRASTE. Se a correcao do Oracle tivesse ido para o caminho comum,
  // TODAS estas celulas cairiam - e tres delas fixam texto que o respectivo
  // motor RECUSA na forma ANSI (MSSQL Msg 128, MySQL 1067, SQLite parse error).
  LCelulas := 0;

  if _EstaRegistrado(dbnMSSQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE [T] ([D] DATE DEFAULT ''2024-04-14'')',
      _DefaultDeData(dbnMSSQL), False,
      'SQL Server 2022 aceita o literal cru e RECUSA DATE ''...'' (Msg 128).');
  end;

  if _EstaRegistrado(dbnPostgreSQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "T" ("D" DATE DEFAULT ''2024-04-14'')',
      _DefaultDeData(dbnPostgreSQL), False,
      'PostgreSQL 16.14 aceita o literal cru (medido: cria e devolve 2026-08-10).');
  end;

  if _EstaRegistrado(dbnMySQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE `T` (`D` DATE DEFAULT ''2024-04-14'')',
      _DefaultDeData(dbnMySQL), False,
      'MySQL 8.4 aceita o literal cru e RECUSA DATE ''...'' solto (ERRO 1067).');
  end;

  if _EstaRegistrado(dbnSQLite) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE `T` (`D` TEXT DEFAULT ''2024-04-14'')',
      _DefaultDeData(dbnSQLite), False,
      'SQLite 3.53.4 aceita o literal cru e RECUSA DATE ''...'' (parse error).');
  end;

  if _EstaRegistrado(dbnFirebird) then
  begin
    // ============================================================ ATENCAO
    // Esta celula fixa o formato US mm/dd/yyyy que o framework emite para
    // Firebird/Interbase desde sempre. O QUE ESTA ENTREGA MEDIU no Firebird
    // 5.0.4, e so isto:
    //   D DATE DEFAULT '04/14/2026'  -> cria, e o INSERT devolve 2026-04-14
    //   D DATE DEFAULT '12/13/2026'  -> cria, e o INSERT devolve 2026-12-13
    //
    // NAO mexer no ramo dbnFirebird/dbnInterbase e decisao de ESCOPO: a T19
    // nasceu do defeito do Oracle e nao foi encarregada de decidir o formato
    // de outro dialeto. NAO leia esta celula como "nao ha nada a rever no
    // Firebird" - ela nao mediu terreno suficiente para dizer isso.
    //
    // NAO MEDIDO POR ESTA ENTREGA, e a atribuicao importa: a REVISAO da T19
    // mediu que '13/12/2026' e RECUSADO pelo Firebird com SQLSTATE 22018
    // (conversion error from string). O MOMENTO da recusa depende do caminho:
    // por CAST ela e IMEDIATA, e pelo DEFAULT de coluna - que e o que o
    // framework emite - ela e DIFERIDA: o CREATE TABLE PASSA e o erro so
    // aparece no INSERT. Uma versao anterior deste comentario afirmava o
    // contrario ("o motor tambem aceita '13/12/2026', caindo para DD/MM") por
    // INFERENCIA: o CREATE nao reclamou e o valor nunca foi lido. Nao havia
    // medicao por tras da frase.
    //
    // A falha DIFERIDA de literal de data no Firebird esta catalogada como
    // tarefa propria PELO ORQUESTRADOR desta fila - sem identificador
    // atribuido ate aqui, e nao invento numero. Medir isso direito nao e
    // desta entrega.
    // ====================================================================
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "T" ("D" DATE DEFAULT ''04/14/2024'')',
      _DefaultDeData(dbnFirebird), False,
      'Firebird 5.0.4 aceita o formato US - medido, nao suposto.');
  end;

  Assert.IsTrue(LCelulas >= 4,
    Format('A matriz mediu so %d dialetos: build sem os drivers da promessa?',
      [LCelulas]));
end;

procedure TTestDateLiteralMatrix.TestDemaisDialetosSeguemComLiteralCruNoTimestamp;
var
  LCelulas: Integer;
begin
  LCelulas := 0;

  if _EstaRegistrado(dbnMSSQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE [T] ([D] DATETIME2 DEFAULT ''2024-04-14 12:34:56'')',
      _DefaultDeTimestamp(dbnMSSQL), False,
      'SQL Server 2022 RECUSA TIMESTAMP ''...'' (Msg 128).');
  end;

  if _EstaRegistrado(dbnPostgreSQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "T" ("D" TIMESTAMP DEFAULT ''2024-04-14 12:34:56'')',
      _DefaultDeTimestamp(dbnPostgreSQL), False,
      'PostgreSQL 16.14 aceita o literal cru.');
  end;

  if _EstaRegistrado(dbnMySQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE `T` (`D` DATETIME DEFAULT ''2024-04-14 12:34:56'')',
      _DefaultDeTimestamp(dbnMySQL), False,
      'MySQL 8.4 RECUSA TIMESTAMP ''...'' solto (ERRO 1067).');
  end;

  if _EstaRegistrado(dbnSQLite) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE `T` (`D` DATETIME DEFAULT ''2024-04-14 12:34:56'')',
      _DefaultDeTimestamp(dbnSQLite), False,
      'SQLite 3.53.4 RECUSA TIMESTAMP ''...'' (parse error).');
  end;

  if _EstaRegistrado(dbnFirebird) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "T" ("D" TIMESTAMP DEFAULT ''04/14/2024 12:34:56'')',
      _DefaultDeTimestamp(dbnFirebird), False,
      'Firebird 5.0.4 aceita o formato US com hora - medido.');
  end;

  Assert.IsTrue(LCelulas >= 4,
    Format('A matriz mediu so %d dialetos: build sem os drivers da promessa?',
      [LCelulas]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDateLiteralMatrix);

end.
