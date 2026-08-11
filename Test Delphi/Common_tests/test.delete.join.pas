{
  ------------------------------------------------------------------------------
  FluentSQL - JOIN dentro do DELETE: a construcao NAO existe (T30)

  O que este arquivo trava: Delete.From(A).InnerJoin(B) - e LeftJoin, RightJoin
  e FullJoin - deixa de emitir SQL e passa a levantar
  EFluentSQLConstructNotSupported, em todo dialeto.

  ⭐ POR QUE RECUSAR, E A RAZAO NAO E "O TEXTO NAO EXECUTA". Essa e verdadeira e
  e a menor das duas. A que decide e esta:

    Delete.From('A','X').LeftJoin('B','Y').OnCond('Y.AID = X.ID')   SEM Where

  A forma NATIVA que corresponde a essa chamada - "DELETE X FROM A AS X LEFT
  JOIN B AS Y ON Y.AID = X.ID" - foi medida em motor real com contagem antes e
  depois, massa de 4 linhas em A das quais 2 casam com B:

    SQL Server 2022 16.0.4265.3   A: 4 -> 0     B: 2 -> 2     APAGOU TUDO
    MySQL 8.4.11                  A: 4 -> 0     B: 2 -> 2     APAGOU TUDO

  Os dois executam, reportam SUCESSO e apagam a tabela inteira. Na juncao
  EXTERNA a condicao e DECORATIVA: ela nao filtra nada, porque a juncao preserva
  toda linha da relacao da esquerda. O usuario escreve o que parece um filtro e
  perde a tabela, sem uma linha de erro.

  E a MESMA CLASSE do achado do Oracle no PR #160 - apagar MAIS do que se pediu,
  sem erro. La era a tabela errada; aqui e a tabela certa, inteira. Nao e caso
  isolado: e classe conhecida, e e por isso que esta porta se fecha em vez de se
  traduzir.

  POR QUE A FAMILIA INTEIRA, E NAO SO O LEFT. Porque dentro do DELETE os membros
  da familia NAO significam a mesma coisa: o InnerJoin FILTRA (a forma nativa
  apaga 2 das 4), o LeftJoin NAO (apaga 4 das 4). Deixar .InnerJoin passar e
  .LeftJoin levantar seria uma distincao que a superficie fluente nao insinua e
  que gramatica nenhuma dos sete espelha - 5 dos 7 recusam os dois por parse, 2
  dos 7 aceitam os dois.

  O QUE SE PERDE, DITO SEM MAQUIAGEM: para o InnerJoin ISOLADO existe forma
  portavel, medida e aceita pelos sete - "DELETE FROM A WHERE EXISTS (SELECT 1
  FROM B WHERE ...)". Recusar tira essa conveniencia. Ela esta catalogada como
  tarefa propria, com o custo ja medido (o WHERE precisa migrar para dentro da
  subconsulta, porque pode citar a relacao juntada). Nao se entrega junto porque
  entregar so metade da familia e a distincao silenciosa descrita acima.

  A SAIDA QUE O USUARIO TEM HOJE, e que a mensagem da guarda aponta:

    Delete.From('A','X').Where('').Exists('SELECT 1 FROM B AS Y WHERE Y.AID = X.ID')

  Ela FUNCIONA - a subconsulta sai verbatim nos sete desde o conserto de
  IFluentSQL.Exists. TestSaidaApontadaPelaMensagemRealmenteEmiteSubconsulta
  trava isso: se o Exists voltar a parametrizar, a mensagem vira mentira e o
  teste fica vermelho.

  O CASO DO "ON" PENDURADO E PROPRIO, e nao um subcaso. Sem OnCond o builder
  emitia "DELETE FROM A AS X INNER JOIN B AS Y ON" - com ON e sem predicado.
  Nao e produto cartesiano: e SENTENCA TRUNCADA, e os sete a recusam. O DB2 e
  quem nomeia melhor: SQL0104N, token "END-OF-STATEMENT" apos "INNER JOIN B AS
  Y ON", esperado "<boolean_predicate>". A guarda desta tarefa o alcanca POR
  CIMA, porque fecha na porta do JOIN antes de qualquer serializacao - mas a
  CAUSA continua la: TFluentSQLJoins.Serialize (Source\Core\FluentSQL.Joins.pas)
  concatena 'ON' incondicionalmente e TUtils.Concat descarta a condicao vazia,
  o que produz o mesmo ON pendurado TAMBEM NO SELECT. Isso e de OUTRA tarefa e
  NAO esta consertado aqui.

  ONDE A GUARDA MORA: em TFluentSQL._CreateJoin (Source\Core\FluentSQL.pas), que
  e o unico ponto por onde InnerJoin, LeftJoin, RightJoin e FullJoin passam -
  os quatro delegam a ele. Uma guarda, quatro portas fechadas. Ela NAO e um
  _AssertSection generico de proposito: aquele levanta Exception cru com "Not
  supported in this section", e quem recebe a recusa precisa do TIPO proprio e
  da mensagem que aponta a saida.

  ANTI-COLATERAL: os testes "TestNao..." afirmam TEXTO EXATO do que nao podia
  mudar - SELECT com JOIN (nos quatro tipos) e DELETE sem JOIN (com e sem
  apelido). Cada um foi falsificado por mutacao dirigida na propria guarda; a
  tabela esta no relatorio da tarefa.

  CAIXA: todo Assert.AreEqual aqui passa False no parametro IgnoreCase. O padrao
  do DUnitX ignora maiuscula/minuscula - numa biblioteca cujo produto E texto
  SQL isso deixaria "as" passar por "AS".

  A MATRIZ EM MOTOR REAL, com digest de imagem, versao perguntada ao motor,
  transcricao literal e controle positivo e negativo, esta em
  test.delete.join.matrix.sql, nesta mesma pasta.
  ------------------------------------------------------------------------------
}

