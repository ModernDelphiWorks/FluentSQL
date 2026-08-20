{
  ------------------------------------------------------------------------------
  FluentSQL - blindagem estrutural da matriz driver x funcao (T3)

  Este arquivo existe para impedir que a matriz driver x IFluentSQLFunctions
  volte a ter celulas que explodem em runtime.

  Antes da T3, a matriz tinha dois modos de falha, ambos invisiveis em tempo de
  compilacao:

    * EAccessViolation - TFluentSQLRegister.Functions devolvia nil para dialeto
      nao registrado e FluentSQL.Functions.pas dereferenciava a interface nil;
    * EAbstractError   - o dialeto estava registrado mas a unit de driver nao
      sobrescrevia o metodo, entao caia no corpo de
      FluentSQL.FunctionsAbstract.pas que levanta.

  Sao DUAS regras, e a segunda e a que realmente trava a regressao.

  REGRA 1 - nada explode de forma opaca. Chamar qualquer funcao de
  IFluentSQLFunctions ou devolve SQL, ou levanta UMA das duas excecoes nomeadas
  do FluentSQL. Nunca EAbstractError, nunca EAccessViolation, nunca Exception
  crua.

  REGRA 2 - a matriz bate com a TABELA DE SUPORTE (_FuncoesNaoSuportadas).
  A regra 1 sozinha e fraca demais: ela aceita que um driver troque o corpo de
  uma funcao que hoje funciona por um raise nomeado, porque isso continua sendo
  "uma das duas excecoes". A matriz seria rebaixada em silencio e a suite ficaria
  verde - a regressao que esta tarefa consertou poderia voltar sem barulho. Por
  isso cada par (dialeto, funcao) tem valor esperado declarado, e o desvio e
  vermelho NOS DOIS SENTIDOS: suportado que parou de responder, e nao-suportado
  que voltou a responder.

  ATE ONDE A REGRA 2 ALCANCA - leia antes de confiar na tabela.

  A tabela so tem poder real sobre as funcoes do PADRAO B, as que delegam ao
  driver (ver o bloco de padroes em Source\Core\FluentSQL.Functions.pas). Para as
  do PADRAO A - Count, Sum, Min, Max, Average, Abs, Cast(String,String), Upper,
  Lower, Round, Floor - o core emite SQL ANSI fixo SEM consultar o driver, entao a
  chamada sempre devolve texto e a tabela as marca "suportado" TRIVIALMENTE, para
  todo dialeto. Isso nao e evidencia de que o SQL gerado seja valido naquele motor.

  A tabela NAO detecta divergencia de dialeto no padrao A. Foi exatamente esse o
  buraco por onde passaram TRES celulas erradas: CEIL(...) no MSSQL (T-SQL so tem
  CEILING), LENGTH(...) no MSSQL (T-SQL usa LEN) e LENGTH(...) no Firebird (que
  usa CHAR_LENGTH). O conserto foi mover Ceil e Length para o padrao B, nao
  ajustar teste. Caso vivo hoje: no
  MongoDB, Abs/Cast/Upper/Lower/Round/Floor nao levantam e mesmo assim produzem
  MQL invalido - a coluna e descartada em silencio (ver o comentario da linha
  dbnMongoDB na tabela, e a divida no CHANGELOG). Suspeita de divergencia numa
  funcao do padrao A se investiga lendo a documentacao do dialeto, nao rodando
  esta suite.

  O CASO 'Cast' NESTA TABELA - leia antes de citar a linha dele como prova.

  Depois da T17, Cast tem DUAS sobrecargas e elas estao em padroes diferentes:

    Cast(x, ADataType: TFluentSQLDataFieldType) .. PADRAO B, ciente de dialeto,
      coberta celula a celula por test.cast.matrix.pas. NAO e o que esta tabela
      exercita.
    Cast(x, ADataType: String) ................... PADRAO A por decisao, emite
      verbatim. E ESTA que _Invoke chama, com 'INTEGER'.

  Logo, a celula 'Cast' desta tabela afirma UMA coisa so: o escape hatch continua
  devolvendo texto em todo dialeto. Ela NAO afirma que o texto roda. E nao roda em
  toda parte: Cast('C', 'INTEGER') produz CAST(C AS INTEGER), que e ERROR 1064 no
  MySQL 8.4 - o alvo de CAST do MySQL e lista fechada e a grafia dele e SIGNED
  (medido; transcricao em test.cast.matrix.sql). A celula fica verde assim mesmo, e
  esta certo que fique: quem chama a sobrecarga de String assumiu a portabilidade
  por contrato. Quem quer a garantia do framework chama Cast(x, dftInteger), que
  em MySQL emite SIGNED.

  OS SEIS DIALETOS SEM DRIVER - por que a matriz tem 15 linhas e nao 9.

  TFluentSQLDriver tem 15 membros, e SEIS deles (dbnInformix, dbnADS, dbnASA,
  dbnAbsoluteDB, dbnElevateDB, dbnNexusDB) nao tem unit em Source\Drivers nem
  _Register* no FluentSQL.Register.pas. Eles existem no enum porque a superficie e
  a ORDEM dele sao contrato publico - consumidores externos nomeiam esses valores
  e o ordinal e serializavel.

  As 156 celulas deles NAO se comportam todas igual, e a diferenca e a mesma dos
  padroes A e B descritos acima. Medido: 90 celulas levantam
  EFluentSQLDriverNotRegistered (as 15 funcoes do padrao B, que passam pelo
  Register) e 66 devolvem TEXTO ANSI (as 11 do padrao A - Count, Sum, Min, Max,
  Average, Abs, Cast(String), Upper, Lower, Round, Floor -, que o core emite sem
  consultar o driver: Count('C') devolve 'COUNT(C)' para dbnADS como devolve para
  qualquer outro). Nenhuma das 156 levanta AV ou EAbstractError.

  Quem afirma isso e TestDriverSemImplementacaoLevantaErroNomeado, nas quatro
  portas de entrada (Register.Functions/Select/Serialize e a chamada de funcao do
  padrao B - Trim, deliberadamente, porque padrao A nao chegaria ao Register). O
  contrato do enum em si - ordinal e nome - esta em
  TestOrdinalENomeDeCadaDialetoSaoContrato.

  Adicionou uma funcao nova em IFluentSQLFunctions? Acrescente-a em _Invoke e em
  cFUNCTIONS. Se ela for do padrao B (delega ao driver), a matriz vai ficar
  vermelha ate voce implementa-la em CADA Source\Drivers\FluentSQL.Functions*.pas
  ou declara-la em _FuncoesNaoSuportadas com justificativa de dialeto escrita no
  driver - que e exatamente o ponto deste arquivo.
  ------------------------------------------------------------------------------
}

