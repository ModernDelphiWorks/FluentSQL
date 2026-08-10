{
  ------------------------------------------------------------------------------
  FluentSQL - matriz do APELIDO por dialeto (T12)

  O que este arquivo trava: a palavra que antecede o apelido deixou de ser um
  literal do nucleo e passou a vir do serializador do dialeto
  (IFluentSQLSerialize.RelationAliasKeyword).

  A DISTINCAO QUE SUSTENTA TUDO - leia antes de mexer numa expectativa.

  TFluentSQLName serve os DOIS papeis. O mesmo objeto e o mesmo Serialize
  atendem:

    * apelido de COLUNA  - montado em TFluentSQL.Column (FluentSQL.pas:608),
                           vai para FAST.ASTColumns;
    * apelido de RELACAO - montado em TFluentSQL.From (FluentSQL.pas:898) e em
                           TFluentSQL._CreateJoin (FluentSQL.pas:700), vai para
                           FAST.ASTTableNames e para o JoinedTable do join.

  A Oracle trata os dois de forma OPOSTA: aceita "col AS ap" e RECUSA
  "tabela AS ap". Por isso a correcao nao pode ser "tirar o AS do Serialize" -
  isso consertaria a tabela e quebraria a coluna. Todo teste daqui existe aos
  PARES: um afirma o que mudou na relacao, o outro afirma o que NAO mudou na
  coluna.

  MEDIDO EM MOTOR REAL, nao deduzido da doc: a transcricao das execucoes esta em
  test.alias.oracle.sql, nesta mesma pasta.

  CAIXA: todo Assert.AreEqual aqui passa False no parametro IgnoreCase. O padrao
  do DUnitX e comparar SQL sem distinguir maiuscula de minuscula - numa
  biblioteca cujo produto E texto SQL, isso deixaria "as" passar por "AS".
  ------------------------------------------------------------------------------
}

unit test.alias.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAliasMatrix = class
  public
    /// <summary>From(tabela, apelido) em cada dialeto registrado.</summary>
    [Test]
    procedure TestApelidoDeRelacaoNoFrom;
    /// <summary>As quatro sobrecargas de join com apelido, em cada dialeto.</summary>
    [Test]
    procedure TestApelidoDeRelacaoNosQuatroJoins;
    /// <summary>Delete.From(tabela, apelido): mesma regra, mesma recusa na Oracle.</summary>
    [Test]
    procedure TestApelidoDeRelacaoNoDeleteFrom;
    /// <summary>O contraste: apelido de COLUNA continua com AS em TODO dialeto.</summary>
    [Test]
    procedure TestApelidoDeColunaContinuaComASEmTodoDialeto;
    /// <summary>Oracle: nenhuma forma de apelido de relacao carrega a palavra AS.</summary>
    [Test]
    procedure TestOracleNaoEmiteASAntesDeApelidoDeRelacao;
    /// <summary>Oracle: coluna e relacao na MESMA consulta, cada uma com sua forma.</summary>
    [Test]
    procedure TestOracleApelidoDeColunaEDeRelacaoNaMesmaConsulta;
    /// <summary>Anti-colateral: os outros dialetos nao perderam o AS.</summary>
    [Test]
    procedure TestDemaisDialetosRelacionaisMantiveramAS;
    /// <summary>MongoDB nao e SQL: o apelido vira chave de $lookup/$project, nao palavra.</summary>
    [Test]
    procedure TestMongoDBNaoEAfetadoPelaPalavraDoApelido;
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

  /// <summary>
  ///   A palavra que cada dialeto usa antes do apelido de RELACAO. Esta tabela
  ///   e a expectativa; a fonte da verdade no codigo e
  ///   IFluentSQLSerialize.RelationAliasKeyword. Divergir aqui e vermelho de
  ///   proposito.
  ///
  ///   O DB2 fica com 'AS' e isso e uma DECISAO, nao um descuido: o DB2 herda o
  ///   qualificador da Oracle (FluentSQL.SelectDB2.pas:46 instancia
  ///   TFluentSQLSelectQualifiersOracle e deixa TFluentSQLSelectQualifiersDB2
  ///   inalcancavel). Se a regra do apelido morasse no qualificador, o DB2
  ///   passaria a emitir "T AP" sem que ninguem tivesse decidido isso. Ela mora
  ///   no serializador, e TFluentSQLSerializeDB2 descende da base - por isso o
  ///   DB2 continua em 'AS', que e o que o correlation-clause dele aceita.
  /// </summary>
  cPALAVRA_RELACAO: array[TFluentSQLDriver] of String = (
    {dbnMSSQL}      'AS',
    {dbnMySQL}      'AS',
    {dbnFirebird}   'AS',
    {dbnSQLite}     'AS',
    {dbnInterbase}  'AS',
    {dbnDB2}        'AS',
    {dbnOracle}     '',
    {dbnPostgreSQL} 'AS',
    {dbnMongoDB}    ''   // nao usado: MongoDB nao passa por esta matriz
  );

