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
    function MapLogicalType(const ACol: IFluentDDLColumn): string; override;
    function GetDialect: TFluentSQLDriver; override;
    function Quote(const AName: string): string; override;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; override;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; override;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; override;
    function AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string; override;
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
  end;

implementation

{ TFluentDDLSerializerFirebird }

function TFluentDDLSerializerFirebird.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('"')) then
    Exit(AName);
  Result := '"' + AName + '"';
end;

function TFluentDDLSerializerFirebird.GetDialect: TFluentSQLDriver;
begin
  Result := dbnFirebird;
end;

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
    dltGuid:
      Result := 'CHAR(16) CHARACTER SET OCTETS';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function TFluentDDLSerializerFirebird.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + ')';
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
    Result := 'DROP TABLE ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerFirebird.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  LCol := ADef.Column;
  if not Assigned(LCol) then
    raise EArgumentException.Create('DDL ALTER TABLE: a column definition is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ADD ' + GetColumnDefinition(LCol);
end;

function TFluentDDLSerializerFirebird.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP ' + Quote(ADef.ColumnName);
end;

function TFluentDDLSerializerFirebird.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ALTER ' + Quote(ADef.OldColumnName) + ' TO ' + Quote(ADef.NewColumnName);
end;

function TFluentDDLSerializerFirebird.AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.OldTableName) + ' TO ' + Quote(ADef.NewTableName);
end;

function TFluentDDLSerializerFirebird.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')'
  else
    Result := 'CREATE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')';
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
    Result := 'DROP INDEX IF EXISTS ' + Quote(ADef.IndexName)
  else
    Result := 'DROP INDEX ' + Quote(ADef.IndexName);
end;

function TFluentDDLSerializerFirebird.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetRestartIdentity or ADef.GetCascade then
    raise ENotSupportedException.Create(
      'DDL TRUNCATE TABLE: RESTART IDENTITY and CASCADE are PostgreSQL-only options in this vertical (ESP-029 / ADR-029).');
  Result := 'TRUNCATE TABLE ' + Quote(ADef.TableName);
end;

end.
