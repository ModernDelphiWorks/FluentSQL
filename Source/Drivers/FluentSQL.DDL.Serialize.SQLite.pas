{
  ------------------------------------------------------------------------------
  FluentSQL
  SQLite DDL serialization driver (ESP-040).

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.SQLite;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerSQLite = class(TFluentDDLSerializeAbstract)
  protected
    function MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string; override;
    function GetDialect: TFluentSQLDriver; override;
    function Quote(const AName: string): string; override;
    function GetComputedDefinition(const ACol: IFluentDDLColumn): string; override;
    function GetIdentityDefinition(const ACol: IFluentDDLColumn): string; override;
    function MapConstraints(const ACol: IFluentDDLColumn): string; override;
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

{ TFluentDDLSerializerSQLite }

function TFluentDDLSerializerSQLite.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('`')) then
    Exit(AName);
  Result := '`' + AName + '`';
end;

function TFluentDDLSerializerSQLite.GetComputedDefinition(const ACol: IFluentDDLColumn): string;
begin
  if ACol.ComputedExpression <> '' then
    raise ENotSupportedException.Create('DDL: Computed columns are not supported in SQLite.');
  Result := '';
end;

function TFluentDDLSerializerSQLite.GetIdentityDefinition(const ACol: IFluentDDLColumn): string;
begin
  // SQLite's AUTOINCREMENT must be part of the PRIMARY KEY clause.
  // We handle it in MapConstraints to ensure correct ordering.
  Result := '';
end;

function TFluentDDLSerializerSQLite.MapConstraints(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.DefaultValue <> '' then
    Result := Result + ' DEFAULT ' + GetLiteralValue(ACol.DefaultValue, ACol.LogicalType);
  if ACol.NotNull then
    Result := Result + ' NOT NULL';

  if ACol.ConstraintName <> '' then
    Result := Result + ' CONSTRAINT ' + Quote(ACol.ConstraintName);

  if ACol.IsPrimaryKey then
  begin
    Result := Result + ' PRIMARY KEY';
    if ACol.IsIdentity then
      Result := Result + ' AUTOINCREMENT';
  end;
  if ACol.IsUnique then
    Result := Result + ' UNIQUE';
  if ACol.CheckCondition <> '' then
    Result := Result + ' CHECK (' + ACol.CheckCondition + ')';
  if ACol.ReferenceTable <> '' then
  begin
    Result := Result + ' REFERENCES ' + Quote(ACol.ReferenceTable);
    if ACol.ReferenceColumn <> '' then
      Result := Result + '(' + Quote(ACol.ReferenceColumn) + ')';
  end;
end;

function TFluentDDLSerializerSQLite.GetDialect: TFluentSQLDriver;
begin
  Result := dbnSQLite;
end;

function TFluentDDLSerializerSQLite.MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string;
begin
  case AType of
    dltInteger:
      Result := 'INTEGER';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'TEXT';
    dltBoolean:
      Result := 'BOOLEAN';
    dltDate:
      Result := 'TEXT';
    dltDateTime:
      Result := 'DATETIME';
    dltLongText:
      Result := 'TEXT';
    dltBlob:
      Result := 'BLOB';
    dltGuid:
      Result := 'GUID';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function TFluentDDLSerializerSQLite.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + GetTableConstraintList(ADef) + ')';
end;

function TFluentDDLSerializerSQLite.DropTable(const ADef: IFluentDDLDropTableDef): string;
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

function TFluentDDLSerializerSQLite.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  LCol := ADef.Column;
  if not Assigned(LCol) then
    raise EArgumentException.Create('DDL ALTER TABLE: a column definition is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ADD COLUMN ' + GetColumnDefinition(LCol);
end;

function TFluentDDLSerializerSQLite.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP COLUMN ' + Quote(ADef.ColumnName);
end;

function TFluentDDLSerializerSQLite.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' RENAME COLUMN ' + Quote(ADef.OldColumnName) + ' TO ' + Quote(ADef.NewColumnName);
end;

function TFluentDDLSerializerSQLite.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
begin
  raise ENotSupportedException.Create('DDL ALTER TABLE ALTER COLUMN: is not supported by SQLite (requires table recreation).');
end;



function TFluentDDLSerializerSQLite.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')'
  else
    Result := 'CREATE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')';
end;

function TFluentDDLSerializerSQLite.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.GetIfExists then
    Result := 'DROP INDEX IF EXISTS ' + Quote(ADef.IndexName)
  else
    Result := 'DROP INDEX ' + Quote(ADef.IndexName);
end;

function TFluentDDLSerializerSQLite.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  // SQLite mappings: DELETE FROM is the standard way to clear a table.
  Result := 'DELETE FROM ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerSQLite.CreateView(const ADef: IFluentDDLCreateViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  // SQLite does not support OR REPLACE/ALTER. 
  // We emit simple CREATE VIEW as per ADR-053.
  Result := 'CREATE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString;
end;

function TFluentDDLSerializerSQLite.DropView(const ADef: IFluentDDLDropViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP VIEW IF EXISTS ' + Quote(ADef.ViewName)
  else
    Result := 'DROP VIEW ' + Quote(ADef.ViewName);
end;

function TFluentDDLSerializerSQLite.CreateSequence(const ADef: IFluentDDLCreateSequenceDef): string;
begin
  raise ENotSupportedException.Create('DDL SQLite: sequences are not supported (use INTEGER PRIMARY KEY AUTOINCREMENT instead; ADR-054).');
end;

function TFluentDDLSerializerSQLite.DropSequence(const ADef: IFluentDDLDropSequenceDef): string;
begin
  raise ENotSupportedException.Create('DDL SQLite: sequences are not supported (ADR-054).');
end;

function TFluentDDLSerializerSQLite.AlterTableAddConstraint(const ADef: IFluentDDLAlterTableAddConstraintDef): string;
begin
  raise ENotSupportedException.Create('DDL SQLite: ALTER TABLE ADD CONSTRAINT is not supported (ESP-057).');
end;

function TFluentDDLSerializerSQLite.AlterTableDropConstraint(const ADef: IFluentDDLAlterTableDropConstraintDef): string;
begin
  raise ENotSupportedException.Create('DDL SQLite: ALTER TABLE DROP CONSTRAINT is not supported (ESP-057).');
end;

end.
