{
  ------------------------------------------------------------------------------
  FluentSQL - matriz CAST: dialeto x TFluentSQLDataFieldType (T17)

  POR QUE ESTE ARQUIVO EXISTE

  Ate a T17, IFluentSQLFunctions.Cast estava no PADRAO A: o core emitia
  'CAST(x AS ' + ADataType + ')' com o tipo vindo como String livre, sem consultar
  o driver, e NENHUM dos nove drivers o sobrescrevia. Uma unica grafia respondia
  pelos sete dialetos.

  Isso e o mesmo defeito estrutural que a T3 matou em CEIL/LENGTH, com um
  agravante: aqui o valor errado nao levanta. Medido contra motor real (a
  transcricao literal dos erros esta em test.cast.matrix.sql, ao lado deste
  arquivo), a mesma celula diverge de TRES formas diferentes:

    SINTAXE       CAST(x AS INTEGER)  e ERROR 1064 no MySQL 8.4 - o alvo de CAST
                  do MySQL e lista fechada e nao inclui INTEGER, TEXT, BOOLEAN
                  nem UUID.

    LARGURA       CAST(x AS VARCHAR) sem largura e erro no Firebird (-104) e na
                  Oracle (ORA-00906); passa no PostgreSQL sem truncar; e no SQL
                  Server TRUNCA EM SILENCIO EM 30 CARACTERES.

    SEMANTICA     no SQLite nenhum alvo e recusado - nem 'BANANA'. A palavra cai
                  nas regras de afinidade e o dado e destruido sem erro:
                  CAST('2026-08-10' AS DATE) devolve 2026.

  A terceira e a pior, e e a razao de a sobrecarga de enum LEVANTAR onde o motor
  responderia. A regra da casa vale na ordem: erro nomeado > SQL que o motor
  recusa > SQL que o motor aceita com semantica errada.

  A POLITICA QUE ESTE ARQUIVO TRAVA: INTERSECAO ESTRITA

  A medicao encontrou 46 celulas que EXISTEM em 70. A sobrecarga portavel oferece
  TRES. Isso nao e a matriz e o codigo discordando - e a decisao, e ela e o ponto:

    a API do FluentSQL e a INTERSECAO dos dialetos, nao a uniao.

  So dftString, dftInteger e dftFloat existem nos SETE. Todo o resto e recusado em
  TODOS os dialetos, INCLUSIVE naqueles em que a celula existe e foi medida:
  dftGuid levanta no PostgreSQL (onde UUID funciona), dftBoolean levanta no SQL
  Server (onde BIT funciona), dftText levanta no DB2 (onde CLOB funciona).

  Se a recusa fosse por celula, Cast(x, dftGuid) responderia no PG e explodiria na
  Oracle - e o programador so descobriria na migracao, que e o momento mais caro
  possivel. Uma sobrecarga que se apresenta como portavel e devolve a uniao nao e
  uma API com lacunas, e uma API que depende do banco.

  Tres razoes secundarias, todas verificaveis aqui:
    * alargar a lista depois e ADITIVO; estreitar depois e BREAKING. Comecar
      apertado e de graca enquanto nada depende disso.
    * dftBoolean na Oracle depende da VERSAO do servidor (so 23ai+), e esta
      biblioteca nao sabe a versao. Celula que depende de informacao que o
      framework nao tem nao pode ser promessa.
    * as duas sobrecargas passam a ter contrato legivel:
        Cast(x, dftString) .... a garantia de portabilidade e do framework
        Cast(x, 'VARCHAR2') ... voce escolheu a palavra, a garantia e sua

  O QUE ESTA MATRIZ TRAVA, ENTAO

  Cada par (dialeto, TFluentSQLDataFieldType) tem valor esperado LITERAL declarado
  em _Esperado. Nao e "nao levanta": e o texto exato. Consequencia pratica:

    * trocar NVARCHAR(4000) por NVARCHAR no MSSQL ........ VERMELHO
      (e essa mutacao e a que reintroduziria o truncamento silencioso em 30)
    * trocar SIGNED por INTEGER no MySQL ................. VERMELHO
    * fazer o PostgreSQL emitir VARCHAR(4000) ............ VERMELHO
      (largura no PG INTRODUZ truncamento; ver o driver)
    * devolver dftGuid no PostgreSQL "porque la funciona"  VERMELHO
      (TestRecusaDeTipoForaDaIntersecaoEUniforme, que e a trava da POLITICA:
       quebrar a recusa em UM SO dialeto ja fica vermelho)
    * apagar a explicacao da mensagem de erro ............ VERMELHO
      (TestMensagemDeRecusaEnsinaASaida)

  A comparacao e CASE-SENSITIVE de proposito: Assert.AreEqual de string no DUnitX
  ignora caixa por default, e 'nvarchar' passando por 'NVARCHAR' esconderia
  exatamente o tipo de divergencia que esta matriz existe para pegar.

  A MATRIZ MEDIDA COMPLETA - as 70 celulas e o motivo de cada uma das 24 que nao
  existem - fica em test.cast.matrix.sql, ao lado. Ela NAO foi jogada fora quando
  a politica encolheu para tres: e a justificativa da politica, e e o que impede
  alguem de alargar a lista sem remedir.

  NAO MEDIDO: InterBase - nao ha imagem de container publica. Todas as celulas
  dele levantam, e isso e deliberado: a grafia NAO foi inferida do Firebird. Ver
  FluentSQL.FunctionsInterbase.pas.

  MONGODB: levanta em todas, pela regra geral daquele driver (escalar levanta erro
  nomeado). Ele esta FORA da promessa de intersecao, que e RELACIONAL, por decisao
  do autor: aqui ele e varrido como EXTRA, com a mesma exigencia celula a celula,
  mas NENHUM piso desta unidade se apoia nele. Os pisos contam so os relacionais -
  ver _ERelacional.
  ------------------------------------------------------------------------------
}

