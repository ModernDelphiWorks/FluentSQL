{
  ------------------------------------------------------------------------------
  FluentSQL - matriz de MERGE por dialeto.

  MERGE nao e universal: e palavra-chave em SQL Server, Oracle e PostgreSQL 15+,
  e NAO existe em MySQL nem SQLite. Hoje um unico dialeto tem serializador de
  MERGE registrado (MSSQL, em FluentSQL.SerializeMSSQL.pas). Esta matriz fixa,
  celula por celula, o que cada dialeto faz - inclusive os que NAO suportam, que
  precisam levantar excecao NOMEADA em vez de estourar a pilha ou emitir SQL mudo.

  QUAIS DIALETOS ESTAO REGISTRADOS - leia com cuidado, ja custou um bloqueador.

  Register.pas inclui Source\FluentSQL.inc e liga um driver por IFDEF. O
  conjunto de defines que ele enxerga tem DUAS fontes, e nao uma:

    (a) o proprio Source\FluentSQL.inc - hoje liga FIREBIRD, MSSQL, MYSQL,
        SQLITE, ORACLE, POSTGRESQL e MONGODB, e deixa INTERBASE e DB2
        comentados;
    (b) os -D da LINHA DE COMANDO do compilador, que sao globais e valem para
        toda unit. Compilar com -DDB2 -DINTERBASE liga os dois, e isso e acao
        SUPORTADA - o proprio CHANGELOG a recomenda a quem precisa desses
        dialetos.

  O que NAO conta e o DEFINE escrito dentro de um .dpr: ele tem escopo de
  ARQUIVO e nunca chega a Register.pas.

  Consequencia para esta matriz: INTERBASE e DB2 nao tem celula fixa. Com eles
  desligados a chamada morre em EFluentSQLDriverNotRegistered, antes de chegar
  ao MERGE; com eles ligados o driver existe, o MERGE e que nao, e a chamada cai
  em EFluentSQLStatementNotSupported - a MESMA celula dos outros cinco sem
  serializador. As duas sao corretas, cada uma na sua build, e por isso a classe
  esperada e escolhida em RUNTIME (ver _DriverEstaRegistrado abaixo) e nao por
  IFDEF - assim o teste continua valido tanto se o dono ligar o driver no
  .inc quanto se o consumidor o ligar por -D.
  ------------------------------------------------------------------------------
}

unit test.merge.matrix;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Register,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestMergeMatrix = class
  private
    function BuildMerge(const ADialect: TFluentSQLDriver; const AValue: string;
      out ASql: string): IFluentSQL;
    function DialectOf(const AName: string): TFluentSQLDriver;
    function _DriverEstaRegistrado(const ADialect: TFluentSQLDriver): Boolean;
  public
    /// <summary>
    ///   Dialeto COM serializador de MERGE: o valor do usuario vira :pN e o texto
    ///   do SQL nunca o contem.
    /// </summary>
    [Test]
    [TestCase('MSSQL', 'MSSQL')]
    procedure TestMerge_Supported_ParameterizesHostileValue(const ADialectName: string);

    /// <summary>
    ///   Dialeto SEM serializador de MERGE: tem de levantar excecao NOMEADA.
    ///   Antes desta tarefa TFluentSQLSerialize.Merge delegava a si mesmo via
    ///   Register e estourava EStackOverflow - crash, nao erro tratavel.
    /// </summary>
    [Test]
    [TestCase('Firebird',   'Firebird')]
    [TestCase('MySQL',      'MySQL')]
    [TestCase('SQLite',     'SQLite')]
    [TestCase('Oracle',     'Oracle')]
    [TestCase('PostgreSQL', 'PostgreSQL')]
    procedure TestMerge_Unsupported_RaisesNamedException(const ADialectName: string);

    /// <summary>
    ///   Dialeto OPCIONAL - desligado no .inc, mas ligavel por -D na linha de
    ///   comando. A celula muda de classe conforme a build, e as duas classes
    ///   sao corretas:
    ///
    ///     driver NAO compilado -> EFluentSQLDriverNotRegistered
    ///                             (morre antes de chegar ao MERGE)
    ///     driver compilado     -> EFluentSQLStatementNotSupported
    ///                             (o driver existe, o MERGE dele e que nao)
    ///
    ///   O que o teste trava, nas duas builds, e o mesmo: excecao NOMEADA,
    ///   nunca AV, nunca EStackOverflow, nunca SQL silencioso.
    /// </summary>
    [Test]
    [TestCase('Interbase', 'Interbase')]
    [TestCase('DB2',       'DB2')]
    procedure TestMerge_OptionalDriver_RaisesNamedException(const ADialectName: string);

    /// <summary>
    ///   FRONTEIRA CONHECIDA, NAO CORRIGIDA NESTA TAREFA: o MongoDB nao tem MERGE
    ///   e seu serializador sobrescreve AsString inteiro, entao a clausula MERGE e
    ///   descartada EM SILENCIO e sai "{}". Nao e injecao (nada do usuario vaza),
    ///   mas tambem nao e excecao nomeada. Este teste trava o comportamento atual
    ///   para que a correcao futura falhe aqui, de forma visivel, em vez de passar
    ///   despercebida.
    /// </summary>
    [Test]
    procedure TestMerge_MongoDB_DropsMergeSilently_KnownGap;
  end;

