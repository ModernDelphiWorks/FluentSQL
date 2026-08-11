{
  ------------------------------------------------------------------------------
  FluentSQL
  Database-agnostic fluent SQL/MQL script generation library for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.Cases;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Variants,
  Generics.Collections,
  FluentSQL.Interfaces,
  FluentSQL.Expression;

type
  TFluentSQLCaseWhenThen = class(TInterfacedObject, IFluentSQLCaseWhenThen)
  strict private
    FThenExpression: IFluentSQLExpression;
    FWhenExpression: IFluentSQLExpression;
  protected
    function GetThenExpression: IFluentSQLExpression;
    function GetWhenExpression: IFluentSQLExpression;
    procedure SetThenExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenExpression(const AValue: IFluentSQLExpression);
  public
    constructor Create;
    destructor Destroy; override;
    property WhenExpression: IFluentSQLExpression read GetWhenExpression write SetWhenExpression;
    property ThenExpression: IFluentSQLExpression read GetThenExpression write SetThenExpression;
  end;

  TFluentSQLCaseWhenList = class(TInterfacedObject, IFluentSQLCaseWhenList)
  strict private
    FWhenThenList: TList<IFluentSQLCaseWhenThen>;
  protected
    function GetWhenThen(AIdx: Integer): IFluentSQLCaseWhenThen;
    procedure SetWhenThen(AIdx: Integer; const AValue: IFluentSQLCaseWhenThen);
    constructor Create;
  public
    destructor Destroy; override;
    function Add: IFluentSQLCaseWhenThen; overload;
    function Add(const AWhenThen: IFluentSQLCaseWhenThen): Integer; overload;
    function Count: Integer;
    property WhenThen[AIdx: Integer]: IFluentSQLCaseWhenThen read GetWhenThen write SetWhenThen; default;
  end;

  TFluentSQLCase = class(TInterfacedObject, IFluentSQLCase)
  protected
    FCaseExpression: IFluentSQLExpression;
    FElseExpression: IFluentSQLExpression;
    FWhenList: IFluentSQLCaseWhenList;
    function SerializeExpression(const AExpression: IFluentSQLExpression): String;
    function GetCaseExpression: IFluentSQLExpression;
    function GetElseExpression: IFluentSQLExpression;
    function GetWhenList: IFluentSQLCaseWhenList;
    procedure SetCaseExpression(const AValue: IFluentSQLExpression);
    procedure SetElseExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenList(const AValue: IFluentSQLCaseWhenList);
  public
    constructor Create;
    destructor Destroy; override;
    function Serialize: String; virtual;
    property CaseExpression: IFluentSQLExpression read GetCaseExpression write SetCaseExpression;
    property WhenList: IFluentSQLCaseWhenList read GetWhenList write SetWhenList;
    property ElseExpression: IFluentSQLExpression read GetElseExpression write SetElseExpression;
  end;

  TFluentSQLCriteriaCase = class(TInterfacedObject, IFluentSQLCriteriaCase)
  strict private
    FOwner: IFluentSQL;
    FCase: IFluentSQLCase;
    FLastExpression: IFluentSQLCriteriaExpression;
    /// <summary>
    ///   Indice do WHEN cujo ramo THEN foi preenchido por um SLOT DE VALOR, ou -1
    ///   se nenhum. Nao e cache: e o registro de que existe um :pN na colecao
    ///   apontado SO por aquele termo. Ver _AssertValueSlotFree.
    /// </summary>
    FThenValueSlotIdx: Integer;
    /// <summary>Idem para o ramo ELSE, que e unico e por isso e so um Boolean.</summary>
    FElseValueSlotUsed: Boolean;
    function _GetCase: IFluentSQLCase;
    procedure _AssertHaveWhen(const AMethod, AKeyword: String);
    procedure _AssertValueCarriesData(const AMethod: String; const AValue: Variant);
    procedure _AssertValueSlotFree(const AMethod: String; const AIsElse: Boolean);
    function _ValueSlotTerm(const AValue: Variant;
      const ADataType: TFluentSQLDataFieldType): String;
  public
    constructor Create(const AOwner: IFluentSQL; const AExpression: String);
    destructor Destroy; override;
    function AndOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: String): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: Int64): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: Variant;
      const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase; overload;
    function EndCase: IFluentSQL;
    function OrOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: String): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: Int64): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: Variant;
      const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: String): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: array of const): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    property Value: IFluentSQLCase read _GetCase;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLCase }

