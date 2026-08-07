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

  A regra que estes testes travam e simples e vale para TODO dialeto do enum:

      chamar qualquer funcao de IFluentSQLFunctions ou devolve SQL, ou levanta
      UMA das duas excecoes nomeadas do FluentSQL. Nunca EAbstractError, nunca
      EAccessViolation, nunca Exception crua.

  Adicionou uma funcao nova em IFluentSQLFunctions? Acrescente-a em _Invoke e em
  cFUNCTIONS. Se ela for do padrao B (delega ao driver), a matriz vai ficar
  vermelha ate voce implementa-la em CADA Source\Drivers\FluentSQL.Functions*.pas
  - que e exatamente o ponto deste arquivo.
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
    /// <summary>Trava do defeito do CEIL: T-SQL so tem CEILING.</summary>
    [Test]
    procedure TestCeilRespeitaODialeto;
    /// <summary>Trava do defeito do LENGTH: MSSQL usa LEN, Firebird CHAR_LENGTH.</summary>
    [Test]
    procedure TestLengthRespeitaODialeto;
    /// <summary>
    ///   TStrDBEngineName e indexado posicionalmente pelo enum. Se as duas
    ///   listas sairem de sincronia, o Register devolve o driver do vizinho, em
    ///   silencio. Estas assercoes de assinatura por dialeto detectam isso.
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

  Assert.AreEqual(9 * 26, LCelulas,
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

procedure TTestDriverFunctionsMatrix.TestEnumEArrayDeNomesEstaoAlinhados;
var
  LRegister: TFluentSQLRegister;
  LFn: IFluentSQLFunctions;
begin
  LRegister := TFluentSQLRegister.Create;
  try
    // Cada dialeto abaixo tem uma assinatura de saida que NENHUM vizinho no enum
    // produz. Se TStrDBEngineName sair de sincronia com TFluentSQLDriver, o
    // Register entrega o driver errado e estas igualdades quebram.
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
