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

unit FluentSQL.Update;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Namevalue,
  FluentSQL.Interfaces;

type
  TFluentSQLUpdate = class(TFluentSQLSection, IFluentSQLUpdate)
  strict private
    FTableName: String;
    FValues: IFluentSQLNameValuePairs;
    function _SerializeNameValuePairsForUpdate(const APairs: IFluentSQLNameValuePairs): String;
    function  _GetTableName: String;
    procedure _SetTableName(const value: String);
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Values: IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLUpdate }

procedure TFluentSQLUpdate.Clear;
begin
  FTableName := '';
  FValues.Clear;
end;

constructor TFluentSQLUpdate.Create;
begin
  inherited Create('Update');
  FValues := TFluentSQLNameValuePairs.Create;
end;

function TFluentSQLUpdate._GetTableName: String;
begin
  Result := FTableName;
end;

function TFluentSQLUpdate.IsEmpty: Boolean;
begin
  Result := (TableName = '');
end;

function TFluentSQLUpdate.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['UPDATE', FTableName, 'SET',
      _SerializeNameValuePairsForUpdate(FValues)]);
end;

function TFluentSQLUpdate._SerializeNameValuePairsForUpdate(const APairs: IFluentSQLNameValuePairs): String;
var
  LFor: Integer;
begin
  Result := '';
  for LFor := 0 to APairs.Count -1 do
    Result := TUtils.Concat([Result, TUtils.Concat([APairs[LFor].Name, '=', APairs[LFor].Value])], ', ');
end;

procedure TFluentSQLUpdate._SetTableName(const value: String);
begin
  FTableName := Value;
end;

function TFluentSQLUpdate.Values: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

end.




