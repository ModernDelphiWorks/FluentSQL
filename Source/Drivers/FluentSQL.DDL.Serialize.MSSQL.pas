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

{ TFluentDDLSerializerMSSQL }

function TFluentDDLSerializerMSSQL.MapLogicalType(const ACol: IFluentDDLColumn): string;
begin
  case ACol.LogicalType of
    dltInteger:
      Result := 'INT';
    dltBigInt:
      Result := 'BIGINT';
    dltVarChar:
      Result := 'VARCHAR(' + IntToStr(ACol.TypeArg) + ')';
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
  else
    raise ENotSupportedException.Create('DDL MSSQL: unknown logical type');
  end;
  Result := Result + MapConstraints(ACol);
end;

function TFluentDDLSerializerMSSQL.CreateTable(const ADef: IFluentDDLTableDef): string;
var
  LI: Integer;
  LParts: string;
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL MSSQL: empty column list');

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

function TFluentDDLSerializerMSSQL.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');

  if ADef.GetIfExists then
    Result := 'DROP TABLE IF EXISTS ' + ADef.TableName
  else
    Result := 'DROP TABLE ' + ADef.TableName;
end;

function TFluentDDLSerializerMSSQL.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LCol: IFluentDDLColumn;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
  LCol := ADef.Column;
  if not Assigned(LCol) then
    raise EArgumentException.Create('DDL MSSQL ALTER TABLE: a column definition is required');
  if Trim(LCol.Name) = '' then
    raise EArgumentException.Create('DDL MSSQL: column name is required');

  Result := 'ALTER TABLE ' + ADef.TableName + ' ADD ' + LCol.Name + ' ' + MapLogicalType(LCol);
end;

function TFluentDDLSerializerMSSQL.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
  if Trim(ADef.ColumnName) = '' then
    raise EArgumentException.Create('DDL MSSQL ALTER TABLE DROP COLUMN: a column target is required');

  Result := 'ALTER TABLE ' + ADef.TableName + ' DROP COLUMN ' + ADef.ColumnName;
end;

function TFluentDDLSerializerMSSQL.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
  if (Trim(ADef.OldColumnName) = '') or (Trim(ADef.NewColumnName) = '') then
    raise EArgumentException.Create('DDL MSSQL: old and new column names are required');

  Result := 'EXEC sp_rename ''' + ADef.TableName + '.' + ADef.OldColumnName + ''', ''' + ADef.NewColumnName + ''', ''COLUMN''';
end;

function TFluentDDLSerializerMSSQL.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
var
  I: Integer;
  LCols: string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MSSQL: index name is required');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
  if ADef.GetColumnCount <= 0 then
    raise EArgumentException.Create('DDL MSSQL: column list required for index');

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

function TFluentDDLSerializerMSSQL.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MSSQL: index name is required');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL DROP INDEX: table name is required (DROP INDEX Name ON Table).');

  if ADef.GetIfExists then
    Result := 'DROP INDEX IF EXISTS ' + ADef.IndexName + ' ON ' + ADef.TableName
  else
    Result := 'DROP INDEX ' + ADef.IndexName + ' ON ' + ADef.TableName;
end;

function TFluentDDLSerializerMSSQL.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MSSQL: table name is required');
    
  Result := 'TRUNCATE TABLE ' + ADef.TableName;
end;

end.
