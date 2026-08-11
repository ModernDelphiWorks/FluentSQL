{
  ------------------------------------------------------------------------------
  FluentSQL - DELETE com mais de uma relacao: a construcao NAO existe (T26)

  O que este arquivo trava: Delete.From(A).From(B) deixa de emitir SQL e passa a
  levantar EFluentSQLConstructNotSupported, em todo dialeto.

  POR QUE RECUSAR, e nao traduzir. O texto que o framework emitia -
  "DELETE FROM A AS X, B AS Y WHERE ..." para seis dialetos e
  "DELETE FROM A X, B Y WHERE ..." para o Oracle - foi submetido aos SETE
  motores. Os SETE recusam por PARSE. A transcricao literal, com docker run e
  versao perguntada a cada motor, esta em test.delete.multirelacao.matrix.sql,
  nesta mesma pasta:

    SQL Server 2022 16.0.4265.3   Msg 156 (com AS) / Msg 102 (sem AS)
    Oracle 23.26.2.0.0            ORA-03048
    PostgreSQL 16.14              syntax error at or near ","
    MySQL 8.4.11                  ERROR 1064
    Firebird 5.0.4                SQL error code = -104
    SQLite 3.53.4                 near ",": syntax error
    DB2 12.1.5.0                  SQL0104N
    InterBase                     NAO MEDIDO - nao existe imagem publica

  A UNIAO tambem e vazia, nao so a intersecao: nao ha um motor sequer em que a
  forma emitida executasse. Nao havia usuario a preservar.

  POR QUE NAO EMITIR A FORMA NATIVA DE CADA UM. Porque elas nao querem dizer a
  MESMA coisa. Medido, com contagem antes e depois:

    T-SQL       DELETE X FROM A AS X JOIN B AS Y ON ...  -> A 2->1, B 2 (so A)
    PostgreSQL  DELETE FROM A AS X USING B AS Y WHERE ... -> A 2->1, B 2 (so A)
    MySQL       DELETE X, Y FROM A AS X JOIN B AS Y ON ... -> A 2->1, B 2->1 (as DUAS)

  E o T-SQL RECUSA a forma das duas (Msg 102 para "DELETE X, Y FROM ..."), e o
  PostgreSQL nao tem forma das duas. Ou seja: "apagar de uma filtrando pela
  outra" e "apagar das duas" sao construcoes DIFERENTES, e a segunda existe em 1
  dos 7. Mapear uma unica chamada para elas trocaria SQL que nao executa por SQL
  que executa APAGANDO COISAS DIFERENTES conforme o banco - defeito pior que o
  original, porque silencioso.

  E O QUE MATA A CONSTRUCAO DE VEZ: a API nao tem como saber qual das duas foi
  pedida. Delete.From('A','X').From('B','Y') nao tem designador de alvo, nao tem
  condicao de juncao propria da secao e nao tem marcador de relacao auxiliar.
  Nem o framework nem o usuario sabem dizer o que essa chamada significa.

  ONDE A GUARDA MORA: em TFluentSQL.From(const ATableName: String)
  (Source\Core\FluentSQL.pas), e nao num serializador. Ela falha na chamada que
  errou, vale para todos os dialetos sem uma linha por driver, e nao acrescenta
  membro a IFluentSQLSerialize.

  O QUE ESTE ARQUIVO COBRE, COM PRECISAO: a LISTA DE RELACOES DO FROM da secao
  DELETE. From e o unico ponto de entrada que alimenta ASTTableNames -
  IFluentSQL nao publica o AST, entao IFluentSQLDelete.TableNames.Add nao e
  alcancavel por consumidor.

  O QUE ELE NAO COBRE: a segunda relacao que entra por TFluentSQL._CreateJoin,
  que nao passa por ASTTableNames e por isso nunca e vista pela guarda de From.
  Essa porta TEM GUARDA PROPRIA e TEM TESTE PROPRIO - test.delete.join.pas,
  nesta mesma pasta. Hoje ela RECUSA os quatro tipos de juncao.

  ⚠️ A PREVISAO QUE ESTE CABECALHO CARREGAVA ESTAVA ERRADA. Ele dizia que "NAO
  ha teste aqui que o trave - de proposito, porque a resposta la e OUTRA", que
  "o irmao e TRADUZIVEL, nao recusavel" e que "quem for escrever o teste dele
  NAO deve copiar as afirmacoes deste arquivo". Fica corrigido em vez de
  apagado, porque quem lesse aquilo hoje concluiria que test.delete.join.pas
  contraria um plano - e ele nao contraria: ele corrige.

  O que desmentiu a previsao: a revisao de entao mediu SO o InnerJoin. Medindo
  os QUATRO tipos, com LeftJoin e sem WHERE a forma nativa APAGA A TABELA
  INTEIRA (A: 4 -> 0) e reporta SUCESSO nos dois motores que a analisam - na
  juncao externa a condicao nao filtra nada. InnerJoin filtra, LeftJoin nao: a
  familia nao tem UMA semantica.

  O que a previsao ACERTAVA e continua valendo: para o InnerJoin ISOLADO existe
  forma portavel aceita pelos sete, e a intersecao NAO e vazia. E tarefa
  propria. Matriz em test.delete.join.matrix.sql.

  ANTI-COLATERAL: os testes "TestNao..." afirmam o que NAO podia mudar - DELETE
  com UMA relacao (com e sem apelido) e SELECT com VARIAS relacoes, que e forma
  valida e antiga. Cada um foi falsificado por mutacao dirigida na propria
  guarda; a tabela esta no relatorio da tarefa.

  CAIXA: todo Assert.AreEqual aqui passa False no parametro IgnoreCase. O padrao
  do DUnitX ignora maiuscula/minuscula - numa biblioteca cujo produto E texto
  SQL isso deixaria "as" passar por "AS".
  ------------------------------------------------------------------------------
}

