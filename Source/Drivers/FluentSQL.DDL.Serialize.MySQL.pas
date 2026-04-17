{
  ------------------------------------------------------------------------------
  FluentSQL
  MySQL DDL serialization driver.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.MySQL;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerMySQL = class(TFluentDDLSerializeAbstract)
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
    function CreateProcedure(const ADef: IFluentDDLProcedureDef): string; override;
    function DropProcedure(const ADef: IFluentDDLDropProcedureDef): string; override;
    function CreateTrigger(const ADef: IFluentDDLTriggerDef): string; override;
    function DropTrigger(const ADef: IFluentDDLDropTriggerDef): string; override;
    function ManageTrigger(const ADef: IFluentDDLTriggerManagementDef): string; override;
    function CreateFunction(const ADef: IFluentDDLFunctionDef): string; override;
    function DropFunction(const ADef: IFluentDDLDropFunctionDef): string; override;
  end;

implementation

{ TFluentDDLSerializerMySQL }

function TFluentDDLSerializerMySQL.GetComputedDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.ComputedExpression <> '' then
    Result := ' AS (' + ACol.ComputedExpression + ') VIRTUAL';
end;

function TFluentDDLSerializerMySQL.GetIdentityDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.IsIdentity then
    Result := ' AUTO_INCREMENT';
end;

function TFluentDDLSerializerMySQL.MapConstraints(const ACol: IFluentDDLColumn): string;
begin
  Result := inherited MapConstraints(ACol);
  if ACol.Description <> '' then
    Result := Result + ' COMMENT ' + QuotedStr(ACol.Description);
end;

function TFluentDDLSerializerMySQL.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('`')) then
    Exit(AName);
  Result := '`' + AName + '`';
end;

function TFluentDDLSerializerMySQL.GetDialect: TFluentSQLDriver;
begin
  Result := dbnMySQL;
end;

function TFluentDDLSerializerMySQL.MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string;
begin
  case AType of
    dltInteger:
      Result := 'INT';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(AArg) + ')';
    dltBoolean:
      Result := 'BOOLEAN';
    dltDate:
      Result := 'DATE';
    dltDateTime:
      Result := 'DATETIME';
    dltLongText:
      Result := 'LONGTEXT';
    dltBlob:
      Result := 'LONGBLOB';
    dltGuid:
      Result := 'CHAR(36)';
  else
    raise ENotSupportedException.Create('DDL: unknown logical type');
  end;
end;

function TFluentDDLSerializerMySQL.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + GetTableConstraintList(ADef) + ')';
  
  if ADef.Description <> '' then
    Result := Result + ' COMMENT = ' + QuotedStr(ADef.Description);
end;

function TFluentDDLSerializerMySQL.DropTable(const ADef: IFluentDDLDropTableDef): string;
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

function TFluentDDLSerializerMySQL.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
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

function TFluentDDLSerializerMySQL.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP COLUMN ' + Quote(ADef.ColumnName);
end;

function TFluentDDLSerializerMySQL.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' RENAME COLUMN ' + Quote(ADef.OldColumnName) + ' TO ' + Quote(ADef.NewColumnName);
end;

function TFluentDDLSerializerMySQL.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
var
  LType: string;
  LBase: string;
begin
  if not Assigned(ADef) then
    Exit('');

  LBase := 'ALTER TABLE ' + Quote(ADef.TableName);

  if ADef.DefaultSet or ADef.DefaultDropped then
  begin
    Result := LBase + ' ALTER COLUMN ' + Quote(ADef.ColumnName);
    if ADef.DefaultDropped then
      Result := Result + ' DROP DEFAULT'
    else
      Result := Result + ' SET DEFAULT ' + GetLiteralValue(ADef.DefaultValue, ADef.LogicalType);
  end
  else
  begin
    if not ADef.TypeChanged then
      raise EArgumentException.Create('DDL MySQL: column type must be restated during ALTER COLUMN (MODIFY COLUMN).');

    LType := MapLogicalType(ADef.LogicalType, ADef.TypeArg);
    Result := LBase + ' MODIFY COLUMN ' + Quote(ADef.ColumnName) + ' ' + LType;

    if ADef.NotNull then
      Result := Result + ' NOT NULL'
    else
      Result := Result + ' NULL';
  end;
end;



function TFluentDDLSerializerMySQL.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')'
  else
    Result := 'CREATE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')';
end;

function TFluentDDLSerializerMySQL.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
var
  LTable: string;
begin
  if not Assigned(ADef) then
    Exit('');
  LTable := Trim(ADef.GetTableName);
  if LTable = '' then
    raise EArgumentException.Create(
      'DDL DROP INDEX: table name is required for MySQL (DROP INDEX ... ON ...); see ESP-028 / ADR-028.');
  if ADef.GetIfExists then
    raise ENotSupportedException.Create(
      'DDL DROP INDEX IF EXISTS is not emitted for MySQL / MariaDB in this build for the standalone DROP INDEX ... ON ... form (ESP-028 / ADR-028).');
  if ADef.GetConcurrently then
    raise ENotSupportedException.Create(
      'DDL DROP INDEX CONCURRENTLY (ESP-027) is not supported for MySQL; only PostgreSQL maps CONCURRENTLY (ADR-027).');

  Result := 'DROP INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(LTable);
