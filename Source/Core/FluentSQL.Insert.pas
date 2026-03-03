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

unit FluentSQL.Insert;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Name,
  FluentSQL.Namevalue,
  FluentSQL.Interfaces;

type
  TFluentSQLInsert = class(TFluentSQLSection, IFluentSQLInsert)
  strict private
    FColumns: IFluentSQLNames;
    FTableName: String;
    FValues: IFluentSQLNameValuePairs;
    function _SerializeNameValuePairsForInsert(const APairs: IFluentSQLNameValuePairs): String;
    function _GetTableName: String;
    procedure _SetTableName(const Value: String);
  public
    constructor Create;
    procedure Clear; override;
    function Columns: IFluentSQLNames;
    function IsEmpty: Boolean; override;
    function Values: IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLInsert }

procedure TFluentSQLInsert.Clear;
begin
  FTableName := '';
  FColumns.Clear;
  FValues.Clear;
end;

function TFluentSQLInsert.Columns: IFluentSQLNames;
begin
  Result := FColumns;
end;

constructor TFluentSQLInsert.Create;
begin
  inherited Create('Insert');
  FColumns := TFluentSQLNames.Create;
  FValues := TFluentSQLNameValuePairs.Create;
end;

function TFluentSQLInsert._GetTableName: String;
begin
  Result := FTableName;
end;

function TFluentSQLInsert.IsEmpty: Boolean;
begin
  Result := (TableName = '');
end;

function TFluentSQLInsert.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
  begin
    Result := TUtils.Concat(['INSERT INTO', FTableName]);
    if FColumns.Count > 0 then
      Result := TUtils.Concat([Result, '(', Columns.Serialize, ')'])
    else
      Result := TUtils.Concat([Result, _SerializeNameValuePairsForInsert(FValues)]);
  end;
end;

function TFluentSQLInsert._SerializeNameValuePairsForInsert(const APairs: IFluentSQLNameValuePairs): String;
var
  LFor: integer;
  LColumns: String;
  LValues: String;
begin
  Result := '';
  if APairs.Count = 0 then
    Exit;

  LColumns := '';
  LValues := '';
  for LFor := 0 to APairs.Count - 1 do
  begin
    LColumns := TUtils.Concat([LColumns, APairs[LFor].Name] , ', ');
    LValues  := TUtils.Concat([LValues , APairs[LFor].Value], ', ');
  end;
  Result := TUtils.Concat(['(', LColumns, ') VALUES (', LValues, ')'],'');
end;

procedure TFluentSQLInsert._SetTableName(const Value: String);
begin
  FTableName := Value;
end;

function TFluentSQLInsert.Values: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

end.