unit test.delete.multirelacao;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDeleteMultiRelacao = class
  public
    /// <summary>Duas relacoes no DELETE levantam em todo dialeto relacional.</summary>
    [Test]
    procedure TestDuasRelacoesNoDeleteLevantamEmTodoDialeto;
    /// <summary>Tres relacoes tambem - a guarda pega na SEGUNDA, nao na ultima.</summary>
    [Test]
    procedure TestTresRelacoesLevantamNaSegundaChamada;
    /// <summary>Sem apelido tambem: o defeito nunca foi do apelido.</summary>
    [Test]
    procedure TestDuasRelacoesSemApelidoTambemLevantam;
    /// <summary>A excecao e NOMEADA e capturavel, nao Exception cru.</summary>
    [Test]
    procedure TestExcecaoENomeadaECapturavelPeloTipo;
    /// <summary>A mensagem nao nomeia dialeto: trocar de banco nao resolve.</summary>
    [Test]
    procedure TestMensagemNaoMandaTrocarDeDialeto;
    /// <summary>MongoDB tambem recusa - antes ele DESCARTAVA a segunda em silencio.</summary>
    [Test]
    procedure TestMongoDBTambemRecusaEmVezDeDescartarCalado;
    /// <summary>ANTI-COLATERAL: DELETE de UMA relacao, com apelido, texto exato.</summary>
    [Test]
    procedure TestNaoMudouODeleteDeUmaRelacaoComApelido;
    /// <summary>ANTI-COLATERAL: DELETE de UMA relacao, sem apelido, texto exato.</summary>
    [Test]
    procedure TestNaoMudouODeleteDeUmaRelacaoSemApelido;
    /// <summary>ANTI-COLATERAL: SELECT com VARIAS relacoes continua valendo.</summary>
    [Test]
    procedure TestNaoMudouOSelectComVariasRelacoes;
    /// <summary>A guarda le o estado VIVO da secao: Clear libera um From novo.</summary>
    [Test]
    procedure TestClearNaSecaoDeleteLiberaUmFromNovo;
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
///   nao assumido - mesma tecnica de test.delete.alias.matrix.pas.
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