unit test.cast.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestCastMatrix = class
  public
    /// <summary>Cada celula devolve o texto exato declarado, ou levanta o erro nomeado.</summary>
    [Test]
    procedure TestMatrizCastCelulaPorCelula;
    /// <summary>
    ///   A TRAVA DA POLITICA. Tipo fora de cFluentSQLCastPortableTypes levanta em
    ///   TODO dialeto registrado, com a MESMA mensagem - inclusive nos que teriam
    ///   a celula. Quebrar a recusa em um so dialeto ja e vermelho.
    /// </summary>
    [Test]
    procedure TestRecusaDeTipoForaDaIntersecaoEUniforme;
    /// <summary>A lista portavel e exatamente tres, e sao os tres medidos nos sete.</summary>
    [Test]
    procedure TestListaPortavelEExatamenteOsTresUniversais;
    /// <summary>A mensagem de recusa nomeia o tipo e entrega as duas saidas.</summary>
    [Test]
    procedure TestMensagemDeRecusaEnsinaASaida;
    /// <summary>
    ///   Na PORTA DO CORE, dialeto registrado nunca cai no corpo abstrato
    ///   (EAbstractError). O escopo e esse e nao mais - ver o comentario da
    ///   implementacao, que declara o que este teste NAO cobre.
    /// </summary>
    [Test]
    procedure TestNenhumaCelulaLevantaEAbstractError;
    /// <summary>A sobrecarga String continua verbatim - escape hatch preservado.</summary>
    [Test]
    procedure TestSobrecargaStringContinuaVerbatimEmTodoDialeto;
    /// <summary>Largura explicita sobrepoe o default onde o dialeto usa largura.</summary>
    [Test]
    procedure TestLarguraExplicitaSobrepoeODefault;
    /// <summary>Largura explicita NAO aparece onde o dialeto nao usa largura.</summary>
    [Test]
    procedure TestDialetoSemLarguraIgnoraOuHonraConformeMedido;
    /// <summary>
    ///   A forma que desbloqueia a T13: CASE ... THEN CAST(:p AS T) ELSE CAST(:p AS T).
    ///   Firebird e DB2 recusam parametro nu no PREPARE (-804 / SQL0418N); com estas
    ///   strings exatas os dois aceitam. Medido - ver test.cast.matrix.sql.
    /// </summary>
    [Test]
    procedure TestFormaQueDesbloqueiaAT13;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Functions,
  FluentSQL.Register;

const
  /// <summary>Sentinela: a celula deve levantar EFluentSQLFunctionNotSupported.</summary>
  cLEVANTA = '<levanta EFluentSQLFunctionNotSupported>';

/// <summary>
///   A TABELA. Texto literal esperado de Cast('C', <tipo>) com largura default.
///   Cada linha desta funcao e uma afirmacao sobre motor real; a transcricao dos
///   erros que a sustentam esta em test.cast.matrix.sql.
///
///   SO HA TRES LINHAS POR DIALETO, e a ausencia das outras e informacao, nao
///   esquecimento. As celulas medidas que EXISTEM em cada motor mas nao estao aqui
///   vao anotadas em comentario: elas continuam verdadeiras sobre o motor e
///   continuam alcancaveis pela sobrecarga de String; o que elas nao sao e
///   portaveis, e a sobrecarga de enum so promete o portavel.
/// </summary>
function _Esperado(const ADriver: TFluentSQLDriver;
  const AType: TFluentSQLDataFieldType): String;