constructor TFluentSQLCase.Create;
begin
  FCaseExpression := TFluentSQLExpression.Create;
  FElseExpression := TFluentSQLExpression.Create;
  FWhenList := TFluentSQLCaseWhenList.Create;
end;

destructor TFluentSQLCase.Destroy;
begin
  FCaseExpression := nil;
  FElseExpression := nil;
  FWhenList := nil;
  inherited;
end;

function TFluentSQLCase.GetCaseExpression: IFluentSQLExpression;
begin
  Result := FCaseExpression;
end;

function TFluentSQLCase.GetElseExpression: IFluentSQLExpression;
begin
  Result := FElseExpression;
end;

function TFluentSQLCase.GetWhenList: IFluentSQLCaseWhenList;
begin
  Result := FWhenList;
end;

function TFluentSQLCase.Serialize: String;
var
  LFor: Integer;
  LWhenThen: IFluentSQLCaseWhenThen;
begin
  Result := 'CASE';
  if not FCaseExpression.IsEmpty then
    Result := TUtils.Concat([Result, FCaseExpression.Serialize]);
  for LFor := 0 to FWhenList.Count - 1 do
  begin
    Result := TUtils.Concat([Result, 'WHEN']);
    LWhenThen := FWhenList[LFor];
    if not LWhenThen.WhenExpression.IsEmpty then
      Result := TUtils.Concat([Result, LWhenThen.WhenExpression.Serialize]);
    Result := TUtils.Concat([Result, 'THEN', LWhenThen.ThenExpression.Serialize]);
  end;
  if not FElseExpression.IsEmpty then
    Result := TUtils.Concat([Result, 'ELSE', FElseExpression.Serialize]);
  Result := TUtils.Concat([Result, 'END']);
end;

function TFluentSQLCase.SerializeExpression(const AExpression: IFluentSQLExpression): String;
begin
  Result := AExpression.Serialize;
end;

procedure TFluentSQLCase.SetCaseExpression(const AValue: IFluentSQLExpression);
begin
  FCaseExpression := AValue;
end;

procedure TFluentSQLCase.SetElseExpression(const AValue: IFluentSQLExpression);
begin
  FElseExpression := AValue;
end;

procedure TFluentSQLCase.SetWhenList(const AValue: IFluentSQLCaseWhenList);
begin
  FWhenList := AValue;
end;

{ TFluentSQLCaseWhenList }

constructor TFluentSQLCaseWhenList.Create;
begin
  FWhenThenList := TList<IFluentSQLCaseWhenThen>.Create;
end;

destructor TFluentSQLCaseWhenList.Destroy;
begin
  FWhenThenList.Free;
  inherited;
end;

function TFluentSQLCaseWhenList.Add: IFluentSQLCaseWhenThen;
begin
  Result := TFluentSQLCaseWhenThen.Create;
  Add(Result);
end;

function TFluentSQLCaseWhenList.Add(const AWhenThen: IFluentSQLCaseWhenThen): Integer;
begin
  Result := FWhenThenList.Add(AWhenThen);
end;

function TFluentSQLCaseWhenList.Count: Integer;
begin
  Result := FWhenThenList.Count;
end;

function TFluentSQLCaseWhenList.GetWhenThen(AIdx: Integer): IFluentSQLCaseWhenThen;
begin
  Result := FWhenThenList[AIdx];
end;

procedure TFluentSQLCaseWhenList.SetWhenThen(AIdx: Integer; const AValue: IFluentSQLCaseWhenThen);
begin
  FWhenThenList[AIdx] := AValue;
end;

{ TFluentSQLCaseWhenThen }

constructor TFluentSQLCaseWhenThen.Create;
begin
  FWhenExpression := TFluentSQLExpression.Create;
  FThenExpression := TFluentSQLExpression.Create;
end;

destructor TFluentSQLCaseWhenThen.Destroy;
begin
  FThenExpression := nil;
  FWhenExpression := nil;
  inherited;
