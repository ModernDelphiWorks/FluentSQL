{
  ------------------------------------------------------------------------------
  FluentSQL - matriz da FORMA do DELETE com apelido, por dialeto (T18)

  O que este arquivo trava: no DELETE, o apelido de relacao nao muda so a
  PALAVRA que o antecede - em um dialeto ele muda a FORMA da clausula inteira.

  A T12 resolveu a palavra (IFluentSQLSerialize.RelationAliasKeyword: 'AS' na
  base, '' na Oracle) e isso bastou para FROM e para JOIN. Nao basta para o
  DELETE do T-SQL, porque la o alvo da instrucao passa a ser o APELIDO e a
  tabela apelidada vai para um FROM proprio:

      DELETE AP FROM A AS AP WHERE ...
             ^^        ^^^^^

  MEDIDO EM MOTOR REAL, nao deduzido da doc. A transcricao literal, com o
  docker run e a versao perguntada a cada motor, esta em
  test.delete.alias.matrix.sql, nesta mesma pasta. Resumo do que cada motor
  respondeu para "DELETE FROM A <ap>", que e o que o FluentSQL emitia:

    MSSQL 2022 16.0.4265.3   DELETE FROM A AS AP  -> Msg 156 (RECUSA)
                             DELETE FROM A AP     -> Msg 102 (RECUSA)
                             DELETE AP FROM A AS AP -> executa
    Oracle 23.26.2.0.0       DELETE FROM A AS AP  -> ORA-03048 (RECUSA)
                             DELETE FROM A AP     -> executa
    PostgreSQL 16.14         DELETE FROM A AS AP  -> executa
    MySQL 8.4.11             DELETE FROM A AS AP  -> executa
    Firebird 5.0.4           DELETE FROM A AS AP  -> executa
    SQLite 3.53.4            DELETE FROM A AS AP  -> executa
                             DELETE FROM A AP     -> RECUSA (exige o AS)
    DB2 12.1.5.0             DELETE FROM A AS AP  -> executa

  NAO EXISTE FORMA UNICA. As tres formas medidas se excluem duas a duas: o
  T-SQL e o unico que aceita "DELETE ap FROM t AS ap"; a Oracle e a unica que
  recusa o AS; a SQLite e a unica que recusa a ausencia dele. A interseccao dos
  sete e VAZIA para apelido em DELETE - por isso a forma e do dialeto, e nao ha
  denominador comum a adotar.

  ONDE A REGRA MORA, E POR QUE NAO NO QUALIFICADOR: em
  IFluentSQLSerialize.DeleteClause(const ADelete: IFluentSQLDelete): String,
  virtual na base (FluentSQL.Serialize.pas) e sobrescrita apenas em
  FluentSQL.SerializeMSSQL.pas. O qualificador esta descartado pelo mesmo motivo
  da T12: TFluentSQLSelectDB2 instancia o qualificador da ORACLE
  (FluentSQL.SelectDB2.pas:46), entao regra hospedada la faria o DB2 herdar
  calado a forma de outro dialeto.

  ANTI-COLATERAL: os testes que comecam por "TestNao..." afirmam o que NAO podia
  mudar - DELETE sem apelido, SELECT com apelido, apelido de COLUNA. Cada um
  deles foi falsificado por mutacao dirigida: a tabela de mutacoes esta no
  relatorio da tarefa, e nenhum deles fica verde sob a mutacao que o ataca.

  CAIXA: todo Assert.AreEqual aqui passa False no parametro IgnoreCase. O padrao
  do DUnitX ignora maiuscula/minuscula - numa biblioteca cujo produto E texto
  SQL isso deixaria "as" passar por "AS".
  ------------------------------------------------------------------------------
}

unit test.delete.alias.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDeleteAliasMatrix = class
  public
    /// <summary>A forma emitida por dialeto, texto exato e case-sensitive.</summary>
    [Test]
    procedure TestFormaDoDeleteComApelidoPorDialeto;
    /// <summary>MSSQL: o alvo do DELETE e o apelido, e "DELETE FROM" nao abre a instrucao.</summary>
    [Test]
    procedure TestMSSQLDeleteComApelidoTemOApelidoComoAlvo;
    /// <summary>MSSQL: sem apelido nada muda - continua "DELETE FROM T".</summary>
    [Test]
    procedure TestNaoMudouODeleteSemApelidoEmDialetoNenhum;
    /// <summary>O SELECT com apelido nao foi tocado: "FROM A AS AP" segue igual.</summary>
    [Test]
    procedure TestNaoMudouOApelidoDeRelacaoNoSelect;
    /// <summary>O apelido de COLUNA continua com AS em todo dialeto.</summary>
    [Test]
    procedure TestNaoMudouOApelidoDeColuna;
    /// <summary>Os dialetos que nao sao MSSQL seguem abrindo com "DELETE FROM".</summary>
    [Test]
    procedure TestNaoMudouAFormaDosDemaisDialetos;
    /// <summary>MongoDB nao produz SQL: o DELETE dele e MQL e nao passa por aqui.</summary>
    [Test]
    procedure TestMongoDBNaoEAfetado;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

