{
  ------------------------------------------------------------------------------
  FluentSQL - guardas de ordem do builder que eram Assert.

  Ate esta branch o Source/ inteiro tinha DOIS Assert, e os dois guardavam a
  mesma coisa: um metodo do builder que so faz sentido depois de outro ter sido
  chamado, e que sem ele indexa uma colecao vazia em Count-1.

    FluentSQL.Cases.pas:340  Assert(FCase.WhenList.Count > 0, ...)   -> IfThen
    FluentSQL.pas:838        Assert(FAST.ASTColumns.Count > 0, ...)  -> Desc

  Assert e compilado para FORA com $C-, que e o default de qualquer build de
  release. Ou seja: em producao nao havia guarda nenhuma, e a chamada caia em
  WhenList[-1] / Columns[-1] - EArgumentOutOfRangeException vinda de dentro da
  TList, com mensagem que nao nomeia nem o metodo nem a unit do chamador.

  ESTES TESTES SAO LOAD-BEARING NAS DUAS CONFIGURACOES. Rodam identicos com
  assercoes ligadas ($C+, default do dcc32) e desligadas ($C-): a excecao
  esperada e EArgumentException, que nenhum Assert produz. Com o codigo
  anterior eles ficam vermelhos em $C+ (vinha EAssertionFailed) E em $C-
  (vinha EArgumentOutOfRangeException). Prova de mutacao no relatorio da tarefa.

  A classe escolhida e EArgumentException porque e a que a casa ja usa para
  "esta chamada nao produz SQL serializavel" - ver TUtils._AssertSingleValue e
  FluentSQL.Merge.pas:297 ("MERGE sem nenhuma clausula WHEN nao e
  serializavel"), que e literalmente o mesmo caso de uso.

  O IRMAO: ElseIf. So havia dois Assert, mas o levantamento dos metodos que
  dependem de um WHEN previo devolve TRES chamadas, nao duas - IfThen tinha
  Assert, Desc tinha Assert, e ElseIf nao tinha nada. Sem WHEN o ElseIf emitia
  calado "CASE ELSE <x> END", que nao e aceito por motor nenhum (medido, ver
  test.cases.guards.matrix.sql). Ganhou a mesma guarda e tem celula propria aqui.

  NAO existe Asc para receber a guarda equivalente: IFluentSQL nao declara esse
  metodo (FluentSQL.Interfaces.pas:245 declara so Desc; dirAscending e o
  default de TOrderByDirection). Desc e o unico modificador de direcao da API,
  logo a familia "indexa Count-1 sem guarda" esta fechada em dois pontos, e os
  dois estao cobertos abaixo.
  ------------------------------------------------------------------------------
}

unit test.builder.guards;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Register,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestBuilderGuards = class
  private
    function _MensagemDe(const AProc: TProc): String;
  public
    // --- IfThen / ElseIf sem When -------------------------------------------
    [Test]
    procedure TestIfThenSemWhenLevanta;
    [Test]
    procedure TestIfThenSemWhenNomeiaAChamadaNaMensagem;
    [Test]
    procedure TestIfThenInt64SemWhenLevantaTambem;
    [Test]
    procedure TestElseIfSemWhenLevanta;
    [Test]
    procedure TestElseIfSemWhenNomeiaAChamadaNaMensagem;
    [Test]
    procedure TestElseIfInt64SemWhenLevantaTambem;

    // --- Desc sem coluna no ORDER BY ----------------------------------------
    [Test]
    procedure TestDescSemColunaNoOrderByLevanta;
    [Test]
    procedure TestDescSemColunaNoOrderByNomeiaAChamadaNaMensagem;
    [Test]
    procedure TestDescComColunaNoSelectMasNenhumaNoOrderByLevanta;

    // --- controles: o caminho legitimo continua montando --------------------
    [Test]
    procedure TestControleCaseComWhenContinuaSerializando;
    [Test]
    procedure TestControleDescComColunaContinuaEmitindoDESC;
  end;

implementation

/// <summary>
///   Executa AProc esperando que levante, e devolve a mensagem. Falha o teste
///   se NAO levantar - senao um "guarda sumiu" viraria string vazia e a
///   assercao de conteudo passaria por acidente.
/// </summary>
function TTestBuilderGuards._MensagemDe(const AProc: TProc): String;
var
  LLevantou: Boolean;
begin
  Result := '';
  LLevantou := False;
  try
    AProc();
  except
    on E: Exception do
    begin
      LLevantou := True;
      Result := E.Message;
    end;
  end;
  // Fora do try de proposito: Assert.Fail levanta ETestFailure, e se fosse
  // chamado ali dentro o proprio except o engoliria e o teste passaria verde.
  if not LLevantou then
    Assert.Fail('A chamada tinha de ter levantado e nao levantou.');
end;

{ --- IfThen / ElseIf sem When --------------------------------------------- }

procedure TTestBuilderGuards.TestIfThenSemWhenLevanta;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .IfThen('''FISICA''');
    end,
    EArgumentException,
    'IfThen antes de When tem de levantar EArgumentException, e nao depender ' +
    'de Assert - que some com {$C-} e deixa cair em WhenList[-1]');
end;