unit test.driver.functions.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDriverFunctionsMatrix = class
  public
    /// <summary>A blindagem: nenhuma celula da matriz levanta inesperadamente.</summary>
    [Test]
    procedure TestMatrizInteiraNaoLevantaExcecaoInesperada;
    /// <summary>Dialeto registrado nunca pode cair no corpo abstrato.</summary>
    [Test]
    procedure TestDialetoRegistradoNuncaLevantaEAbstractError;
    /// <summary>Dialeto nao registrado da erro nomeado, nao AV.</summary>
    [Test]
    procedure TestDialetoNaoRegistradoLevantaErroNomeado;
    /// <summary>Toda celula que responde tem que devolver texto nao vazio.</summary>
    [Test]
    procedure TestCelulaQueRespondeNaoDevolveVazio;
    /// <summary>
    ///   A trava de regressao de verdade: confronta a matriz observada com a
    ///   TABELA DE SUPORTE declarada em _FuncoesNaoSuportadas. Sem isto, um
    ///   driver pode rebaixar em silencio uma funcao que hoje funciona, trocando
    ///   o corpo por um raise, e a suite fica verde.
    /// </summary>
    [Test]
    procedure TestMatrizBateComATabelaDeSuporte;
    /// <summary>A tabela de suporte so pode citar funcoes que existem.</summary>
    [Test]
    procedure TestTabelaDeSuporteNaoCitaFuncaoInexistente;
    /// <summary>Trava do defeito do CEIL: T-SQL so tem CEILING.</summary>
    [Test]
    procedure TestCeilRespeitaODialeto;
    /// <summary>Trava do defeito do LENGTH: MSSQL usa LEN, Firebird CHAR_LENGTH.</summary>
    [Test]
    procedure TestLengthRespeitaODialeto;
    /// <summary>
    ///   Os SEIS membros de TFluentSQLDriver que nao tem unit em Source\Drivers
    ///   (dbnInformix, dbnADS, dbnASA, dbnAbsoluteDB, dbnElevateDB, dbnNexusDB)
    ///   EXISTEM no enum e, ao serem pedidos, levantam a excecao NOMEADA - nunca
    ///   EAccessViolation, nunca EAbstractError, nunca Exception crua. E a prova
    ///   de que restaurar a superficie do enum nao trouxe de volta o modo de
    ///   falha opaco que cd9e71d matou.
    /// </summary>
    [Test]
    procedure TestDriverSemImplementacaoLevantaErroNomeado;
    /// <summary>
    ///   O ORDINAL de cada membro e o nome que ele carrega sao contrato: o valor
    ///   e serializavel e consumidores externos nomeiam os membros. Reordenar,
    ///   remover ou desalinhar CDriverNames tem de ficar vermelho AQUI.
    /// </summary>
    [Test]
    procedure TestOrdinalENomeDeCadaDialetoSaoContrato;
    /// <summary>
    ///   Pega COLISAO de nome em TStrDBEngineName (duas entradas iguais fazem um
    ///   driver sobrescrever o outro no registo). Nao pega permutacao, que e
    ///   invisivel por o array ser chave simetrica; cardinalidade e pega pelo
    ///   compilador via array[TFluentSQLDriver]. Detalhe no corpo do metodo.
    /// </summary>
    [Test]
    procedure TestEnumEArrayDeNomesEstaoAlinhados;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Functions,
  FluentSQL.Register;

