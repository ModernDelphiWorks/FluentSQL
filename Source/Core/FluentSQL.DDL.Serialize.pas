{
  ------------------------------------------------------------------------------
  FluentSQL
  ESP-017: CREATE TABLE string generation per dialect (no execution).

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
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
function DDLAlterTableAddColumnSQL(const ADef: IFluentDDLAlterTableAddColumnDef): string;
function DDLAlterTableDropColumnSQL(const ADef: IFluentDDLAlterTableDropColumnDef): string;
function DDLCreateIndexSQL(const ADef: IFluentDDLCreateIndexDef): string;
function DDLDropIndexSQL(const ADef: IFluentDDLDropIndexDef): string;

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

function DDLAlterTableAddColumnSQL(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  LCol := ADef.Column;
  if not Assigned(LCol) then
    raise EArgumentException.Create('DDL ALTER TABLE: a column definition is required');
  if Trim(LCol.Name) = '' then
    raise EArgumentException.Create('DDL: column name is required');

  case ADef.Dialect of
    dbnFirebird, dbnPostgreSQL:
      Result := 'ALTER TABLE ' + ADef.TableName + ' ADD ' + LCol.Name + ' ' +
        MapLogicalType(ADef.Dialect, LCol);
  else
    raise ENotSupportedException.CreateFmt(
      'DDL ALTER TABLE ADD COLUMN (ESP-019) is not implemented for dialect %d in this build',
      [Ord(ADef.Dialect)]);
  end;
end;

function DDLAlterTableDropColumnSQL(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  case ADef.Dialect of
    dbnFirebird:
      Result := 'ALTER TABLE ' + ADef.TableName + ' DROP ' + ADef.ColumnName;
    dbnPostgreSQL:
      Result := 'ALTER TABLE ' + ADef.TableName + ' DROP COLUMN ' + ADef.ColumnName;
  else
    raise ENotSupportedException.CreateFmt(
      'DDL ALTER TABLE DROP COLUMN (ESP-020) is not implemented for dialect %d in this build',
      [Ord(ADef.Dialect)]);
  end;
end;

function DDLCreateIndexSQL(const ADef: IFluentDDLCreateIndexDef): string;
var
  I: Integer;
  LCols: string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL CREATE INDEX: at least one column is required');

  LCols := '';
  for I := 0 to ADef.GetColumnCount - 1 do
  begin
    if LCols <> '' then
      LCols := LCols + ', ';
    LCols := LCols + ADef.GetColumnName(I);
  end;

  case ADef.Dialect of
    dbnFirebird, dbnPostgreSQL:
      begin
        if ADef.IsUnique then
          Result := 'CREATE UNIQUE INDEX ' + ADef.IndexName + ' ON ' + ADef.TableName + ' (' + LCols + ')'
        else
          Result := 'CREATE INDEX ' + ADef.IndexName + ' ON ' + ADef.TableName + ' (' + LCols + ')';
      end;
  else
    raise ENotSupportedException.CreateFmt(
      'DDL CREATE INDEX (ESP-022) is not implemented for dialect %d in this build',
      [Ord(ADef.Dialect)]);
  end;
end;

function DDLDropIndexSQL(const ADef: IFluentDDLDropIndexDef): string;
var
  LTable: string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');

  LTable := Trim(ADef.GetTableName);

  case ADef.Dialect of
    dbnPostgreSQL:
      begin
        if LTable <> '' then
          raise ENotSupportedException.Create(
            'DDL DROP INDEX: ON TABLE is not used for PostgreSQL in this vertical (ESP-028 / ADR-028).');
        if ADef.GetConcurrently then
        begin
          if ADef.GetIfExists then
            Result := 'DROP INDEX CONCURRENTLY IF EXISTS ' + ADef.IndexName
          else
            Result := 'DROP INDEX CONCURRENTLY ' + ADef.IndexName;
        end
        else if ADef.GetIfExists then
          Result := 'DROP INDEX IF EXISTS ' + ADef.IndexName
        else
          Result := 'DROP INDEX ' + ADef.IndexName;
      end;
    dbnFirebird:
      begin
        if LTable <> '' then
          raise ENotSupportedException.Create(
            'DDL DROP INDEX: ON TABLE is not used for Firebird in this vertical (ESP-028 / ADR-028).');
        if ADef.GetConcurrently then
          raise ENotSupportedException.Create(
            'DDL DROP INDEX CONCURRENTLY (ESP-027) is not supported for Firebird; only PostgreSQL maps CONCURRENTLY (ADR-027). Use IF EXISTS without CONCURRENTLY per ADR-026.');
        if ADef.GetIfExists then
          Result := 'DROP INDEX IF EXISTS ' + ADef.IndexName
        else
          Result := 'DROP INDEX ' + ADef.IndexName;
      end;
    dbnMySQL:
      begin
        if ADef.GetConcurrently then
          raise ENotSupportedException.Create(
            'DDL DROP INDEX CONCURRENTLY (ESP-027 / ESP-028) is not supported for MySQL; only PostgreSQL maps CONCURRENTLY (ADR-027).');
        if LTable = '' then
          raise EArgumentException.Create(
            'DDL DROP INDEX: table name is required for MySQL (DROP INDEX ... ON ...); see ESP-028 / ADR-028.');
        if ADef.GetIfExists then
          raise ENotSupportedException.Create(
            'DDL DROP INDEX IF EXISTS is not emitted for MySQL / MariaDB in this build for the standalone DROP INDEX ... ON ... form (ESP-028 / ADR-028); use dialect-specific SQL or omit IfExists.')
        else
          Result := 'DROP INDEX ' + ADef.IndexName + ' ON ' + LTable;
      end;
  else
    begin
      if LTable <> '' then
        raise ENotSupportedException.Create(
          'DDL DROP INDEX: ON TABLE is only mapped for dbnMySQL in this vertical (ESP-028 / ADR-028).');
      if ADef.GetConcurrently then
        raise ENotSupportedException.CreateFmt(
          'DDL DROP INDEX CONCURRENTLY (ESP-027) is not implemented for dialect %d; only PostgreSQL supports CONCURRENTLY in this build.',
          [Ord(ADef.Dialect)])
      else
        raise ENotSupportedException.CreateFmt(
          'DDL DROP INDEX (ESP-026) is not implemented for dialect %d in this build (ESP-025 baseline).',
          [Ord(ADef.Dialect)]);
    end;
  end;
end;

end.
