{
  ------------------------------------------------------------------------------
  FluentSQL
  PostgreSQL DDL serialization driver.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.PostgreSQL;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerPostgreSQL = class(TFluentDDLSerializeAbstract)
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
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
  end;

implementation

{ TFluentDDLSerializerPostgreSQL }

function TFluentDDLSerializerPostgreSQL.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('"')) then
    Exit(AName);
  Result := '"' + AName + '"';
end;

function TFluentDDLSerializerPostgreSQL.GetDialect: TFluentSQLDriver;
begin
  Result := dbnPostgreSQL;
end;

function TFluentDDLSerializerPostgreSQL.MapLogicalType(const ACol: IFluentDDLColumn): string;
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
    dltGuid:
      Result := 'UUID';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function TFluentDDLSerializerPostgreSQL.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + ')';
end;

function TFluentDDLSerializerPostgreSQL.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');

  if ADef.GetIfExists then
    Result := 'DROP TABLE IF EXISTS ' + Quote(ADef.TableName)
  else
    Result := 'DROP TABLE ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerPostgreSQL.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
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

function TFluentDDLSerializerPostgreSQL.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP COLUMN ' + Quote(ADef.ColumnName);
end;

function TFluentDDLSerializerPostgreSQL.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' RENAME COLUMN ' + Quote(ADef.OldColumnName) + ' TO ' + Quote(ADef.NewColumnName);
end;



function TFluentDDLSerializerPostgreSQL.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')'
  else
    Result := 'CREATE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')';
end;

function TFluentDDLSerializerPostgreSQL.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.GetTableName) <> '' then
    raise ENotSupportedException.Create('DDL DROP INDEX: table name is not supported for PostgreSQL (DROP INDEX ... ON ...).');

  if ADef.GetConcurrently then
  begin
    if ADef.GetIfExists then
      Result := 'DROP INDEX CONCURRENTLY IF EXISTS ' + Quote(ADef.IndexName)
    else
      Result := 'DROP INDEX CONCURRENTLY ' + Quote(ADef.IndexName);
  end
  else if ADef.GetIfExists then
    Result := 'DROP INDEX IF EXISTS ' + Quote(ADef.IndexName)
  else
    Result := 'DROP INDEX ' + Quote(ADef.IndexName);
end;

function TFluentDDLSerializerPostgreSQL.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'TRUNCATE TABLE ' + Quote(ADef.TableName);
  if ADef.GetRestartIdentity then
    Result := Result + ' RESTART IDENTITY';
  if ADef.GetCascade then
    Result := Result + ' CASCADE';
end;

end.
