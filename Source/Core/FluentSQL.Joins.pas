{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.Joins;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Expression,
  FluentSQL.Utils,
  FluentSQL.Section,
  FluentSQL.Name,
  FluentSQL.Interfaces;

type
  TFluentSQLJoin = class(TFluentSQLSection, IFluentSQLJoin)
  strict private
    FCondition: IFluentSQLExpression;
    FJoinedTable: IFluentSQLName;
    FJoinType: TJoinType;
    function _GetCondition: IFluentSQLExpression;
    function _GetJoinedTable: IFluentSQLName;
    function _GetJoinType: TJoinType;
    procedure _SetCondition(const Value: IFluentSQLExpression);
    procedure _SetJoinedTable(const Value: IFluentSQLName);
    procedure _SetJoinType(const Value: TJoinType);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    property Condition: IFluentSQLExpression read _GetCondition write _SetCondition;
    property JoinedTable: IFluentSQLName read _GetJoinedTable write _SetJoinedTable;
    property JoinType: TJoinType read _GetJoinType write _SetJoinType;
  end;

  TFluentSQLJoins = class(TInterfacedObject, IFluentSQLJoins)
  strict private
    FJoins: TList<IFluentSQLJoin>;
    function SerializeJoinType(const AJoin: IFluentSQLJoin): String;
    function _GetJoins(AIdx: Integer): IFluentSQLJoin;
    procedure _SetJoins(AIdx: Integer; const Value: IFluentSQLJoin);
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLJoin; overload;
    procedure Add(const AJoin: IFluentSQLJoin); overload;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Joins[AIdx: Integer]: IFluentSQLJoin read _GetJoins write _SetJoins; default;
  end;

implementation

{ TFluentSQLJoin }

procedure TFluentSQLJoin.Clear;
begin
  FCondition.Clear;
  FJoinedTable.Clear;
end;

constructor TFluentSQLJoin.Create;
begin
  inherited Create('Join');
  FJoinedTable := TFluentSQLName.Create;
  FCondition := TFluentSQLExpression.Create;
end;

destructor TFluentSQLJoin.Destroy;
begin
  FCondition := nil;
  FJoinedTable := nil;
  inherited;
end;

function TFluentSQLJoin._GetCondition: IFluentSQLExpression;
begin
  Result := FCondition;
end;

function TFluentSQLJoin._GetJoinedTable: IFluentSQLName;
begin
  Result := FJoinedTable;
end;

function TFluentSQLJoin._GetJoinType: TJoinType;
begin
  Result := FJoinType;
end;

function TFluentSQLJoin.IsEmpty: Boolean;
begin
  Result := (FCondition.IsEmpty and FJoinedTable.IsEmpty);
end;

procedure TFluentSQLJoin._SetCondition(const Value: IFluentSQLExpression);
begin
  FCondition := Value;
end;

procedure TFluentSQLJoin._SetJoinedTable(const Value: IFluentSQLName);
begin
  FJoinedTable := Value;
end;

procedure TFluentSQLJoin._SetJoinType(const Value: TJoinType);
begin
  FJoinType := Value;
end;

{ TFluentSQLJoins }

procedure TFluentSQLJoins.Add(const AJoin: IFluentSQLJoin);
begin
  FJoins.Add(AJoin);
end;

function TFluentSQLJoins.Add: IFluentSQLJoin;
begin
  Result := TFluentSQLJoin.Create;
  Add(Result);
end;

procedure TFluentSQLJoins.Clear;
begin
  FJoins.Clear;
end;

function TFluentSQLJoins.Count: Integer;
begin
  Result := FJoins.Count;
end;

constructor TFluentSQLJoins.Create;
begin
  inherited Create;
  FJoins := TList<IFluentSQLJoin>.Create;
end;

destructor TFluentSQLJoins.Destroy;
begin
  FJoins.Free;
  inherited;
end;

function TFluentSQLJoins._GetJoins(AIdx: Integer): IFluentSQLJoin;
begin
  Result := FJoins[AIdx];
end;

function TFluentSQLJoins.IsEmpty: Boolean;
begin
  Result := (FJoins.Count = 0);
end;

function TFluentSQLJoins.Serialize: String;
var
  LFor: Integer;
  LJoin: IFluentSQLJoin;
begin
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    LJoin := FJoins[LFor];
    Result := TUtils.Concat([Result,
                             SerializeJoinType(LJoin),
                             'JOIN',
                             LJoin.JoinedTable.Serialize,
                             'ON',
                             LJoin.Condition.Serialize]);
  end;
end;

function TFluentSQLJoins.SerializeJoinType(const AJoin: IFluentSQLJoin): String;
begin
  case AJoin.JoinType of
    jtINNER: Result := 'INNER';
    jtLEFT:  Result := 'LEFT';
    jtRIGHT: Result := 'RIGHT';
    jtFULL:  Result := 'FULL';
  else
    raise Exception.Create('Error Message');
  end;
end;

procedure TFluentSQLJoins._SetJoins(AIdx: Integer; const Value: IFluentSQLJoin);
begin
  FJoins[AIdx] := Value;
end;

end.





