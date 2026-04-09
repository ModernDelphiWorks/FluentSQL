{
  ------------------------------------------------------------------------------
  FluentSQL
  ESP-017: CREATE TABLE string generation per dialect (no execution).

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces;

function DDLCreateTableSQL(const ADef: IFluentDDLTableDef): string;
function DDLDropTableSQL(const ADef: IFluentDDLDropTableDef): string;

implementation

function MapLogicalTypeFirebird(const ACol: IFluentDDLColumn): string;
begin
  case ACol.LogicalType of
    dltInteger:
      Result := 'INTEGER';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(ACol.TypeArg) + ')';
    dltBoolean:
      Result := 'BOOLEAN';
    dltDate:
      Result := 'DATE';
    dltDateTime:
      Result := 'TIMESTAMP';
    dltLongText:
      Result := 'BLOB SUB_TYPE 1';
    dltBlob:
      Result := 'BLOB SUB_TYPE 0';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function MapLogicalTypePostgreSQL(const ACol: IFluentDDLColumn): string;
begin
  case ACol.LogicalType of
    dltInteger:
      Result := 'INTEGER';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(ACol.TypeArg) + ')';
    dltBoolean:
      Result := 'BOOLEAN';
    dltDate:
      Result := 'DATE';
    dltDateTime:
      Result := 'TIMESTAMP';
    dltLongText:
      Result := 'TEXT';
    dltBlob:
      Result := 'BYTEA';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function MapLogicalType(const ADialect: TFluentSQLDriver; const ACol: IFluentDDLColumn): string;
begin
  case ADialect of
    dbnFirebird:
      Result := MapLogicalTypeFirebird(ACol);
    dbnPostgreSQL:
      Result := MapLogicalTypePostgreSQL(ACol);
  else
    raise ENotSupportedException.CreateFmt(
      'DDL CREATE TABLE (ESP-017) is not implemented for dialect %d in this build',
      [Ord(ADialect)]);
  end;
end;

function DDLCreateTableSQL(const ADef: IFluentDDLTableDef): string;
var
  I: Integer;
  LParts: string;
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  LParts := '';
  for I := 0 to ADef.GetColumnCount - 1 do
  begin
    LCol := ADef.GetColumn(I);
    if LParts <> '' then
      LParts := LParts + ', ';
    LParts := LParts + LCol.Name + ' ' + MapLogicalType(ADef.Dialect, LCol);
  end;

  Result := 'CREATE TABLE ' + ADef.TableName + ' (' + LParts + ')';
end;

function DDLDropTableSQL(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');

  case ADef.Dialect of
    dbnPostgreSQL:
      if ADef.GetIfExists then
        Result := 'DROP TABLE IF EXISTS ' + ADef.TableName
      else
        Result := 'DROP TABLE ' + ADef.TableName;
    dbnFirebird:
      if ADef.GetIfExists then
        raise ENotSupportedException.Create(
          'DDL DROP TABLE: IF EXISTS is not emitted for Firebird in this build; use CreateFluentDDLDropTable(...).AsString ' +
          'without IfExists, or compose dialect-specific SQL in the application (e.g. Firebird 4+).')
      else
        Result := 'DROP TABLE ' + ADef.TableName;
  else
    raise ENotSupportedException.CreateFmt(
      'DDL DROP TABLE (ESP-018) is not implemented for dialect %d in this build',
      [Ord(ADef.Dialect)]);
  end;
end;

end.