/// <summary>
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.pagination.filter.pas.
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

/// <summary>Relacional e registrado: os unicos que produzem texto SQL comparavel.</summary>
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

/// <summary>"B AS X" ou "B X", conforme o dialeto. Sem espaco duplo.</summary>
function _ComApelido(const ADriver: TFluentSQLDriver;
  const ARelacao, AApelido: String): String;
begin
  if cPALAVRA_RELACAO[ADriver] = '' then
    Result := ARelacao + ' ' + AApelido
  else
    Result := ARelacao + ' ' + cPALAVRA_RELACAO[ADriver] + ' ' + AApelido;
end;

procedure TTestAliasMatrix.TestApelidoDeRelacaoNoFrom;
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
    Assert.AreEqual('SELECT * FROM ' + _ComApelido(LDriver, 'CLIENTES', 'CLI'),
      Query(LDriver).Select.All.From('CLIENTES', 'CLI').AsString, False,
      cDIALETO[LDriver] + ': apelido de tabela no FROM.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestAliasMatrix.TestApelidoDeRelacaoNosQuatroJoins;
var
  LDriver: TFluentSQLDriver;
  LEsperado: String;
  LCelulas: Integer;
begin
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    LEsperado := 'SELECT * FROM A %s JOIN ' + _ComApelido(LDriver, 'B', 'X') +
                 ' ON X.A_ID = A.ID';

    Assert.AreEqual(Format(LEsperado, ['INNER']),
      Query(LDriver).Select.All.From('A').InnerJoin('B', 'X')
        .OnCond('X.A_ID = A.ID').AsString, False,
      cDIALETO[LDriver] + ': InnerJoin(tabela, apelido).');

    Assert.AreEqual(Format(LEsperado, ['LEFT']),
      Query(LDriver).Select.All.From('A').LeftJoin('B', 'X')
        .OnCond('X.A_ID = A.ID').AsString, False,
      cDIALETO[LDriver] + ': LeftJoin(tabela, apelido).');

    Assert.AreEqual(Format(LEsperado, ['RIGHT']),
      Query(LDriver).Select.All.From('A').RightJoin('B', 'X')
        .OnCond('X.A_ID = A.ID').AsString, False,
      cDIALETO[LDriver] + ': RightJoin(tabela, apelido).');

    Assert.AreEqual(Format(LEsperado, ['FULL']),
      Query(LDriver).Select.All.From('A').FullJoin('B', 'X')
        .OnCond('X.A_ID = A.ID').AsString, False,
      cDIALETO[LDriver] + ': FullJoin(tabela, apelido).');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestAliasMatrix.TestApelidoDeRelacaoNoDeleteFrom;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // O DELETE cai no MESMO TFluentSQL.From (a assercao de secao aceita secSelect
  // e secDelete), entao ele acompanha a regra sem codigo proprio. Medido na
  // Oracle: "DELETE FROM A AS AP" devolve ORA-03048; sem o AS, executa.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('DELETE FROM ' + _ComApelido(LDriver, 'A', 'AP') +
      ' WHERE (AP.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString, False,
      cDIALETO[LDriver] + ': apelido de tabela no DELETE FROM.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestAliasMatrix.TestApelidoDeColunaContinuaComASEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // O CONTRASTE. Se este teste ficar vermelho junto com os de cima, a correcao
  // nao distinguiu os dois papeis de TFluentSQLName e derrubou o apelido de
  // coluna junto - inclusive na Oracle, onde ele e valido e a doc do SELECT diz
  // que "The AS keyword is optional" para c_alias.
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

procedure TTestAliasMatrix.TestOracleNaoEmiteASAntesDeApelidoDeRelacao;
begin
  Assert.AreEqual('SELECT * FROM CLIENTES CLI',
    Query(dbnOracle).Select.All.From('CLIENTES', 'CLI').AsString, False,
    'FROM T AS AP devolve ORA-03048 na Oracle.');

  Assert.AreEqual('SELECT * FROM A LEFT JOIN B X ON X.A_ID = A.ID',
    Query(dbnOracle).Select.All.From('A').LeftJoin('B', 'X')
      .OnCond('X.A_ID = A.ID').AsString, False,
    'LEFT JOIN B AS X devolve ORA-02000 na Oracle.');

  // Espaco duplo seria sintaxe valida mas texto sujo, e denunciaria que a
  // palavra vazia foi concatenada em vez de descartada por TUtils.Concat.
  Assert.DoesNotContain(
    Query(dbnOracle).Select.All.From('CLIENTES', 'CLI').AsString, '  ', False,
    'Palavra vazia nao pode virar espaco duplo.');
end;

procedure TTestAliasMatrix.TestOracleApelidoDeColunaEDeRelacaoNaMesmaConsulta;
begin
  // A consulta que so passa se as DUAS regras convivem. Executada no motor:
  // "SELECT AP.NOME AS N FROM A AP LEFT JOIN B X ON (X.A_ID = AP.ID)" devolve
  // linha; trocar qualquer um dos dois lados a derruba.
  Assert.AreEqual(
    'SELECT AP.NOME AS N FROM A AP LEFT JOIN B X ON X.A_ID = AP.ID',
    Query(dbnOracle).Select.Column('AP.NOME').Alias('N').From('A', 'AP')
      .LeftJoin('B', 'X').OnCond('X.A_ID = AP.ID').AsString, False,
    'Na Oracle a coluna leva AS e a relacao nao, na mesma consulta.');
end;

procedure TTestAliasMatrix.TestDemaisDialetosRelacionaisMantiveramAS;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // Anti-colateral explicito. A alternativa recusada nesta tarefa era "emitir
  // sem AS em TODOS", que os sete aceitam - ela teria trocado o texto de seis
  // dialetos para consertar um. Se alguem a adotar mais tarde, este teste cai.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if (LDriver = dbnOracle) or (not _Medivel(LDriver)) then
      Continue;
    Inc(LCelulas);
    Assert.Contains(Query(LDriver).Select.All.From('CLIENTES', 'CLI').AsString,
      'CLIENTES AS CLI', False,
      cDIALETO[LDriver] + ': o texto deste dialeto nao podia mudar na T12.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestAliasMatrix.TestMongoDBNaoEAfetadoPelaPalavraDoApelido;
var
  LSql: String;
begin
  // MongoDB fica fora da matriz de texto SQL porque nao produz SQL. O apelido
  // dele nunca passa por TFluentSQLName.Serialize: o serializador de MQL le a
  // propriedade Alias e a transforma em "as" do $lookup. Este teste existe para
  // que isso continue verdade - se um dia o MQL comecar a exibir a palavra do
  // apelido, ele cai.
  LSql := Query(dbnMongoDB).Select.All.From('A').LeftJoin('B', 'X')
            .OnCond('X.A_ID = A.ID').AsString;
  Assert.Contains(LSql, '"as":"X"', False,
    'O apelido do MongoDB e chave de $lookup.');
  Assert.DoesNotContain(LSql, ' AS ', False,
    'MQL nao carrega a palavra AS.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAliasMatrix);

end.