unit test.delete.join;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDeleteJoin = class
  public
    /// <summary>InnerJoin num DELETE levanta em todo dialeto relacional.</summary>
    [Test]
    procedure TestInnerJoinNoDeleteLevantaEmTodoDialeto;
    /// <summary>LeftJoin idem - e e ELE o motivo da recusa.</summary>
    [Test]
    procedure TestLeftJoinNoDeleteLevantaEmTodoDialeto;
    /// <summary>RightJoin idem: a familia inteira, nao uma amostra.</summary>
    [Test]
    procedure TestRightJoinNoDeleteLevantaEmTodoDialeto;
    /// <summary>FullJoin idem.</summary>
    [Test]
    procedure TestFullJoinNoDeleteLevantaEmTodoDialeto;
    /// <summary>Com apelido tambem - era o UNICO caminho que um motor aceitava.</summary>
    [Test]
    procedure TestComApelidoTambemLevantaEmTodoDialeto;
    /// <summary>Sem OnCond: a sentenca truncada tambem para na porta.</summary>
    [Test]
    procedure TestSemOnCondTambemLevanta;
    /// <summary>Dois joins encadeados: a guarda pega no PRIMEIRO.</summary>
    [Test]
    procedure TestDoisJoinsLevantamNoPrimeiro;
    /// <summary>A excecao e NOMEADA e capturavel pelo tipo.</summary>
    [Test]
    procedure TestExcecaoENomeadaECapturavelPeloTipo;
    /// <summary>A mensagem LIDERA pelo dano, nao pela taxonomia.</summary>
    [Test]
    procedure TestMensagemLideraPeloDanoSilencioso;
    /// <summary>A mensagem diz que vale para a familia toda.</summary>
    [Test]
    procedure TestMensagemDizQueValeParaAFamiliaInteira;
    /// <summary>A mensagem aponta a saida que funciona.</summary>
    [Test]
    procedure TestMensagemApontaASaidaQueFunciona;
    /// <summary>A mensagem NAO nomeia dialeto: trocar de banco nao resolve.</summary>
    [Test]
    procedure TestMensagemNaoNomeiaDialeto;
    /// <summary>A saida apontada pela mensagem realmente emite subconsulta.</summary>
    [Test]
    procedure TestSaidaApontadaPelaMensagemRealmenteEmiteSubconsulta;
    /// <summary>ANTI-COLATERAL: SELECT com INNER JOIN, texto exato.</summary>
    [Test]
    procedure TestNaoMudouOSelectComInnerJoin;
    /// <summary>ANTI-COLATERAL: SELECT com os outros tres tipos de join.</summary>
    [Test]
    procedure TestNaoMudouOSelectComOsOutrosTiposDeJoin;
    /// <summary>ANTI-COLATERAL: DELETE sem JOIN, com apelido, texto exato.</summary>
    [Test]
    procedure TestNaoMudouODeleteSemJoinComApelido;
    /// <summary>ANTI-COLATERAL: DELETE sem JOIN, sem apelido, texto exato.</summary>
    [Test]
    procedure TestNaoMudouODeleteSemJoinSemApelido;
    /// <summary>A guarda le o estado VIVO: Select depois de Delete libera o JOIN.</summary>
    [Test]
    procedure TestSelectDepoisDeDeleteLiberaOJoin;
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
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.delete.multirelacao.pas.
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

