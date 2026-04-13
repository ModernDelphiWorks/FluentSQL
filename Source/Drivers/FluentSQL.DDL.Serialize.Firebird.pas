{
  ------------------------------------------------------------------------------
  FluentSQL
  Firebird DDL serialization driver.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.Firebird;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerFirebird = class(TFluentDDLSerializeAbstract)
  protected
    function MapLogicalType(const ACol: IFluentDDLColumn): string; virtual;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; override;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; override;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; override;
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
  end;

implementation

{ TFluentDDLSerializerFirebird }

function TFluentDDLSerializerFirebird.MapLogicalType(const ACol: IFluentDDLColumn): string;
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
  Result := Result + MapConstraints(ACol);
end;

function TFluentDDLSerializerFirebird.CreateTable(const ADef: IFluentDDLTableDef): string;
var
  LI: Integer;
  LParts: string;
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  LParts := '';
  for LI := 0 to ADef.GetColumnCount - 1 do
  begin
    LCol := ADef.GetColumn(LI);
    if LParts <> '' then
      LParts := LParts + ', ';
    LParts := LParts + LCol.Name + ' ' + MapLogicalType(LCol);
  end;

  Result := 'CREATE TABLE ' + ADef.TableName + ' (' + LParts + ')';
end;

function TFluentDDLSerializerFirebird.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');

  if ADef.GetIfExists then
    raise ENotSupportedException.Create(
      'DDL DROP TABLE: IF EXISTS is not emitted for Firebird in this build; use CreateFluentDDLDropTable(...).AsString ' +
      'without IfExists, or compose dialect-specific SQL in the application (e.g. Firebird 4+).')
  else
    Result := 'DROP TABLE ' + ADef.TableName;
end;

function TFluentDDLSerializerFirebird.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
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

  Result := 'ALTER TABLE ' + ADef.TableName + ' ADD ' + LCol.Name + ' ' + MapLogicalType(LCol);
end;

function TFluentDDLSerializerFirebird.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + ADef.TableName + ' DROP ' + ADef.ColumnName;
end;

function TFluentDDLSerializerFirebird.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
var
  LTable, LOld, LNew: string;
begin
  if not Assigned(ADef) then
    Exit('');
  LTable := Trim(ADef.GetTableName);
  LOld := Trim(ADef.GetOldColumnName);
  LNew := Trim(ADef.GetNewColumnName);
  Result := 'ALTER TABLE ' + LTable + ' ALTER ' + LOld + ' TO ' + LNew;
end;

function TFluentDDLSerializerFirebird.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
var
  I: Integer;
  LCols: string;
begin
  if not Assigned(ADef) then
    Exit('');
  LCols := '';
  for I := 0 to ADef.GetColumnCount - 1 do
  begin
    if LCols <> '' then
      LCols := LCols + ', ';
    LCols := LCols + ADef.GetColumnName(I);
  end;

  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + ADef.IndexName + ' ON ' + ADef.TableName + ' (' + LCols + ')'
  else
    Result := 'CREATE INDEX ' + ADef.IndexName + ' ON ' + ADef.TableName + ' (' + LCols + ')';
end;

function TFluentDDLSerializerFirebird.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetConcurrently then
    raise ENotSupportedException.Create(
      'DDL DROP INDEX CONCURRENTLY (ESP-027) is not supported for Firebird; only PostgreSQL maps CONCURRENTLY (ADR-027).');
  if Trim(ADef.GetTableName) <> '' then
    raise ENotSupportedException.Create('DDL DROP INDEX: table name is not supported for Firebird (DROP INDEX ... ON ...).');

  if ADef.GetIfExists then
    Result := 'DROP INDEX IF EXISTS ' + ADef.IndexName
  else
    Result := 'DROP INDEX ' + ADef.IndexName;
end;

function TFluentDDLSerializerFirebird.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetRestartIdentity or ADef.GetCascade then
    raise ENotSupportedException.Create(
      'DDL TRUNCATE TABLE: RESTART IDENTITY and CASCADE are PostgreSQL-only options in this vertical (ESP-029 / ADR-029).');
  Result := 'TRUNCATE TABLE ' + ADef.TableName;
end;

end.