const
  /// <summary>
  ///   Os membros de TFluentSQLDriver que NAO tem implementacao: nao existe
  ///   FluentSQL.Serialize*/Select*/Functions* deles em Source\Drivers, nem
  ///   _Register* em FluentSQL.Register.pas, nem {$DEFINE} em FluentSQL.inc.
  ///   Estao no enum como superficie publica (consumidores externos nomeiam
  ///   quatro deles) e sao cobrados aqui pelo comportamento honesto.
  ///   Nomea-los um a um e proposital: sumir com qualquer um do enum para a
  ///   COMPILACAO deste arquivo.
  /// </summary>
  cSEM_DRIVER: array[0..5] of TFluentSQLDriver = (
    dbnInformix, dbnADS, dbnASA, dbnAbsoluteDB, dbnElevateDB, dbnNexusDB
  );

  cFUNCTIONS: array[0..25] of String = (
    'Count', 'Sum', 'Min', 'Max', 'Average', 'Abs', 'Cast',
    'Year', 'Month', 'Day', 'Date', 'Upper', 'Lower', 'Length',
    'Trim', 'LTrim', 'RTrim', 'Concat', 'SubString', 'Round',
    'Floor', 'Ceil', 'Modulus', 'Coalesce', 'CurrentDate', 'CurrentTimestamp'
  );

/// <summary>
///   Chama uma funcao de IFluentSQLFunctions pelo nome. Schema e Merge ficam de
///   fora de proposito: sao fabricas de builder, nao geradoras de SQL escalar.
/// </summary>
function _Invoke(const AFunctions: IFluentSQLFunctions; const AName: String): String;
begin
  if AName = 'Count' then Result := AFunctions.Count('C')
  else if AName = 'Sum' then Result := AFunctions.Sum('C')
  else if AName = 'Min' then Result := AFunctions.Min('C')
  else if AName = 'Max' then Result := AFunctions.Max('C')
  else if AName = 'Average' then Result := AFunctions.Average('C')
  else if AName = 'Abs' then Result := AFunctions.Abs('C')
  // Sobrecarga de String (padrao A), NAO a de enum. 'INTEGER' e ERROR 1064 no
  // MySQL: esta linha mede que o escape hatch responde, nao que o SQL roda.
  // A cobertura por dialeto da sobrecarga portavel esta em test.cast.matrix.pas.
  else if AName = 'Cast' then Result := AFunctions.Cast('C', 'INTEGER')
  else if AName = 'Year' then Result := AFunctions.Year('C')
  else if AName = 'Month' then Result := AFunctions.Month('C')
  else if AName = 'Day' then Result := AFunctions.Day('C')
  else if AName = 'Date' then Result := AFunctions.Date('C')
  else if AName = 'Upper' then Result := AFunctions.Upper('C')
  else if AName = 'Lower' then Result := AFunctions.Lower('C')
  else if AName = 'Length' then Result := AFunctions.Length('C')
  else if AName = 'Trim' then Result := AFunctions.Trim('C')
  else if AName = 'LTrim' then Result := AFunctions.LTrim('C')
  else if AName = 'RTrim' then Result := AFunctions.RTrim('C')
  else if AName = 'Concat' then Result := AFunctions.Concat(['A', 'B'])
  else if AName = 'SubString' then Result := AFunctions.SubString('C', 1, 3)
  else if AName = 'Round' then Result := AFunctions.Round('C', 2)
  else if AName = 'Floor' then Result := AFunctions.Floor('C')
  else if AName = 'Ceil' then Result := AFunctions.Ceil('C')
  else if AName = 'Modulus' then Result := AFunctions.Modulus('C', '2')
  else if AName = 'Coalesce' then Result := AFunctions.Coalesce(['C', '0'])
  else if AName = 'CurrentDate' then Result := AFunctions.CurrentDate
  else if AName = 'CurrentTimestamp' then Result := AFunctions.CurrentTimestamp
  else
    raise Exception.Create('Funcao "' + AName + '" ausente de _Invoke. ' +
      'Toda funcao de IFluentSQLFunctions tem que estar coberta pela matriz.');
end;

