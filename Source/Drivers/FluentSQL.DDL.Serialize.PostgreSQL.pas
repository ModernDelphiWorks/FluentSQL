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
    function MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string; override;
    function GetDialect: TFluentSQLDriver; override;
    function Quote(const AName: string): string; override;
    function GetComputedDefinition(const ACol: IFluentDDLColumn): string; override;
    function GetIdentityDefinition(const ACol: IFluentDDLColumn): string; override;
    function GetColumnComment(const ATable: string; const ACol: IFluentDDLColumn): string; override;
    function GetTableComment(const ATable: IFluentDDLTableDef): string; override;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; override;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; override;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; override;
    function AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string; override;
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
    function CreateView(const ADef: IFluentDDLCreateViewDef): string; override;
    function DropView(const ADef: IFluentDDLDropViewDef): string; override;
    function CreateSequence(const ADef: IFluentDDLCreateSequenceDef): string; override;
    function DropSequence(const ADef: IFluentDDLDropSequenceDef): string; override;
    function AlterTableAddConstraint(const ADef: IFluentDDLAlterTableAddConstraintDef): string; override;
    function AlterTableDropConstraint(const ADef: IFluentDDLAlterTableDropConstraintDef): string; override;
  end;

implementation

{ TFluentDDLSerializerPostgreSQL }

function TFluentDDLSerializerPostgreSQL.GetDialect: TFluentSQLDriver;
begin
  Result := dbnPostgreSQL;
end;

function TFluentDDLSerializerPostgreSQL.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('"')) then
    Exit(AName);
  Result := '"' + AName + '"';
end;

function TFluentDDLSerializerPostgreSQL.GetComputedDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.ComputedExpression <> '' then
    Result := ' GENERATED ALWAYS AS (' + ACol.ComputedExpression + ') STORED';
end;

function TFluentDDLSerializerPostgreSQL.GetIdentityDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.IsIdentity then
    Result := ' GENERATED ALWAYS AS IDENTITY';
end;

function TFluentDDLSerializerPostgreSQL.GetColumnComment(const ATable: string; const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.Description <> '' then
    Result := '; ' + 'COMMENT ON COLUMN ' + Quote(ATable) + '.' + Quote(ACol.Name) + ' IS ' + QuotedStr(ACol.Description);
end;

function TFluentDDLSerializerPostgreSQL.GetTableComment(const ATable: IFluentDDLTableDef): string;
begin
  Result := '';
  if ATable.Description <> '' then
    Result := '; ' + 'COMMENT ON TABLE ' + Quote(ATable.TableName) + ' IS ' + QuotedStr(ATable.Description);
end;

function TFluentDDLSerializerPostgreSQL.MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string;
begin
  case AType of
    dltInteger:
      Result := 'INTEGER';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(AArg) + ')';
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
var
  LI: Integer;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + GetTableConstraintList(ADef) + ')';
  
  Result := Result + GetTableComment(ADef);
  for LI := 0 to ADef.GetColumnCount - 1 do
    Result := Result + GetColumnComment(ADef.TableName, ADef.GetColumn(LI));
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
  Result := Result + GetColumnComment(ADef.TableName, LCol);
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

function TFluentDDLSerializerPostgreSQL.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
var
  LBase: string;
  LTypePart: string;
  LNullPart: string;
begin
  if not Assigned(ADef) then
    Exit('');

  LBase := 'ALTER TABLE ' + Quote(ADef.TableName);
  LTypePart := '';
  LNullPart := '';

  if ADef.TypeChanged then
    LTypePart := ' ALTER COLUMN ' + Quote(ADef.ColumnName) + ' TYPE ' + MapLogicalType(ADef.LogicalType, ADef.TypeArg);

  if ADef.NullabilityChanged then
  begin
    LNullPart := ' ALTER COLUMN ' + Quote(ADef.ColumnName);
    if ADef.NotNull then
      LNullPart := LNullPart + ' SET NOT NULL'
    else
      LNullPart := LNullPart + ' DROP NOT NULL';
  end;

  if ADef.TypeChanged and ADef.NullabilityChanged then
    Result := LBase + LTypePart + ',' + LNullPart
  else if ADef.TypeChanged then
    Result := LBase + LTypePart
  else
    Result := LBase + LNullPart;
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

function TFluentDDLSerializerPostgreSQL.CreateView(const ADef: IFluentDDLCreateViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.OrReplace then
    Result := 'CREATE OR REPLACE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString
  else
    Result := 'CREATE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString;
end;

function TFluentDDLSerializerPostgreSQL.DropView(const ADef: IFluentDDLDropViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP VIEW IF EXISTS ' + Quote(ADef.ViewName)
  else
    Result := 'DROP VIEW ' + Quote(ADef.ViewName);
end;

function TFluentDDLSerializerPostgreSQL.CreateSequence(const ADef: IFluentDDLCreateSequenceDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'CREATE SEQUENCE ' + Quote(ADef.SequenceName);
end;

function TFluentDDLSerializerPostgreSQL.DropSequence(const ADef: IFluentDDLDropSequenceDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP SEQUENCE IF EXISTS ' + Quote(ADef.SequenceName)
  else
    Result := 'DROP SEQUENCE ' + Quote(ADef.SequenceName);
end;

function TFluentDDLSerializerPostgreSQL.AlterTableAddConstraint(const ADef: IFluentDDLAlterTableAddConstraintDef): string;
begin
  Result := inherited AlterTableAddConstraint(ADef);
end;

function TFluentDDLSerializerPostgreSQL.AlterTableDropConstraint(const ADef: IFluentDDLAlterTableDropConstraintDef): string;
begin
  Result := inherited AlterTableDropConstraint(ADef);
end;

end.