implementation

uses
  System.SysUtils,
  System.Variants;

const
  HOSTILE = 'x''; DROP TABLE USERS; --';

{ TTestMergeMatrix }

function TTestMergeMatrix.DialectOf(const AName: string): TFluentSQLDriver;
begin
  if SameText(AName, 'MSSQL')      then Exit(dbnMSSQL);
  if SameText(AName, 'MySQL')      then Exit(dbnMySQL);
  if SameText(AName, 'Firebird')   then Exit(dbnFirebird);
  if SameText(AName, 'SQLite')     then Exit(dbnSQLite);
  if SameText(AName, 'Interbase')  then Exit(dbnInterbase);
  if SameText(AName, 'DB2')        then Exit(dbnDB2);
  if SameText(AName, 'Oracle')     then Exit(dbnOracle);
  if SameText(AName, 'PostgreSQL') then Exit(dbnPostgreSQL);
  if SameText(AName, 'MongoDB')    then Exit(dbnMongoDB);
  raise Exception.Create('Dialeto desconhecido na matriz: ' + AName);
end;

function TTestMergeMatrix.BuildMerge(const ADialect: TFluentSQLDriver;
  const AValue: string; out ASql: string): IFluentSQL;
begin
  Result := FluentSQL.Query(ADialect);
  Result.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', AValue]);
  ASql := Result.AsString;
end;

procedure TTestMergeMatrix.TestMerge_Supported_ParameterizesHostileValue(
  const ADialectName: string);
var
  LQuery: IFluentSQL;
  LSql: string;
  I: Integer;
  LFound: Boolean;
begin
  LQuery := BuildMerge(DialectOf(ADialectName), HOSTILE, LSql);

  Assert.IsFalse(LSql.Contains(HOSTILE),
    ADialectName + ': valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains(':p1'),
    ADialectName + ': esperado placeholder :p1. SQL=' + LSql);

  LFound := False;
  for I := 0 to LQuery.Params.Count - 1 do
    if VarToStrDef(LQuery.Params[I].Value, '') = HOSTILE then
      LFound := True;
  Assert.IsTrue(LFound,
    ADialectName + ': o valor tem de estar na lista de parametros, intacto.');
end;

procedure TTestMergeMatrix.TestMerge_Unsupported_RaisesNamedException(
  const ADialectName: string);
var
  LSql: string;
  LDialect: TFluentSQLDriver;
begin
  LDialect := DialectOf(ADialectName);
  Assert.WillRaise(
    procedure
    begin
      BuildMerge(LDialect, HOSTILE, LSql);
    end,
    EFluentSQLStatementNotSupported,
    ADialectName + ': MERGE sem serializador tem de levantar excecao nomeada, ' +
    'nao EStackOverflow nem SQL invalido.');
