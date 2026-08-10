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

unit FluentSQL.Name;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

const
  /// <summary>
  ///   Forma do apelido de COLUNA (c_alias), aceita pelos sete dialetos
  ///   relacionais - inclusive a Oracle, onde a doc do SELECT diz textualmente
  ///   "The AS keyword is optional". E o valor inicial de todo TFluentSQLName;
  ///   so quem representa uma RELACAO recebe outro, vindo do dialeto.
  /// </summary>
  cCOLUMN_ALIAS_KEYWORD = 'AS';

type
  TFluentSQLName = class(TInterfacedObject, IFluentSQLName)
  strict private
    FAlias: String;
    FAliasKeyword: String;
    FCase: IFluentSQLCase;
    FName: String;
    function _GetAlias: String;
    function _GetAliasKeyword: String;
    function _GetCase: IFluentSQLCase;
    function _GetName: String;
    procedure _SetAlias(const Value: String);
    procedure _SetAliasKeyword(const Value: String);
    procedure _SetCase(const Value: IFluentSQLCase);
    procedure _SetName(const Value: String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Name: String read _GetName write _SetName;
    property Alias: String read _GetAlias write _SetAlias;
    property AliasKeyword: String read _GetAliasKeyword write _SetAliasKeyword;
    property CaseExpr: IFluentSQLCase read _GetCase write _SetCase;
  end;

  TFluentSQLNames = class(TInterfacedObject, IFluentSQLNames)
  private
    FColumns: TList<IFluentSQLName>;
    function SerializeName(const AName: IFluentSQLName): String;
    function SerializeDirection(ADirection: TOrderByDirection): String;
  protected
    function GetColumns(AIdx: Integer): IFluentSQLName;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLName; overload; virtual;
    procedure Add(const Value: IFluentSQLName); overload; virtual;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Columns[AIdx: Integer]: IFluentSQLName read GetColumns; default;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLName }

/// <summary>
///   Nasce com a forma do apelido de COLUNA. Quem monta uma RELACAO
///   (FluentSQL.pas, em From e em _CreateJoin) sobrescreve AliasKeyword com o
///   que o serializador do dialeto mandar, ANTES de serializar.
/// </summary>
constructor TFluentSQLName.Create;
begin
  inherited Create;
  FAliasKeyword := cCOLUMN_ALIAS_KEYWORD;
end;

/// <summary>
///   Zera o CONTEUDO do nome, nao a politica de serializacao: AliasKeyword
///   sobrevive de proposito. Ela descreve o papel do no (coluna ou relacao) e o
///   dialeto que o serializa - nem uma coisa nem outra muda porque o texto foi
///   apagado.
/// </summary>
procedure TFluentSQLName.Clear;
begin
  FName := '';
  FAlias := '';
end;

function TFluentSQLName._GetAlias: String;
begin
  Result := FAlias;
end;

function TFluentSQLName._GetAliasKeyword: String;
begin
  Result := FAliasKeyword;
end;

function TFluentSQLName._GetCase: IFluentSQLCase;
begin
  Result := FCase;
end;

function TFluentSQLName._GetName: String;
begin
  Result := FName;
end;

destructor TFluentSQLName.Destroy;
begin
  FCase := nil;
  inherited;
end;

function TFluentSQLName.IsEmpty: Boolean;
begin
  Result := (FName = '') and (FAlias = '');
end;

/// <summary>
///   A palavra que precede o apelido vem de FAliasKeyword, nao de um literal.
///   Antes desta tarefa a linha era Concat([Result, 'AS', FAlias]) - o nucleo
///   escolhia 'AS' para TODO apelido, de coluna e de tabela, sem consultar
///   dialeto nenhum. Isso emitia "FROM T AS AP" e "LEFT JOIN B AS X" tambem para
///   a Oracle, que recusa as duas formas (ORA-03048 e ORA-02000, medidos em
///   Oracle Free 23.26.2.0.0; ver Test Delphi\Common_tests\test.alias.oracle.sql).
///
///   TUtils.Concat descarta membro vazio, entao keyword vazia produz
///   "B X" com um espaco so - nao "B  X".
/// </summary>
function TFluentSQLName.Serialize: String;
begin
  if Assigned(FCase) then
    Result := '(' + FCase.Serialize + ')'
  else
    Result := FName;
  if FAlias <> '' then
    Result := TUtils.Concat([Result, FAliasKeyword, FAlias]);
end;

procedure TFluentSQLName._SetAlias(const Value: String);
begin
  FAlias := Value;
end;

procedure TFluentSQLName._SetAliasKeyword(const Value: String);
begin
  FAliasKeyword := Value;
end;

procedure TFluentSQLName._SetCase(const Value: IFluentSQLCase);
begin
  FCase := Value;
end;

procedure TFluentSQLName._SetName(const Value: String);
begin
  FName := Value;
end;

{ TFluentSQLNames }

function TFluentSQLNames.Add: IFluentSQLName;
begin
  Result := TFluentSQLName.Create;
  Add(Result);
end;

procedure TFluentSQLNames.Add(const Value: IFluentSQLName);
begin
  FColumns.Add(Value);
end;

procedure TFluentSQLNames.Clear;
begin
  FColumns.Clear;
end;

function TFluentSQLNames.Count: Integer;
begin
  Result := FColumns.Count;
end;

constructor TFluentSQLNames.Create;
begin
  FColumns := TList<IFluentSQLName>.Create;
end;

destructor TFluentSQLNames.Destroy;
begin
  FColumns.Free;
  inherited;
end;

function TFluentSQLNames.GetColumns(AIdx: Integer): IFluentSQLName;
begin
  Result := FColumns[AIdx];
end;

function TFluentSQLNames.IsEmpty: Boolean;
begin
  Result := (Count = 0);
end;

function TFluentSQLNames.Serialize: String;
var
  LFor: Integer;
  LOrderByCol: IFluentSQLOrderByColumn;
begin
  Result := '';
  for LFor := 0 to FColumns.Count -1 do
  begin
    Result := TUtils.Concat([Result, SerializeName(FColumns[LFor])], ', ');
    if Supports(FColumns[LFor], IFluentSQLOrderByColumn, LOrderByCol) then
      Result := TUtils.Concat([Result, SerializeDirection(LOrderByCol.Direction)]);
  end;
end;

function TFluentSQLNames.SerializeDirection(ADirection: TOrderByDirection): String;
begin
  case ADirection of
    dirAscending:  Result := 'ASC';
    dirDescending: Result := 'DESC';
  else
    raise Exception.Create('TFluentSQLNames.SerializeDirection: Unknown direction');
  end;
end;

function TFluentSQLNames.SerializeName(const AName: IFluentSQLName): String;
begin
  Result := AName.Serialize;
end;

end.




