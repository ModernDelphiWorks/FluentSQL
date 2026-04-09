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
  SysUtils,
  Generics.Collections,
  FluentSQL.Section,
  FluentSQL.Name,
  FluentSQL.Namevalue,
  FluentSQL.Interfaces;

type
  EFluentSQLInsertBatch = class(Exception);

  TFluentSQLInsert = class(TFluentSQLSection, IFluentSQLInsert)
  strict private
    FColumns: IFluentSQLNames;
    FTableName: String;
    FValues: IFluentSQLNameValuePairs;
    FRows: TList<IFluentSQLNameValuePairs>;
    function _ClonePairs(const ASource: IFluentSQLNameValuePairs): IFluentSQLNameValuePairs;
    procedure _BuildExpectedColumns(out AColumns: TArray<String>);
    procedure _AssertRowMatchesColumns(const AColumns: TArray<String>; const ARow: IFluentSQLNameValuePairs);
    function _TupleForRow(const ARow: IFluentSQLNameValuePairs; const AColumns: TArray<String>): String;
    function _JoinColumnListFromNames(const AColumns: TArray<String>): String;
    function _SerializeNameValuePairsForInsert(const APairs: IFluentSQLNameValuePairs): String;
    function _GetTableName: String;
    procedure _SetTableName(const Value: String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    function Columns: IFluentSQLNames;
    function AddRow: IFluentSQLInsert;
    function SerializedRowCount: Integer;
    function SerializedRow(AIndex: Integer): IFluentSQLNameValuePairs;
    function IsEmpty: Boolean; override;
    function Values: IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

implementation

uses
  FluentSQL.Utils;

function ValueForColumn(const ARow: IFluentSQLNameValuePairs; const ACol: String): String;
var
  LFor: Integer;
begin
  for LFor := 0 to ARow.Count - 1 do
    if SameText(ARow[LFor].Name, ACol) then
      Exit(ARow[LFor].Value);
  raise EFluentSQLInsertBatch.CreateFmt('FluentSQL.Insert: missing value for column "%s"', [ACol]);
end;

{ TFluentSQLInsert }

function TFluentSQLInsert.AddRow: IFluentSQLInsert;
begin
  if FValues.IsEmpty then
    raise EFluentSQLInsertBatch.Create('FluentSQL.Insert: AddRow requires a non-empty current row');
  FRows.Add(_ClonePairs(FValues));
  FValues.Clear;
  Result := Self;
end;

procedure TFluentSQLInsert._AssertRowMatchesColumns(const AColumns: TArray<String>;
  const ARow: IFluentSQLNameValuePairs);
var
  i: Integer;
begin
  if ARow.Count <> Length(AColumns) then
    raise EFluentSQLInsertBatch.Create('FluentSQL.Insert: inconsistent column count between rows');
  for i := 0 to High(AColumns) do
    ValueForColumn(ARow, AColumns[i]);
end;

procedure TFluentSQLInsert._BuildExpectedColumns(out AColumns: TArray<String>);
var
  LFor: Integer;
  LFirst: IFluentSQLNameValuePairs;
begin
  if FColumns.Count > 0 then
  begin
    SetLength(AColumns, FColumns.Count);
    for LFor := 0 to FColumns.Count - 1 do
      AColumns[LFor] := FColumns[LFor].Name;
  end
  else
  begin
    LFirst := SerializedRow(0);
    SetLength(AColumns, LFirst.Count);
    for LFor := 0 to LFirst.Count - 1 do
      AColumns[LFor] := LFirst[LFor].Name;
  end;
end;

function TFluentSQLInsert._ClonePairs(const ASource: IFluentSQLNameValuePairs): IFluentSQLNameValuePairs;
var
  LFor: Integer;
  LDest: IFluentSQLNameValue;
begin
  Result := TFluentSQLNameValuePairs.Create;
  for LFor := 0 to ASource.Count - 1 do
  begin
    LDest := Result.Add;
    LDest.Name := ASource[LFor].Name;
    LDest.Value := ASource[LFor].Value;
  end;
end;

procedure TFluentSQLInsert.Clear;
begin
  FTableName := '';
  FColumns.Clear;
  FValues.Clear;
  FRows.Clear;
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
  FRows := TList<IFluentSQLNameValuePairs>.Create;
end;

destructor TFluentSQLInsert.Destroy;
begin
  FRows.Free;
  inherited;
end;

function TFluentSQLInsert._GetTableName: String;
begin
  Result := FTableName;
end;

function TFluentSQLInsert._JoinColumnListFromNames(const AColumns: TArray<String>): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(AColumns) do
  begin
    if i > 0 then
      Result := Result + ', ';
    Result := Result + AColumns[i];
  end;
end;

function TFluentSQLInsert.IsEmpty: Boolean;
begin
  Result := (TableName = '');
end;

function TFluentSQLInsert.SerializedRow(AIndex: Integer): IFluentSQLNameValuePairs;
begin
  if (AIndex < 0) or (AIndex >= SerializedRowCount) then
    raise EFluentSQLInsertBatch.Create('FluentSQL.Insert: serialized row index out of range');
  if AIndex < FRows.Count then
    Result := FRows[AIndex]
  else
    Result := FValues;
end;

function TFluentSQLInsert.SerializedRowCount: Integer;
begin
  Result := FRows.Count;
  if not FValues.IsEmpty then
    Inc(Result);
end;

function TFluentSQLInsert.Serialize: String;
var
  LCnt: Integer;
  LFor: Integer;
  LCols: TArray<String>;
  LColPart: String;
  LValuesPart: String;
begin
  if IsEmpty then
    Exit('');

  Result := TUtils.Concat(['INSERT INTO', FTableName]);
  LCnt := SerializedRowCount;

  if LCnt = 0 then
  begin
    if FColumns.Count > 0 then
      Result := TUtils.Concat([Result, '(', Columns.Serialize, ')'])
    else
      Result := TUtils.Concat([Result, _SerializeNameValuePairsForInsert(FValues)]);
    Exit;
  end;

  _BuildExpectedColumns(LCols);
  for LFor := 0 to LCnt - 1 do
    _AssertRowMatchesColumns(LCols, SerializedRow(LFor));

  if FColumns.Count > 0 then
    LColPart := '(' + Columns.Serialize + ')'
  else
    LColPart := '(' + _JoinColumnListFromNames(LCols) + ')';

  LValuesPart := '';
  for LFor := 0 to LCnt - 1 do
  begin
    if LFor > 0 then
      LValuesPart := LValuesPart + ', ';
    LValuesPart := LValuesPart + _TupleForRow(SerializedRow(LFor), LCols);
  end;

  Result := TUtils.Concat([Result, LColPart, 'VALUES', LValuesPart]);
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

function TFluentSQLInsert._TupleForRow(const ARow: IFluentSQLNameValuePairs;
  const AColumns: TArray<String>): String;
var
  LFor: Integer;
  LValues: String;
begin
  LValues := '';
  for LFor := 0 to High(AColumns) do
  begin
    if LFor > 0 then
      LValues := LValues + ', ';
    LValues := LValues + ValueForColumn(ARow, AColumns[LFor]);
  end;
  Result := '(' + LValues + ')';
end;

function TFluentSQLInsert.Values: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

end.