procedure TTestDeleteMultiRelacao.TestDuasRelacoesNoDeleteLevantamEmTodoDialeto;
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
        Query(LDriver).Delete.From('A', 'X').From('B', 'Y').Where('X.ID').Equal(1).AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': DELETE com duas relacoes tem de levantar, nao emitir.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestTresRelacoesLevantamNaSegundaChamada;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A guarda conta relacoes JA acumuladas, entao dispara na SEGUNDA chamada de
  // From e nunca chega a ver a terceira. Esta celula cobre o "mais de duas",
  // que nao e o mesmo caso do "exatamente duas".
  //
  // O QUE ELA NAO PEGA, medido e nao suposto: a mutacao "Count > 1" - guarda
  // frouxa, que deixaria DUAS relacoes passarem - mantem este teste VERDE, e
  // com razao: com tres relacoes a guarda frouxa dispara na terceira. Quem
  // falsifica aquela mutacao e TestDuasRelacoesNoDeleteLevantamEmTodoDialeto.
  // Este aqui e falsificado pela guarda REMOVIDA e pela excecao trocada por
  // Exception cru. Fica escrito para nao ser lido como prova do que nao prova.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A').From('B').From('C').AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': tres relacoes no DELETE tem de levantar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestDuasRelacoesSemApelidoTambemLevantam;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // O texto invalido nao dependia do apelido: sem ele saia "DELETE FROM A, B",
  // recusado pelos sete do mesmo jeito (medido; ver o .sql, caso 02 de cada
  // motor). Recusar so a forma COM apelido deixaria metade do defeito de pe.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.WillRaise(
      procedure
      begin
        Query(LDriver).Delete.From('A').From('B').Where('A.ID').Equal(1).AsString;
      end,
      EFluentSQLConstructNotSupported,
      cDIALETO[LDriver] + ': DELETE FROM A, B tem de levantar tambem sem apelido.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestExcecaoENomeadaECapturavelPeloTipo;
var
  LClasse: String;
begin
  // "Levanta alguma coisa" nao e contrato. Quem consome precisa distinguir esta
  // recusa de um EAccessViolation ou de um Exception cru vindo de outro ponto
  // do builder - e so consegue se o TIPO for proprio.
  LClasse := '';
  try
    Query(dbnMSSQL).Delete.From('A').From('B').AsString;
  except
    on E: Exception do
      LClasse := E.ClassName;
  end;
  Assert.AreEqual('EFluentSQLConstructNotSupported', LClasse, False,
    'A recusa tem de chegar com tipo proprio, nao como Exception generico.');
end;

procedure TTestDeleteMultiRelacao.TestMensagemNaoMandaTrocarDeDialeto;
var
  LMsg: String;
begin
  // A recusa e a MESMA nos sete. Uma mensagem que nomeasse o dialeto mandaria
  // quem le tentar outro banco - exatamente o caminho errado, porque nenhum
  // aceita.
  LMsg := '';
  try
    Query(dbnPostgreSQL).Delete.From('A').From('B').AsString;
  except
    on E: EFluentSQLConstructNotSupported do
      LMsg := E.Message;
  end;
  Assert.IsTrue(LMsg <> '', 'A guarda nao levantou EFluentSQLConstructNotSupported.');
  Assert.Contains(LMsg, 'DELETE com mais de uma relacao', False,
    'A mensagem tem de nomear a construcao recusada.');
  Assert.DoesNotContain(LMsg, 'PostgreSQL', False,
    'A mensagem nao pode nomear o dialeto: a recusa nao e dele.');
end;

