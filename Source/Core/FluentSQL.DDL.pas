{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  System.SysUtils,
  Winapi.Windows,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  /// <summary>Owned by <see cref="TFluentDDLBuilder"/> list — not refcounted via interface to avoid
  /// self-free while still stored in <c>TObjectList</c> (TInterfacedObject would destroy on last Release).</summary>
  TFluentDDLColumn = class(TObject, IFluentDDLColumn)
  strict private
    FName: string;
    FLogicalType: TDDLLogicalType;
    FTypeArg: Integer;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer = 0);
    function GetName: string;
    function GetLogicalType: TDDLLogicalType;
    function GetTypeArg: Integer;
  end;

  TFluentDDLBuilder = class(TInterfacedObject, IFluentDDLBuilder, IFluentDDLTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumns: TObjectList<TFluentDDLColumn>;
    function _AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLBuilder;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    destructor Destroy; override;
    { IFluentDDLTableDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnCount: Integer;
    function GetColumn(AIndex: Integer): IFluentDDLColumn;
    { IFluentDDLBuilder }
    function ColumnInteger(const AName: string): IFluentDDLBuilder;
    function ColumnBigInt(const AName: string): IFluentDDLBuilder;
    function ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLBuilder;
    function ColumnBoolean(const AName: string): IFluentDDLBuilder;
    function ColumnDate(const AName: string): IFluentDDLBuilder;
    function ColumnDateTime(const AName: string): IFluentDDLBuilder;
    function ColumnLongText(const AName: string): IFluentDDLBuilder;
    function ColumnBlob(const AName: string): IFluentDDLBuilder;
    function AsString: string;
  end;

  TFluentDDLDropBuilder = class(TInterfacedObject, IFluentDDLDropBuilder, IFluentDDLDropTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    { IFluentDDLDropTableDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropBuilder }
    function IfExists: IFluentDDLDropBuilder;
    function AsString: string;
  end;

  TFluentDDLAlterTableAddBuilder = class(TInterfacedObject, IFluentDDLAlterTableAddBuilder, IFluentDDLAlterTableAddColumnDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumn: TFluentDDLColumn;
    FHasColumn: Boolean;
    function _AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAddBuilder;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    destructor Destroy; override;
    { IFluentDDLAlterTableAddColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumn: IFluentDDLColumn;
    { IFluentDDLAlterTableAddBuilder }
    function ColumnInteger(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnBigInt(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLAlterTableAddBuilder;
    function ColumnBoolean(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnDate(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnDateTime(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnLongText(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnBlob(const AName: string): IFluentDDLAlterTableAddBuilder;
    function AsString: string;
  end;

  TFluentDDLAlterTableDropBuilder = class(TInterfacedObject, IFluentDDLAlterTableDropBuilder, IFluentDDLAlterTableDropColumnDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumnName: string;
    FHasDrop: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    { IFluentDDLAlterTableDropColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnName: string;
    { IFluentDDLAlterTableDropBuilder }
    function DropColumn(const AName: string): IFluentDDLAlterTableDropBuilder;
    function AsString: string;
  end;

  TFluentDDLCreateIndexBuilder = class(TInterfacedObject, IFluentDDLCreateIndexBuilder, IFluentDDLCreateIndexDef)
  strict private
    FDialect: TFluentSQLDriver;
    FIndexName: string;
    FTableName: string;
    FUnique: Boolean;
    FColumns: TList<string>;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AIndexName, ATableName: string);
    destructor Destroy; override;
    { IFluentDDLCreateIndexDef }
    function GetDialect: TFluentSQLDriver;
    function GetIndexName: string;
    function GetTableName: string;
    function GetIsUnique: Boolean;
    function GetColumnCount: Integer;
    function GetColumnName(AIndex: Integer): string;
    { IFluentDDLCreateIndexBuilder }
    function Column(const AName: string): IFluentDDLCreateIndexBuilder;
    function Unique: IFluentDDLCreateIndexBuilder;
    function AsString: string;
  end;

  TFluentDDLDropIndexBuilder = class(TInterfacedObject, IFluentDDLDropIndexBuilder, IFluentDDLDropIndexDef)
  strict private
    FDialect: TFluentSQLDriver;
    FIndexName: string;
    FIfExists: Boolean;
    FConcurrently: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AIndexName: string);
    { IFluentDDLDropIndexDef }
    function GetDialect: TFluentSQLDriver;
    function GetIndexName: string;
    function GetIfExists: Boolean;
    function GetConcurrently: Boolean;
    { IFluentDDLDropIndexBuilder }
    function IfExists: IFluentDDLDropIndexBuilder;
    function Concurrently: IFluentDDLDropIndexBuilder;
    function AsString: string;
  end;

function NewFluentDDLTable(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLBuilder;
function NewFluentDDLDropTable(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLDropBuilder;
function NewFluentDDLAlterTableAddColumn(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLAlterTableAddBuilder;
function NewFluentDDLAlterTableDropColumn(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLAlterTableDropBuilder;
function NewFluentDDLCreateIndex(const ADialect: TFluentSQLDriver; const AIndexName, ATableName: string): IFluentDDLCreateIndexBuilder;
function NewFluentDDLDropIndex(const ADialect: TFluentSQLDriver; const AIndexName: string): IFluentDDLDropIndexBuilder;

implementation

uses
  FluentSQL.DDL.Serialize;

{ TFluentDDLColumn }

constructor TFluentDDLColumn.Create(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer);
begin
  inherited Create;
  FName := AName;
  FLogicalType := ALogicalType;
  FTypeArg := ATypeArg;
end;

function TFluentDDLColumn.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID, IInterface) or IsEqualGUID(IID, IFluentDDLColumn) then
  begin
    Pointer(Obj) := Self;
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TFluentDDLColumn._AddRef: Integer;
begin
  Result := -1;
end;

function TFluentDDLColumn._Release: Integer;
begin
  Result := -1;
end;

function TFluentDDLColumn.GetName: string;
begin
  Result := FName;
end;

function TFluentDDLColumn.GetLogicalType: TDDLLogicalType;
begin
  Result := FLogicalType;
end;

function TFluentDDLColumn.GetTypeArg: Integer;
begin
  Result := FTypeArg;
end;

{ TFluentDDLBuilder }

constructor TFluentDDLBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FColumns := TObjectList<TFluentDDLColumn>.Create(True);
end;

destructor TFluentDDLBuilder.Destroy;
begin
  FColumns.Free;
  inherited;
end;

function TFluentDDLBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLBuilder.GetColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TFluentDDLBuilder.GetColumn(AIndex: Integer): IFluentDDLColumn;
begin
  Result := FColumns[AIndex];
end;

function TFluentDDLBuilder._AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLBuilder;
begin
  FColumns.Add(TFluentDDLColumn.Create(AName, ALogicalType, ATypeArg));
  Result := Self;
end;

function TFluentDDLBuilder.ColumnInteger(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltInteger, 0);
end;

function TFluentDDLBuilder.ColumnBigInt(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltBigInt, 0);
end;

function TFluentDDLBuilder.ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLBuilder;
begin
  if ALength <= 0 then
    raise EArgumentException.Create('ColumnVarChar: ALength must be > 0');
  Result := _AddColumn(AName, dltVarChar, ALength);
end;

function TFluentDDLBuilder.ColumnBoolean(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltBoolean, 0);
end;

function TFluentDDLBuilder.ColumnDate(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltDate, 0);
end;

function TFluentDDLBuilder.ColumnDateTime(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltDateTime, 0);
end;

function TFluentDDLBuilder.ColumnLongText(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltLongText, 0);
end;

function TFluentDDLBuilder.ColumnBlob(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltBlob, 0);
end;

function TFluentDDLBuilder.AsString: string;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if FColumns.Count = 0 then
    raise EArgumentException.Create('DDL: at least one column is required');
  Result := DDLCreateTableSQL(Self as IFluentDDLTableDef);
end;

function NewFluentDDLTable(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLBuilder;
begin
  Result := TFluentDDLBuilder.Create(ADialect, ATableName);
end;

{ TFluentDDLDropBuilder }

constructor TFluentDDLDropBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FIfExists := False;
end;

function TFluentDDLDropBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLDropBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropBuilder.IfExists: IFluentDDLDropBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropBuilder.AsString: string;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  Result := DDLDropTableSQL(Self as IFluentDDLDropTableDef);
end;

function NewFluentDDLDropTable(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLDropBuilder;
begin
  Result := TFluentDDLDropBuilder.Create(ADialect, ATableName);
end;

{ TFluentDDLAlterTableAddBuilder }

constructor TFluentDDLAlterTableAddBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FColumn := nil;
  FHasColumn := False;
end;

destructor TFluentDDLAlterTableAddBuilder.Destroy;
begin
  FColumn.Free;
  inherited;
end;

function TFluentDDLAlterTableAddBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLAlterTableAddBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLAlterTableAddBuilder.GetColumn: IFluentDDLColumn;
begin
  if FHasColumn then
    Result := FColumn
  else
    Result := nil;
end;

function TFluentDDLAlterTableAddBuilder._AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    raise EArgumentException.Create(
      'DDL ALTER TABLE ADD COLUMN: only one logical column per AsString in this build (ESP-019).');
  if Trim(AName) = '' then
    raise EArgumentException.Create('DDL: column name is required');
  FColumn := TFluentDDLColumn.Create(AName, ALogicalType, ATypeArg);
  FHasColumn := True;
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.ColumnInteger(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltInteger, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnBigInt(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltBigInt, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLAlterTableAddBuilder;
begin
  if ALength <= 0 then
    raise EArgumentException.Create('ColumnVarChar: ALength must be > 0');
  Result := _AddColumn(AName, dltVarChar, ALength);
end;

function TFluentDDLAlterTableAddBuilder.ColumnBoolean(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltBoolean, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnDate(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltDate, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnDateTime(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltDateTime, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnLongText(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltLongText, 0);
end;

function TFluentDDLAlterTableAddBuilder.ColumnBlob(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltBlob, 0);
end;

function TFluentDDLAlterTableAddBuilder.AsString: string;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not FHasColumn then
    raise EArgumentException.Create('DDL ALTER TABLE: a column definition is required');
  Result := DDLAlterTableAddColumnSQL(Self as IFluentDDLAlterTableAddColumnDef);
end;

function NewFluentDDLAlterTableAddColumn(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := TFluentDDLAlterTableAddBuilder.Create(ADialect, ATableName);
end;

{ TFluentDDLAlterTableDropBuilder }

constructor TFluentDDLAlterTableDropBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FColumnName := '';
  FHasDrop := False;
end;

function TFluentDDLAlterTableDropBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLAlterTableDropBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLAlterTableDropBuilder.GetColumnName: string;
begin
  if FHasDrop then
    Result := FColumnName
  else
    Result := '';
end;

function TFluentDDLAlterTableDropBuilder.DropColumn(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  if FHasDrop then
    raise EArgumentException.Create(
      'DDL ALTER TABLE DROP COLUMN: only one column target per AsString in this build (ESP-020).');
  if Trim(AName) = '' then
    raise EArgumentException.Create('DDL: column name is required');
  FColumnName := AName;
  FHasDrop := True;
  Result := Self;
end;

function TFluentDDLAlterTableDropBuilder.AsString: string;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not FHasDrop then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');
  Result := DDLAlterTableDropColumnSQL(Self as IFluentDDLAlterTableDropColumnDef);
end;

function NewFluentDDLAlterTableDropColumn(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := TFluentDDLAlterTableDropBuilder.Create(ADialect, ATableName);
end;

{ TFluentDDLCreateIndexBuilder }

constructor TFluentDDLCreateIndexBuilder.Create(const ADialect: TFluentSQLDriver;
  const AIndexName, ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FIndexName := AIndexName;
  FTableName := ATableName;
  FUnique := False;
  FColumns := TList<string>.Create;
end;

destructor TFluentDDLCreateIndexBuilder.Destroy;
begin
  FColumns.Free;
  inherited;
end;

function TFluentDDLCreateIndexBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLCreateIndexBuilder.GetIndexName: string;
begin
  Result := FIndexName;
end;

function TFluentDDLCreateIndexBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLCreateIndexBuilder.GetIsUnique: Boolean;
begin
  Result := FUnique;
end;

function TFluentDDLCreateIndexBuilder.GetColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TFluentDDLCreateIndexBuilder.GetColumnName(AIndex: Integer): string;
begin
  Result := FColumns[AIndex];
end;

function TFluentDDLCreateIndexBuilder.Column(const AName: string): IFluentDDLCreateIndexBuilder;
begin
  if Trim(AName) = '' then
    raise EArgumentException.Create('DDL: column name is required');
  FColumns.Add(AName);
  Result := Self;
end;

function TFluentDDLCreateIndexBuilder.Unique: IFluentDDLCreateIndexBuilder;
begin
  if FUnique then
    raise EArgumentException.Create(
      'DDL CREATE INDEX: UNIQUE can only be specified once per AsString in this build (ESP-022).');
  FUnique := True;
  Result := Self;
end;

function TFluentDDLCreateIndexBuilder.AsString: string;
begin
  if Trim(FIndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if FColumns.Count = 0 then
    raise EArgumentException.Create('DDL CREATE INDEX: at least one column is required');
  Result := DDLCreateIndexSQL(Self as IFluentDDLCreateIndexDef);
end;

function NewFluentDDLCreateIndex(const ADialect: TFluentSQLDriver; const AIndexName, ATableName: string): IFluentDDLCreateIndexBuilder;
begin
  Result := TFluentDDLCreateIndexBuilder.Create(ADialect, AIndexName, ATableName);
end;

{ TFluentDDLDropIndexBuilder }

constructor TFluentDDLDropIndexBuilder.Create(const ADialect: TFluentSQLDriver; const AIndexName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FIndexName := AIndexName;
  FIfExists := False;
  FConcurrently := False;
end;

function TFluentDDLDropIndexBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropIndexBuilder.GetIndexName: string;
begin
  Result := FIndexName;
end;

function TFluentDDLDropIndexBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropIndexBuilder.IfExists: IFluentDDLDropIndexBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropIndexBuilder.GetConcurrently: Boolean;
begin
  Result := FConcurrently;
end;

function TFluentDDLDropIndexBuilder.Concurrently: IFluentDDLDropIndexBuilder;
begin
  FConcurrently := True;
  Result := Self;
end;

function TFluentDDLDropIndexBuilder.AsString: string;
begin
  if Trim(FIndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');
  Result := DDLDropIndexSQL(Self as IFluentDDLDropIndexDef);
end;

function NewFluentDDLDropIndex(const ADialect: TFluentSQLDriver; const AIndexName: string): IFluentDDLDropIndexBuilder;
begin
  Result := TFluentDDLDropIndexBuilder.Create(ADialect, AIndexName);
end;

end.
