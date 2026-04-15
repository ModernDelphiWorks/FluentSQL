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
    FNotNull: Boolean;
    FPrimaryKey: Boolean;
    FUnique: Boolean;
    FCheckCondition: string;
    FDefaultValue: string;
    FComputedExpression: string;
    FIdentity: Boolean;
    FReferenceTable: string;
    FReferenceColumn: string;
    FDescription: string;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer = 0);
    function GetName: string;
    function GetLogicalType: TDDLLogicalType;
    function GetTypeArg: Integer;
    function GetNotNull: Boolean;
    function GetIsPrimaryKey: Boolean;
    function GetIsUnique: Boolean;
    function GetCheckCondition: string;
    function GetDefaultValue: string;
    function GetComputedExpression: string;
    function GetIsIdentity: Boolean;
    function GetReferenceTable: string;
    function GetReferenceColumn: string;
    function GetDescription: string;
    procedure SetNotNull(AValue: Boolean);
    procedure SetPrimaryKey(AValue: Boolean);
    procedure SetUnique(AValue: Boolean);
    procedure SetCheck(const ACondition: string);
    procedure SetDefaultValue(const AValue: string);
    procedure SetComputedBy(const AExpr: string);
    procedure SetIdentity(AValue: Boolean);
    procedure SetReferences(const ATableName, AColumnName: string);
    procedure SetDescription(const AText: string);
  end;

  TFluentDDLBuilder = class(TInterfacedObject, IFluentDDLBuilder, IFluentDDLTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FDescription: string;
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
    function GetDescription: string;
    { IFluentDDLBuilder }
    function ColumnInteger(const AName: string): IFluentDDLBuilder;
    function ColumnBigInt(const AName: string): IFluentDDLBuilder;
    function ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLBuilder;
    function ColumnBoolean(const AName: string): IFluentDDLBuilder;
    function ColumnDate(const AName: string): IFluentDDLBuilder;
    function ColumnDateTime(const AName: string): IFluentDDLBuilder;
    function ColumnLongText(const AName: string): IFluentDDLBuilder;
    function ColumnBlob(const AName: string): IFluentDDLBuilder;
    function ColumnGuid(const AName: string): IFluentDDLBuilder;
    function NotNull: IFluentDDLBuilder;
    function PrimaryKey: IFluentDDLBuilder;
    function Unique: IFluentDDLBuilder;
    function Check(const ACondition: string): IFluentDDLBuilder;
    function DefaultValue(const AValue: string): IFluentDDLBuilder;
    function ComputedBy(const AExpr: string): IFluentDDLBuilder;
    function Identity: IFluentDDLBuilder;
    function References(const ATableName, AColumnName: string): IFluentDDLBuilder;
    function Description(const AText: string): IFluentDDLBuilder;
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
    function ColumnGuid(const AName: string): IFluentDDLAlterTableAddBuilder;
    function NotNull: IFluentDDLAlterTableAddBuilder;
    function PrimaryKey: IFluentDDLAlterTableAddBuilder;
    function Unique: IFluentDDLAlterTableAddBuilder;
    function Check(const ACondition: string): IFluentDDLAlterTableAddBuilder;
    function DefaultValue(const AValue: string): IFluentDDLAlterTableAddBuilder;
    function ComputedBy(const AExpr: string): IFluentDDLAlterTableAddBuilder;
    function Identity: IFluentDDLAlterTableAddBuilder;
    function References(const ATableName, AColumnName: string): IFluentDDLAlterTableAddBuilder;
    function Description(const AText: string): IFluentDDLAlterTableAddBuilder;
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

  TFluentDDLAlterTableRenameColumnBuilder = class(TInterfacedObject, IFluentDDLAlterTableRenameColumnBuilder,
    IFluentDDLAlterTableRenameColumnDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FOldColumnName: string;
    FNewColumnName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName, AOldColumnName, ANewColumnName: string);
    { IFluentDDLAlterTableRenameColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetOldColumnName: string;
    function GetNewColumnName: string;
    { IFluentDDLAlterTableRenameColumnBuilder }
    function AsString: string;
  end;

  TFluentDDLAlterTableRenameTableBuilder = class(TInterfacedObject, IFluentDDLAlterTableRenameTableBuilder,
    IFluentDDLAlterTableRenameTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FOldTableName: string;
    FNewTableName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AOldTableName, ANewTableName: string);
    { IFluentDDLAlterTableRenameTableDef }
    function GetDialect: TFluentSQLDriver;
    function GetOldTableName: string;
    function GetNewTableName: string;
    { IFluentDDLAlterTableRenameTableBuilder }
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
    FTableName: string;
    FIfExists: Boolean;
    FConcurrently: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AIndexName: string);
    { IFluentDDLDropIndexDef }
    function GetDialect: TFluentSQLDriver;
    function GetIndexName: string;
    function GetTableName: string;
    function GetIfExists: Boolean;
    function GetConcurrently: Boolean;
    { IFluentDDLDropIndexBuilder }
    function OnTable(const ATable: string): IFluentDDLDropIndexBuilder;
    function IfExists: IFluentDDLDropIndexBuilder;
    function Concurrently: IFluentDDLDropIndexBuilder;
    function AsString: string;
  end;

  TFluentDDLTruncateTableBuilder = class(TInterfacedObject, IFluentDDLTruncateTableBuilder, IFluentDDLTruncateTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FRestartIdentity: Boolean;
    FCascade: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    { IFluentDDLTruncateTableDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetRestartIdentity: Boolean;
    function GetCascade: Boolean;
    { IFluentDDLTruncateTableBuilder }
    function RestartIdentity: IFluentDDLTruncateTableBuilder;
    function Cascade: IFluentDDLTruncateTableBuilder;
    function AsString: string;
  end;

  TFluentDDLAlterTableAlterColumnBuilder = class(TInterfacedObject, IFluentDDLAlterTableAlterColumnBuilder,
    IFluentDDLAlterTableAlterColumnDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumnName: string;
    FLogicalType: TDDLLogicalType;
    FTypeArg: Integer;
    FNotNull: Boolean;
    FTypeChanged: Boolean;
    FNullabilityChanged: Boolean;
    function _SetType(ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAlterColumnBuilder;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName, AColumnName: string);
    { IFluentDDLAlterTableAlterColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnName: string;
    function GetLogicalType: TDDLLogicalType;
    function GetTypeArg: Integer;
    function GetNotNull: Boolean;
    function GetTypeChanged: Boolean;
    function GetNullabilityChanged: Boolean;
    { IFluentDDLAlterTableAlterColumnBuilder }
    function TypeInteger: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeSmallInt: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeVarchar(ALength: Integer): IFluentDDLAlterTableAlterColumnBuilder;
    function TypeBoolean: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeDate: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeDateTime: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeBigInt: IFluentDDLAlterTableAlterColumnBuilder;
    function TypeGuid: IFluentDDLAlterTableAlterColumnBuilder;
    function NotNull: IFluentDDLAlterTableAlterColumnBuilder;
    function Nullable: IFluentDDLAlterTableAlterColumnBuilder;
    function AsString: string;
  end;

  TFluentDDLCreateViewBuilder = class(TInterfacedObject, IFluentDDLCreateViewBuilder, IFluentDDLCreateViewDef)
  strict private
    FDialect: TFluentSQLDriver;
    FViewName: string;
    FQuery: IFluentSQL;
    FOrReplace: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AViewName: string);
    { IFluentDDLCreateViewDef }
    function GetDialect: TFluentSQLDriver;
    function GetViewName: string;
    function GetQuery: IFluentSQL;
    function GetOrReplace: Boolean;
    { IFluentDDLCreateViewBuilder }
    function OrReplace: IFluentDDLCreateViewBuilder;
    function As(const AQuery: IFluentSQL): IFluentDDLCreateViewBuilder;
    function AsString: string;
  end;

  TFluentDDLDropViewBuilder = class(TInterfacedObject, IFluentDDLDropViewBuilder, IFluentDDLDropViewDef)
  strict private
    FDialect: TFluentSQLDriver;
    FViewName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AViewName: string);
    { IFluentDDLDropViewDef }
    function GetDialect: TFluentSQLDriver;
    function GetViewName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropViewBuilder }
    function IfExists: IFluentDDLDropViewBuilder;
    function AsString: string;
  end;

  TFluentSchema = class(TInterfacedObject, IFluentSchema)
  strict private
    FDialect: TFluentSQLDriver;
  public
    constructor Create(const ADialect: TFluentSQLDriver);
    function CreateTable(const ATableName: string): IFluentDDLBuilder;
    function DropTable(const ATableName: string): IFluentDDLDropBuilder;
    function AlterTableAdd(const ATableName: string): IFluentDDLAlterTableAddBuilder;
    function AlterTableDrop(const ATableName: string): IFluentDDLAlterTableDropBuilder;
    function AlterTableRename(const ATableName, AOldColumnName, ANewColumnName: string): IFluentDDLAlterTableRenameColumnBuilder; overload;
    function AlterTableRename(const AOldTableName, ANewTableName: string): IFluentDDLAlterTableRenameTableBuilder; overload;
    function AlterTableAlter(const ATableName, AColumnName: string): IFluentDDLAlterTableAlterColumnBuilder;
    function CreateIndex(const AIndexName, ATableName: string): IFluentDDLCreateIndexBuilder;
    function DropIndex(const AIndexName: string): IFluentDDLDropIndexBuilder;
    function TruncateTable(const ATableName: string): IFluentDDLTruncateTableBuilder;
    function CreateView(const AName: string): IFluentDDLCreateViewBuilder;
    function DropView(const AName: string): IFluentDDLDropViewBuilder;
  end;


implementation

uses
  FluentSQL.DDL.Serialize;

const
  S_OK = 0;
  E_NOINTERFACE = HResult($80004002);

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

function TFluentDDLColumn.GetComputedExpression: string;
begin
  Result := FComputedExpression;
end;

function TFluentDDLColumn.GetIsIdentity: Boolean;
begin
  Result := FIdentity;
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

function TFluentDDLColumn.GetNotNull: Boolean;
begin
  Result := FNotNull;
end;

function TFluentDDLColumn.GetIsPrimaryKey: Boolean;
begin
  Result := FPrimaryKey;
end;

function TFluentDDLColumn.GetIsUnique: Boolean;
begin
  Result := FUnique;
end;

function TFluentDDLColumn.GetCheckCondition: string;
begin
  Result := FCheckCondition;
end;

function TFluentDDLColumn.GetDefaultValue: string;
begin
  Result := FDefaultValue;
end;

function TFluentDDLColumn.GetReferenceTable: string;
begin
  Result := FReferenceTable;
end;

function TFluentDDLColumn.GetReferenceColumn: string;
begin
  Result := FReferenceColumn;
end;

function TFluentDDLColumn.GetDescription: string;
begin
  Result := FDescription;
end;

procedure TFluentDDLColumn.SetNotNull(AValue: Boolean);
begin
  FNotNull := AValue;
end;

procedure TFluentDDLColumn.SetPrimaryKey(AValue: Boolean);
begin
  FPrimaryKey := AValue;
end;

procedure TFluentDDLColumn.SetUnique(AValue: Boolean);
begin
  FUnique := AValue;
end;

procedure TFluentDDLColumn.SetCheck(const ACondition: string);
begin
  FCheckCondition := ACondition;
end;

procedure TFluentDDLColumn.SetDefaultValue(const AValue: string);
begin
  if (AValue <> '') and (FComputedExpression <> '') then
    raise EArgumentException.Create('DDL: A column cannot have both DefaultValue and ComputedBy.');
  FDefaultValue := AValue;
end;

procedure TFluentDDLColumn.SetComputedBy(const AExpr: string);
begin
  if (AExpr <> '') and (FDefaultValue <> '') then
    raise EArgumentException.Create('DDL: A column cannot have both DefaultValue and ComputedBy.');
  FComputedExpression := AExpr;
end;

procedure TFluentDDLColumn.SetIdentity(AValue: Boolean);
begin
  if AValue and not (FLogicalType in [dltInteger, dltBigInt]) then
    raise EArgumentException.Create('DDL: .Identity can only be used on Integer or BigInt columns.');
  FIdentity := AValue;
end;

procedure TFluentDDLColumn.SetReferences(const ATableName, AColumnName: string);
begin
  FReferenceTable := ATableName;
  FReferenceColumn := AColumnName;
end;

procedure TFluentDDLColumn.SetDescription(const AText: string);
begin
  FDescription := AText;
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

function TFluentDDLBuilder.GetDescription: string;
begin
  Result := FDescription;
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

function TFluentDDLBuilder.ColumnGuid(const AName: string): IFluentDDLBuilder;
begin
  Result := _AddColumn(AName, dltGuid, 0);
end;

function TFluentDDLBuilder.NotNull: IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetNotNull(True);
  Result := Self;
end;

function TFluentDDLBuilder.PrimaryKey: IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetPrimaryKey(True);
  Result := Self;
end;

function TFluentDDLBuilder.Unique: IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetUnique(True);
  Result := Self;
end;

function TFluentDDLBuilder.Check(const ACondition: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetCheck(ACondition);
  Result := Self;
end;

function TFluentDDLBuilder.DefaultValue(const AValue: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetDefaultValue(AValue);
  Result := Self;
end;

function TFluentDDLBuilder.ComputedBy(const AExpr: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetComputedBy(AExpr);
  Result := Self;
end;

function TFluentDDLBuilder.Identity: IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetIdentity(True);
  Result := Self;
end;

function TFluentDDLBuilder.References(const ATableName, AColumnName: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetReferences(ATableName, AColumnName);
  Result := Self;
end;

function TFluentDDLBuilder.Description(const AText: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetDescription(AText)
  else
    FDescription := AText;
  Result := Self;
end;

function TFluentDDLBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if FColumns.Count = 0 then
    raise EArgumentException.Create('DDL: at least one column is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateTable(Self as IFluentDDLTableDef);
  finally
    LSerializer.Free;
  end;
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
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropTable(Self as IFluentDDLDropTableDef);
  finally
    LSerializer.Free;
  end;
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

function TFluentDDLAlterTableAddBuilder.ColumnGuid(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := _AddColumn(AName, dltGuid, 0);
end;

function TFluentDDLAlterTableAddBuilder.NotNull: IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetNotNull(True);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.PrimaryKey: IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetPrimaryKey(True);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Unique: IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetUnique(True);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Check(const ACondition: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetCheck(ACondition);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.DefaultValue(const AValue: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetDefaultValue(AValue);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.ComputedBy(const AExpr: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetComputedBy(AExpr);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Identity: IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetIdentity(True);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.References(const ATableName, AColumnName: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetReferences(ATableName, AColumnName);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Description(const AText: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetDescription(AText);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not FHasColumn then
    raise EArgumentException.Create('DDL ALTER TABLE: a column definition is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.AlterTableAddColumn(Self as IFluentDDLAlterTableAddColumnDef);
  finally
    LSerializer.Free;
  end;
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
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not FHasDrop then
    raise EArgumentException.Create('DDL ALTER TABLE DROP COLUMN: a column target is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.AlterTableDropColumn(Self as IFluentDDLAlterTableDropColumnDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLAlterTableRenameColumnBuilder }

constructor TFluentDDLAlterTableRenameColumnBuilder.Create(const ADialect: TFluentSQLDriver;
  const ATableName, AOldColumnName, ANewColumnName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := Trim(ATableName);
  FOldColumnName := Trim(AOldColumnName);
  FNewColumnName := Trim(ANewColumnName);
end;

function TFluentDDLAlterTableRenameColumnBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLAlterTableRenameColumnBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLAlterTableRenameColumnBuilder.GetOldColumnName: string;
begin
  Result := FOldColumnName;
end;

function TFluentDDLAlterTableRenameColumnBuilder.GetNewColumnName: string;
begin
  Result := FNewColumnName;
end;

function TFluentDDLAlterTableRenameColumnBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if Trim(FOldColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: old column name is required');
  if Trim(FNewColumnName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: new column name is required');
  if SameText(Trim(FOldColumnName), Trim(FNewColumnName)) then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: old and new names must be different');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.AlterTableRenameColumn(Self as IFluentDDLAlterTableRenameColumnDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLAlterTableRenameTableBuilder }

constructor TFluentDDLAlterTableRenameTableBuilder.Create(const ADialect: TFluentSQLDriver; const AOldTableName,
  ANewTableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FOldTableName := Trim(AOldTableName);
  FNewTableName := Trim(ANewTableName);
end;

function TFluentDDLAlterTableRenameTableBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLAlterTableRenameTableBuilder.GetNewTableName: string;
begin
  Result := FNewTableName;
end;

function TFluentDDLAlterTableRenameTableBuilder.GetOldTableName: string;
begin
  Result := FOldTableName;
end;

function TFluentDDLAlterTableRenameTableBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FOldTableName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: old table name is required');
  if Trim(FNewTableName) = '' then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: new table name is required');
  if SameText(Trim(FOldTableName), Trim(FNewTableName)) then
    raise EArgumentException.Create('DDL ALTER TABLE RENAME: old and new names must be different');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.AlterTableRenameTable(Self as IFluentDDLAlterTableRenameTableDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLAlterTableAlterColumnBuilder }

constructor TFluentDDLAlterTableAlterColumnBuilder.Create(const ADialect: TFluentSQLDriver;
  const ATableName, AColumnName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := Trim(ATableName);
  FColumnName := Trim(AColumnName);
  FTypeChanged := False;
  FNullabilityChanged := False;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetColumnName: string;
begin
  Result := FColumnName;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetLogicalType: TDDLLogicalType;
begin
  Result := FLogicalType;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetTypeArg: Integer;
begin
  Result := FTypeArg;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetNotNull: Boolean;
begin
  Result := FNotNull;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetTypeChanged: Boolean;
begin
  Result := FTypeChanged;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetNullabilityChanged: Boolean;
begin
  Result := FNullabilityChanged;
end;

function TFluentDDLAlterTableAlterColumnBuilder._SetType(ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAlterColumnBuilder;
begin
  FLogicalType := ALogicalType;
  FTypeArg := ATypeArg;
  FTypeChanged := True;
  Result := Self;
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeInteger: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltInteger, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeSmallInt: IFluentDDLAlterTableAlterColumnBuilder;
begin
  // SmallInt is mapped to Integer in TDDLLogicalType for now, or we define dltSmallInt?
  // Checking TDDLLogicalType in Interfaces... it doesn't have SmallInt.
  // ESP said to support TypeSmallInt. I'll map to dltInteger for now or check if I should add to enum.
  // Actually, let's stick to what's in TDDLLogicalType.
  Result := _SetType(dltInteger, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeVarchar(ALength: Integer): IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltVarChar, ALength);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeBoolean: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltBoolean, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeDate: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltDate, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeDateTime: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltDateTime, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeBigInt: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltBigInt, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.TypeGuid: IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := _SetType(dltGuid, 0);
end;

function TFluentDDLAlterTableAlterColumnBuilder.NotNull: IFluentDDLAlterTableAlterColumnBuilder;
begin
  FNotNull := True;
  FNullabilityChanged := True;
  Result := Self;
end;

function TFluentDDLAlterTableAlterColumnBuilder.Nullable: IFluentDDLAlterTableAlterColumnBuilder;
begin
  FNotNull := False;
  FNullabilityChanged := True;
  Result := Self;
end;

function TFluentDDLAlterTableAlterColumnBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if Trim(FColumnName) = '' then
    raise EArgumentException.Create('DDL: column name is required');
  if not (FTypeChanged or FNullabilityChanged) then
    raise EArgumentException.Create('DDL ALTER TABLE ALTER COLUMN: at least one change (type or nullability) is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.AlterTableAlterColumn(Self as IFluentDDLAlterTableAlterColumnDef);
  finally
    LSerializer.Free;
  end;
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
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FIndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if FColumns.Count = 0 then
    raise EArgumentException.Create('DDL CREATE INDEX: at least one column is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateIndex(Self as IFluentDDLCreateIndexDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropIndexBuilder }

constructor TFluentDDLDropIndexBuilder.Create(const ADialect: TFluentSQLDriver; const AIndexName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FIndexName := AIndexName;
  FTableName := '';
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

function TFluentDDLDropIndexBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLDropIndexBuilder.OnTable(const ATable: string): IFluentDDLDropIndexBuilder;
begin
  FTableName := Trim(ATable);
  Result := Self;
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
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FIndexName) = '' then
    raise EArgumentException.Create('DDL: index name is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropIndex(Self as IFluentDDLDropIndexDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLTruncateTableBuilder }

constructor TFluentDDLTruncateTableBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FRestartIdentity := False;
  FCascade := False;
end;

function TFluentDDLTruncateTableBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLTruncateTableBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLTruncateTableBuilder.GetRestartIdentity: Boolean;
begin
  Result := FRestartIdentity;
end;

function TFluentDDLTruncateTableBuilder.GetCascade: Boolean;
begin
  Result := FCascade;
end;

function TFluentDDLTruncateTableBuilder.RestartIdentity: IFluentDDLTruncateTableBuilder;
begin
  FRestartIdentity := True;
  Result := Self;
end;

function TFluentDDLTruncateTableBuilder.Cascade: IFluentDDLTruncateTableBuilder;
begin
  FCascade := True;
  Result := Self;
end;

function TFluentDDLTruncateTableBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.TruncateTable(Self as IFluentDDLTruncateTableDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLCreateViewBuilder }

constructor TFluentDDLCreateViewBuilder.Create(const ADialect: TFluentSQLDriver; const AViewName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FViewName := AViewName;
  FQuery := nil;
  FOrReplace := False;
end;

function TFluentDDLCreateViewBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLCreateViewBuilder.GetViewName: string;
begin
  Result := FViewName;
end;

function TFluentDDLCreateViewBuilder.GetQuery: IFluentSQL;
begin
  Result := FQuery;
end;

function TFluentDDLCreateViewBuilder.GetOrReplace: Boolean;
begin
  Result := FOrReplace;
end;

function TFluentDDLCreateViewBuilder.OrReplace: IFluentDDLCreateViewBuilder;
begin
  FOrReplace := True;
  Result := Self;
end;

function TFluentDDLCreateViewBuilder.As(const AQuery: IFluentSQL): IFluentDDLCreateViewBuilder;
begin
  FQuery := AQuery;
  Result := Self;
end;

function TFluentDDLCreateViewBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FViewName) = '' then
    raise EArgumentException.Create('DDL: view name is required');
  if FQuery = nil then
    raise EArgumentException.Create('DDL: view query is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateView(Self as IFluentDDLCreateViewDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropViewBuilder }

constructor TFluentDDLDropViewBuilder.Create(const ADialect: TFluentSQLDriver; const AViewName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FViewName := AViewName;
  FIfExists := False;
end;

function TFluentDDLDropViewBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropViewBuilder.GetViewName: string;
begin
  Result := FViewName;
end;

function TFluentDDLDropViewBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropViewBuilder.IfExists: IFluentDDLDropViewBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropViewBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FViewName) = '' then
    raise EArgumentException.Create('DDL: view name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropView(Self as IFluentDDLDropViewDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentSchema }

constructor TFluentSchema.Create(const ADialect: TFluentSQLDriver);
begin
  FDialect := ADialect;
end;

function TFluentSchema.CreateTable(const ATableName: string): IFluentDDLBuilder;
begin
  Result := TFluentDDLBuilder.Create(FDialect, ATableName);
end;

function TFluentSchema.DropTable(const ATableName: string): IFluentDDLDropBuilder;
begin
  Result := TFluentDDLDropBuilder.Create(FDialect, ATableName);
end;

function TFluentSchema.AlterTableAdd(const ATableName: string): IFluentDDLAlterTableAddBuilder;
begin
  Result := TFluentDDLAlterTableAddBuilder.Create(FDialect, ATableName);
end;

function TFluentSchema.AlterTableDrop(const ATableName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := TFluentDDLAlterTableDropBuilder.Create(FDialect, ATableName);
end;

function TFluentSchema.AlterTableRename(const ATableName, AOldColumnName, ANewColumnName: string): IFluentDDLAlterTableRenameColumnBuilder;
begin
  Result := TFluentDDLAlterTableRenameColumnBuilder.Create(FDialect, ATableName, AOldColumnName, ANewColumnName);
end;

function TFluentSchema.AlterTableRename(const AOldTableName, ANewTableName: string): IFluentDDLAlterTableRenameTableBuilder;
begin
  Result := TFluentDDLAlterTableRenameTableBuilder.Create(FDialect, AOldTableName, ANewTableName);
end;

function TFluentSchema.AlterTableAlter(const ATableName, AColumnName: string): IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := TFluentDDLAlterTableAlterColumnBuilder.Create(FDialect, ATableName, AColumnName);
end;

function TFluentSchema.CreateIndex(const AIndexName, ATableName: string): IFluentDDLCreateIndexBuilder;
begin
  Result := TFluentDDLCreateIndexBuilder.Create(FDialect, AIndexName, ATableName);
end;

function TFluentSchema.DropIndex(const AIndexName: string): IFluentDDLDropIndexBuilder;
begin
  Result := TFluentDDLDropIndexBuilder.Create(FDialect, AIndexName);
end;

function TFluentSchema.TruncateTable(const ATableName: string): IFluentDDLTruncateTableBuilder;
begin
  Result := TFluentDDLTruncateTableBuilder.Create(FDialect, ATableName);
end;

function TFluentSchema.CreateView(const AName: string): IFluentDDLCreateViewBuilder;
begin
  Result := TFluentDDLCreateViewBuilder.Create(FDialect, AName);
end;

function TFluentSchema.DropView(const AName: string): IFluentDDLDropViewBuilder;
begin
  Result := TFluentDDLDropViewBuilder.Create(FDialect, AName);
end;

end.
