{
  ------------------------------------------------------------------------------
  FluentSQL - JOIN dentro do DELETE: a construcao NAO existe (T30)

  O que este arquivo trava: Delete.From(A).InnerJoin(B) - e LeftJoin, RightJoin
  e FullJoin - deixa de emitir SQL e passa a levantar
  EFluentSQLConstructNotSupported, em todo dialeto, EM QUALQUER ORDEM DA CADEIA
  FLUENTE.

  ⚠️ "EM QUALQUER ORDEM" E PARTE DA AFIRMACAO, e nao enfeite. A primeira versao
  desta guarda lia a secao ATIVA (FActiveSection = secDelete), e por isso
  QUALQUER chamada que trocasse a secao entre o From e o join a desarmava -
  Where, OrderBy, GroupBy. Where('') nao emite uma letra e ja bastava:

    Delete.From('A','X').Where('').LeftJoin('B','Y').OnCond('Y.AID = X.ID')
    -> DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID

  que e byte a byte a sentenca medida em A: 4 -> 0. O agravante: Where e
  exatamente a chamada que a mensagem da guarda RECOMENDA como saida.

  A primeira versao destes testes nao viu o furo porque punha o join sempre
  IMEDIATAMENTE depois do From - uma ordem so. As celulas
  Test*EntreOFromEOJoin* existem por causa disso, e percorrem os QUATRO tipos.

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
    /// <summary>ORDEM INTERCALADA: Where('') entre o From e o join nao desarma.</summary>
    [Test]
    procedure TestWhereVazioEntreOFromEOJoinNaoDesarmaAGuarda;
    /// <summary>ORDEM INTERCALADA: Where com predicado, nos QUATRO tipos.</summary>
    [Test]
    procedure TestWhereComPredicadoEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
    /// <summary>ORDEM INTERCALADA: OrderBy entre o From e o join, nos QUATRO tipos.</summary>
    [Test]
    procedure TestOrderByEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
    /// <summary>ORDEM INTERCALADA: GroupBy entre o From e o join, nos QUATRO tipos.</summary>
    [Test]
    procedure TestGroupByEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
    /// <summary>ORDEM INTERCALADA: a saida recomendada nao vira, ela propria, o desvio.</summary>
    [Test]
    procedure TestASaidaRecomendadaNaoDesarmaAGuarda;
    /// <summary>Delete SEM From: nao ha marca duravel, mas a secao ativa pega.</summary>
    [Test]
    procedure TestDeleteSemFromTambemRecusaOJoin;
    /// <summary>A guarda le o estado VIVO: Select depois de Delete libera o JOIN.</summary>
    [Test]
    procedure TestSelectDepoisDeDeleteLiberaOJoin;
    /// <summary>Insert depois de Delete tambem limpa a marca duravel.</summary>
    [Test]
    procedure TestInsertDepoisDeDeleteLimpaAMarcaDuravel;
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
  // "LIDERA" e afirmacao de POSICAO, e a primeira versao deste teste nao a
  // media: so pedia a substring, em qualquer lugar. Uma mensagem que jogasse o
  // dano para o fim, rotulado "detalhe tecnico secundario", passava. Medido por
  // mutacao. Agora se exige que o dano venha na PRIMEIRA METADE do texto.
  Assert.IsTrue(Pos('apaga a tabela inteira', LMsg) > 0, 'substring ausente.');
  Assert.IsTrue(Pos('apaga a tabela inteira', LMsg) < (Length(LMsg) div 2),
    'O dano tem de LIDERAR: aparecer na primeira metade da mensagem, nao no fim.');
  // E o NUMERO medido tem de estar travado. Sem ele a mensagem vira adjetivo, e
  // adjetivo nao sobrevive a uma reescrita distraida.
  Assert.Contains(LMsg, '4 de 4', False,
    'A mensagem tem de carregar a contagem MEDIDA, nao so o adjetivo.');
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
  // A primeira versao pedia so a palavra "Exists" - e uma mensagem que dissesse
  // "consulte a documentacao sobre Exists" passava, sem dar saida nenhuma.
  // Medido por mutacao. A saida tem de vir ESCRITA, em forma copiavel: a
  // chamada e um exemplo de subconsulta que o leitor possa adaptar.
  Assert.Contains(LMsg, 'Where(...).Exists(', False,
    'A mensagem tem de trazer a CHAMADA da saida, nao so a palavra Exists.');
  Assert.Contains(LMsg, 'SELECT 1 FROM', False,
    'A saida tem de vir com exemplo copiavel de subconsulta.');
  Assert.DoesNotContain(LMsg, 'documentacao', False,
    'Mandar consultar documentacao nao e dar saida.');
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

/// <summary>
///   Aplica o join do tipo pedido a uma IFluentSQL ja montada. Existe para que
///   as celulas de ORDEM INTERCALADA percorram os QUATRO tipos sem quatro
///   copias do mesmo corpo - foi testar UM arranjo que deixou o furo passar, e
///   nao se conserta isso escrevendo menos combinacoes.
/// </summary>
function _AplicaJoin(const AQuery: IFluentSQL; const ATipo: Integer): IFluentSQL;
begin
  case ATipo of
    0: Result := AQuery.InnerJoin('B', 'Y');
    1: Result := AQuery.LeftJoin('B', 'Y');
    2: Result := AQuery.RightJoin('B', 'Y');
  else
    Result := AQuery.FullJoin('B', 'Y');
  end;
end;

function _NomeDoTipo(const ATipo: Integer): String;
begin
  case ATipo of
    0: Result := 'InnerJoin';
    1: Result := 'LeftJoin';
    2: Result := 'RightJoin';
  else
    Result := 'FullJoin';
  end;
end;

procedure TTestDeleteJoin.TestWhereVazioEntreOFromEOJoinNaoDesarmaAGuarda;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ⭐ ESTE E O CASO QUE A PRIMEIRA VERSAO DA GUARDA DEIXAVA PASSAR, e ele nao
  // e exotico: Where('') nao emite UMA LETRA - nao ha nem WHERE na saida - mas
  // troca a secao ativa para secWhere, e uma guarda que perguntasse "o cursor
  // esta AGORA na secao DELETE?" nao disparava. O texto que saia era
  //
  //   DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID
  //
  // byte a byte o caso C07 do oraculo, medido A: 4 -> 0 no SQL Server e no
  // MySQL. Ou seja: o dano silencioso que E A RAZAO DESTA TAREFA continuava
  // alcancavel por uma cadeia de uma chamada a mais.
  //
  // A guarda passou a perguntar "este statement E um DELETE?", lendo a marca
  // DURAVEL (a secao Delete do AST, que _DefineSectionDelete estabelece e
  // ClearAll limpa) em vez do cursor.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A', 'X').Where('').LeftJoin('B', 'Y')
          .OnCond('Y.AID = X.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': Where('''') entre o From e o join nao pode ' +
      'desarmar a guarda.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestWhereComPredicadoEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
var
  LDriver: TFluentSQLDriver;
  LTipo, LCelulas: Integer;
begin
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    for LTipo := 0 to 3 do
    begin
      Inc(LCelulas);
      Assert.WillRaise(
        procedure
        begin
          _AplicaJoin(
            Query(LDriver).Delete.From('A', 'X').Where('X.Active').Equal(1),
            LTipo).OnCond('Y.AID = X.ID').AsString;
        end,
        EFluentSQLConstructNotSupported,
        cDIALETO[LDriver] + '/' + _NomeDoTipo(LTipo) +
        ': WHERE antes do join nao pode desarmar a guarda.');
    end;
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestOrderByEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
var
  LDriver: TFluentSQLDriver;
  LTipo, LCelulas: Integer;
begin
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    for LTipo := 0 to 3 do
    begin
      Inc(LCelulas);
      Assert.WillRaise(
        procedure
        begin
          _AplicaJoin(
            Query(LDriver).Delete.From('A', 'X').OrderBy('X.ID'),
            LTipo).OnCond('Y.AID = X.ID').AsString;
        end,
        EFluentSQLConstructNotSupported,
        cDIALETO[LDriver] + '/' + _NomeDoTipo(LTipo) +
        ': ORDER BY antes do join nao pode desarmar a guarda.');
    end;
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestGroupByEntreOFromEOJoinNaoDesarmaNosQuatroTipos;
var
  LDriver: TFluentSQLDriver;
  LTipo, LCelulas: Integer;
begin
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    for LTipo := 0 to 3 do
    begin
      Inc(LCelulas);
      Assert.WillRaise(
        procedure
        begin
          _AplicaJoin(
            Query(LDriver).Delete.From('A', 'X').GroupBy('X.ID'),
            LTipo).OnCond('Y.AID = X.ID').AsString;
        end,
        EFluentSQLConstructNotSupported,
        cDIALETO[LDriver] + '/' + _NomeDoTipo(LTipo) +
        ': GROUP BY antes do join nao pode desarmar a guarda.');
    end;
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestASaidaRecomendadaNaoDesarmaAGuarda;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ⚠️ O AGRAVANTE DO FURO ORIGINAL, e por isso ele tem celula propria: a
  // chamada que desarmava a guarda - Where(...) - e EXATAMENTE a que a
  // mensagem da guarda recomenda como saida. A saida apontada e o desvio eram
  // a MESMA porta. Quem seguisse a recomendacao ao pe da letra e acrescentasse
  // um join depois voltava a ter o SQL destrutivo, sem nenhum aviso.
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
          .Where('').Exists('SELECT 1 FROM B AS Y WHERE Y.AID = X.ID')
          .InnerJoin('C', 'Z').OnCond('Z.AID = X.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': a saida recomendada nao pode ser o desvio.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestDeleteSemFromTambemRecusaOJoin;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A marca DURAVEL e a secao Delete do AST, alimentada pelo From. Sem From
  // ela esta VAZIA - entao aqui quem tem de pegar e a leitura da secao ativa,
  // que continua no lugar. As duas condicoes existem porque nenhuma das duas
  // cobre a outra: esta celula falsifica a mutacao que apaga a leitura da
  // secao ativa e fica so com a marca duravel.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.InnerJoin('B', 'Y').OnCond('Y.AID = A.ID').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': DELETE sem From tambem tem de recusar o join.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteJoin.TestInsertDepoisDeDeleteLimpaAMarcaDuravel;
var
  LSql: String;
begin
  // A marca duravel nao pode ser um sinalizador que so o Select desfaz.
  // _DefineSectionInsert tambem chama ClearAll, entao um INSERT montado depois
  // de um Delete na mesma instancia nao pode herdar a recusa. Esta celula e o
  // par de TestSelectDepoisDeDeleteLiberaOJoin para a outra porta de limpeza.
  LSql := Query(dbnPostgreSQL).Delete.From('A')
            .Insert.Into('T').Values('C', '1').AsString;
  Assert.Contains(LSql, 'INSERT INTO T', False,
    'Trocar para a secao INSERT tem de limpar a marca deixada pelo Delete.');
  Assert.DoesNotContain(LSql, 'DELETE', False,
    'O INSERT nao pode carregar residuo da secao DELETE anterior.');
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