/// <summary>
///   MongoDB fica FORA da conta: nao produz SQL e esta fora da promessa
///   relacional. A guarda o alcanca de graca por ser de nucleo - e isso e um
///   efeito, nao uma promessa desta tarefa.
/// </summary>
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

/// <summary>
///   A palavra do apelido de RELACAO neste dialeto. Vem da T12 e nao e assunto
///   desta tarefa - esta aqui so para o anti-colateral poder afirmar TEXTO
///   EXATO em vez de prefixo.
/// </summary>
function _ComApelido(const ADriver: TFluentSQLDriver;
  const ATabela, AApelido: String): String;
begin
  if ADriver = dbnOracle then
    Result := ATabela + ' ' + AApelido
  else
    Result := ATabela + ' AS ' + AApelido;
end;

procedure TTestDeleteJoin.TestInnerJoinNoDeleteLevantaEmTodoDialeto;
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
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A').InnerJoin('B').OnCond('B.AID = A.ID')
          .Where('A.X').Equal(1).AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': INNER JOIN no DELETE tem de levantar, nao emitir.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestLeftJoinNoDeleteLevantaEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ESTA e a celula que carrega a razao da tarefa. A forma nativa que
  // corresponde a esta chamada apagou as 4 de 4 linhas de A no SQL Server e no
  // MySQL - medido, com contagem antes e depois, sem WHERE nenhum.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').LeftJoin('B', 'Y')
          .OnCond('Y.AID = X.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': LEFT JOIN no DELETE tem de levantar - a forma ' +
      'nativa apaga a tabela inteira em silencio.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestRightJoinNoDeleteLevantaEmTodoDialeto;
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
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').RightJoin('B', 'Y')
          .OnCond('Y.AID = X.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': RIGHT JOIN no DELETE tem de levantar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestFullJoinNoDeleteLevantaEmTodoDialeto;
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
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').FullJoin('B', 'Y')
          .OnCond('Y.AID = X.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': FULL JOIN no DELETE tem de levantar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestComApelidoTambemLevantaEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // O caminho COM apelido era o unico em que ALGUM motor aceitava o texto
  // emitido: "DELETE X FROM A AS X INNER JOIN B AS Y ON ..." executa no SQL
  // Server e no MySQL (medido, A 4->3). Recusar so o caminho sem apelido
  // deixaria de pe justamente a metade que executa - e que executa com a
  // armadilha do LEFT ao lado.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').InnerJoin('B', 'Y')
          .OnCond('Y.AID = X.ID').Where('X.ID').Equal(1).AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': INNER JOIN com apelido no DELETE tem de levantar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestSemOnCondTambemLevanta;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // Sem OnCond o texto saia com ON PENDURADO - "... INNER JOIN B AS Y ON", sem
  // predicado. Nao e produto cartesiano, e sentenca truncada, e os sete a
  // recusam. A guarda pega antes disso, na porta do JOIN.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').InnerJoin('B', 'Y').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': JOIN sem OnCond no DELETE tem de levantar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestDoisJoinsLevantamNoPrimeiro;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A guarda le a secao ATIVA, entao dispara na PRIMEIRA chamada de join e
  // nunca chega a ver a segunda. Esta celula cobre o encadeamento, que nao e o
  // mesmo caso do join unico.
  //
  // ⚠️ CORRECAO DE UMA AFIRMACAO QUE A MUTACAO DESMENTIU. A primeira versao
  // deste comentario dizia que uma guarda que so olhasse o SEGUNDO join
  // manteria este teste VERDE. E FALSO, e a mutacao dirigida mostrou: ao trocar
  // a condicao por "(FActiveSection = secDelete) and (FAST.Joins.Count > 0)"
  // este teste ficou VERMELHO junto com os outros onze. A razao e que o
  // PRIMEIRO join, ao passar, faz FActiveSection := secJoin - entao na segunda
  // chamada a secao ja NAO e secDelete e a guarda nunca dispara. Nao existe,
  // aqui, mutacao "so o segundo join" que sobreviva: a secao deixa de ser
  // secDelete assim que o primeiro passa. Fica escrito porque o comentario
  // errado ja estava no arquivo antes de a mutacao ser rodada.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X')
          .InnerJoin('B', 'Y').OnCond('Y.AID = X.ID')
          .InnerJoin('C', 'Z').OnCond('Z.BID = Y.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': dois JOINs no DELETE tem de levantar no primeiro.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestExcecaoENomeadaECapturavelPeloTipo;
var
  LClasse: String;
begin
  // "Levanta alguma coisa" nao e contrato. Sem tipo proprio, quem consome nao
  // distingue esta recusa de um Exception cru vindo de _AssertSection nem do
  // EArgumentOutOfRangeException que o MongoDB devolvia.
  LClasse := '';
  try
    Query(dbnMSSQL).Delete.From('A').InnerJoin('B').AsString;
  except
    on E: Exception do
      LClasse := E.ClassName;
  end;
  Assert.AreEqual('EFluentSQLConstructNotSupported', LClasse, False,
    'A recusa tem de chegar com tipo proprio, nao como Exception generico.');
end;

procedure TTestDeleteJoin.TestMensagemLideraPeloDanoSilencioso;
var
  LMsg: String;
begin
  // A mensagem tem de dizer o DANO, nao a taxonomia. Quem le "a familia nao tem
  // uma semantica" nao muda de comportamento; quem le "apaga a tabela inteira
  // sem erro" muda.
  LMsg := '';
  try
    Query(dbnPostgreSQL).Delete.From('A', 'X').LeftJoin('B', 'Y')
      .OnCond('Y.AID = X.ID').AsString;
  except
    on E: EFluentSQLConstructNotSupported do
      LMsg := E.Message;
  end;
  Assert.IsTrue(LMsg <> '', 'A guarda nao levantou EFluentSQLConstructNotSupported.');
  Assert.Contains(LMsg, 'apaga a tabela inteira', False,
    'A mensagem tem de liderar pelo DANO: a forma nativa do LEFT apaga tudo.');
  Assert.Contains(LMsg, 'silencio', False,
    'A mensagem tem de dizer que o dano e SILENCIOSO - o motor reporta sucesso.');
end;

procedure TTestDeleteJoin.TestMensagemDizQueValeParaAFamiliaInteira;
var
  LMsg: String;
begin
  // Quem levar um erro no LeftJoin nao pode sair achando que o InnerJoin passa.
  LMsg := '';
  try
    Query(dbnFirebird).Delete.From('A').InnerJoin('B').AsString;
  except
    on E: EFluentSQLConstructNotSupported do
      LMsg := E.Message;
  end;
  Assert.IsTrue(LMsg <> '', 'A guarda nao levantou EFluentSQLConstructNotSupported.');
  Assert.Contains(LMsg, 'JOIN em DELETE', False,
    'A mensagem tem de nomear a construcao recusada.');
  // A afirmacao e a RAZAO, nao a mencao. Citar "InnerJoin" e "LeftJoin" em
  // qualquer lugar do texto nao prova nada: a primeira versao deste teste so
  // pedia as duas palavras, e a mutacao que APAGOU a razao ("O InnerJoin filtra
  // e o LeftJoin nao") o manteve VERDE, porque as palavras sobrevivem em outros
  // trechos da mensagem. Medido. Por isso aqui se exige o contraste.
  Assert.Contains(LMsg, 'InnerJoin filtra', False,
    'A mensagem tem de dizer que o InnerJoin FILTRA - e a metade do contraste.');
  Assert.Contains(LMsg, 'LeftJoin nao', False,
    'A mensagem tem de dizer que o LeftJoin NAO filtra - e a outra metade, e ' +
    'e o contraste que explica por que a familia inteira cai.');
end;

procedure TTestDeleteJoin.TestMensagemApontaASaidaQueFunciona;
var
  LMsg: String;
begin
  // Recusar sem saida e pior que o defeito. A mensagem tem de nomear a porta
  // que ABRE - e TestSaidaApontadaPelaMensagemRealmenteEmiteSubconsulta prova
  // que ela abre mesmo.
  LMsg := '';
  try
    Query(dbnSQLite).Delete.From('A').InnerJoin('B').AsString;
  except
    on E: EFluentSQLConstructNotSupported do
      LMsg := E.Message;
  end;
  Assert.IsTrue(LMsg <> '', 'A guarda nao levantou EFluentSQLConstructNotSupported.');
  Assert.Contains(LMsg, 'Exists', False,
    'A mensagem tem de apontar a saida portavel: Where(...).Exists(subconsulta).');
end;

procedure TTestDeleteJoin.TestMensagemNaoNomeiaDialeto;
var
  LMsg: String;
  LDriver: TFluentSQLDriver;
begin
  // A recusa e a MESMA nos sete. Nomear um dialeto mandaria quem le tentar
  // outro banco - o caminho errado, porque nenhum resolve. O dano do LEFT, que
  // a mensagem descreve, foi medido em dois motores; a mensagem diz "dois
  // motores" e NAO quais, de proposito.
  LMsg := '';
  try
    Query(dbnOracle).Delete.From('A').InnerJoin('B').AsString;
  except
    on E: EFluentSQLConstructNotSupported do
      LMsg := E.Message;
  end;
  Assert.IsTrue(LMsg <> '', 'A guarda nao levantou EFluentSQLConstructNotSupported.');
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    Assert.DoesNotContain(LMsg, Copy(cDIALETO[LDriver], 4, MaxInt), False,
      'A mensagem nao pode nomear dialeto: citou ' + cDIALETO[LDriver] + '.');
  Assert.DoesNotContain(LMsg, 'SQL Server', False,
    'A mensagem nao pode nomear dialeto.');
end;

procedure TTestDeleteJoin.TestSaidaApontadaPelaMensagemRealmenteEmiteSubconsulta;
var
  LDriver: TFluentSQLDriver;
  LSql: String;
  LCelulas: Integer;
begin
  // Se IFluentSQL.Exists voltar a PARAMETRIZAR a subconsulta - como fazia antes
  // do conserto, emitindo "WHERE (exists :p1)" - a saida que esta guarda aponta
  // deixa de existir e a mensagem vira mentira. Esta celula e quem pega isso.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    LSql := Query(LDriver).Delete.From('A', 'X')
              .Where('').Exists('SELECT 1 FROM B AS Y WHERE Y.AID = X.ID').AsString;
    Assert.Contains(LSql, 'SELECT 1 FROM B AS Y WHERE Y.AID = X.ID', False,
      cDIALETO[LDriver] + ': a subconsulta tem de sair VERBATIM, nao como bind.');
    Assert.DoesNotContain(LSql, 'exists ' + _Bind(LDriver), False,
      cDIALETO[LDriver] + ': a subconsulta virou valor de bind outra vez.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestNaoMudouOSelectComInnerJoin;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // JOIN em SELECT e a razao de existir do recurso e nao pode ter sido tocado.
  // Texto EXATO, nao prefixo.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual(
      'SELECT * FROM ' + _ComApelido(LDriver, 'A', 'X') +
      ' INNER JOIN ' + _ComApelido(LDriver, 'B', 'Y') +
      ' ON Y.AID = X.ID WHERE (X.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Select.All.From('A', 'X').InnerJoin('B', 'Y')
        .OnCond('Y.AID = X.ID').Where('X.ID').Equal(1).AsString,
      False,
      cDIALETO[LDriver] + ': SELECT com INNER JOIN nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestNaoMudouOSelectComOsOutrosTiposDeJoin;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A guarda mora em _CreateJoin, por onde os QUATRO tipos passam. Se ela
  // olhasse o tipo do join em vez da secao, ou se errasse a condicao, o SELECT
  // dos outros tres cairia junto - e so o INNER estaria coberto acima.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual(
      'SELECT * FROM ' + _ComApelido(LDriver, 'A', 'X') +
      ' LEFT JOIN ' + _ComApelido(LDriver, 'B', 'Y') + ' ON Y.AID = X.ID',
      Query(LDriver).Select.All.From('A', 'X').LeftJoin('B', 'Y')
        .OnCond('Y.AID = X.ID').AsString,
      False, cDIALETO[LDriver] + ': SELECT com LEFT JOIN nao podia mudar.');
    Assert.AreEqual(
      'SELECT * FROM ' + _ComApelido(LDriver, 'A', 'X') +
      ' RIGHT JOIN ' + _ComApelido(LDriver, 'B', 'Y') + ' ON Y.AID = X.ID',
      Query(LDriver).Select.All.From('A', 'X').RightJoin('B', 'Y')
        .OnCond('Y.AID = X.ID').AsString,
      False, cDIALETO[LDriver] + ': SELECT com RIGHT JOIN nao podia mudar.');
    Assert.AreEqual(
      'SELECT * FROM ' + _ComApelido(LDriver, 'A', 'X') +
      ' FULL JOIN ' + _ComApelido(LDriver, 'B', 'Y') + ' ON Y.AID = X.ID',
      Query(LDriver).Select.All.From('A', 'X').FullJoin('B', 'Y')
        .OnCond('Y.AID = X.ID').AsString,
      False, cDIALETO[LDriver] + ': SELECT com FULL JOIN nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestNaoMudouODeleteSemJoinComApelido;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
  LEsperado: String;
begin
  // DELETE de uma relacao com apelido executa nos sete (medido na T18) e nao
  // podia ser atingido. O dbnMSSQL emite a forma com designador de alvo.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    if LDriver = dbnMSSQL then
      LEsperado := 'DELETE X FROM ' + _ComApelido(LDriver, 'A', 'X')
    else
      LEsperado := 'DELETE FROM ' + _ComApelido(LDriver, 'A', 'X');
    Assert.AreEqual(
      LEsperado + ' WHERE (X.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A', 'X').Where('X.ID').Equal(1).AsString,
      False,
      cDIALETO[LDriver] + ': DELETE sem JOIN com apelido nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestNaoMudouODeleteSemJoinSemApelido;
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
    Assert.AreEqual(
      'DELETE FROM A WHERE (A.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A').Where('A.ID').Equal(1).AsString,
      False,
      cDIALETO[LDriver] + ': DELETE sem JOIN sem apelido nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestSelectDepoisDeDeleteLiberaOJoin;
var
  LSql: String;
begin
  // A guarda le a secao ATIVA no momento da chamada, nao uma marca que fica
  // grudada na instancia. Se ela fosse um sinalizador pegajoso, esta mesma
  // IFluentSQL nunca mais aceitaria um JOIN depois de ter passado pelo Delete.
  LSql := Query(dbnPostgreSQL).Delete.From('A')
            .Select.All.From('A', 'X').InnerJoin('B', 'Y')
            .OnCond('Y.AID = X.ID').AsString;
  Assert.AreEqual(
    'SELECT * FROM A AS X INNER JOIN B AS Y ON Y.AID = X.ID', LSql, False,
    'Trocar para a secao SELECT tem de liberar o JOIN de novo.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeleteJoin);

end.