/// <summary>
///   TABELA DE SUPORTE: dialeto x funcao -> suportado / nao suportado.
///
///   Esta e a trava de regressao da matriz. Cada par (dialeto, funcao) tem um
///   valor esperado definido: as funcoes NOMEADAS aqui devem levantar
///   EFluentSQLFunctionNotSupported; TODAS as outras de cFUNCTIONS devem
///   devolver SQL. TestMatrizBateComATabelaDeSuporte verifica as DUAS direcoes:
///
///     * celula marcada suportada que levanta ......... VERMELHO (regressao)
///     * celula marcada nao-suportada que devolve SQL .. VERMELHO (tabela podre)
///
///   Consequencia pratica: rebaixar uma funcao que hoje funciona - trocando o
///   corpo do driver por um raise - NAO passa despercebido. Exige acrescentar o
///   nome dela aqui, que e uma linha de diff que um revisor humano ve.
///
///   ATENCAO: esta tabela e o CONTRATO, nao um retrato da implementacao. Uma
///   celula marcada suportada que levanta e um DEFEITO A CORRIGIR no driver, nao
///   um convite a mover a funcao para a lista de nao-suportadas. Mover so se
///   houver justificativa de dialeto, escrita no driver.
///
///   Dialetos desligados no FluentSQL.inc nao sao verificados contra a tabela
///   (levantam EFluentSQLDriverNotRegistered antes de chegar ao driver), mas a
///   linha deles fica declarada para valer no dia em que forem ligados.
/// </summary>
function _FuncoesNaoSuportadas(const ADriver: TFluentSQLDriver): TArray<String>;
begin
  case ADriver of
    dbnMSSQL:      Result := [];
    dbnMySQL:      Result := [];
    dbnFirebird:   Result := [];
    dbnSQLite:     Result := [];
    dbnOracle:     Result := [];
    dbnPostgreSQL: Result := [];

    // Desligado no .inc. Length e Ceil nao tem forma verificada no InterBase
    // (ver comentario em FluentSQL.FunctionsInterbase.pas). As demais funcoes do
    // padrao B continuam marcadas como suportadas de proposito: o driver ainda
    // nao as implementa, e ligar {$DEFINE INTERBASE} deve mesmo acusar isso.
    dbnInterbase:  Result := ['Length', 'Ceil'];

    // Desligado no .inc. Lista VAZIA, ao contrario da do Interbase logo acima, e
    // a assimetria e proposital: o DB2 implementa Length e Ceil (LENGTH/CEIL sao
    // built-ins documentados), enquanto no InterBase nenhuma das duas formas foi
    // verificada. As demais funcoes do padrao B o DB2 tambem nao implementa, e
    // seguem marcadas suportadas pela mesma razao do Interbase: ligar
    // {$DEFINE DB2} deve mesmo acusar a lacuna, nao abenco-la.
    dbnDB2:        Result := [];

    // Deliberado, nao e driver incompleto: o SerializeMongoDB so consome nome de
    // campo ou marcador de agregacao. Ver FluentSQL.FunctionsMongoDB.pas.
    //
    // As agregacoes (Count/Sum/Min/Max/Average) funcionam DE VERDADE: o
    // serializador reconhece os prefixos ANSI 'SUM(' / 'COUNT(' / ... e monta o
    // $project. Sonda ponta a ponta:
    //   Sum   -> {"aggregate":"t","pipeline":[{"$project":{"x":1,"_id":0}}],...}
    //
    // JA Abs/Cast/Upper/Lower/Round/Floor NAO produzem MQL valido. Elas apenas
    // NAO LEVANTAM, porque sao do padrao A - o core emite ANSI sem consultar o
    // driver, e o serializador nao reconhece 'UPPER(' / 'ROUND(' / 'ABS(' /
    // 'CAST(' / 'FLOOR(' / 'LOWER('. A coluna cai em NormalizeFieldName e e
    // DESCARTADA EM SILENCIO. Sonda ponta a ponta:
    //   Round -> {"find":"t","filter":{},"projection":{}}      <- a coluna sumiu
    //   Upper -> {"find":"t","filter":{},"projection":{}}      <- a coluna sumiu
    //
    // Nao da para corrigir aqui: marcar essas 6 como nao-suportadas deixa o
    // TestMatrizBateComATabelaDeSuporte vermelho com TABELA PODRE, porque o core
    // responde em ANSI antes de qualquer consulta ao driver. E o ponto cego do
    // padrao A descrito no cabecalho deste arquivo. Divida registrada no
    // CHANGELOG, seccao [Unreleased].
    dbnMongoDB:    Result := ['Year', 'Month', 'Day', 'Date', 'Length', 'Trim',
                              'LTrim', 'RTrim', 'Concat', 'SubString', 'Ceil',
                              'Modulus', 'Coalesce', 'CurrentDate',
                              'CurrentTimestamp'];

    // OS SEIS SEM DRIVER. Nao ha unit FluentSQL.Functions* deles em
    // Source\Drivers e nao ha _Register* no FluentSQL.Register.pas - nao ha
    // {$DEFINE} que os ligue. A lista vazia aqui NAO afirma "suporta as 26":
    // nenhuma chamada chega ao driver, porque TFluentSQLRegister.Functions
    // levanta EFluentSQLDriverNotRegistered antes. Quem os cobre e
    // TestDriverSemImplementacaoLevantaErroNomeado, que os nomeia um a um; esta
    // linha existe porque TestTabelaDeSuporteNaoCitaFuncaoInexistente percorre
    // o enum INTEIRO, inclusive os nao registrados.
    dbnInformix,
    dbnADS,
    dbnASA,
    dbnAbsoluteDB,
    dbnElevateDB,
    dbnNexusDB:    Result := [];
  else
    raise Exception.Create('Dialeto sem linha na TABELA DE SUPORTE. ' +
      'Todo membro de TFluentSQLDriver precisa declarar o que suporta.');
  end;