procedure TTestBuilderGuards.TestIfThenSemWhenNomeiaAChamadaNaMensagem;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .IfThen('''FISICA''');
    end);
  // False = nao ignore caixa. O default de DUnitX e ignorar, e ai 'ifthen'
  // passaria - a exigencia aqui e que a mensagem cite o metodo como ele se
  // escreve na API.
  Assert.Contains(LMsg, 'IfThen', False,
    'A mensagem tem de nomear a chamada que falhou. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'When', False,
    'A mensagem tem de dizer o que faltou (When). Recebido: ' + LMsg);
end;

procedure TTestBuilderGuards.TestIfThenInt64SemWhenLevantaTambem;
begin
  // A sobrecarga Int64 delega na de String; celula propria para que quebrar a
  // delegacao nao passe despercebido.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .IfThen(Int64(1));
    end,
    EArgumentException,
    'A sobrecarga IfThen(Int64) tem de cair na mesma guarda');
end;

procedure TTestBuilderGuards.TestElseIfSemWhenLevanta;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .ElseIf('''OUTRO''');
    end,
    EArgumentException,
    'ElseIf antes de When emitia calado "CASE ELSE x END", que motor nenhum ' +
    'aceita; tem de levantar');
end;

procedure TTestBuilderGuards.TestElseIfSemWhenNomeiaAChamadaNaMensagem;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .ElseIf('''OUTRO''');
    end);
  Assert.Contains(LMsg, 'ElseIf', False,
    'A mensagem tem de nomear ElseIf, nao IfThen. Recebido: ' + LMsg);
end;

procedure TTestBuilderGuards.TestElseIfInt64SemWhenLevantaTambem;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .CaseExpr('TIPO')
        .ElseIf(Int64(0));
    end,
    EArgumentException,
    'A sobrecarga ElseIf(Int64) tem de cair na mesma guarda');
end;

{ --- Desc sem coluna no ORDER BY ------------------------------------------ }

procedure TTestBuilderGuards.TestDescSemColunaNoOrderByLevanta;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .OrderBy()
        .Desc;
    end,
    EArgumentException,
    'Desc sem coluna no ORDER BY tem de levantar EArgumentException, e nao ' +
    'depender de Assert - que some com {$C-} e deixa cair em Columns[-1]');
end;

procedure TTestBuilderGuards.TestDescSemColunaNoOrderByNomeiaAChamadaNaMensagem;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select
        .From('CLIENTES')
        .OrderBy()
        .Desc;
    end);
  Assert.Contains(LMsg, 'Desc', False,
    'A mensagem tem de nomear a chamada que falhou. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'ORDER BY', False,
    'A mensagem tem de dizer qual clausula esta vazia. Recebido: ' + LMsg);
end;

procedure TTestBuilderGuards.TestDescComColunaNoSelectMasNenhumaNoOrderByLevanta;
begin
  // Esta e a porta que o relatorio de origem descrevia como "passa a guarda e
  // ainda assim estoura": coluna no SELECT, nenhuma no ORDER BY. Ela NAO passa
  // - _DefineSectionOrderBy (FluentSQL.pas:794) faz FAST.ASTColumns apontar
  // para FAST.OrderBy.Columns, entao as duas colecoes sao o mesmo objeto
  // enquanto a secao e secOrderBy. A celula fica porque a equivalencia so vale
  // enquanto _DefineSectionOrderBy mantiver a ligacao: se alguem separar as
  // duas colecoes, este teste e que avisa.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Select('ID')
        .Column('NOME')
        .From('CLIENTES')
        .OrderBy()
        .Desc;
    end,
    EArgumentException,
    'Com coluna no SELECT e nenhuma no ORDER BY, Desc tem de levantar - nunca ' +
    'indexar Columns[-1]');
end;

{ --- controles ------------------------------------------------------------- }

procedure TTestBuilderGuards.TestControleCaseComWhenContinuaSerializando;
var
  LSql: String;
begin
  // Controle da guarda de Cases: o caminho legitimo nao pode ter sido afetado.
  LSql := FluentSQL.Query(dbnPostgreSQL)
    .Select
    .Column('ID')
    .Column('TIPO_CLIENTE')
    .CaseExpr
      .When('0').IfThen('''FISICA''')
      .When('1').IfThen('''JURIDICA''')
      .ElseIf('''OUTRO''')
    .EndCase
    .Alias('TIPO_PESSOA')
    .From('CLIENTES')
    .AsString;
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO_CLIENTE WHEN 0 THEN ''FISICA'' WHEN 1 THEN ''JURIDICA'' ' +
    'ELSE ''OUTRO'' END) AS TIPO_PESSOA FROM CLIENTES',
    LSql, False,
    'A guarda nao pode ter mexido no CASE legitimo');
end;

procedure TTestBuilderGuards.TestControleDescComColunaContinuaEmitindoDESC;
var
  LSql: String;
begin
  LSql := FluentSQL.Query(dbnPostgreSQL)
    .Select
    .From('CLIENTES')
    .OrderBy('NOME')
    .Desc
    .AsString;
  Assert.Contains(LSql, 'DESC', False,
    'Desc com coluna tem de continuar emitindo DESC. Recebido: ' + LSql);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBuilderGuards);

end.