end;

function TFluentSQLCaseWhenThen.GetThenExpression: IFluentSQLExpression;
begin
  Result := FThenExpression;
end;

function TFluentSQLCaseWhenThen.GetWhenExpression: IFluentSQLExpression;
begin
  Result := FWhenExpression;
end;

procedure TFluentSQLCaseWhenThen.SetThenExpression(const AValue: IFluentSQLExpression);
begin
  FThenExpression := AValue;
end;

procedure TFluentSQLCaseWhenThen.SetWhenExpression(const AValue: IFluentSQLExpression);
begin
  FWhenExpression := AValue;
end;

{ TFluentSQLCriteriaCase }

function TFluentSQLCriteriaCase.AndOpe(const AExpression: String): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(AExpression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.AndOpe(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FOwner.Params));
  Result := Self;
end;

constructor TFluentSQLCriteriaCase.Create(const AOwner: IFluentSQL; const AExpression: String);
begin
  FOwner := AOwner;
  FCase := TFluentSQLCase.Create;
  FThenValueSlotIdx := -1;
  FElseValueSlotUsed := False;
  if AExpression <> '' then
    FCase.CaseExpression.Term := AExpression;
end;

destructor TFluentSQLCriteriaCase.Destroy;
begin
  FOwner := nil;
  FCase := nil;
  FLastExpression := nil;
  inherited;
end;

function TFluentSQLCriteriaCase.ElseIf(const AValue: String): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('ElseIf', 'ELSE');
  _AssertValueSlotFree('ElseIf', True);
  FLastExpression := TFluentSQLCriteriaExpression.Create(AValue, FOwner.Params);
  FCase.ElseExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.ElseIf(const AValue: int64): IFluentSQLCriteriaCase;
begin
  Result := ElseIf(IntToStr(AValue));
end;