end;

function _EhNaoSuportada(const ADriver: TFluentSQLDriver; const AName: String): Boolean;
var
  LName: String;
begin
  Result := False;
  for LName in _FuncoesNaoSuportadas(ADriver) do
    if LName = AName then
      Exit(True);
end;

/// <summary>
///   O dialeto tem implementacao de funcoes registrada na build corrente? Isso
///   depende dos {$DEFINE} de FluentSQL.inc, entao e detectado em runtime e nao
///   assumido - assim o teste continua valido se o dono ligar ou desligar um
///   driver no .inc.
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

procedure TTestDriverFunctionsMatrix.TestMatrizInteiraNaoLevantaExcecaoInesperada;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LIdx: Integer;
  LCelulas: Integer;
  LFalhas: String;
begin
  LCelulas := 0;
  LFalhas := '';
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      for LIdx := Low(cFUNCTIONS) to High(cFUNCTIONS) do
      begin
        Inc(LCelulas);
        try
          _Invoke(LFunctions, cFUNCTIONS[LIdx]);
        except
          // As duas unicas excecoes que a matriz pode produzir.
          on E: EFluentSQLDriverNotRegistered do ;
          on E: EFluentSQLFunctionNotSupported do ;
          on E: Exception do
            LFalhas := LFalhas + sLineBreak + '  ' + IntToStr(Ord(LDriver)) + '/' +
              cFUNCTIONS[LIdx] + ' -> ' + E.ClassName + ': ' + E.Message;
        end;
      end;
      LFunctions := nil;
    end;
  finally
    LRegister.Free;
  end;

  // 15 dialetos x 26 funcoes. Sao 15 e nao 9 porque o enum tem SEIS membros sem
  // driver (ver TestDriverSemImplementacaoLevantaErroNomeado): eles entram na
  // varredura e as 156 celulas deles tem de sair por EFluentSQLDriverNotRegistered,
  // que e uma das duas excecoes que o "except" acima aceita.
  Assert.AreEqual(15 * 26, LCelulas,
    'A matriz mudou de tamanho. Atualize cFUNCTIONS/_Invoke junto com o enum.');
  Assert.AreEqual('', LFalhas,
    'Celulas da matriz levantaram excecao NAO nomeada (indice do driver/funcao):' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestDialetoRegistradoNuncaLevantaEAbstractError;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LIdx: Integer;
  LRegistrados: Integer;
  LFalhas: String;
begin
  LRegistrados := 0;
  LFalhas := '';
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      Inc(LRegistrados);
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      for LIdx := Low(cFUNCTIONS) to High(cFUNCTIONS) do
        try
          _Invoke(LFunctions, cFUNCTIONS[LIdx]);
        except
          on E: EFluentSQLFunctionNotSupported do ;
          on E: Exception do
            LFalhas := LFalhas + sLineBreak + '  ' + IntToStr(Ord(LDriver)) + '/' +
              cFUNCTIONS[LIdx] + ' -> ' + E.ClassName;
        end;
      LFunctions := nil;
    end;
  finally
    LRegister.Free;
  end;

  Assert.IsTrue(LRegistrados >= 7,
    'Esperado ao menos 7 dialetos registrados (FluentSQL.inc), obtido ' + IntToStr(LRegistrados));
  Assert.AreEqual('', LFalhas,
    'Dialeto registrado caiu no corpo abstrato ou em erro nao previsto:' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestDialetoNaoRegistradoLevantaErroNomeado;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LNaoRegistrados: Integer;
  LClasse: String;
begin
  LNaoRegistrados := 0;
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if _EstaRegistrado(LRegister, LDriver) then
        Continue;
      Inc(LNaoRegistrados);
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      LClasse := '';
      try
        // Trim e padrao B: obrigatoriamente passa pelo Register.
        LFunctions.Trim('C');
      except
        on E: Exception do
          LClasse := E.ClassName;
      end;
      LFunctions := nil;
      Assert.AreEqual('EFluentSQLDriverNotRegistered', LClasse,
        'Dialeto nao registrado (indice ' + IntToStr(Ord(LDriver)) +
        ') tem que dar erro nomeado, nao nil/EAccessViolation.');
    end;
  finally
    LRegister.Free;
  end;
  Assert.IsTrue(LNaoRegistrados > 0,
    'O teste precisa de ao menos um dialeto desligado no .inc para ter valor.');
end;

procedure TTestDriverFunctionsMatrix.TestCelulaQueRespondeNaoDevolveVazio;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LIdx: Integer;
  LSql: String;
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
      for LIdx := Low(cFUNCTIONS) to High(cFUNCTIONS) do
      begin
        LSql := '';
        try
          LSql := _Invoke(LFunctions, cFUNCTIONS[LIdx]);
        except
          on E: EFluentSQLFunctionNotSupported do
            Continue;
        end;
        if Trim(LSql) = '' then
          LFalhas := LFalhas + sLineBreak + '  ' + IntToStr(Ord(LDriver)) + '/' + cFUNCTIONS[LIdx];
      end;
      LFunctions := nil;
    end;
  finally
    LRegister.Free;
  end;
  Assert.AreEqual('', LFalhas, 'Celulas devolveram string vazia:' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestMatrizBateComATabelaDeSuporte;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LIdx: Integer;
  LEsperadoSuportado: Boolean;
  LObtidoSuportado: Boolean;
  LSql: String;
  LVerificadas: Integer;
  LFalhas: String;
begin
  LVerificadas := 0;
  LFalhas := '';
  LRegister := TFluentSQLRegister.Create;
  try
    for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    begin
      if not _EstaRegistrado(LRegister, LDriver) then
        Continue;
      LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
      for LIdx := Low(cFUNCTIONS) to High(cFUNCTIONS) do
      begin
        Inc(LVerificadas);
        LEsperadoSuportado := not _EhNaoSuportada(LDriver, cFUNCTIONS[LIdx]);

        LObtidoSuportado := True;
        LSql := '';
        try
          LSql := _Invoke(LFunctions, cFUNCTIONS[LIdx]);
        except
          on E: EFluentSQLFunctionNotSupported do
            LObtidoSuportado := False;
        end;
        if Trim(LSql) = '' then
          LObtidoSuportado := False;

        if LEsperadoSuportado and (not LObtidoSuportado) then
          LFalhas := LFalhas + sLineBreak +
            '  REGRESSAO: driver ' + IntToStr(Ord(LDriver)) + '/' + cFUNCTIONS[LIdx] +
            ' era suportado e parou de responder. Conserte o driver; nao mova a ' +
            'funcao para _FuncoesNaoSuportadas sem justificativa de dialeto.'
        else if (not LEsperadoSuportado) and LObtidoSuportado then
          LFalhas := LFalhas + sLineBreak +
            '  TABELA PODRE: driver ' + IntToStr(Ord(LDriver)) + '/' + cFUNCTIONS[LIdx] +
            ' passou a devolver "' + LSql + '". Remova o nome de _FuncoesNaoSuportadas.';
      end;
      LFunctions := nil;
    end;
  finally
    LRegister.Free;
  end;

  Assert.IsTrue(LVerificadas >= 7 * 26,
    'Esperado ao menos 7 dialetos x 26 funcoes verificados contra a tabela, obtido ' +
    IntToStr(LVerificadas));
  Assert.AreEqual('', LFalhas, 'Matriz divergiu da TABELA DE SUPORTE:' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestTabelaDeSuporteNaoCitaFuncaoInexistente;
var
  LDriver: TFluentSQLDriver;
  LName: String;
  LIdx: Integer;
  LExiste: Boolean;
  LFalhas: String;
begin
  // Um nome com typo em _FuncoesNaoSuportadas ('Trimm') abriria um buraco mudo:
  // a entrada nao casaria com nada e a funcao de verdade passaria a ser cobrada
  // como suportada sem ninguem notar a intencao contraria.
  LFalhas := '';
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
    for LName in _FuncoesNaoSuportadas(LDriver) do
    begin
      LExiste := False;
      for LIdx := Low(cFUNCTIONS) to High(cFUNCTIONS) do
        if cFUNCTIONS[LIdx] = LName then
          LExiste := True;
      if not LExiste then
        LFalhas := LFalhas + sLineBreak + '  driver ' + IntToStr(Ord(LDriver)) +
          ' cita "' + LName + '", que nao esta em cFUNCTIONS';
    end;
  Assert.AreEqual('', LFalhas, 'TABELA DE SUPORTE cita funcao inexistente:' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestCeilRespeitaODialeto;
var
  LRegister: TFluentSQLRegister;
  LFn: IFluentSQLFunctions;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // O defeito original: Ceil era padrao A e emitia CEIL(...) para todo mundo,
    // deixando inalcancavel o CEILING ja escrito em FluentSQL.FunctionsMSSQL.pas.
    LFn := TFluentSQLFunctions.Create(dbnMSSQL, LRegister);
    Assert.AreEqual('CEILING(VALOR)', LFn.Ceil('VALOR'), 'T-SQL nao tem CEIL, so CEILING.');
    LFn := TFluentSQLFunctions.Create(dbnOracle, LRegister);
    Assert.AreEqual('CEIL(VALOR)', LFn.Ceil('VALOR'), 'Oracle tem CEIL e nao tem CEILING.');
    LFn := TFluentSQLFunctions.Create(dbnFirebird, LRegister);
    Assert.AreEqual('CEIL(VALOR)', LFn.Ceil('VALOR'), 'dbnFirebird');
    LFn := TFluentSQLFunctions.Create(dbnPostgreSQL, LRegister);
    Assert.AreEqual('CEIL(VALOR)', LFn.Ceil('VALOR'), 'dbnPostgreSQL');
    LFn := nil;
  finally
    LRegister.Free;
  end;
end;

procedure TTestDriverFunctionsMatrix.TestLengthRespeitaODialeto;
var
  LRegister: TFluentSQLRegister;
  LFn: IFluentSQLFunctions;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // O defeito original: Length era padrao A e emitia LENGTH(...) para todo
    // mundo, inclusive para os dois dialetos que nao tem essa funcao.
    LFn := TFluentSQLFunctions.Create(dbnMSSQL, LRegister);
    Assert.AreEqual('LEN(NOME)', LFn.Length('NOME'), 'T-SQL nao tem LENGTH; a funcao e LEN.');
    LFn := TFluentSQLFunctions.Create(dbnFirebird, LRegister);
    Assert.AreEqual('CHAR_LENGTH(NOME)', LFn.Length('NOME'),
      'Firebird nao tem LENGTH no core; a funcao e CHAR_LENGTH.');
    LFn := TFluentSQLFunctions.Create(dbnOracle, LRegister);
    Assert.AreEqual('LENGTH(NOME)', LFn.Length('NOME'), 'dbnOracle');
    LFn := TFluentSQLFunctions.Create(dbnPostgreSQL, LRegister);
    Assert.AreEqual('LENGTH(NOME)', LFn.Length('NOME'), 'dbnPostgreSQL');
    LFn := nil;
  finally
    LRegister.Free;
  end;
end;

procedure TTestDriverFunctionsMatrix.TestDriverSemImplementacaoLevantaErroNomeado;
var
  LRegister: TFluentSQLRegister;
  LFunctions: IFluentSQLFunctions;
  LDriver: TFluentSQLDriver;
  LIdx: Integer;
  LVerbo: Integer;
  LClasse: String;
  LFalhas: String;
  LMedidas: Integer;
begin
  LFalhas := '';
  LMedidas := 0;
  LRegister := TFluentSQLRegister.Create;
  try
    for LIdx := Low(cSEM_DRIVER) to High(cSEM_DRIVER) do
    begin
      LDriver := cSEM_DRIVER[LIdx];
      // Quatro portas de entrada: as tres do Register mais a chamada de funcao
      // do padrao B, que e a que o usuario faz e a que produzia a AV opaca.
      for LVerbo := 0 to 3 do
      begin
        Inc(LMedidas);
        LClasse := '<nao levantou>';
        try
          case LVerbo of
            0: LRegister.Functions(LDriver);
            1: LRegister.Select(LDriver);
            2: LRegister.Serialize(LDriver);
            3: begin
                 LFunctions := TFluentSQLFunctions.Create(LDriver, LRegister);
                 LFunctions.Trim('C');
               end;
          end;
        except
          on E: Exception do
            LClasse := E.ClassName;
        end;
        LFunctions := nil;
        if LClasse <> 'EFluentSQLDriverNotRegistered' then
          LFalhas := LFalhas + sLineBreak + '  ' + DriverName(LDriver) +
            ' (ordinal ' + IntToStr(Ord(LDriver)) + ') verbo ' + IntToStr(LVerbo) +
            ' -> ' + LClasse;
      end;
    end;
  finally
    LRegister.Free;
  end;

  Assert.AreEqual(6 * 4, LMedidas,
    'Esperado 6 dialetos sem driver x 4 portas de entrada.');
  Assert.AreEqual('', LFalhas,
    'Dialeto sem implementacao tem que levantar EFluentSQLDriverNotRegistered, ' +
    'e nao AV/EAbstractError/Exception crua:' + LFalhas);
end;

procedure TTestDriverFunctionsMatrix.TestOrdinalENomeDeCadaDialetoSaoContrato;
begin
  // O ordinal e serializavel e a superficie e publica: consumidores externos
  // nomeiam membros deste enum no proprio codigo. Reordenar ou remover nao e
  // refatoracao cosmetica - e BREAKING CHANGE, e tem de sair vermelho aqui.
  // Esta e tambem a UNICA assercao que pega PERMUTACAO de CDriverNames:
  // TestEnumEArrayDeNomesEstaoAlinhados nao pega, pelo motivo escrito no corpo dele.
  Assert.AreEqual(15, Ord(High(TFluentSQLDriver)) + 1, 'TFluentSQLDriver mudou de tamanho.');

  Assert.AreEqual(0,  Ord(dbnMSSQL),      'dbnMSSQL');
  Assert.AreEqual(1,  Ord(dbnMySQL),      'dbnMySQL');
  Assert.AreEqual(2,  Ord(dbnFirebird),   'dbnFirebird');
  Assert.AreEqual(3,  Ord(dbnSQLite),     'dbnSQLite');
  Assert.AreEqual(4,  Ord(dbnInterbase),  'dbnInterbase');
  Assert.AreEqual(5,  Ord(dbnDB2),        'dbnDB2');
  Assert.AreEqual(6,  Ord(dbnOracle),     'dbnOracle');
  Assert.AreEqual(7,  Ord(dbnInformix),   'dbnInformix');
  Assert.AreEqual(8,  Ord(dbnPostgreSQL), 'dbnPostgreSQL');
  Assert.AreEqual(9,  Ord(dbnADS),        'dbnADS');
  Assert.AreEqual(10, Ord(dbnASA),        'dbnASA');
  Assert.AreEqual(11, Ord(dbnAbsoluteDB), 'dbnAbsoluteDB');
  Assert.AreEqual(12, Ord(dbnMongoDB),    'dbnMongoDB');
  Assert.AreEqual(13, Ord(dbnElevateDB),  'dbnElevateDB');
  Assert.AreEqual(14, Ord(dbnNexusDB),    'dbnNexusDB');

  Assert.AreEqual('MSSQL',      DriverName(dbnMSSQL),      'nome de dbnMSSQL');
  Assert.AreEqual('MySQL',      DriverName(dbnMySQL),      'nome de dbnMySQL');
  Assert.AreEqual('Firebird',   DriverName(dbnFirebird),   'nome de dbnFirebird');
  Assert.AreEqual('SQLite',     DriverName(dbnSQLite),     'nome de dbnSQLite');
  Assert.AreEqual('Interbase',  DriverName(dbnInterbase),  'nome de dbnInterbase');
  Assert.AreEqual('DB2',        DriverName(dbnDB2),        'nome de dbnDB2');
  Assert.AreEqual('Oracle',     DriverName(dbnOracle),     'nome de dbnOracle');
  Assert.AreEqual('Informix',   DriverName(dbnInformix),   'nome de dbnInformix');
  Assert.AreEqual('PostgreSQL', DriverName(dbnPostgreSQL), 'nome de dbnPostgreSQL');
  Assert.AreEqual('ADS',        DriverName(dbnADS),        'nome de dbnADS');
  Assert.AreEqual('ASA',        DriverName(dbnASA),        'nome de dbnASA');
  Assert.AreEqual('AbsoluteDB', DriverName(dbnAbsoluteDB), 'nome de dbnAbsoluteDB');
  Assert.AreEqual('MongoDB',    DriverName(dbnMongoDB),    'nome de dbnMongoDB');
  Assert.AreEqual('ElevateDB',  DriverName(dbnElevateDB),  'nome de dbnElevateDB');
  Assert.AreEqual('NexusDB',    DriverName(dbnNexusDB),    'nome de dbnNexusDB');
end;

procedure TTestDriverFunctionsMatrix.TestEnumEArrayDeNomesEstaoAlinhados;
var
  LRegister: TFluentSQLRegister;
  LFn: IFluentSQLFunctions;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // O QUE ESTAS ASSERCOES PEGAM, e o que NAO pegam.
    //
    // Cada dialeto abaixo tem uma assinatura de saida que nenhum outro produz.
    // Isso pega COLISAO DE NOME em TStrDBEngineName: se dois membros do enum
    // mapearem para a mesma string, o segundo RegisterFunctions sobrescreve a
    // entrada do primeiro no dicionario e um dos dois passa a devolver o driver
    // do outro - aqui vira desigualdade.
    //
    // NAO pega PERMUTACAO. Trocar duas entradas de lugar no array e invisivel,
    // porque o array e chave simetrica: registro e consulta usam o MESMO indice,
    // entao o par (dbnX -> "Nome errado") continua interno e consistente. Quem
    // pega desalinhamento de CARDINALIDADE e o compilador: o array e declarado
    // array[TFluentSQLDriver], entao membro adicionado ou removido do enum para
    // a build com E2072 antes de qualquer teste rodar.
    LFn := TFluentSQLFunctions.Create(dbnMSSQL, LRegister);
    Assert.AreEqual('CONCAT(A, B)', LFn.Concat(['A', 'B']), 'dbnMSSQL');
    LFn := TFluentSQLFunctions.Create(dbnMySQL, LRegister);
    Assert.AreEqual('CURDATE()', LFn.CurrentDate, 'dbnMySQL');
    LFn := TFluentSQLFunctions.Create(dbnFirebird, LRegister);
    Assert.AreEqual('TRIM(LEADING FROM C)', LFn.LTrim('C'), 'dbnFirebird');
    LFn := TFluentSQLFunctions.Create(dbnSQLite, LRegister);
    Assert.AreEqual('STRFTIME(%Y, C)', LFn.Year('C'), 'dbnSQLite');
    LFn := TFluentSQLFunctions.Create(dbnOracle, LRegister);
    Assert.AreEqual('SYSTIMESTAMP', LFn.CurrentTimestamp, 'dbnOracle');
    LFn := TFluentSQLFunctions.Create(dbnPostgreSQL, LRegister);
    Assert.AreEqual('SUBSTRING(C FROM 1 FOR 3)', LFn.SubString('C', 1, 3), 'dbnPostgreSQL');
    LFn := nil;
  finally
    LRegister.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDriverFunctionsMatrix);

end.