begin
  Result := cLEVANTA;
  case ADriver of
    // Firebird 5.0.4. Largura OBRIGATORIA (sem ela: -104). Estouro de largura e
    // erro (22001), nunca truncamento calado.
    // Medidas e fora da intersecao: DATE, TIMESTAMP, BOOLEAN, BLOB SUB_TYPE TEXT.
    dbnFirebird:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR(4000))';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE PRECISION)';
      end;

    // SQL Server 2022 CU26. NVARCHAR SEMPRE com largura: 'AS NVARCHAR' nu trunca
    // em 30 sem erro nem aviso. Teto 4000 (Msg 131 em 4001).
    // Medidas e fora da intersecao: DATE, DATETIME, NVARCHAR(MAX),
    // UNIQUEIDENTIFIER, BIT - 5 celulas, o maior preco pago por um dialeto aqui.
    dbnMSSQL:
      case AType of
        dftString:   Result := 'CAST(C AS NVARCHAR(4000))';
        dftInteger:  Result := 'CAST(C AS INT)';
        dftFloat:    Result := 'CAST(C AS FLOAT)';
      end;

    // MySQL 8.4.11. Alvo de CAST e LISTA FECHADA: INTEGER/TEXT/BOOLEAN/UUID sao
    // ERROR 1064. CHAR sem largura nao trunca.
    // Medidas e fora da intersecao: DATE, DATETIME.
    dbnMySQL:
      case AType of
        dftString:   Result := 'CAST(C AS CHAR)';
        dftInteger:  Result := 'CAST(C AS SIGNED)';
        dftFloat:    Result := 'CAST(C AS DOUBLE)';
      end;

    // SQLite 3.53.4. So TEXT/INTEGER/REAL/BLOB tem significado, e o motor nao
    // recusa NADA - nem 'BANANA'. E o dialeto que prova a intersecao estrita.
    dbnSQLite:
      case AType of
        dftString:   Result := 'CAST(C AS TEXT)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS REAL)';
      end;

    // Oracle AI 26ai 23.26.2.0.0. Largura OBRIGATORIA (ORA-00906), teto 4000
    // (ORA-00910).
    // Medidas e fora da intersecao: DATE, TIMESTAMP e BOOLEAN - esta ultima so
    // valida em 23ai+, versao que o framework nao tem como conhecer.
    dbnOracle:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR2(4000))';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS BINARY_DOUBLE)';
      end;

    // PostgreSQL 16.14. VARCHAR SEM largura de proposito: aqui a largura e que
    // trunca em silencio (VARCHAR(4) sobre 10 chars devolve 4).
    // Medidas e fora da intersecao: DATE, TEXT, TIMESTAMP, UUID, BOOLEAN.
    dbnPostgreSQL:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE PRECISION)';
      end;

    // DB2 v12.1.5.0. VARCHAR sem largura nao trunca (300 chars entram, 300 saem).
    // Medidas e fora da intersecao: DATE, CLOB, TIMESTAMP, BOOLEAN. CLOB E alvo
    // valido aqui e NAO e na Oracle - o par que mostra que familia nao prediz
    // celula.
    dbnDB2:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE)';
      end;

    // NAO MEDIDO (sem imagem publica) e NAO inferido do Firebird. Todas levantam.
    dbnInterbase: ;

    // Fora da intersecao relacional, por decisao do dono. Todas levantam.
    dbnMongoDB: ;
  else
    raise Exception.Create('Dialeto sem linha na matriz CAST. Todo membro de ' +
      'TFluentSQLDriver precisa declarar o que emite.');
  end;
end;