/// <summary>
///   SLOT DE VALOR do ramo ELSE. Gemeo de IfThen(Variant, ...) - a doutrina toda
///   esta no comentario de _ValueSlotTerm e na declaracao em
///   FluentSQL.Interfaces.pas. A ordem aqui e a mesma e pela mesma razao: toda
///   recusa possivel acontece ANTES de _ValueSlotTerm, que e quem grava.
///
///   O FElseValueSlotUsed so vai a True DEPOIS da delegacao, e nao antes: a
///   sobrecarga de String para a qual delegamos tambem consulta
///   _AssertValueSlotFree, e marcar antes faria esta chamada recusar a si mesma.
/// </summary>
function TFluentSQLCriteriaCase.ElseIf(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('ElseIf', 'ELSE');
  _AssertValueSlotFree('ElseIf', True);
  _AssertValueCarriesData('ElseIf', AValue);
  Result := ElseIf(_ValueSlotTerm(AValue, ADataType));
  FElseValueSlotUsed := True;
end;

function TFluentSQLCriteriaCase.EndCase: IFluentSQL;
begin
  Result := FOwner;
end;

function TFluentSQLCriteriaCase._GetCase: IFluentSQLCase;
begin
  Result := FCase;
end;

/// <summary>
///   THEN e ELSE sao ramos de um WHEN: sem nenhum WHEN na lista, nem um nem
///   outro tem onde se prender e o que sai nao e CASE de dialeto nenhum.
///
///   Isto era um Assert (FluentSQL.Cases.pas:340 antes desta mudanca), o que
///   significa que a guarda existia so em build de debug. Com {$C-} - que e o
///   default de qualquer build de release - o Assert some e o IfThen cai direto
///   em WhenList[-1], ou seja EArgumentOutOfRangeException vinda de dentro da
///   TList, com pilha que nao aponta para a chamada que causou o erro. O
///   ElseIf nao tinha guarda nenhuma e emitia calado "CASE ELSE x END".
///
///   Medido, motor por motor, com o CASE sem WHEN (oraculo em
///   test.cases.guards.matrix.sql):
///     PostgreSQL 16.14   ERROR: syntax error at or near "ELSE"
///     SQL Server 2022    Msg 156 Incorrect syntax near the keyword 'ELSE'.
///     Oracle 26ai        ORA-00923: FROM keyword not found where expected
///
///   Zero motor aceita. Vale aqui a mesma regua ja aplicada em
///   TUtils._AssertSingleValue e em TFluentSQLMerge: entre emitir SQL que o
///   motor recusa e recusar a chamada na linha que a causou, recusa - e com a
///   chamada nomeada na mensagem.
/// </summary>
procedure TFluentSQLCriteriaCase._AssertHaveWhen(const AMethod, AKeyword: String);
begin
  if FCase.WhenList.Count > 0 then
    Exit;
  raise EArgumentException.CreateFmt(
    'IFluentSQLCriteriaCase.%s chamado antes de When: o CASE nao tem nenhum ' +
    'ramo WHEN, e %s so existe dentro de um. A forma que sairia ' +
    '("CASE %s <valor> END") nao e aceita por dialeto nenhum: PostgreSQL 16 ' +
    'responde "syntax error at or near", SQL Server 2022 "Msg 156 Incorrect ' +
    'syntax near", Oracle 26ai "ORA-00923". Chame When(...) antes de %s.',
    [AMethod, AKeyword, AKeyword, AMethod]);
end;

/// <summary>
///   O slot de valor do CASE nao decide a convencao de NULL, e por isso recusa
///   os dois Variants que NAO carregam dado.
///
///   Null (varNull) e Unassigned (varEmpty) sao coisas diferentes de nil - e nil
///   nem chega aqui: o compilador recusa a chamada antes de gerar codigo. O erro
///   do dcc32 36.0, MEDIDO e nao lembrado, e
///
///     E2250 There is no overloaded version of 'IfThen' that can be called
///           with these arguments
///
///   e NAO E2010: IfThen e sobrecarregado, entao a resolucao de sobrecarga
///   responde antes da compatibilidade de tipos. (O E2010 "Incompatible types:
///   'Variant' and 'Pointer'" sai da atribuicao direta V := nil, que e outro
///   experimento e nao esta chamada.) A decisao "nil levanta, nao vira NULL" e
///   portanto cumprida pelo SISTEMA DE TIPOS nesta sobrecarga, e nao por guarda
///   de runtime; nao existe guarda de nil aqui porque nao existe caminho de nil
///   ate aqui.
///
///   Restam Null e Unassigned. Os dois sao RECUSADOS, e a escolha e deliberada e
///   conservadora: emitir CAST(:pN AS <tipo>) com o parametro ligado em NULL e
///   SQL valido e util - "CASE WHEN c THEN NULL END" existe - mas transformar
///   Null em NULL do banco e decisao de CONVENCAO, e ela nao foi tomada aqui. A
///   assimetria decide: aceitar depois e ADITIVO, recusar depois seria BREAKING.
///   E a mesma regua ja escrita em TUtils._AssertValueSlotCarriesData, que recusa
///   os dois pelo mesmo motivo no slot de valor de SetValue/Values.
///
///   Unassigned tem ainda um agravante proprio: nao ha dado nenhum a ligar, e
///   o que o motor receberia dependeria de como o driver trata varEmpty.
/// </summary>
procedure TFluentSQLCriteriaCase._AssertValueCarriesData(const AMethod: String;
  const AValue: Variant);
const
  cCONVENCAO = ' Dar semantica de NULL a este slot e decisao de convencao, e ' +
               'ela nao foi tomada: se o ramo deve devolver NULL, use a ' +
               'sobrecarga de String com o termo que o seu dialeto espera.';
begin
  if VarIsNull(AValue) then
    raise EArgumentException.CreateFmt(
      'IFluentSQLCriteriaCase.%s recebeu Variant Null em posicao de VALOR: ' +
      'este slot liga um DADO como parametro e nao exprime NULL.' + cCONVENCAO,
      [AMethod]);
  if VarIsEmpty(AValue) then
    raise EArgumentException.CreateFmt(
      'IFluentSQLCriteriaCase.%s recebeu Variant Unassigned em posicao de ' +
      'VALOR: nao ha dado a ligar ao parametro.' + cCONVENCAO,
      [AMethod]);
end;

/// <summary>
///   O INVARIANTE DESTE ARQUIVO, e a razao de esta guarda existir:
///
///       nenhum caminho de recusa pode deixar parametro para tras,
///       e nenhum termo que carrega :pN pode ser SUBSTITUIDO.
///
///   A primeira metade e ordem de guardas. A segunda e esta guarda, e ela fecha
///   um vazamento que NAO envolve excecao nenhuma: quem chama IfThen duas vezes
///   no MESMO ramo sobrescreve o TEXTO, e o :pN da primeira chamada fica na
///   colecao sem nada no SQL que o referencie. Medido, antes desta guarda:
///
///     .When('1').IfThen('A',dftString).IfThen('B',dftString)
///        SQL: ... THEN CAST(:p2 AS VARCHAR(4000)) ...   colecao: p1=A, p2=B
///                                                       p1 ORFAO
///     .When('1').IfThen('A',dftString).ElseIf('B',...).ElseIf('C',...)
///        SQL: ... THEN CAST(:p1 ...) ELSE CAST(:p3 ...) colecao: p1,p2,p3
///                                                       p2 ORFAO
///     .When('1').IfThen('A',dftString).IfThen('''LITERAL''')
///        SQL: ... THEN 'LITERAL' ...                    colecao: p1=A
///                                                       p1 ORFAO, e o dado do
///                                                       usuario ficou na
///                                                       colecao FORA do SQL
///
///   Quem liga parametro por POSICAO - que e como todo driver Delphi liga - liga
///   errado a partir do primeiro buraco. E o pior dos tres casos e o terceiro,
///   porque nem sequer ha excecao para o chamador perceber.
///
///   POR QUE A GUARDA TAMBEM VALE NAS SOBRECARGAS ANTIGAS (String e Int64):
///   porque a substituicao que vaza pode vir DELAS - e o terceiro caso acima. E
///   isso NAO quebra codigo que existia: para o slot estar ocupado alguem tem de
///   ter chamado a sobrecarga de Variant, que nasceu aqui. Programa anterior a
///   esta entrega nao tem como alcancar esta recusa. Sobrescrever um ramo com
///   String depois de outra String continua permitido e continua nao vazando,
///   porque ali nao ha :pN envolvido.
///
///   O QUE LIBERA O SLOT: um When novo. Cada WHEN tem o seu proprio ramo THEN, e
///   por isso o registro e o INDICE do WHEN, e nao um Boolean. O ELSE e unico no
///   CASE, entao ali um Boolean basta.
/// </summary>
procedure TFluentSQLCriteriaCase._AssertValueSlotFree(const AMethod: String;
  const AIsElse: Boolean);
var
  LKeyword: String;
begin
  if AIsElse then
  begin
    if not FElseValueSlotUsed then
      Exit;
    LKeyword := 'ELSE';
  end
  else
  begin
    // As DUAS condicoes, e a primeira nao e redundante: sem nenhum When,
    // Count-1 e -1 e FThenValueSlotIdx tambem e -1, entao a comparacao sozinha
    // daria "ramo ocupado" para um CASE que nao tem ramo nenhum. O sintoma seria
    // esta guarda ROUBAR a recusa de _AssertHaveWhen e devolver a mensagem
    // errada - a que fala em substituicao, e nao a que manda chamar When. Achado
    // por mutacao: apagar _AssertHaveWhen de IfThen(Variant) nao deixava teste
    // vermelho justamente porque esta linha mascarava a falta.
    if (FThenValueSlotIdx < 0) or (FThenValueSlotIdx <> FCase.WhenList.Count - 1) then
      Exit;
    LKeyword := 'THEN';
  end;
  raise EArgumentException.CreateFmt(
    'IFluentSQLCriteriaCase.%s: o ramo %s ja foi preenchido por um slot de ' +
    'VALOR, e substituir o termo abandonaria o parametro dele na colecao - o ' +
    'SQL deixaria de citar um :pN que continua ligado, e quem liga por posicao ' +
    'passaria a ligar errado a partir dali. Chame %s UMA vez por ramo; para ' +
    'outro ramo, abra um When novo.',
    [AMethod, LKeyword, AMethod]);
end;

/// <summary>
///   O motor do slot de valor, compartilhado por IfThen e ElseIf - os dois ramos
///   do mesmo CASE nao podem divergir de forma, e uma funcao so garante isso.
///
///   O que sai daqui e CAST(:pN AS <tipo do dialeto>), NAO :pN nu, e nos SETE
///   dialetos, nao so onde o motor exige. Duas razoes, nesta ordem:
///
///   1. PARAMETRO NU NAO PASSA DO PREPARE EM DOIS DOS SETE. Medido, transcricao
///      literal em Test Delphi\Common_tests\test.cases.bind.matrix.sql:
///        Firebird 5.0.4    -804 / HY004  "Data type unknown"
///        DB2 v12.1.5.0     SQL0418N / 42610  "untyped parameter marker"
///      E nao e do CASE: isolado, "SELECT :a FROM RDB$DATABASE" da o mesmo -804.
///      E o marcador SEM TIPO. Com CAST os dois passam do prepare (caso E5 do
///      mesmo arquivo).
///
///   2. EMITIR CAST SO ONDE O MOTOR EXIGE criaria uma tabela de "quem precisa de
///      tipo" para manter, e ela seria fragil pelo mesmo motivo que a matriz de
///      CAST da T17 e: a resposta muda por versao de motor. Como esta e uma
///      sobrecarga NOVA, nao ha SQL emitido hoje por ela e portanto nao ha
///      oraculo a quebrar - uniformizar aqui e de graca. (E o oposto do que
///      valeu para o apelido de tabela do Oracle, onde emitir a forma nova nos
///      sete teria trocado o texto de seis dialetos que ja funcionavam.)
///
///   A LARGURA do VARCHAR nao e decidida aqui: ALength fica no default 0 e cada
///   driver resolve (Firebird/Oracle/MSSQL preenchem com
///   cFluentSQLCastDefaultLength; DB2, MySQL e PostgreSQL emitem SEM largura, o
///   que no DB2 foi medido como a escolha certa - impor 4000 criaria um teto que
///   o motor nao tem). Nao ha sobrecarga com largura neste slot: acrescentar uma
///   depois e aditivo.
///
///   NADA AQUI GRAVA PARAMETRO ANTES DE TODA RECUSA POSSIVEL TER SIDO FEITA. E o
///   Cast recusa por DOIS motivos independentes:
///
///   CAUSA A - o TIPO esta fora da intersecao portavel. Vale igual nos nove
///     dialetos, e quem responde e a porta unica da T17
///     (TFluentSQLFunctionAbstract._AssertCastTypeIsPortable).
///
///   CAUSA B - o tipo esta na intersecao mas ESTE DIALETO nao tem grafia para
///     ele. Hoje vale para o InterBase (matriz de CAST nao medida, e nao inferida
///     do Firebird de proposito) e para o driver nao relacional.
///
///   As duas nascem DENTRO do Cast, ou seja DEPOIS de ele ser chamado, e a causa
///   B foi vazamento real desta entrega ate esta versao: o Params.Add corria
///   antes e a excecao vinha depois, deixando p1 na colecao com o dado do usuario
///   e nenhum SQL que o citasse. Medido: InterBase e o driver nao relacional
///   devolviam Params.Count = 1.
///
///   A SONDA fecha as DUAS com uma linha so. Ela chama o MESMO Cast com uma
///   expressao descartavel, antes de a colecao crescer, e por isso reproduz
///   QUALQUER recusa que a chamada real fosse produzir - inclusive a de tipo,
///   porque TFluentSQLFunctions.Cast roda _AssertCastTypeIsPortable como PRIMEIRA
///   linha e so entao despacha ao driver.
///
///   NAO HA, PORTANTO, CHAMADA EXPLICITA A _AssertCastTypeIsPortable AQUI, e a
///   ausencia e medida, nao esquecimento: com a sonda no lugar, uma chamada
///   explicita nao deixa NENHUM teste vermelho quando movida para depois do
///   Params.Add - ou seja, seria linha morta. Como efeito colateral bom, a
///   politica da T17 continua exatamente onde a T17 a pos, sem precisar alargar
///   a visibilidade de nada.
///
///   A sonda so e equivalente a chamada real porque a recusa do Cast depende de
///   (dialeto, tipo) e NAO da expressao - conferido lendo os nove drivers em
///   Source\Drivers: em todos, AExpression so aparece na concatenacao final do
///   Result, nunca numa condicao. Se um driver futuro passar a recusar por
///   expressao, a sonda deixa de valer - e ha teste que compara a recusa da sonda
///   com a da chamada real, exatamente para nao deixar isso passar calado.
///
///   O custo e uma concatenacao de string descartada por chamada de slot, em
///   funcao pura. O que ele compra e o invariante inteiro.
/// </summary>
function TFluentSQLCriteriaCase._ValueSlotTerm(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): String;
const
  /// Expressao descartavel da sonda. Nunca chega a SQL nenhum: o Result da sonda
  /// e jogado fora. O nome existe para nao parecer placeholder de verdade.
  cSONDA = 'SONDA';
var
  LPlaceholder: String;
begin
  FOwner.AsFun.Cast(cSONDA, ADataType);   // pre-voo: provoca as causas A e B
  LPlaceholder := FOwner.Params.Add(AValue, ADataType);
  Result := FOwner.AsFun.Cast(LPlaceholder, ADataType);
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: String): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(AExpression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FOwner.Params));
  Result := Self;
