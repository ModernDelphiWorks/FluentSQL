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

  A terceira e a pior, e e a razao de varias celulas desta matriz LEVANTAREM em
  vez de emitir SQL. A regra da casa vale na ordem: erro nomeado > SQL que o motor
  recusa > SQL que o motor aceita com semantica errada.

  O QUE ESTA MATRIZ TRAVA

  Cada par (dialeto, TFluentSQLDataFieldType) tem valor esperado LITERAL declarado
  em _Esperado. Nao e "nao levanta": e o texto exato. Consequencia pratica:

    * trocar NVARCHAR(4000) por NVARCHAR no MSSQL ........ VERMELHO
      (e essa mutacao e a que reintroduziria o truncamento silencioso em 30)
    * trocar SIGNED por INTEGER no MySQL ................. VERMELHO
    * fazer o SQLite responder dftDate em vez de levantar  VERMELHO
    * fazer o PostgreSQL emitir VARCHAR(4000) ............ VERMELHO
      (largura no PG INTRODUZ truncamento; ver o driver)

  A comparacao e CASE-SENSITIVE de proposito: Assert.AreEqual de string no DUnitX
  ignora caixa por default, e 'nvarchar' passando por 'NVARCHAR' esconderia
  exatamente o tipo de divergencia que esta matriz existe para pegar.

  NAO MEDIDO: InterBase - nao ha imagem de container publica. Todas as dez celulas
  dele levantam, e isso e deliberado: a grafia NAO foi inferida do Firebird. Ver
  FluentSQL.FunctionsInterbase.pas. MongoDB tambem levanta em todas, pela doutrina
  ja escrita em FluentSQL.FunctionsMongoDB.pas (a intersecao e relacional).
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
    /// <summary>Dialeto registrado nunca cai no corpo abstrato (EAbstractError).</summary>
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
/// </summary>
function _Esperado(const ADriver: TFluentSQLDriver;
  const AType: TFluentSQLDataFieldType): String;
begin
  Result := cLEVANTA;
  case ADriver of
    // Firebird 5.0.4. Largura OBRIGATORIA (sem ela: -104). Estouro de largura e
    // erro (22001), nunca truncamento calado.
    dbnFirebird:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR(4000))';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE PRECISION)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftText:     Result := 'CAST(C AS BLOB SUB_TYPE TEXT)';
        dftDateTime: Result := 'CAST(C AS TIMESTAMP)';
        dftBoolean:  Result := 'CAST(C AS BOOLEAN)';
      end;

    // SQL Server 2022 CU26. NVARCHAR SEMPRE com largura: 'AS NVARCHAR' nu trunca
    // em 30 sem erro nem aviso. Teto 4000 (Msg 131 em 4001).
    dbnMSSQL:
      case AType of
        dftString:   Result := 'CAST(C AS NVARCHAR(4000))';
        dftInteger:  Result := 'CAST(C AS INT)';
        dftFloat:    Result := 'CAST(C AS FLOAT)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftText:     Result := 'CAST(C AS NVARCHAR(MAX))';
        dftDateTime: Result := 'CAST(C AS DATETIME)';
        dftGuid:     Result := 'CAST(C AS UNIQUEIDENTIFIER)';
        dftBoolean:  Result := 'CAST(C AS BIT)';
      end;

    // MySQL 8.4.11. Alvo de CAST e LISTA FECHADA: INTEGER/TEXT/BOOLEAN/UUID sao
    // ERROR 1064. CHAR sem largura nao trunca.
    dbnMySQL:
      case AType of
        dftString:   Result := 'CAST(C AS CHAR)';
        dftText:     Result := 'CAST(C AS CHAR)';
        dftInteger:  Result := 'CAST(C AS SIGNED)';
        dftFloat:    Result := 'CAST(C AS DOUBLE)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftDateTime: Result := 'CAST(C AS DATETIME)';
      end;

    // SQLite 3.53.4. So TEXT/INTEGER/REAL/BLOB tem significado. Date, DateTime,
    // Guid e Boolean LEVANTAM embora o motor "aceite": ele destroi o dado calado.
    dbnSQLite:
      case AType of
        dftString:   Result := 'CAST(C AS TEXT)';
        dftText:     Result := 'CAST(C AS TEXT)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS REAL)';
      end;

    // Oracle AI 26ai 23.26.2.0.0. Largura OBRIGATORIA (ORA-00906), teto 4000
    // (ORA-00910). dftText levanta: CLOB nao e alvo de CAST (ORA-22849).
    dbnOracle:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR2(4000))';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS BINARY_DOUBLE)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftDateTime: Result := 'CAST(C AS TIMESTAMP)';
        dftBoolean:  Result := 'CAST(C AS BOOLEAN)';
      end;

    // PostgreSQL 16.14. VARCHAR SEM largura de proposito: aqui a largura e que
    // trunca em silencio (VARCHAR(4) sobre 10 chars devolve 4).
    dbnPostgreSQL:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE PRECISION)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftText:     Result := 'CAST(C AS TEXT)';
        dftDateTime: Result := 'CAST(C AS TIMESTAMP)';
        dftGuid:     Result := 'CAST(C AS UUID)';
        dftBoolean:  Result := 'CAST(C AS BOOLEAN)';
      end;

    // DB2 v12.1.5.0. VARCHAR sem largura nao trunca (300 chars entram, 300 saem).
    // CLOB E alvo valido aqui, ao contrario da Oracle.
    dbnDB2:
      case AType of
        dftString:   Result := 'CAST(C AS VARCHAR)';
        dftInteger:  Result := 'CAST(C AS INTEGER)';
        dftFloat:    Result := 'CAST(C AS DOUBLE)';
        dftDate:     Result := 'CAST(C AS DATE)';
        dftText:     Result := 'CAST(C AS CLOB)';
        dftDateTime: Result := 'CAST(C AS TIMESTAMP)';
        dftBoolean:  Result := 'CAST(C AS BOOLEAN)';
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
begin
  LConferidas := 0;
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
    Assert.IsTrue(LConferidas >= 70,
      'Esperado ao menos 70 celulas conferidas (7 dialetos x 10 tipos); ' +
      'conferidas ' + IntToStr(LConferidas) + '. Driver desligado no .inc ' +
      'reduz a cobertura desta matriz.');
  finally
    LRegister.Free;
  end;
end;

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