/// <summary>
///   O dialeto tem driver registrado nesta build? Depende dos {$DEFINE} de
///   FluentSQL.inc e da linha de comando, entao e detectado em runtime.
/// </summary>
function _EstaRegistrado(const ARegister: TFluentSQLRegister;
  const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    ARegister.Functions(ADriver);
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
  end;
end;

/// <summary>
///   A promessa de intersecao do FluentSQL e RELACIONAL, e por decisao do autor
///   (2026-08-08) o MongoDB esta FORA dela, em regime congelado: o driver
///   continua compilando e continua sendo varrido por estas matrizes, mas nao
///   vota em regra de feature e NAO PODE SUSTENTAR NUMERO DE PISO. Se um piso
///   dependesse dele, desligar um dialeto congelado derrubaria um teste que
///   afirma coisa sobre os dialetos vivos.
/// </summary>
function _ERelacional(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := ADriver <> dbnMongoDB;
end;

function _NomeTipo(const AType: TFluentSQLDataFieldType): String;
begin
  case AType of
    dftUnknown:  Result := 'dftUnknown';
    dftString:   Result := 'dftString';
    dftInteger:  Result := 'dftInteger';
    dftFloat:    Result := 'dftFloat';
    dftDate:     Result := 'dftDate';
    dftArray:    Result := 'dftArray';
    dftText:     Result := 'dftText';
    dftDateTime: Result := 'dftDateTime';
    dftGuid:     Result := 'dftGuid';
    dftBoolean:  Result := 'dftBoolean';
  else
    Result := 'dft?';
  end;
end;

function _Celula(const ADriver: TFluentSQLDriver;
  const AType: TFluentSQLDataFieldType): String;
begin
  Result := DriverName(ADriver) + '/' + _NomeTipo(AType);
end;

/// <summary>
///   Devolve como INTERFACE de proposito. TFluentSQLFunctions e TInterfacedObject:
///   chamar TFluentSQLFunctions.Create(...).Cast(...) direto na classe deixa o
///   refcount em zero e vaza - o DUnitX contabiliza isso em "Tests Leaked".
/// </summary>
function _Funcoes(const ARegister: TFluentSQLRegister;
  const ADriver: TFluentSQLDriver): IFluentSQLFunctions;
begin
  Result := TFluentSQLFunctions.Create(ADriver, ARegister);
end;

procedure TTestCastMatrix.TestMatrizCastCelulaPorCelula;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LType: TFluentSQLDataFieldType;
  LEsperado: String;
  LObtido: String;
  LLevantou: Boolean;
  LConferidas: Integer;
  LConferidasRelacionais: Integer;
begin
  LConferidas := 0;
  LConferidasRelacionais := 0;
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
      begin
        LEsperado := _Esperado(LDriver, LType);
        LLevantou := False;
        LObtido := '';
        try
          LObtido := LFunctions.Cast('C', LType);
        except
          on E: EFluentSQLFunctionNotSupported do
            LLevantou := True;
        end;
        Inc(LConferidas);
        if _ERelacional(LDriver) then
          Inc(LConferidasRelacionais);

        if LEsperado = cLEVANTA then
          Assert.IsTrue(LLevantou,
            'Celula ' + _Celula(LDriver, LType) + ' deveria levantar ' +
            'EFluentSQLFunctionNotSupported e devolveu "' + LObtido + '". ' +
            'Uma celula que volta a responder e mudanca de contrato: se for ' +
            'proposital, a linha em _Esperado tem de mudar junto.')
        else
        begin
          Assert.IsFalse(LLevantou,
            'Celula ' + _Celula(LDriver, LType) + ' deveria emitir "' +
            LEsperado + '" e levantou EFluentSQLFunctionNotSupported.');
          // ignoreCase = False: 'nvarchar' NAO pode passar por 'NVARCHAR'.
          Assert.AreEqual(LEsperado, LObtido, False,
            'Celula ' + _Celula(LDriver, LType) + ' emitiu grafia diferente da ' +
            'medida contra motor real (ver test.cast.matrix.sql).');
        end;
      end;
    end;
    // O piso conta SO os RELACIONAIS: 6 ligados por default (Firebird, MSSQL,
    // MySQL, SQLite, Oracle, PostgreSQL) x 10 tipos. O MongoDB continua sendo
    // varrido acima - celula a celula, com a mesma exigencia - mas entra como
    // EXTRA e nao sustenta este numero, porque e dialeto congelado e fora da
    // promessa de intersecao.
    Assert.IsTrue(LConferidasRelacionais >= 60,
      'Esperado ao menos 60 celulas relacionais conferidas (6 dialetos ' +
      'relacionais ligados por default x 10 tipos); conferidas ' +
      IntToStr(LConferidasRelacionais) + ' de ' + IntToStr(LConferidas) +
      ' no total. Driver desligado no .inc reduz a cobertura desta matriz.');
  finally
    LRegister.Free;
  end;
end;

/// <summary>
///   A TRAVA DA POLITICA, e ela e UMA afirmacao so: para tipo fora da intersecao,
///   a resposta NAO DEPENDE DO DIALETO. Repare que nao basta "levanta em todos" -
///   a MENSAGEM tem de ser a mesma, caractere a caractere. Se cada driver
///   respondesse com o proprio texto, o erro viraria pista de qual driver esta
///   ligado, e a recusa seria uniforme so no papel: o programador leria "MySQL
///   nao suporta" e concluiria, errado, que trocar de banco resolve.
///
///   E daqui que vem a exigencia de a guarda ser a PRIMEIRA linha de Cast tambem
///   no InterBase, que recusa TUDO com mensagem propria de dialeto. Se a guarda
///   viesse depois do raise proprio dele, Cast('C', dftGuid) devolveria a mensagem
///   do InterBase ali e a mensagem de politica no PostgreSQL - duas respostas para
///   a mesma pergunta.
///
///   AS DUAS PORTAS, e por que o teste tem de bater nas duas. Ha DOIS objetos que
///   implementam IFluentSQLFunctions e os dois sao alcancaveis:
///
///     porta do core ... TFluentSQLFunctions, o que TFluentSQL usa. Guarda em
///                       Source\Core\FluentSQL.Functions.pas, ANTES do despacho.
///     porta do driver . TFluentSQLRegister.Functions(D), o objeto do dialeto.
///                       Guarda na primeira linha do Cast de cada driver.
///
///   A guarda do core faz CURTO-CIRCUITO: por ela, o Cast do driver nunca chega a
///   rodar para tipo fora da intersecao. Se este teste so batesse na porta do
///   core, as NOVE guardas de driver seriam decoracao nao observavel - medido: com
///   o teste so no core, fazer o PostgreSQL responder 'UUID' para dftGuid passava
///   VERDE. Por isso o laco varre as duas portas e exige a MESMA mensagem em
///   todas: e o que torna a ordem das linhas dentro de cada driver uma afirmacao
///   testada, e nao um comentario.
///
///   O QUE ESTE TESTE NAO PEGA, declarado: a guarda do CORE. Como o driver logo
///   abaixo recusa com a MESMA mensagem, apagar a linha do core deixa este teste -
///   e a suite inteira - VERDE. A camada do core existe para o driver futuro que
///   esquecer a guarda, e essa redundancia e deliberada e NAO coberta por teste.
/// </summary>
procedure TTestCastMatrix.TestRecusaDeTipoForaDaIntersecaoEUniforme;
const
  cPORTA: array[Boolean] of String = (
    'porta do core (TFluentSQLFunctions)',
    'porta do driver (TFluentSQLRegister.Functions)');
var
  LRegister: TFluentSQLRegister;
  LDriver: TFluentSQLDriver;
  LType: TFluentSQLDataFieldType;
  LPortaDriver: Boolean;
  LMensagemReferencia: String;
  LOrigemReferencia: String;
  LOrigem: String;
  LMensagem: String;
  LLevantou: Boolean;
  LObtido: String;
  LConferidas: Integer;
  LConferidasRelacionais: Integer;
begin
  LConferidas := 0;
  LConferidasRelacionais := 0;
  LRegister := TFluentSQLRegister.Create;
  try
    for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
    begin
      if LType in cFluentSQLCastPortableTypes then
        Continue;
      LMensagemReferencia := '';
      LOrigemReferencia := '';
      for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
      begin
        if not _EstaRegistrado(LRegister, LDriver) then
          Continue;
        for LPortaDriver := False to True do
        begin
          LOrigem := _Celula(LDriver, LType) + ' pela ' + cPORTA[LPortaDriver];
          LLevantou := False;
          LMensagem := '';
          LObtido := '';
          try
            if LPortaDriver then
              LObtido := LRegister.Functions(LDriver).Cast('C', LType)
            else
              LObtido := _Funcoes(LRegister, LDriver).Cast('C', LType);
          except
            on E: EFluentSQLFunctionNotSupported do
            begin
              LLevantou := True;
              LMensagem := E.Message;
            end;
          end;
          Inc(LConferidas);
          if _ERelacional(LDriver) then
            Inc(LConferidasRelacionais);

          Assert.IsTrue(LLevantou,
            LOrigem + ' respondeu "' + LObtido + '" em vez de levantar. ' +
            _NomeTipo(LType) + ' nao esta em cFluentSQLCastPortableTypes, logo a ' +
            'sobrecarga de enum tem de recusar AQUI TAMBEM - inclusive se a celula ' +
            'existir neste motor. Oferece-la so onde ela existe e devolver a UNIAO ' +
            'dos dialetos por uma porta que se apresenta como portavel.');

          if LOrigemReferencia = '' then
          begin
            LMensagemReferencia := LMensagem;
            LOrigemReferencia := LOrigem;
          end
          else
            // ignoreCase = False: a mensagem e o contrato visivel da politica.
            Assert.AreEqual(LMensagemReferencia, LMensagem, False,
              'A recusa de ' + _NomeTipo(LType) + ' tem texto diferente em ' +
              LOrigem + ' e em ' + LOrigemReferencia + '. A recusa e de POLITICA, ' +
              'nao de dialeto: e a MESMA nos nove drivers e nas duas portas. Texto ' +
              'proprio aqui significa que _AssertCastTypeIsPortable deixou de ser a ' +
              'PRIMEIRA linha do Cast neste ponto, ou que alguem a duplicou com ' +
              'mensagem propria.');
        end;
      end;
    end;
    // Piso SO sobre os relacionais: 7 tipos fora da intersecao x 6 dialetos
    // relacionais ligados por default x 2 portas. O MongoDB e varrido junto e a
    // exigencia de mensagem identica vale para ele tambem, mas ele NAO sustenta
    // este numero: e dialeto congelado, fora da promessa de intersecao, e um piso
    // que dependesse dele afirmaria sobre os vivos contando com um morto.
    Assert.IsTrue(LConferidasRelacionais >= 84,
      'Esperado ao menos 84 recusas relacionais conferidas (7 tipos fora da ' +
      'intersecao x 6 dialetos relacionais ligados por default x 2 portas); ' +
      'conferidas ' + IntToStr(LConferidasRelacionais) + ' de ' +
      IntToStr(LConferidas) + ' no total.');
  finally
    LRegister.Free;
  end;
end;

/// <summary>
///   A lista e exatamente tres, e a ORDEM da checagem segue o enum. Este teste e
///   o que torna caro alargar a intersecao por descuido: acrescentar um membro a
///   cFluentSQLCastPortableTypes fica vermelho aqui, e consertar o vermelho
///   obriga a escrever o nome do tipo novo nesta linha - uma linha de diff que o
///   revisor ve, e que o obriga a perguntar em que medicao aquilo se apoia.
///
///   O segundo bloco confere DataFieldTypeName membro a membro. CDataFieldTypeNames
///   e uma tabela POSICIONAL: acrescentar um membro no fim quebra a compilacao
///   (E2072), mas REORDENAR o enum nao quebra nada - so faz a mensagem de erro
///   passar a nomear o tipo errado, calada. Como a mensagem de recusa existe
///   justamente para nomear o tipo, uma tabela deslocada esvazia a feature inteira.
/// </summary>
procedure TTestCastMatrix.TestListaPortavelEExatamenteOsTresUniversais;
var
  LType: TFluentSQLDataFieldType;
  LLista: String;
begin
  LLista := '';
  for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
    if LType in cFluentSQLCastPortableTypes then
    begin
      if LLista <> '' then
        LLista := LLista + ',';
      LLista := LLista + _NomeTipo(LType);
    end;

  Assert.AreEqual('dftString,dftInteger,dftFloat', LLista, False,
    'cFluentSQLCastPortableTypes mudou. Esses tres sao os UNICOS tipos que a ' +
    'matriz medida contra motor real encontrou nos sete dialetos relacionais ' +
    '(ver test.cast.matrix.sql). Alargar a lista e aditivo e permitido, mas ' +
    'exige medir o tipo novo nos sete E implementa-lo em cada ' +
    'Source\Drivers\FluentSQL.Functions*.pas; estreita-la e BREAKING.');

  for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
    Assert.AreEqual(_NomeTipo(LType), DataFieldTypeName(LType), False,
      'DataFieldTypeName saiu de sincronia com TFluentSQLDataFieldType. A tabela ' +
      'CDataFieldTypeNames e posicional: reordenar o enum nao quebra a ' +
      'compilacao, so faz a mensagem de recusa nomear o tipo ERRADO - e nomear o ' +
      'tipo pedido e a unica coisa que aquela mensagem tem de fazer.');
end;

/// <summary>
///   A mensagem de recusa e parte do contrato, nao enfeite: e o unico momento em
///   que a explicacao chega barata ao programador que errou a linha. Este teste
///   trava os quatro fatos que ela precisa carregar - o tipo pedido pelo nome, o
///   que a sobrecarga garante, as DUAS saidas, e onde esta a medicao que sustenta
///   a lista. Reduzir a mensagem a "nao suportado" fica vermelho.
/// </summary>
procedure TTestCastMatrix.TestMensagemDeRecusaEnsinaASaida;
var
  LRegister: TFluentSQLRegister;
  LDriver: TFluentSQLDriver;
  LEncontrado: Boolean;
  LMensagem: String;

  procedure _Exige(const ATrecho, APorque: String);
  begin
    Assert.IsTrue(Pos(ATrecho, LMensagem) > 0,
      'A mensagem de recusa de Cast(dftGuid) perdeu "' + ATrecho + '". ' +
      APorque + sLineBreak + 'Mensagem atual: ' + LMensagem);
  end;

begin
  LEncontrado := False;
  LMensagem := '';
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      try
        _Funcoes(LRegister, LDriver).Cast('C', dftGuid);
      except
        on E: EFluentSQLFunctionNotSupported do
        begin
          LMensagem := E.Message;
          LEncontrado := True;
        end;
      end;
      Break;
    end;
    Assert.IsTrue(LEncontrado,
      'Nenhum dialeto registrado recusou Cast(C, dftGuid). Sem recusa nao ha ' +
      'mensagem, e a politica de intersecao estrita deixou de existir.');

    _Exige('dftGuid',
      'A mensagem tem de NOMEAR o tipo pedido: "Cast(dftGuid) foi recusado" e ' +
      'acionavel, "tipo invalido" manda o programador adivinhar.');
    _Exige('dftString',
      'A mensagem tem de dizer o que a sobrecarga ACEITA, senao o proximo passo ' +
      'do leitor e tentar os outros nove tipos um a um.');
    _Exige('intersecao',
      'A mensagem tem de dizer que a recusa e de intersecao, e nao do banco ' +
      'dele - sem isso o leitor troca de dialeto achando que resolve.');
    _Exige('Cast(AExpression, ''GRAFIA_DO_BANCO'')',
      'Primeira saida: a sobrecarga de String, com a grafia da chamada pronta.');
    _Exige('ForDialectOnly',
      'Segunda saida: registrar o fragmento so no motor em que ele vale.');
    _Exige('test.cast.matrix.sql',
      'Sem o ponteiro para a medicao, o proximo dev alarga a lista no palpite.');
  finally
    LRegister.Free;
  end;
end;

/// <summary>
///   ESCOPO DECLARADO: este teste varre UMA porta - a do CORE (TFluentSQLFunctions,
///   o objeto que TFluentSQL usa) - e UMA sobrecarga - a de TFluentSQLDataFieldType.
///   Dentro disso a afirmacao e forte: nenhum dos dez tipos, em nenhum dialeto
///   registrado, cai no corpo abstrato.
///
///   O QUE ELE NAO COBRE, dito aqui porque teste nao pode afirmar cobertura que
///   nao tem: pela PORTA DO DRIVER, a sobrecarga de String tem EAbstractError
///   CONHECIDO - LRegister.Functions(dbnMSSQL).Cast('C', 'INTEGER') levanta
///   EAbstractError, e o mesmo vale nos nove drivers, porque nenhum deles
///   sobrescreve Cast(String, String) e o corpo herdado de
///   TFluentSQLFunctionAbstract levanta. Isso e PRE-EXISTENTE a T17 (antes dela
///   nenhum driver sobrescrevia sobrecarga alguma de Cast) e continua aberto de
///   proposito: nao e escopo desta entrega. Pela porta do CORE a mesma chamada
///   responde 'CAST(C AS INTEGER)', porque ali a sobrecarga de String e padrao A e
///   nao despacha - e e por isso que o buraco nao aparece aqui.
/// </summary>
procedure TTestCastMatrix.TestNenhumaCelulaLevantaEAbstractError;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LType: TFluentSQLDataFieldType;
  LFalhas: String;
begin
  LFalhas := '';
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      for LType := Low(TFluentSQLDataFieldType) to High(TFluentSQLDataFieldType) do
      begin
        try
          LFunctions.Cast('C', LType);
        except
          on E: EFluentSQLFunctionNotSupported do
            ; // erro nomeado e a resposta correta para celula inexistente
          on E: EAbstractError do
            LFalhas := LFalhas + sLineBreak + '  ' + _Celula(LDriver, LType) +
              ' caiu no corpo abstrato: ' + E.Message;
          on E: Exception do
            LFalhas := LFalhas + sLineBreak + '  ' + _Celula(LDriver, LType) +
              ' levantou ' + E.ClassName + ': ' + E.Message;
        end;
      end;
    end;
    Assert.AreEqual('', LFalhas, False,
      'Driver registrado que nao sobrescreve Cast cai em EAbstractError - ' +
      'compila limpo e explode na primeira consulta:' + LFalhas);
  finally
    LRegister.Free;
  end;
end;

procedure TTestCastMatrix.TestSobrecargaStringContinuaVerbatimEmTodoDialeto;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      // A sobrecarga String segue no PADRAO A e NAO mudou na T17: quem ja
      // chamava Cast('C','INTEGER') continua recebendo o mesmo texto em todo
      // dialeto. E o escape hatch para o que o enum nao exprime.
      Assert.AreEqual('CAST(C AS INTEGER)', LFunctions.Cast('C', 'INTEGER'), False,
        'A sobrecarga Cast(String, String) mudou de comportamento em ' +
        DriverName(LDriver) + '. Ela e o escape hatch e tem de continuar verbatim.');
      Assert.AreEqual('CAST(C AS DECIMAL(10,2))', LFunctions.Cast('C', 'DECIMAL(10,2)'), False,
        'A sobrecarga String precisa continuar aceitando o que o enum nao ' +
        'exprime, como DECIMAL(10,2), em ' + DriverName(LDriver) + '.');
    end;
  finally
    LRegister.Free;
  end;
end;

procedure TTestCastMatrix.TestLarguraExplicitaSobrepoeODefault;
var
  LRegister: TFluentSQLRegister;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // Onde a largura e obrigatoria, o default 4000 sai do
    // cFluentSQLCastDefaultLength e o valor explicito o substitui.
    if _EstaRegistrado(LRegister, dbnFirebird) then
      Assert.AreEqual('CAST(C AS VARCHAR(50))',
        _Funcoes(LRegister, dbnFirebird).Cast('C', dftString, 50), False,
        'Firebird deve honrar largura explicita.');
    if _EstaRegistrado(LRegister, dbnOracle) then
      Assert.AreEqual('CAST(C AS VARCHAR2(50))',
        _Funcoes(LRegister, dbnOracle).Cast('C', dftString, 50), False,
        'Oracle deve honrar largura explicita.');
    if _EstaRegistrado(LRegister, dbnMSSQL) then
      Assert.AreEqual('CAST(C AS NVARCHAR(50))',
        _Funcoes(LRegister, dbnMSSQL).Cast('C', dftString, 50), False,
        'SQL Server deve honrar largura explicita.');
    // E o default e mesmo 4000, nao um numero solto no driver.
    Assert.AreEqual(4000, cFluentSQLCastDefaultLength,
      'O default de largura e o maior valor legal na Oracle (ORA-00910 em 4001) ' +
      'e no SQL Server (Msg 131 em 4001). Mudar isso quebra os dois.');
  finally
    LRegister.Free;
  end;
end;

procedure TTestCastMatrix.TestDialetoSemLarguraIgnoraOuHonraConformeMedido;
var
  LRegister: TFluentSQLRegister;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // PostgreSQL: sem pedido explicito NAO leva largura, porque no PG a largura
    // e que trunca em silencio. Com pedido explicito, o chamador manda.
    if _EstaRegistrado(LRegister, dbnPostgreSQL) then
    begin
      Assert.AreEqual('CAST(C AS VARCHAR)',
        _Funcoes(LRegister, dbnPostgreSQL).Cast('C', dftString), False,
        'PostgreSQL sem largura explicita nao pode ganhar teto que hoje nao tem.');
      Assert.AreEqual('CAST(C AS VARCHAR(50))',
        _Funcoes(LRegister, dbnPostgreSQL).Cast('C', dftString, 50), False,
        'PostgreSQL deve honrar largura explicita quando pedida.');
    end;
    // SQLite: a largura e IGNORADA pelo motor (CAST(x AS TEXT(4)) devolve o texto
    // inteiro), entao nao e emitida nem quando pedida - enfeite que mente e pior.
    if _EstaRegistrado(LRegister, dbnSQLite) then
      Assert.AreEqual('CAST(C AS TEXT)',
        _Funcoes(LRegister, dbnSQLite).Cast('C', dftString, 50), False,
        'SQLite ignora largura no motor; emiti-la seria enfeite enganoso.');
  finally
    LRegister.Free;
  end;
end;

procedure TTestCastMatrix.TestFormaQueDesbloqueiaAT13;
var
  LRegister: TFluentSQLRegister;
  LFirebird: String;
  LDB2: String;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // A T13 (slot de valor do CASE) ficou bloqueada porque Firebird e DB2 recusam
    // 'CASE WHEN c THEN :p1 ELSE :p2 END' no PREPARE:
    //   Firebird 5.0.4 .. -804 Data type unknown
    //   DB2 v12.1.5.0 ... SQL0418N untyped parameter marker
    // Com os dois ramos em CAST, os dois motores aceitam. Medido com AS STRINGS
    // EXATAS abaixo - ver a seccao T13 de test.cast.matrix.sql.
    if _EstaRegistrado(LRegister, dbnFirebird) then
    begin
      LFirebird := _Funcoes(LRegister, dbnFirebird).Cast(':p1', dftString);
      Assert.AreEqual('CAST(:p1 AS VARCHAR(4000))', LFirebird, False,
        'A forma que o Firebird aceitou no PREPARE mudou. Se este texto mudar, ' +
        'a T13 volta a ficar bloqueada no Firebird e a prova tem de ser refeita ' +
        'contra motor real.');
    end;
    if _EstaRegistrado(LRegister, dbnDB2) then
    begin
      LDB2 := _Funcoes(LRegister, dbnDB2).Cast('?', dftString);
      Assert.AreEqual('CAST(? AS VARCHAR)', LDB2, False,
        'A forma que o DB2 aceitou no PREPARE mudou. Se este texto mudar, a T13 ' +
        'volta a ficar bloqueada no DB2 e a prova tem de ser refeita.');
    end;
  finally
    LRegister.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCastMatrix);

end.