end;

function TFluentDDLSerializerMySQL.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetRestartIdentity or ADef.GetCascade then
    raise ENotSupportedException.Create(
      'DDL TRUNCATE TABLE: RESTART IDENTITY and CASCADE are PostgreSQL-only options in this vertical (ESP-029 / ADR-029).');
  Result := 'TRUNCATE TABLE ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerMySQL.CreateView(const ADef: IFluentDDLCreateViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.OrReplace then
    Result := 'CREATE OR REPLACE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString
  else
    Result := 'CREATE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString;
end;

function TFluentDDLSerializerMySQL.DropView(const ADef: IFluentDDLDropViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP VIEW IF EXISTS ' + Quote(ADef.ViewName)
  else
    Result := 'DROP VIEW ' + Quote(ADef.ViewName);
end;

function TFluentDDLSerializerMySQL.CreateSequence(const ADef: IFluentDDLCreateSequenceDef): string;
begin
  raise ENotSupportedException.Create('DDL MySQL: sequences are not supported (use AUTO_INCREMENT on columns instead; ADR-054).');
end;

function TFluentDDLSerializerMySQL.DropSequence(const ADef: IFluentDDLDropSequenceDef): string;
begin
  raise ENotSupportedException.Create('DDL MySQL: sequences are not supported (ADR-054).');
end;

function TFluentDDLSerializerMySQL.AlterTableAddConstraint(const ADef: IFluentDDLAlterTableAddConstraintDef): string;
begin
  Result := inherited AlterTableAddConstraint(ADef);
end;

function TFluentDDLSerializerMySQL.AlterTableDropConstraint(const ADef: IFluentDDLAlterTableDropConstraintDef): string;
begin
  if not Assigned(ADef) or (ADef.ConstraintName = '') then
    Exit('');
  // ESP-057: special handling for PK drop in MySQL
  if SameText(ADef.ConstraintName, 'PRIMARY') then
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP PRIMARY KEY'
  else
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP CONSTRAINT ' + Quote(ADef.ConstraintName);
end;

function TFluentDDLSerializerMySQL.CreateProcedure(const ADef: IFluentDDLProcedureDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.OrReplace then
    raise ENotSupportedException.Create('DDL MySQL: CREATE OR REPLACE PROCEDURE is not supported (ADR-070); use DropProcedure.IfExists first.');

  Result := 'CREATE PROCEDURE ' + Quote(ADef.ProcedureName) + '(' + ADef.Params + ') ' + ADef.Body;
end;

function TFluentDDLSerializerMySQL.DropProcedure(const ADef: IFluentDDLDropProcedureDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP PROCEDURE IF EXISTS ' + Quote(ADef.ProcedureName)
  else
    Result := 'DROP PROCEDURE ' + Quote(ADef.ProcedureName);
end;

function TFluentDDLSerializerMySQL.CreateTrigger(const ADef: IFluentDDLTriggerDef): string;
var
  LTime, LEvent: string;
begin
  if not Assigned(ADef) then
    Exit('');

  LTime := 'AFTER';
  if ADef.Time = ttBefore then LTime := 'BEFORE';

  case ADef.Event of
    teInsert: LEvent := 'INSERT';
    teUpdate: LEvent := 'UPDATE';
    teDelete: LEvent := 'DELETE';
  else
    LEvent := 'INSERT';
  end;

  Result := 'CREATE TRIGGER ' + Quote(ADef.TriggerName) + ' ' + LTime + ' ' + LEvent +
            ' ON ' + Quote(ADef.TableName) + ' FOR EACH ROW ' + ADef.Body;
end;

function TFluentDDLSerializerMySQL.DropTrigger(const ADef: IFluentDDLDropTriggerDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP TRIGGER IF EXISTS ' + Quote(ADef.TriggerName)
  else
    Result := 'DROP TRIGGER ' + Quote(ADef.TriggerName);
end;

function TFluentDDLSerializerMySQL.ManageTrigger(const ADef: IFluentDDLTriggerManagementDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  Result := '-- MySQL: Direct trigger management is MariaDB-specific. Standard MySQL does not support ENABLE/DISABLE TRIGGER.' + sLineBreak;
  if ADef.Enabled then
    Result := Result + 'ALTER TRIGGER ' + Quote(ADef.TriggerName) + ' ENABLE'
  else
    Result := Result + 'ALTER TRIGGER ' + Quote(ADef.TriggerName) + ' DISABLE';
end;

function TFluentDDLSerializerMySQL.CreateFunction(const ADef: IFluentDDLFunctionDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.OrReplace then
    raise ENotSupportedException.Create('DDL MySQL: CREATE OR REPLACE FUNCTION is not supported (ADR-071); use DropFunction.IfExists first.');

  Result := 'CREATE FUNCTION ' + Quote(ADef.FunctionName) + '(' + ADef.Params + ') ' +
            'RETURNS ' + ADef.Returns + ' ' + ADef.Body;
end;

function TFluentDDLSerializerMySQL.DropFunction(const ADef: IFluentDDLDropFunctionDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP FUNCTION IF EXISTS ' + Quote(ADef.FunctionName)
  else
    Result := 'DROP FUNCTION ' + Quote(ADef.FunctionName);
end;

end.