end;

function TFluentSQLCriteriaCase.IfThen(const AValue: int64): IFluentSQLCriteriaCase;
begin
  Result := IfThen(IntToStr(AValue));
end;

/// <summary>
///   SLOT DE VALOR do ramo THEN. As sobrecargas de String e de Int64 logo acima
///   sao slot de EXPRESSAO: o argumento vira termo SQL verbatim (a de Int64
///   passa por IntToStr e cai na de String). Esta aqui e a unica em que o dado
///   NAO entra no texto.
///
///   A ordem NAO e estilo. Toda recusa possivel corre ANTES de _ValueSlotTerm,
///   que e o unico ponto que grava:
///     1. _AssertHaveWhen ....... estrutural, ja existente, a mesma das outras
///        sobrecargas. Vem antes de qualquer efeito colateral.
///     2. _AssertValueSlotFree .. este ramo ja tem um :pN preso a ele?
///     3. _AssertValueCarriesData o Variant carrega dado?
///     4. _ValueSlotTerm ........ recusa por tipo, recusa por dialeto (sonda), e
///        so ENTAO Params.Add.
///   Mover qualquer uma para depois da 4 deixa :pN orfao na colecao quando a
///   chamada e recusada - e a mesma regra que TUtils._AssertSingleValue ja aplica
///   ao slot de valor de SetValue/Values. Ha teste para cada uma das portas, e
///   cada teste assere Params.Count = 0.
///
///   O FThenValueSlotIdx so e marcado DEPOIS da delegacao: a sobrecarga de String
///   para a qual delegamos tambem consulta _AssertValueSlotFree, e marcar antes
///   faria esta chamada recusar a si mesma.
/// </summary>
function TFluentSQLCriteriaCase.IfThen(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('IfThen', 'THEN');
  _AssertValueSlotFree('IfThen', False);
  _AssertValueCarriesData('IfThen', AValue);
  Result := IfThen(_ValueSlotTerm(AValue, ADataType));
  FThenValueSlotIdx := FCase.WhenList.Count - 1;
end;

function TFluentSQLCriteriaCase.When(const ACondition: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
var
  LWhenThen: IFluentSQLCaseWhenThen;
begin
  FLastExpression := ACondition;
  LWhenThen := FCase.WhenList.Add;
  LWhenThen.WhenExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.IfThen(const AValue: String): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('IfThen', 'THEN');
  _AssertValueSlotFree('IfThen', False);
  FLastExpression := TFluentSQLCriteriaExpression.Create(AValue, FOwner.Params);
  FCase.WhenList[FCase.WhenList.Count-1].ThenExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.When(const ACondition: array of const): IFluentSQLCriteriaCase;
begin
  Result := When(TUtils.SqlArrayOfConstToParameterizedSql(ACondition, FOwner.Params));
end;

function TFluentSQLCriteriaCase.When(const ACondition: String): IFluentSQLCriteriaCase;
begin
  Result := When(TFluentSQLCriteriaExpression.Create(ACondition, FOwner.Params));
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(AExpression.Expression);
  Result := Self;
end;

end.






