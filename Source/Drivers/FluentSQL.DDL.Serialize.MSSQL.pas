{
  ------------------------------------------------------------------------------
  FluentSQL
  MS SQL Server DDL serialization driver.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.MSSQL;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerMSSQL = class(TFluentDDLSerializeAbstract)
  protected
    function MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string; override;
    function GetDialect: TFluentSQLDriver; override;
    function Quote(const AName: string): string; override;
    function GetComputedDefinition(const ACol: IFluentDDLColumn): string; override;
    function GetIdentityDefinition(const ACol: IFluentDDLColumn): string; override;
    function GetLiteralValue(const AValue: string; const ALogicalType: TDDLLogicalType = dltVarChar): string; override;
    function GetColumnComment(const ATable: string; const ACol: IFluentDDLColumn): string; override;
    function GetTableComment(const ATable: IFluentDDLTableDef): string; override;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; override;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; override;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; override;
    function AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string; override;
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

{ TFluentDDLSerializerMSSQL }

function TFluentDDLSerializerMSSQL.GetComputedDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.ComputedExpression <> '' then
    Result := ' AS (' + ACol.ComputedExpression + ')';
end;

function TFluentDDLSerializerMSSQL.GetIdentityDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.IsIdentity then
    Result := ' IDENTITY(1,1)';
end;

function TFluentDDLSerializerMSSQL.Quote(const AName: string): string;
begin
  if (AName = '') or (AName.StartsWith('[')) then
    Exit(AName);
  Result := '[' + AName + ']';
end;

function TFluentDDLSerializerMSSQL.GetDialect: TFluentSQLDriver;
begin
  Result := dbnMSSQL;
end;

function TFluentDDLSerializerMSSQL.GetLiteralValue(const AValue: string;
  const ALogicalType: TDDLLogicalType): string;
begin
  Result := inherited GetLiteralValue(AValue, ALogicalType);
end;

function TFluentDDLSerializerMSSQL.GetColumnComment(const ATable: string; const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.Description <> '' then
  begin
    Result := '; EXEC sp_addextendedproperty ' +
      '@name = N''MS_Description'', ' +
      '@value = N' + QuotedStr(ACol.Description) + ', ' +
      '@level0type = N''SCHEMA'', @level0name = N''dbo'', ' +
      '@level1type = N''TABLE'', @level1name = N' + QuotedStr(ATable) + ', ' +
      '@level2type = N''COLUMN'', @level2name = N' + QuotedStr(ACol.Name);
  end;
end;

function TFluentDDLSerializerMSSQL.GetTableComment(const ATable: IFluentDDLTableDef): string;
begin
  Result := '';
  if ATable.Description <> '' then
  begin
    Result := '; EXEC sp_addextendedproperty ' +
      '@name = N''MS_Description'', ' +
      '@value = N' + QuotedStr(ATable.Description) + ', ' +
      '@level0type = N''SCHEMA'', @level0name = N''dbo'', ' +
      '@level1type = N''TABLE'', @level1name = N' + QuotedStr(ATable.TableName);
  end;
end;

function TFluentDDLSerializerMSSQL.MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string;
begin
  case AType of
    dltInteger:
      Result := 'INT';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(AArg) + ')';
    dltBoolean:
      Result := 'BIT';
    dltDate:
      Result := 'DATE';
    dltDateTime:
      Result := 'DATETIME2';
    dltLongText:
      Result := 'VARCHAR(MAX)';
    dltBlob:
      Result := 'VARBINARY(MAX)';
    dltGuid:
      Result := 'UNIQUEIDENTIFIER';
  else
    raise ENotSupportedException.Create('DDL MSSQL: unknown logical type');
  end;
end;

function TFluentDDLSerializerMSSQL.CreateTable(const ADef: IFluentDDLTableDef): string;
var
  LI: Integer;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL MSSQL: empty column list');

  Result := 'CREATE TABLE ' + Quote(ADef.TableName) + ' (' + GetColumnDefinitionList(ADef) + GetTableConstraintList(ADef) + ')';
  
  Result := Result + GetTableComment(ADef);
  for LI := 0 to ADef.GetColumnCount - 1 do
    Result := Result + GetColumnComment(ADef.TableName, ADef.GetColumn(LI));
end;

function TFluentDDLSerializerMSSQL.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');

  if ADef.GetIfExists then
    Result := 'DROP TABLE IF EXISTS ' + Quote(ADef.TableName)
  else
    Result := 'DROP TABLE ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerMSSQL.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  LCol := ADef.Column;
  if not Assigned(LCol) then
    raise EArgumentException.Create('DDL MSSQL ALTER TABLE: a column definition is required');
    
  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ADD ' + GetColumnDefinition(LCol);
  Result := Result + GetColumnComment(ADef.TableName, LCol);
end;

function TFluentDDLSerializerMSSQL.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL MSSQL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DROP COLUMN ' + Quote(ADef.ColumnName);
end;

function TFluentDDLSerializerMSSQL.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if (Trim(ADef.OldColumnName) = '') or (Trim(ADef.NewColumnName) = '') then
    raise EArgumentException.Create('DDL MSSQL: old and new column names are required');

  Result := 'EXEC sp_rename ''' + Quote(ADef.TableName) + '.' + Quote(ADef.OldColumnName) + ''', ''' + ADef.NewColumnName + ''', ''COLUMN''';
end;

function TFluentDDLSerializerMSSQL.AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'EXEC sp_rename ''' + ADef.OldTableName + ''', ''' + ADef.NewTableName + '''';
end;

function TFluentDDLSerializerMSSQL.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
var
  LType: string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.DefaultDropped then
    raise ENotSupportedException.Create('DDL MSSQL: DROP DEFAULT requires a constraint name (use DropConstraint).')
  else if ADef.DefaultSet then
  begin
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ADD DEFAULT ' +
      GetLiteralValue(ADef.DefaultValue, ADef.LogicalType) + ' FOR ' + Quote(ADef.ColumnName);
  end
  else
  begin
    if not ADef.TypeChanged then
      raise EArgumentException.Create('DDL MSSQL: column type must be restated during ALTER COLUMN.');

    LType := MapLogicalType(ADef.LogicalType, ADef.TypeArg);
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ALTER COLUMN ' + Quote(ADef.ColumnName) + ' ' + LType;

    if ADef.NotNull then
      Result := Result + ' NOT NULL'
    else
      Result := Result + ' NULL';
  end;
end;

function TFluentDDLSerializerMSSQL.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MSSQL: index name is required');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL MSSQL: column list required for index');

  if ADef.IsUnique then
    Result := 'CREATE UNIQUE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')'
  else
    Result := 'CREATE INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName) + ' (' + GetColumnNameList(ADef) + ')';
end;

function TFluentDDLSerializerMSSQL.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MSSQL: index name is required');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL DROP INDEX: table name is required (DROP INDEX Name ON Table).');

  if ADef.GetIfExists then
    Result := 'DROP INDEX IF EXISTS ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName)
  else
    Result := 'DROP INDEX ' + Quote(ADef.IndexName) + ' ON ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerMSSQL.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
    
  Result := 'TRUNCATE TABLE ' + Quote(ADef.TableName);
end;

function TFluentDDLSerializerMSSQL.CreateView(const ADef: IFluentDDLCreateViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.OrReplace then
    Result := 'CREATE OR ALTER VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString
  else
    Result := 'CREATE VIEW ' + Quote(ADef.ViewName) + ' AS ' + ADef.Query.AsString;
end;

function TFluentDDLSerializerMSSQL.DropView(const ADef: IFluentDDLDropViewDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP VIEW IF EXISTS ' + Quote(ADef.ViewName)
  else
    Result := 'DROP VIEW ' + Quote(ADef.ViewName);
end;

function TFluentDDLSerializerMSSQL.CreateSequence(const ADef: IFluentDDLCreateSequenceDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'CREATE SEQUENCE ' + Quote(ADef.SequenceName);
end;

function TFluentDDLSerializerMSSQL.DropSequence(const ADef: IFluentDDLDropSequenceDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.IfExists then
    Result := 'DROP SEQUENCE IF EXISTS ' + Quote(ADef.SequenceName)
  else
    Result := 'DROP SEQUENCE ' + Quote(ADef.SequenceName);
end;

function TFluentDDLSerializerMSSQL.AlterTableAddConstraint(const ADef: IFluentDDLAlterTableAddConstraintDef): string;
begin
  Result := inherited AlterTableAddConstraint(ADef);
end;

function TFluentDDLSerializerMSSQL.AlterTableDropConstraint(const ADef: IFluentDDLAlterTableDropConstraintDef): string;
begin
  Result := inherited AlterTableDropConstraint(ADef);
end;

function TFluentDDLSerializerMSSQL.CreateProcedure(const ADef: IFluentDDLProcedureDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.OrReplace then
    Result := 'CREATE OR ALTER PROCEDURE ' + Quote(ADef.ProcedureName)
  else
    Result := 'CREATE PROCEDURE ' + Quote(ADef.ProcedureName);

  if ADef.Params <> '' then
    Result := Result + ' ' + ADef.Params;

  Result := Result + ' AS ' + ADef.Body;
end;

function TFluentDDLSerializerMSSQL.DropProcedure(const ADef: IFluentDDLDropProcedureDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP PROCEDURE IF EXISTS ' + Quote(ADef.ProcedureName)
  else
    Result := 'DROP PROCEDURE ' + Quote(ADef.ProcedureName);
end;

function TFluentDDLSerializerMSSQL.CreateTrigger(const ADef: IFluentDDLTriggerDef): string;
var
  LEvent, LTime: string;
begin
  if not Assigned(ADef) then
    Exit('');

  case ADef.Event of
    teInsert: LEvent := 'INSERT';
    teUpdate: LEvent := 'UPDATE';
    teDelete: LEvent := 'DELETE';
  else
    LEvent := 'INSERT';
  end;

  if ADef.Time = ttBefore then
    LTime := 'FOR'
  else
    LTime := 'AFTER';

  Result := 'CREATE TRIGGER ' + Quote(ADef.TriggerName) + ' ON ' + Quote(ADef.TableName) +
            ' ' + LTime + ' ' + LEvent + ' AS ' + ADef.Body;
end;

function TFluentDDLSerializerMSSQL.DropTrigger(const ADef: IFluentDDLDropTriggerDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP TRIGGER IF EXISTS ' + Quote(ADef.TriggerName)
  else
    Result := 'DROP TRIGGER ' + Quote(ADef.TriggerName);
end;

function TFluentDDLSerializerMSSQL.ManageTrigger(const ADef: IFluentDDLTriggerManagementDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.Enabled then
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' ENABLE TRIGGER ' + Quote(ADef.TriggerName)
  else
    Result := 'ALTER TABLE ' + Quote(ADef.TableName) + ' DISABLE TRIGGER ' + Quote(ADef.TriggerName);
end;

function TFluentDDLSerializerMSSQL.CreateFunction(const ADef: IFluentDDLFunctionDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.OrReplace then
    Result := 'CREATE OR ALTER FUNCTION ' + Quote(ADef.FunctionName)
  else
    Result := 'CREATE FUNCTION ' + Quote(ADef.FunctionName);

  if ADef.Params <> '' then
    Result := Result + ' (' + ADef.Params + ')';

  Result := Result + ' RETURNS ' + ADef.Returns + ' AS ' + ADef.Body;
end;

function TFluentDDLSerializerMSSQL.DropFunction(const ADef: IFluentDDLDropFunctionDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if ADef.IfExists then
    Result := 'DROP FUNCTION IF EXISTS ' + Quote(ADef.FunctionName)
  else
    Result := 'DROP FUNCTION ' + Quote(ADef.FunctionName);
end;

end.