end;

/// <summary>
///   O driver tem serializador registrado NESTA build? Perguntado ao registro
///   em runtime, e nao deduzido por {$IFDEF} no proprio teste - porque o
///   conjunto de defines que Register.pas enxerga vem do .inc E dos -D da linha
///   de comando, e um {$IFDEF} escrito aqui so acompanharia o segundo se esta
///   unit tambem incluisse o .inc. Mesmo padrao ja usado por
///   test.driver.functions.matrix.pas (_EstaRegistrado).
///
///   O canal e independente do codigo sob teste: aqui pergunta-se ao registro
///   direto, la a chamada percorre TFluentSQL.Query -> Merge -> Serialize.
/// </summary>
function TTestMergeMatrix._DriverEstaRegistrado(
  const ADialect: TFluentSQLDriver): Boolean;
var
  LRegister: TFluentSQLRegister;
begin
  Result := True;
  LRegister := TFluentSQLRegister.Create;
  try
    try
      LRegister.Serialize(ADialect);
    except
      on E: EFluentSQLDriverNotRegistered do
        Result := False;
    end;
  finally
    LRegister.Free;
  end;
end;

procedure TTestMergeMatrix.TestMerge_OptionalDriver_RaisesNamedException(
  const ADialectName: string);
var
  LSql: string;
  LDialect: TFluentSQLDriver;
  LEsperada: ExceptClass;
  LPorque: string;
begin
  LDialect := DialectOf(ADialectName);
  if _DriverEstaRegistrado(LDialect) then
  begin
    // Build com -DDB2 / -DINTERBASE (ou com o .inc alterado): o driver existe,
    // e a celula e a MESMA dos outros cinco sem serializador de MERGE.
    LEsperada := EFluentSQLStatementNotSupported;
    LPorque := ' esta compilado nesta build, entao o MERGE tem de cair na ' +
      'mesma excecao dos demais dialetos sem serializador.';
  end
  else
  begin
    LEsperada := EFluentSQLDriverNotRegistered;
    LPorque := ' nao esta compilado nesta build, entao a chamada tem de morrer ' +
      'em erro nomeado de driver ausente, antes de chegar ao MERGE.';
  end;

  Assert.WillRaise(
    procedure
    begin
      BuildMerge(LDialect, HOSTILE, LSql);
    end,
    LEsperada,
    ADialectName + LPorque);
end;

procedure TTestMergeMatrix.TestMerge_MongoDB_DropsMergeSilently_KnownGap;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := BuildMerge(dbnMongoDB, HOSTILE, LSql);

  // Nada do usuario vaza - isto o teste garante de verdade.
  Assert.IsFalse(LSql.Contains(HOSTILE),
    'MongoDB: valor hostil nao pode aparecer na saida. MQL=' + LSql);
  // ... mas a clausula inteira some sem aviso. Frontier declarada, nao corrigida.
  Assert.AreEqual('{}', LSql, False,
    'MongoDB descarta o MERGE em silencio; se isto mudou, a lacuna foi fechada ' +
    'e este teste precisa virar assercao de excecao nomeada.');

  // PARAMETRO ORFAO: a parametrizacao do slot de valor acontece na construcao,
  // antes da serializacao, entao o valor entra em Params mesmo com a clausula
  // sendo descartada depois. Na base eram 0 parametros - o valor virava texto, e
  // o texto era jogado fora junto com a clausula; aqui e 1, referenciado por
  // nada no MQL emitido. E consequencia direta da lacuna acima e desaparece
  // junto com ela. Afirmado aqui, e nao escondido.
  Assert.AreEqual(1, LQuery.Params.Count,
    'MongoDB acumula 1 parametro que o MQL emitido nao referencia; se virou 0, ' +
    'o descarte passou a acontecer antes da parametrizacao.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMergeMatrix);
end.