const
  cDIALETO: array[TFluentSQLDriver] of String = (
    'dbnMSSQL', 'dbnMySQL', 'dbnFirebird', 'dbnSQLite', 'dbnInterbase',
    'dbnDB2', 'dbnOracle', 'dbnPostgreSQL', 'dbnMongoDB'
  );

type
  /// <summary>
  ///   fdFromComAS   -> DELETE FROM A AS AP     (padrao da base)
  ///   fdFromSemAS   -> DELETE FROM A AP        (Oracle; RelationAliasKeyword = '')
  ///   fdAlvoApelido -> DELETE AP FROM A AS AP  (T-SQL; forma propria)
  /// </summary>
  TFormaDelete = (fdFromComAS, fdFromSemAS, fdAlvoApelido);

const
  /// <summary>
  ///   A forma medida de cada dialeto. Esta tabela e a EXPECTATIVA; a fonte da
  ///   verdade no codigo e IFluentSQLSerialize.DeleteClause somada a
  ///   IFluentSQLSerialize.RelationAliasKeyword. Divergir aqui e vermelho de
  ///   proposito.
  ///
  ///   O Interbase esta em fdFromComAS por HERANCA, nao por medicao: nao existe
  ///   imagem publica de InterBase e ele nao foi executado em motor nenhum nesta
  ///   tarefa. TFluentSQLSerializeInterbase descende da base e nao sobrescreve
  ///   nem DeleteClause nem RelationAliasKeyword, entao o que ele emite e o
  ///   texto da base - e e isso, e so isso, que a celula abaixo afirma.
  /// </summary>
  cFORMA: array[TFluentSQLDriver] of TFormaDelete = (
    {dbnMSSQL}      fdAlvoApelido,
    {dbnMySQL}      fdFromComAS,
    {dbnFirebird}   fdFromComAS,
    {dbnSQLite}     fdFromComAS,
    {dbnInterbase}  fdFromComAS,
    {dbnDB2}        fdFromComAS,
    {dbnOracle}     fdFromSemAS,
    {dbnPostgreSQL} fdFromComAS,
    {dbnMongoDB}    fdFromComAS  // nao usado: MongoDB nao passa por esta matriz
  );

