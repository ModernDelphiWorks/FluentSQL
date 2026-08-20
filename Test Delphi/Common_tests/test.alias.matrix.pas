{
  ------------------------------------------------------------------------------
  FluentSQL - matriz do APELIDO por dialeto (T12)

  O que este arquivo trava: a palavra que antecede o apelido deixou de ser um
  literal do nucleo e passou a vir do serializador do dialeto
  (IFluentSQLSerialize.RelationAliasKeyword).

  A DISTINCAO QUE SUSTENTA TUDO - leia antes de mexer numa expectativa.

  TFluentSQLName serve os DOIS papeis. O mesmo objeto e o mesmo Serialize
  atendem:

    * apelido de COLUNA  - o no nasce em
                           TFluentSQL.Column(const AColumnName: String)
                           (FluentSQL.pas:626; o ASTColumns.Add esta na 630) e
                           NAO recebe marcacao nenhuma: fica com o valor inicial
                           cCOLUMN_ALIAS_KEYWORD = 'AS'
                           (FluentSQL.Name.pas:34, aplicado no construtor em
                           FluentSQL.Name.pas:97). Vai para FAST.ASTColumns.
    * apelido de RELACAO - o no nasce em
                           TFluentSQL.From(const ATableName: String)
                           (FluentSQL.pas:918; a marcacao AliasKeyword :=
                           _RelationAliasKeyword esta na 922) e em
                           TFluentSQL._CreateJoin (FluentSQL.pas:715; marcacao
                           na 723). Vai para FAST.ASTTableNames e para o
                           JoinedTable do join.

  CITAR SO O NOME DO METODO NAO IDENTIFICA NADA AQUI: Column tem quatro
  sobrecargas (FluentSQL.pas:626, 638, 655, 686) e From tem quatro
  (FluentSQL.pas:908, 913, 918, 1469). Por isso as linhas acima trazem a
  assinatura, e nao so o nome.

  A sobrecarga que o usuario chama para apelidar tabela e
  TFluentSQL.From(const ATableName, AAlias: String) (FluentSQL.pas:1469) - e ela
  NAO marca coisa alguma sozinha. Seu corpo inteiro e
  "From(ATableName).Alias(AAlias)": delega para a sobrecarga de String
  (FluentSQL.pas:918), que e onde a marcacao acontece, e so DEPOIS chama
  TFluentSQL.Alias (FluentSQL.pas:307), que apenas grava o texto do apelido.
  Mesma coisa para as quatro sobrecargas <Join>(tabela, apelido): delegam a
  _CreateJoin e depois a Alias.

  Consequencia que o leitor da matriz precisa: como as sobrecargas
  From(IFluentSQLCriteriaExpression) (FluentSQL.pas:908) e From(IFluentSQL)
  (FluentSQL.pas:913) tambem desaguam na de 918 - passando a subconsulta como
  texto entre parenteses -, a regra da relacao vale para elas pelo mesmo
  caminho, sem codigo proprio.

  TestApelidoDeSubconsultaSegueARegraDaRelacao trava isso com uma celula por
  dialeto para CADA UMA das tres portas que levam uma subconsulta ao FROM:

    1. From(const ATableName: String) (FluentSQL.pas:918) com o texto ja
       parentizado pelo chamador;
    2. From(const AQuery: IFluentSQL) (FluentSQL.pas:913);
    3. From(const AExpression: IFluentSQLCriteriaExpression)
       (FluentSQL.pas:908), com o criterio obtido de
       TFluentSQL.Expression(const ATerm: String) (FluentSQL.pas:903) - a
       porta da API fluente para montar um IFluentSQLCriteriaExpression a
       partir de texto (a irma da 896 recebe array of const).

  A celula 3 nao esta ai por simetria decorativa, e sim porque a ausencia dela
  foi MEDIDA: reescrever a 908 para montar o no por conta propria, sem
  "AliasKeyword := _RelationAliasKeyword", devolvia a Oracle ao
  "FROM (SELECT ...) AS S" do ORA-03048 com a suite INTEIRA verde - nenhum dos
  590 testes caia. Com a celula 3, a mesma mutacao derruba este teste.

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
    /// <summary>From(subconsulta) + Alias: a subconsulta e t_alias, nao c_alias.</summary>
    [Test]
    procedure TestApelidoDeSubconsultaSegueARegraDaRelacao;
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
  // Os seis sem unit em Source\Drivers (Informix, ADS, ASA, AbsoluteDB,
  // ElevateDB, NexusDB) estao aqui so para a tabela cobrir o enum inteiro: _Medivel
  // os descarta em runtime, porque _EstaRegistrado pega EFluentSQLDriverNotRegistered.
  cDIALETO: array[TFluentSQLDriver] of String = (
    'dbnMSSQL', 'dbnMySQL', 'dbnFirebird', 'dbnSQLite', 'dbnInterbase',
    'dbnDB2', 'dbnOracle', 'dbnInformix', 'dbnPostgreSQL', 'dbnADS', 'dbnASA',
    'dbnAbsoluteDB', 'dbnMongoDB', 'dbnElevateDB', 'dbnNexusDB'
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
    {dbnInformix}   '',  // sem driver: nunca medido (_Medivel filtra)
    {dbnPostgreSQL} 'AS',
    {dbnADS}        '',  // sem driver
    {dbnASA}        '',  // sem driver
    {dbnAbsoluteDB} '',  // sem driver
    {dbnMongoDB}    '',  // nao usado: MongoDB nao passa por esta matriz
    {dbnElevateDB}  '',  // sem driver
    {dbnNexusDB}    ''   // sem driver
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
  LEsperado: String;
  LCelulas: Integer;
begin
  // O DELETE cai no MESMO TFluentSQL.From (a assercao de secao aceita secSelect
  // e secDelete), entao ele acompanha a regra da PALAVRA sem codigo proprio.
  // Medido na Oracle: "DELETE FROM A AS AP" devolve ORA-03048; sem o AS,
  // executa.
  //
  // A FORMA da clausula, porem, NAO e universal, e este teste deixou de afirmar
  // que era. O T-SQL recusa as duas formas "DELETE FROM <relacao apelidada>":
  //   DELETE FROM A AS AP -> Msg 156   DELETE FROM A AP -> Msg 102
  // e exige "DELETE AP FROM A AS AP", com o apelido como alvo. Ate a T18 esta
  // celula fixava para o dbnMSSQL exatamente o texto que o motor recusa - ela
  // estava verde afirmando SQL invalido.
  //
  // Quem responde pela forma agora e test.delete.alias.matrix.pas, com a matriz
  // dos sete medida em motor real. Aqui fica so o que e desta matriz: a
  // PALAVRA do apelido, lida da mesma cPALAVRA_RELACAO das outras celulas.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    if LDriver = dbnMSSQL then
      LEsperado := 'DELETE AP FROM ' + _ComApelido(LDriver, 'A', 'AP')
    else
      LEsperado := 'DELETE FROM ' + _ComApelido(LDriver, 'A', 'AP');
    Assert.AreEqual(LEsperado + ' WHERE (AP.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString, False,
      cDIALETO[LDriver] + ': apelido de tabela no DELETE.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestAliasMatrix.TestApelidoDeSubconsultaSegueARegraDaRelacao;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A linha da tabela do CHANGELOG que faltava travar. A subconsulta apelidada
  // e t_alias como qualquer relacao, e nao tem UMA linha de codigo propria: as
  // duas sobrecargas que recebem subconsulta - From(IFluentSQL) na
  // FluentSQL.pas:913 e From(IFluentSQLCriteriaExpression) na 908 - desaguam na
  // de String (918), que e quem marca o no.
  // Este teste existe para que a equivalencia nao se perca numa refatoracao que
  // "otimize" QUALQUER uma das sobrecargas para montar o no por conta propria -
  // por isso ele tem celula para as TRES portas, e nao so para a mais usada.
  // Falsificado por mutacao, nao deduzido: quando so havia as celulas 1 e 2,
  // reescrever a 908 para montar o no sozinha passava com os 590 testes verdes.
  // Medido na Oracle: "FROM (SELECT ...) AS S" devolve ORA-03048; sem o AS,
  // devolve linha (secoes 10 e 11 de test.alias.oracle.sql).
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);

    // 1) subconsulta passada como texto - a forma que o CHANGELOG lista.
    Assert.AreEqual('SELECT * FROM ' +
      _ComApelido(LDriver, '(SELECT ID FROM A)', 'S'),
      Query(LDriver).Select.All.From('(SELECT ID FROM A)').Alias('S').AsString,
      False, cDIALETO[LDriver] + ': From(texto de subconsulta) + Alias.');

    // 2) subconsulta passada como IFluentSQL - mesmo destino, outro caminho.
    Assert.AreEqual('SELECT * FROM ' +
      _ComApelido(LDriver, '(SELECT ID FROM A)', 'S'),
      Query(LDriver).Select.All
        .From(Query(LDriver).Select.Column('ID').From('A')).Alias('S').AsString,
      False, cDIALETO[LDriver] + ': From(IFluentSQL) + Alias.');

    // 3) subconsulta passada como IFluentSQLCriteriaExpression - a TERCEIRA
    // porta, a unica que ficou sem celula ate aqui. O criterio nasce em
    // TFluentSQL.Expression(const ATerm: String) (FluentSQL.pas:903), que e a
    // unica forma publica de obter um IFluentSQLCriteriaExpression a partir de
    // texto; From(IFluentSQLCriteriaExpression) (FluentSQL.pas:908) so
    // parentiza o AsString dele e repassa para a sobrecarga de String.
    Assert.AreEqual('SELECT * FROM ' +
      _ComApelido(LDriver, '(SELECT ID FROM A)', 'S'),
      Query(LDriver).Select.All
        .From(Query(LDriver).Expression('SELECT ID FROM A')).Alias('S').AsString,
      False, cDIALETO[LDriver] + ': From(IFluentSQLCriteriaExpression) + Alias.');
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
