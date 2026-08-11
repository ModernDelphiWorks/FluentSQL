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
    function _GetCase: IFluentSQLCase;
    procedure _AssertHaveWhen(const AMethod, AKeyword: String);
    procedure _AssertValueCarriesData(const AMethod: String; const AValue: Variant);
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
  FluentSQL.Utils,
  FluentSQL.FunctionsAbstract;

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
///   FluentSQL.Interfaces.pas. A ordem aqui e a mesma e pela mesma razao: a
///   guarda estrutural PRIMEIRO, porque _ValueSlotTerm grava parametro.
/// </summary>
function TFluentSQLCriteriaCase.ElseIf(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('ElseIf', 'ELSE');
  _AssertValueCarriesData('ElseIf', AValue);
  Result := ElseIf(_ValueSlotTerm(AValue, ADataType));
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
///   nem chega aqui: 'Variant' e 'Pointer' sao tipos incompativeis e o compilador
///   recusa a chamada com E2010 antes de gerar codigo (medido). A decisao "nil
///   levanta, nao vira NULL" e portanto cumprida pelo SISTEMA DE TIPOS nesta
///   sobrecarga, e nao por guarda de runtime; nao existe guarda de nil aqui
///   porque nao existe caminho de nil ate aqui.
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
///   A GUARDA DE TIPO vem ANTES do Params.Add, e ela e a MESMA da T17 -
///   TFluentSQLFunctionAbstract._AssertCastTypeIsPortable, a porta unica. Sim, o
///   Cast logo abaixo tambem a chama; a chamada explicita aqui existe so pela
///   ORDEM: sem ela, um ADataType fora da intersecao seria recusado depois de o
///   :pN ja estar gravado, e a numeracao dos parametros ficaria com um buraco.
/// </summary>
function TFluentSQLCriteriaCase._ValueSlotTerm(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): String;
var
  LPlaceholder: String;
begin
  TFluentSQLFunctionAbstract._AssertCastTypeIsPortable(ADataType);
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
///   A ordem das tres linhas nao e estilo:
///     1. _AssertHaveWhen ... guarda ESTRUTURAL, ja existente, e a mesma das
///        outras sobrecargas. Vem antes de qualquer efeito colateral.
///     2. _AssertValueCarriesData ... o Variant carrega dado?
///     3. _ValueSlotTerm ... so entao GRAVA o parametro e monta o CAST.
///   Inverter 1/2 com 3 deixaria :pN orfao na colecao quando a chamada e
///   recusada - e a mesma regra que TUtils._AssertSingleValue ja aplica ao slot
///   de valor de SetValue/Values.
/// </summary>
function TFluentSQLCriteriaCase.IfThen(const AValue: Variant;
  const ADataType: TFluentSQLDataFieldType): IFluentSQLCriteriaCase;
begin
  _AssertHaveWhen('IfThen', 'THEN');
  _AssertValueCarriesData('IfThen', AValue);
  Result := IfThen(_ValueSlotTerm(AValue, ADataType));
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