procedure TTestDeleteMultiRelacao.TestMongoDBTambemRecusaEmVezDeDescartarCalado;
begin
  // MongoDB esta fora da intersecao relacional e nao entra na conta de nada.
  // Esta celula existe por um motivo estreito e proprio: antes desta guarda a
  // segunda relacao era DESCARTADA em silencio la - o MQL emitido citava so a
  // colecao A. Guarda no nucleo alcanca este dialeto tambem, e e isto que o
  // teste fixa.
  if not _EstaRegistrado(dbnMongoDB) then
    Assert.Pass('dbnMongoDB nao esta registrado nesta configuracao de build.');
  Assert.WillRaise(
    procedure
    begin
      Query(dbnMongoDB).Delete.From('A').From('B').Where('ID').Equal(1).AsString;
    end,
    EFluentSQLConstructNotSupported,
    'dbnMongoDB: a segunda colecao nao pode ser descartada em silencio.');
end;

procedure TTestDeleteMultiRelacao.TestNaoMudouODeleteDeUmaRelacaoComApelido;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
  LEsperado: String;
begin
  // ANTI-COLATERAL, e o mais importante do arquivo. UMA relacao e o caminho que
  // funciona e que todo consumidor usa; a guarda nao pode encostar nele.
  // Falsificado por mutacao dirigida: escrever a guarda como "Count >= 0" - ou
  // seja, recusar ja a PRIMEIRA relacao - derruba este teste em todo dialeto.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    if LDriver = dbnMSSQL then
      LEsperado := 'DELETE AP FROM A AS AP'
    else
      LEsperado := 'DELETE FROM ' + _ComApelido(LDriver, 'A', 'AP');
    Assert.AreEqual(LEsperado + ' WHERE (AP.ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A', 'AP').Where('AP.ID').Equal(1).AsString,
      False, cDIALETO[LDriver] + ': DELETE de uma relacao com apelido nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestNaoMudouODeleteDeUmaRelacaoSemApelido;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ANTI-COLATERAL. Mesma mutacao "Count >= 0" derruba esta tambem, e por um
  // caminho diferente: aqui nem apelido existe para a guarda se apoiar.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('DELETE FROM A WHERE (ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A').Where('ID').Equal(1).AsString, False,
      cDIALETO[LDriver] + ': DELETE de uma relacao sem apelido nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestNaoMudouOSelectComVariasRelacoes;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // ANTI-COLATERAL. A lista separada por virgula e forma VALIDA e antiga no
  // FROM do SELECT - e o produto cartesiano da norma, aceito nos sete. A guarda
  // e do DELETE e so do DELETE.
  // Falsificado por mutacao dirigida: apagar a condicao "FActiveSection =
  // secDelete" da guarda derruba este teste em todo dialeto.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('SELECT * FROM A, B',
      Query(LDriver).Select.All.From('A').From('B').AsString, False,
      cDIALETO[LDriver] + ': SELECT com duas relacoes nao podia mudar.');
    Assert.AreEqual('SELECT * FROM ' + _ComApelido(LDriver, 'A', 'X') + ', ' +
      _ComApelido(LDriver, 'B', 'Y'),
      Query(LDriver).Select.All.From('A', 'X').From('B', 'Y').AsString, False,
      cDIALETO[LDriver] + ': SELECT com duas relacoes apelidadas nao podia mudar.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestDeleteMultiRelacao.TestClearNaSecaoDeleteLiberaUmFromNovo;
var
  LDriver: TFluentSQLDriver;
  LCelulas: Integer;
begin
  // A guarda le a contagem VIVA da secao, nao um sinalizador de "ja passou por
  // aqui". IFluentSQL.Clear zera TFluentSQLDelete.TableNames, e depois disso um
  // From novo e a PRIMEIRA relacao outra vez - tem de passar. Uma guarda escrita
  // com flag de instancia recusaria isto e quebraria quem reaproveita o builder.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if not _Medivel(LDriver) then
      Continue;
    Inc(LCelulas);
    Assert.AreEqual('DELETE FROM B WHERE (ID = ' + _Bind(LDriver) + ')',
      Query(LDriver).Delete.From('A').Clear.From('B').Where('ID').Equal(1).AsString,
      False, cDIALETO[LDriver] + ': Clear tem de liberar uma relacao nova.');
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeleteMultiRelacao);

end.
