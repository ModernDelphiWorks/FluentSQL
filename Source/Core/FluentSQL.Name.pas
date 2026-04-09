{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

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

type
  TFluentSQLName = class(TInterfacedObject, IFluentSQLName)
  strict private
    FAlias: String;
    FCase: IFluentSQLCase;
    FName: String;
    function _GetAlias: String;
    function _GetCase: IFluentSQLCase;
    function _GetName: String;
    procedure _SetAlias(const Value: String);
    procedure _SetCase(const Value: IFluentSQLCase);
    procedure _SetName(const Value: String);
  public
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Name: String read _GetName write _SetName;
    property Alias: String read _GetAlias write _SetAlias;
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

procedure TFluentSQLName.Clear;
begin
  FName := '';
  FAlias := '';
end;

function TFluentSQLName._GetAlias: String;
begin
  Result := FAlias;
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

function TFluentSQLName.Serialize: String;
begin
  if Assigned(FCase) then
    Result := '(' + FCase.Serialize + ')'
  else
    Result := FName;
  if FAlias <> '' then
    Result := TUtils.Concat([Result, 'AS', FAlias]);
end;

procedure TFluentSQLName._SetAlias(const Value: String);
begin
  FAlias := Value;
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