/// <summary>
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.alias.matrix.pas.
/// </summary>
function _EstaRegistrado(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    Query(ADriver).Select.All.From('T').AsString;
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
  end;
end;

function _Medivel(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := (ADriver <> dbnMongoDB) and _EstaRegistrado(ADriver);
end;

/// <summary>Como o primeiro bind aparece no texto. O MySQL troca :pN por ?.</summary>
function _Bind(const ADriver: TFluentSQLDriver): String;
begin
  if ADriver = dbnMySQL then
    Result := '?'
  else
    Result := ':p1';
end;

/// <summary>A clausula DELETE inteira que este dialeto deve emitir.</summary>
function _ClausulaDelete(const ADriver: TFluentSQLDriver;
  const ATabela, AApelido: String): String;
begin
  case cFORMA[ADriver] of
    fdFromSemAS:   Result := 'DELETE FROM ' + ATabela + ' ' + AApelido;
    fdAlvoApelido: Result := 'DELETE ' + AApelido + ' FROM ' + ATabela +
                             ' AS ' + AApelido;
  else
    Result := 'DELETE FROM ' + ATabela + ' AS ' + AApelido;
  end;
end;

procedure TTestDeleteAliasMatrix.TestFormaDoDeleteComApelidoPorDialeto;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual(_ClausulaDelete(LDriver, 'A', 'AP') +
      ' WHERE (AP.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString,
      False, cDIALETO[LDriver] + ': forma do DELETE com apelido.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteAliasMatrix.TestMSSQLDeleteComApelidoTemOApelidoComoAlvo;
var
  LSql: String;
begin
  // A celula que nomeia o defeito. Antes desta tarefa o MSSQL emitia
  // "DELETE FROM A AS AP WHERE (AP.ID = :p1)" e o motor devolvia
  // "Msg 156, Incorrect syntax near the keyword 'AS'" - SQL que nao executa.
  // Tirar so o AS nao salva: "DELETE FROM A AP" devolve "Msg 102, Incorrect
  // syntax near 'AP'". As duas recusas estao transcritas em
  // test.delete.alias.matrix.sql, secoes 01 e 02.
  if not _Medivel(dbnMSSQL) then
    Exit;
  LSql := Query(dbnMSSQL).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString;

  Assert.AreEqual('DELETE AP FROM A AS AP WHERE (AP.ID = :p1)', LSql, False,
    'T-SQL: o alvo do DELETE e o apelido e o FROM carrega a tabela apelidada.');
  Assert.IsFalse(LSql.StartsWith('DELETE FROM'),
    'No T-SQL com apelido a instrucao NAO pode abrir com DELETE FROM.');
  Assert.DoesNotContain(LSql, '  ', False,
    'Concatenacao nao pode deixar espaco duplo.');
end;

procedure TTestDeleteAliasMatrix.TestNaoMudouODeleteSemApelidoEmDialetoNenhum;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ANTI-COLATERAL. A forma nova so pode aparecer quando ha apelido. Sem
  // apelido, os sete continuam em "DELETE FROM T WHERE ...", que e o que
  // emitiam antes - inclusive o MSSQL.
  // Falsificado por mutacao: emitir a forma do T-SQL tambem com apelido vazio
  // ("DELETE  FROM A") derruba a celula do dbnMSSQL deste teste.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('DELETE FROM A WHERE (ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A').Where('ID').Equal(1).AsString, False,
      cDIALETO[LDriver] + ': DELETE sem apelido nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteAliasMatrix.TestNaoMudouOApelidoDeRelacaoNoSelect;
var
  LDriver: TFluentSQLDriver;
  LEsperado: String;
  LCelulas: Integer;
begin
  // ANTI-COLATERAL. A forma nova e do DELETE, nao do FROM. O SELECT com apelido
  // continua exatamente como a T12 o deixou.
  // Falsificado por mutacao: fazer DeleteClause do MSSQL alterar o AliasKeyword
  // do no (em vez de montar texto proprio) contamina o FROM do SELECT e derruba
  // a celula do dbnMSSQL daqui.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    if LDriver = dbnOracle then
      LEsperado := 'SELECT * FROM A AP'
    else
      LEsperado := 'SELECT * FROM A AS AP';
    Assert.AreEqual(LEsperado,
      Query(LDriver).Select.All.From('A', 'AP').AsString, False,
      cDIALETO[LDriver] + ': apelido de relacao no SELECT nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteAliasMatrix.TestNaoMudouOApelidoDeColuna;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ANTI-COLATERAL. TFluentSQLName serve apelido de COLUNA e de TABELA na mesma
  // classe; correcao que nao distingue conserta a tabela e quebra a coluna.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('SELECT NOME AS N FROM A',
      Query(LDriver).Select.Column('NOME').Alias('N').From('A').AsString, False,
      cDIALETO[LDriver] + ': apelido de COLUNA nao muda em dialeto nenhum.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteAliasMatrix.TestNaoMudouAFormaDosDemaisDialetos;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
  LSql: String;
begin
  // ANTI-COLATERAL. Sobrescrever DeleteClause na BASE em vez de no MSSQL levaria
  // a forma do T-SQL para os outros seis de uma vez. Este teste e o que cai
  // nesse caso.
  // Falsificado por mutacao: mover a sobrescrita de DeleteClause do
  // TFluentSQLSerializerMSSQL para TFluentSQLSerialize derruba as celulas de
  // todos os dialetos nao-MSSQL daqui.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if (LDriver = dbnMSSQL) or (not _Medivel(LDriver)) then
      Continue;
    Inc(LCelulas);
    LSql := Query(LDriver).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString;
    Assert.IsTrue(LSql.StartsWith('DELETE FROM A'),
      cDIALETO[LDriver] + ': este dialeto tem de continuar abrindo com DELETE FROM A.');
    Assert.DoesNotContain(LSql, 'DELETE AP', False,
      cDIALETO[LDriver] + ': a forma do T-SQL nao pode vazar para este dialeto.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteAliasMatrix.TestMongoDBNaoEAfetado;
var
  LSql: String;
begin
  // MongoDB fica fora da matriz porque nao produz SQL. O DELETE dele vira
  // documento MQL e nao passa por DeleteClause nenhum. Este teste existe para
  // que isso continue verdade.
  LSql := Query(dbnMongoDB).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString;
  Assert.DoesNotContain(LSql, 'DELETE AP', False,
    'A forma do T-SQL nao pode aparecer em MQL.');
  Assert.DoesNotContain(LSql, 'DELETE FROM', False,
    'MQL nao carrega a clausula DELETE FROM.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeleteAliasMatrix);

end.
