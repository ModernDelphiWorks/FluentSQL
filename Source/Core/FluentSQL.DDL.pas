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
    FIdentityScope: TDDLIdentityScope;
    FReferenceTable: string;
    FReferenceColumn: string;
    FDescription: string;
    FConstraintName: string;
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
    function GetIdentityScope: TDDLIdentityScope;
    function GetReferenceTable: string;
    function GetReferenceColumn: string;
    function GetDescription: string;
    function GetConstraintName: string;
    procedure SetNotNull(AValue: Boolean);
    procedure SetPrimaryKey(AValue: Boolean; const AName: string = '');
    procedure SetUnique(AValue: Boolean; const AName: string = '');
    procedure SetCheck(const ACondition: string; const AName: string = '');
    procedure SetDefaultValue(const AValue: string);
    procedure SetComputedBy(const AExpr: string);
    procedure SetIdentity(AValue: Boolean; AScope: TDDLIdentityScope = disAlways);
    procedure SetReferences(const ATableName, AColumnName: string);
    procedure SetDescription(const AText: string);
  end;

  /// <summary>ESP-055: concrete implementation of table-level constraints.</summary>
  TFluentDDLTableConstraint = class(TObject, IFluentDDLTableConstraint)
  strict private
    FName: string;
    FConstraintType: TDDLConstraintType;
    FColumns: TArray<string>;
    FCheckCondition: string;
    FReferenceTable: string;
    FReferenceColumn: string;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AName: string; AType: TDDLConstraintType; const AColumns: array of string); overload;
    constructor Create(const AName, ACheckCondition: string); overload;
    constructor Create(const AName: string; AType: TDDLConstraintType; const AColumn, ARefTable, ARefColumn: string); overload;
    function GetName: string;
    function GetConstraintType: TDDLConstraintType;
    function GetColumnCount: Integer;
    function GetColumnName(AIndex: Integer): string;
    function GetCheckCondition: string;
    function GetReferenceTable: string;
    function GetReferenceColumn: string;
  end;

  TFluentDDLBuilder = class(TInterfacedObject, IFluentDDLBuilder, IFluentDDLTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FDescription: string;
    FColumns: TObjectList<TFluentDDLColumn>;
    FTableConstraints: TObjectList<TFluentDDLTableConstraint>;
    FIsCapped: Boolean;
    FCappedSize: Int64;
    FCappedMax: Integer;
    function _AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLBuilder;
    procedure _CheckPKDuplicity;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    destructor Destroy; override;
    { IFluentDDLTableDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnCount: Integer;
    function GetColumn(AIndex: Integer): IFluentDDLColumn;
    function GetTableConstraintCount: Integer;
    function GetTableConstraint(AIndex: Integer): IFluentDDLTableConstraint;
    function GetIsCapped: Boolean;
    function GetCappedSize: Int64;
    function GetCappedMax: Integer;
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
    function PrimaryKey: IFluentDDLBuilder; overload;
    function PrimaryKey(const AName: string): IFluentDDLBuilder; overload;
    function PrimaryKey(const AColumns: array of string; const AName: string = ''): IFluentDDLBuilder; overload;
    function Unique: IFluentDDLBuilder; overload;
    function Unique(const AName: string): IFluentDDLBuilder; overload;
    function Unique(const AColumns: array of string; const AName: string = ''): IFluentDDLBuilder; overload;
    function Check(const ACondition: string; const AName: string = ''): IFluentDDLBuilder;
    function DefaultValue(const AValue: string): IFluentDDLBuilder;
    function ComputedBy(const AExpr: string): IFluentDDLBuilder;
    function Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLBuilder;
    function References(const ATableName, AColumnName: string): IFluentDDLBuilder;
    function Capped(ASize: Int64; AMaxDocs: Integer = 0): IFluentDDLBuilder;
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

  TFluentDDLAlterTableAddBuilder = class(TInterfacedObject, IFluentDDLAlterTableAddBuilder,
    IFluentDDLAlterTableAddColumnDef, IFluentDDLAlterTableAddConstraintDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumn: TFluentDDLColumn;
    FConstraint: TFluentDDLTableConstraint;
    FHasColumn: Boolean;
    FHasConstraint: Boolean;
    function _AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAddBuilder;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    destructor Destroy; override;
    { IFluentDDLAlterTableAddColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumn: IFluentDDLColumn;
    function GetConstraint: IFluentDDLTableConstraint;
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
    function PrimaryKey: IFluentDDLAlterTableAddBuilder; overload;
    function PrimaryKey(const AName: string): IFluentDDLAlterTableAddBuilder; overload;
    function Unique: IFluentDDLAlterTableAddBuilder; overload;
    function Unique(const AName: string): IFluentDDLAlterTableAddBuilder; overload;
    function Check(const ACondition: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
    function DefaultValue(const AValue: string): IFluentDDLAlterTableAddBuilder;
    function ComputedBy(const AExpr: string): IFluentDDLAlterTableAddBuilder;
    function Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLAlterTableAddBuilder;
    function References(const ATableName, AColumnName: string): IFluentDDLAlterTableAddBuilder;
    function Description(const AText: string): IFluentDDLAlterTableAddBuilder;
    function AsString: string;
    function AddPrimaryKey(const AColumns: array of string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
    function AddUnique(const AColumns: array of string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
    function AddForeignKey(const AColumn, ARefTable, ARefColumn: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
    function AddCheck(const ACondition: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
  end;

  TFluentDDLAlterTableDropBuilder = class(TInterfacedObject, IFluentDDLAlterTableDropBuilder,
    IFluentDDLAlterTableDropColumnDef, IFluentDDLAlterTableDropConstraintDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FColumnName: string;
    FConstraintName: string;
    FHasDropColumn: Boolean;
    FHasDropConstraint: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    { IFluentDDLAlterTableDropColumnDef }
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnName: string;
    { IFluentDDLAlterTableDropConstraintDef }
    function GetConstraintName: string;
    { IFluentDDLAlterTableDropBuilder }
    function DropColumn(const AName: string): IFluentDDLAlterTableDropBuilder;
    function DropConstraint(const AName: string): IFluentDDLAlterTableDropBuilder;
    function Column(const AName: string): IFluentDDLAlterTableDropBuilder;
    function Constraint(const AName: string): IFluentDDLAlterTableDropBuilder;
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
    FExpireAfter: Integer;
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
    function GetExpireAfter: Integer;
    { IFluentDDLCreateIndexBuilder }
    function Column(const AName: string): IFluentDDLCreateIndexBuilder;
    function Unique: IFluentDDLCreateIndexBuilder;
    function ExpireAfter(ASeconds: Integer): IFluentDDLCreateIndexBuilder;
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
    FDefaultValue: string;
    FDefaultSet: Boolean;
    FDefaultDropped: Boolean;
    FIdentity: Boolean;
    FIdentityScope: TDDLIdentityScope;
    FIdentityChanged: Boolean;
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
    function GetDefaultValue: string;
    function GetDefaultSet: Boolean;
    function GetDefaultDropped: Boolean;
    function GetIsIdentity: Boolean;
    function GetIdentityScope: TDDLIdentityScope;
    function GetIdentityChanged: Boolean;
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
    function SetDefault(const AValue: string): IFluentDDLAlterTableAlterColumnBuilder;
    function DropDefault: IFluentDDLAlterTableAlterColumnBuilder;
    function Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLAlterTableAlterColumnBuilder;
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
    function &As(const AQuery: IFluentSQL): IFluentDDLCreateViewBuilder;
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
  
  TFluentDDLCreateSequenceBuilder = class(TInterfacedObject, IFluentDDLCreateSequenceBuilder, IFluentDDLCreateSequenceDef)
  strict private
    FDialect: TFluentSQLDriver;
    FSequenceName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ASequenceName: string);
    { IFluentDDLCreateSequenceDef }
    function GetDialect: TFluentSQLDriver;
    function GetSequenceName: string;
    { IFluentDDLCreateSequenceBuilder }
    function AsString: string;
  end;

  TFluentDDLDropSequenceBuilder = class(TInterfacedObject, IFluentDDLDropSequenceBuilder, IFluentDDLDropSequenceDef)
  strict private
    FDialect: TFluentSQLDriver;
    FSequenceName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ASequenceName: string);
    { IFluentDDLDropSequenceDef }
    function GetDialect: TFluentSQLDriver;
    function GetSequenceName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropSequenceBuilder }
    function IfExists: IFluentDDLDropSequenceBuilder;
    function AsString: string;
  end;

  TFluentDDLFunctionBuilder = class(TInterfacedObject, IFluentDDLFunctionBuilder, IFluentDDLFunctionDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FParams: string;
    FReturns: string;
    FBody: string;
    FOrReplace: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLFunctionDef }
    function GetDialect: TFluentSQLDriver;
    function GetFunctionName: string;
    function GetParams: string;
    function GetReturns: string;
    function GetBody: string;
    function GetOrReplace: Boolean;
    { IFluentDDLFunctionBuilder }
    function Params(const AValue: string): IFluentDDLFunctionBuilder;
    function Returns(const AValue: string): IFluentDDLFunctionBuilder;
    function Body(const AValue: string): IFluentDDLFunctionBuilder;
    function OrReplace: IFluentDDLFunctionBuilder;
    function AsString: string;
  end;

  TFluentDDLDropFunctionBuilder = class(TInterfacedObject, IFluentDDLDropFunctionBuilder, IFluentDDLDropFunctionDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLDropFunctionDef }
    function GetDialect: TFluentSQLDriver;
    function GetFunctionName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropFunctionBuilder }
    function IfExists: IFluentDDLDropFunctionBuilder;
    function AsString: string;
  end;

  TFluentDDLProcedureBuilder = class(TInterfacedObject, IFluentDDLProcedureBuilder, IFluentDDLProcedureDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FParams: string;
    FBody: string;
    FOrReplace: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLProcedureDef }
    function GetDialect: TFluentSQLDriver;
    function GetProcedureName: string;
    function GetParams: string;
    function GetBody: string;
    function GetOrReplace: Boolean;
    { IFluentDDLProcedureBuilder }
    function Params(const AValue: string): IFluentDDLProcedureBuilder;
    function Body(const AValue: string): IFluentDDLProcedureBuilder;
    function OrReplace: IFluentDDLProcedureBuilder;
    function AsString: string;
  end;

  TFluentDDLDropProcedureBuilder = class(TInterfacedObject, IFluentDDLDropProcedureBuilder, IFluentDDLDropProcedureDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLDropProcedureDef }
    function GetDialect: TFluentSQLDriver;
    function GetProcedureName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropProcedureBuilder }
    function IfExists: IFluentDDLDropProcedureBuilder;
    function AsString: string;
  end;

  TFluentDDLTriggerBuilder = class(TInterfacedObject, IFluentDDLTriggerBuilder, IFluentDDLTriggerDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FTableName: string;
    FEvent: TTriggerEvent;
    FTime: TTriggerTime;
    FBody: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLTriggerDef }
    function GetDialect: TFluentSQLDriver;
    function GetTriggerName: string;
    function GetTableName: string;
    function GetEvent: TTriggerEvent;
    function GetTime: TTriggerTime;
    function GetBody: string;
    { IFluentDDLTriggerBuilder }
    function Table(const AValue: string): IFluentDDLTriggerBuilder;
    function Before: IFluentDDLTriggerBuilder;
    function After: IFluentDDLTriggerBuilder;
    function OnInsert: IFluentDDLTriggerBuilder;
    function OnUpdate: IFluentDDLTriggerBuilder;
    function OnDelete: IFluentDDLTriggerBuilder;
    function Body(const AValue: string): IFluentDDLTriggerBuilder;
    function AsString: string;
  end;

  TFluentDDLDropTriggerBuilder = class(TInterfacedObject, IFluentDDLDropTriggerBuilder, IFluentDDLDropTriggerDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FTableName: string;
    FIfExists: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const AName: string);
    { IFluentDDLDropTriggerDef }
    function GetDialect: TFluentSQLDriver;
    function GetTriggerName: string;
    function GetTableName: string;
    function GetIfExists: Boolean;
    { IFluentDDLDropTriggerBuilder }
    function OnTable(const AValue: string): IFluentDDLDropTriggerBuilder;
    function IfExists: IFluentDDLDropTriggerBuilder;
    function AsString: string;
  end;

  TFluentDDLTriggerManagementBuilder = class(TInterfacedObject, IFluentDDLTriggerManagementBuilder, IFluentDDLTriggerManagementDef)
  strict private
    FDialect: TFluentSQLDriver;
    FName: string;
    FTableName: string;
    FEnabled: Boolean;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName, ATriggerName: string; AEnabled: Boolean);
    { IFluentDDLTriggerManagementDef }
    function GetDialect: TFluentSQLDriver;
    function GetTriggerName: string;
    function GetTableName: string;
    function GetEnabled: Boolean;
    { IFluentDDLTriggerManagementBuilder }
    function AsString: string;
  end;

  TFluentDDLTableDrop = class(TInterfacedObject, IFluentDDLTableDrop, IFluentDDLDropBuilder, IFluentDDLDropTableDef)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
    FDropBuilder: IFluentDDLDropBuilder;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    function Column(const AName: string): IFluentDDLAlterTableDropBuilder;
    function Constraint(const AName: string): IFluentDDLAlterTableDropBuilder;
    function IfExists: IFluentDDLDropBuilder;
    function AsString: string;
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetIfExists: Boolean;
  end;

  TFluentDDLTableRename = class(TInterfacedObject, IFluentDDLTableRename)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    function Column(const AOldColumnName, ANewColumnName: string): IFluentDDLAlterTableRenameColumnBuilder;
  end;

  TFluentDDLTableAlter = class(TInterfacedObject, IFluentDDLTableAlter)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    function Column(const AName: string): IFluentDDLAlterTableAlterColumnBuilder;
  end;

  TFluentDDLTable = class(TInterfacedObject, IFluentDDLTable)
  strict private
    FDialect: TFluentSQLDriver;
    FTableName: string;
  public
    constructor Create(const ADialect: TFluentSQLDriver; const ATableName: string);
    function CreateBuilder: IFluentDDLBuilder;
    function IFluentDDLTable.Create = CreateBuilder;
    function Drop: IFluentDDLTableDrop;
    function Rename(const ANewTableName: string): IFluentDDLAlterTableRenameTableBuilder; overload;
    function Rename: IFluentDDLTableRename; overload;
    function Add: IFluentDDLAlterTableAddBuilder;
    function Alter: IFluentDDLTableAlter;
    function EnableTrigger(const ATriggerName: string): IFluentDDLTriggerManagementBuilder;
    function DisableTrigger(const ATriggerName: string): IFluentDDLTriggerManagementBuilder;
  end;

  TFluentSchema = class(TInterfacedObject, IFluentSchema)
  strict private
    FDialect: TFluentSQLDriver;
  public
    constructor Create(const ADialect: TFluentSQLDriver);
    function Table(const ATableName: string): IFluentDDLTable;
    function CreateIndex(const AIndexName, ATableName: string): IFluentDDLCreateIndexBuilder;
    function DropIndex(const AIndexName: string): IFluentDDLDropIndexBuilder;
    function TruncateTable(const ATableName: string): IFluentDDLTruncateTableBuilder;
    function CreateView(const AName: string): IFluentDDLCreateViewBuilder;
    function DropView(const AName: string): IFluentDDLDropViewBuilder;
    function CreateSequence(const AName: string): IFluentDDLCreateSequenceBuilder;
    function DropSequence(const AName: string): IFluentDDLDropSequenceBuilder;
    function CreateProcedure(const AName: string): IFluentDDLProcedureBuilder;
    function DropProcedure(const AName: string): IFluentDDLDropProcedureBuilder;
    function CreateFunction(const AName: string): IFluentDDLFunctionBuilder;
    function DropFunction(const AName: string): IFluentDDLDropFunctionBuilder;
    function CreateTrigger(const AName: string): IFluentDDLTriggerBuilder;
    function DropTrigger(const AName: string): IFluentDDLDropTriggerBuilder;
    function EnableTrigger(const ATableName, ATriggerName: string): IFluentDDLTriggerManagementBuilder;
    function DisableTrigger(const ATableName, ATriggerName: string): IFluentDDLTriggerManagementBuilder;
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
  FIdentityScope := disAlways;
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

function TFluentDDLColumn.GetIdentityScope: TDDLIdentityScope;
begin
  Result := FIdentityScope;
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

function TFluentDDLColumn.GetConstraintName: string;
begin
  Result := FConstraintName;
end;

procedure TFluentDDLColumn.SetNotNull(AValue: Boolean);
begin
  FNotNull := AValue;
end;

procedure TFluentDDLColumn.SetPrimaryKey(AValue: Boolean; const AName: string = '');
begin
  FPrimaryKey := AValue;
  if AName <> '' then
    FConstraintName := AName;
end;

procedure TFluentDDLColumn.SetUnique(AValue: Boolean; const AName: string = '');
begin
  FUnique := AValue;
  if AName <> '' then
    FConstraintName := AName;
end;

procedure TFluentDDLColumn.SetCheck(const ACondition: string; const AName: string = '');
begin
  FCheckCondition := ACondition;
  if AName <> '' then
    FConstraintName := AName;
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

function TFluentDDLTableConstraint.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID, IInterface) or IsEqualGUID(IID, IFluentDDLTableConstraint) then
  begin
    Pointer(Obj) := Self;
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TFluentDDLTableConstraint._AddRef: Integer;
begin
  Result := -1;
end;

function TFluentDDLTableConstraint._Release: Integer;
begin
  Result := -1;
end;

constructor TFluentDDLTableConstraint.Create(const AName: string; AType: TDDLConstraintType;
  const AColumns: array of string);
var
  I: Integer;
begin
  inherited Create;
  FName := AName;
  FConstraintType := AType;
  SetLength(FColumns, Length(AColumns));
  for I := 0 to High(AColumns) do
    FColumns[I] := AColumns[I];
end;

constructor TFluentDDLTableConstraint.Create(const AName, ACheckCondition: string);
begin
  inherited Create;
  FName := AName;
  FConstraintType := dctCheck;
  FCheckCondition := ACheckCondition;
end;

constructor TFluentDDLTableConstraint.Create(const AName: string; AType: TDDLConstraintType; const AColumn, ARefTable,
  ARefColumn: string);
begin
  inherited Create;
  FName := AName;
  FConstraintType := AType;
  SetLength(FColumns, 1);
  FColumns[0] := AColumn;
  FReferenceTable := ARefTable;
  FReferenceColumn := ARefColumn;
end;

function TFluentDDLTableConstraint.GetCheckCondition: string;
begin
  Result := FCheckCondition;
end;

function TFluentDDLTableConstraint.GetReferenceTable: string;
begin
  Result := FReferenceTable;
end;

function TFluentDDLTableConstraint.GetReferenceColumn: string;
begin
  Result := FReferenceColumn;
end;

function TFluentDDLTableConstraint.GetColumnCount: Integer;
begin
  Result := Length(FColumns);
end;

function TFluentDDLTableConstraint.GetColumnName(AIndex: Integer): string;
begin
  Result := FColumns[AIndex];
end;

function TFluentDDLTableConstraint.GetConstraintType: TDDLConstraintType;
begin
  Result := FConstraintType;
end;

function TFluentDDLTableConstraint.GetName: string;
begin
  Result := FName;
end;

procedure TFluentDDLColumn.SetIdentity(AValue: Boolean; AScope: TDDLIdentityScope = disAlways);
begin
  if AValue and not (FLogicalType in [dltInteger, dltBigInt]) then
    raise EArgumentException.Create('DDL: .Identity can only be used on Integer or BigInt columns.');
  FIdentity := AValue;
  FIdentityScope := AScope;
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
  FTableConstraints := TObjectList<TFluentDDLTableConstraint>.Create(True);
  FIsCapped := False;
end;

destructor TFluentDDLBuilder.Destroy;
begin
  FTableConstraints.Free;
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

function TFluentDDLBuilder.GetTableConstraintCount: Integer;
begin
  Result := FTableConstraints.Count;
end;

function TFluentDDLBuilder.GetTableConstraint(AIndex: Integer): IFluentDDLTableConstraint;
begin
  Result := FTableConstraints[AIndex];
end;

function TFluentDDLBuilder.GetDescription: string;
begin
  Result := FDescription;
end;
 
function TFluentDDLBuilder.GetIsCapped: Boolean;
begin
  Result := FIsCapped;
end;
 
function TFluentDDLBuilder.GetCappedSize: Int64;
begin
  Result := FCappedSize;
end;
 
function TFluentDDLBuilder.GetCappedMax: Integer;
begin
  Result := FCappedMax;
end;

procedure TFluentDDLBuilder._CheckPKDuplicity;
var
  I: Integer;
begin
  for I := 0 to FColumns.Count - 1 do
    if FColumns[I].GetIsPrimaryKey then
      raise EArgumentException.Create('DDL: Table already has a Primary Key defined (inline).');

  for I := 0 to FTableConstraints.Count - 1 do
    if FTableConstraints[I].GetConstraintType = dctPrimaryKey then
      raise EArgumentException.Create('DDL: Table already has a Primary Key defined (table constraint).');
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
  begin
    _CheckPKDuplicity;
    FColumns.Last.SetPrimaryKey(True);
  end;
  Result := Self;
end;

function TFluentDDLBuilder.PrimaryKey(const AName: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
  begin
    _CheckPKDuplicity;
    FColumns.Last.SetPrimaryKey(True, AName);
  end;
  Result := Self;
end;

function TFluentDDLBuilder.PrimaryKey(const AColumns: array of string; const AName: string = ''): IFluentDDLBuilder;
begin
  _CheckPKDuplicity;
  FTableConstraints.Add(TFluentDDLTableConstraint.Create(AName, dctPrimaryKey, AColumns));
  Result := Self;
end;

function TFluentDDLBuilder.Unique: IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetUnique(True);
  Result := Self;
end;

function TFluentDDLBuilder.Unique(const AName: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetUnique(True, AName);
  Result := Self;
end;

function TFluentDDLBuilder.Unique(const AColumns: array of string; const AName: string = ''): IFluentDDLBuilder;
begin
  FTableConstraints.Add(TFluentDDLTableConstraint.Create(AName, dctUnique, AColumns));
  Result := Self;
end;

function TFluentDDLBuilder.Check(const ACondition: string; const AName: string = ''): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetCheck(ACondition, AName)
  else
    FTableConstraints.Add(TFluentDDLTableConstraint.Create(AName, ACondition));
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

function TFluentDDLBuilder.Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetIdentity(True, AScope);
  Result := Self;
end;

function TFluentDDLBuilder.References(const ATableName, AColumnName: string): IFluentDDLBuilder;
begin
  if FColumns.Count > 0 then
    FColumns.Last.SetReferences(ATableName, AColumnName);
  Result := Self;
end;

function TFluentDDLBuilder.Capped(ASize: Int64; AMaxDocs: Integer): IFluentDDLBuilder;
begin
  FIsCapped := True;
  FCappedSize := ASize;
  FCappedMax := AMaxDocs;
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
  if (FColumns.Count = 0) and (FDialect <> dbnMongoDB) then
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
  FConstraint := nil;
  FHasColumn := False;
  FHasConstraint := False;
end;

destructor TFluentDDLAlterTableAddBuilder.Destroy;
begin
  FColumn.Free;
  FConstraint.Free;
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

function TFluentDDLAlterTableAddBuilder.GetConstraint: IFluentDDLTableConstraint;
begin
  if FHasConstraint then
    Result := FConstraint
  else
    Result := nil;
end;

function TFluentDDLAlterTableAddBuilder._AddColumn(const AName: string; ALogicalType: TDDLLogicalType; ATypeArg: Integer): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn or FHasConstraint then
    raise EArgumentException.Create(
      'DDL ALTER TABLE ADD: only one logical operation per AsString in this build (ESP-019/ESP-057).');
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

function TFluentDDLAlterTableAddBuilder.PrimaryKey(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetPrimaryKey(True, AName);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Unique: IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetUnique(True);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Unique(const AName: string): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetUnique(True, AName);
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.Check(const ACondition: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetCheck(ACondition, AName);
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

function TFluentDDLAlterTableAddBuilder.Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn then
    FColumn.SetIdentity(True, AScope);
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

function TFluentDDLAlterTableAddBuilder.AddPrimaryKey(const AColumns: array of string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn or FHasConstraint then
    raise EArgumentException.Create('DDL ALTER TABLE ADD: only one operation per AsString.');
  FConstraint := TFluentDDLTableConstraint.Create(AName, dctPrimaryKey, AColumns);
  FHasConstraint := True;
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.AddUnique(const AColumns: array of string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn or FHasConstraint then
    raise EArgumentException.Create('DDL ALTER TABLE ADD: only one operation per AsString.');
  FConstraint := TFluentDDLTableConstraint.Create(AName, dctUnique, AColumns);
  FHasConstraint := True;
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.AddForeignKey(const AColumn, ARefTable, ARefColumn: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn or FHasConstraint then
    raise EArgumentException.Create('DDL ALTER TABLE ADD: only one operation per AsString.');
  FConstraint := TFluentDDLTableConstraint.Create(AName, dctForeignKey, AColumn, ARefTable, ARefColumn);
  FHasConstraint := True;
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.AddCheck(const ACondition: string; const AName: string = ''): IFluentDDLAlterTableAddBuilder;
begin
  if FHasColumn or FHasConstraint then
    raise EArgumentException.Create('DDL ALTER TABLE ADD: only one operation per AsString.');
  FConstraint := TFluentDDLTableConstraint.Create(AName, ACondition);
  FHasConstraint := True;
  Result := Self;
end;

function TFluentDDLAlterTableAddBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not (FHasColumn or FHasConstraint) then
    raise EArgumentException.Create('DDL ALTER TABLE: an operation (column or constraint) is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    if FHasColumn then
      Result := LSerializer.AlterTableAddColumn(Self as IFluentDDLAlterTableAddColumnDef)
    else
      Result := LSerializer.AlterTableAddConstraint(Self as IFluentDDLAlterTableAddConstraintDef);
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
  FConstraintName := '';
  FHasDropColumn := False;
  FHasDropConstraint := False;
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
  if FHasDropColumn then
    Result := FColumnName
  else
    Result := '';
end;

function TFluentDDLAlterTableDropBuilder.GetConstraintName: string;
begin
  if FHasDropConstraint then
    Result := FConstraintName
  else
    Result := '';
end;

function TFluentDDLAlterTableDropBuilder.DropColumn(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  if FHasDropColumn or FHasDropConstraint then
    raise EArgumentException.Create(
      'DDL ALTER TABLE DROP: only one operation per AsString.');
  if Trim(AName) = '' then
    raise EArgumentException.Create('DDL: column name is required');
  FColumnName := AName;
  FHasDropColumn := True;
  Result := Self;
end;

function TFluentDDLAlterTableDropBuilder.DropConstraint(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  if FHasDropColumn or FHasDropConstraint then
    raise EArgumentException.Create(
      'DDL ALTER TABLE DROP: only one operation per AsString.');
  if Trim(AName) = '' then
    raise EArgumentException.Create('DDL: constraint name is required');
  FConstraintName := AName;
  FHasDropConstraint := True;
  Result := Self;
end;

function TFluentDDLAlterTableDropBuilder.Column(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := DropColumn(AName);
end;

function TFluentDDLAlterTableDropBuilder.Constraint(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := DropConstraint(AName);
end;

function TFluentDDLAlterTableDropBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: table name is required');
  if not (FHasDropColumn or FHasDropConstraint) then
    raise EArgumentException.Create('DDL ALTER TABLE DROP: a target (column or constraint) is required');
  LSerializer := TFluentDDLSerialize.Create;
  try
    if FHasDropColumn then
      Result := LSerializer.AlterTableDropColumn(Self as IFluentDDLAlterTableDropColumnDef)
    else
      Result := LSerializer.AlterTableDropConstraint(Self as IFluentDDLAlterTableDropConstraintDef);
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
  FDefaultSet := False;
  FDefaultDropped := False;
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

function TFluentDDLAlterTableAlterColumnBuilder.GetDefaultValue: string;
begin
  Result := FDefaultValue;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetDefaultSet: Boolean;
begin
  Result := FDefaultSet;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetDefaultDropped: Boolean;
begin
  Result := FDefaultDropped;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetIsIdentity: Boolean;
begin
  Result := FIdentity;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetIdentityScope: TDDLIdentityScope;
begin
  Result := FIdentityScope;
end;

function TFluentDDLAlterTableAlterColumnBuilder.GetIdentityChanged: Boolean;
begin
  Result := FIdentityChanged;
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

function TFluentDDLAlterTableAlterColumnBuilder.SetDefault(const AValue: string): IFluentDDLAlterTableAlterColumnBuilder;
begin
  FDefaultValue := AValue;
  FDefaultSet := True;
  FDefaultDropped := False;
  Result := Self;
end;

function TFluentDDLAlterTableAlterColumnBuilder.DropDefault: IFluentDDLAlterTableAlterColumnBuilder;
begin
  FDefaultValue := '';
  FDefaultSet := False;
  FDefaultDropped := True;
  Result := Self;
end;

function TFluentDDLAlterTableAlterColumnBuilder.Identity(AScope: TDDLIdentityScope = disAlways): IFluentDDLAlterTableAlterColumnBuilder;
begin
  FIdentity := True;
  FIdentityScope := AScope;
  FIdentityChanged := True;
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
  if not (FTypeChanged or FNullabilityChanged or FDefaultSet or FDefaultDropped or FIdentityChanged) then
    raise EArgumentException.Create('DDL ALTER TABLE ALTER COLUMN: at least one change (type, nullability, default or identity) is required');

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
  FExpireAfter := 0;
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
 
function TFluentDDLCreateIndexBuilder.GetExpireAfter: Integer;
begin
  Result := FExpireAfter;
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

function TFluentDDLCreateIndexBuilder.ExpireAfter(ASeconds: Integer): IFluentDDLCreateIndexBuilder;
begin
  FExpireAfter := ASeconds;
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

function TFluentDDLCreateViewBuilder.&As(const AQuery: IFluentSQL): IFluentDDLCreateViewBuilder;
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

{ TFluentDDLCreateSequenceBuilder }

constructor TFluentDDLCreateSequenceBuilder.Create(const ADialect: TFluentSQLDriver; const ASequenceName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FSequenceName := ASequenceName;
end;

function TFluentDDLCreateSequenceBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLCreateSequenceBuilder.GetSequenceName: string;
begin
  Result := FSequenceName;
end;

function TFluentDDLCreateSequenceBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FSequenceName) = '' then
    raise EArgumentException.Create('DDL: sequence name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateSequence(Self as IFluentDDLCreateSequenceDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropSequenceBuilder }

constructor TFluentDDLDropSequenceBuilder.Create(const ADialect: TFluentSQLDriver; const ASequenceName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FSequenceName := ASequenceName;
  FIfExists := False;
end;

function TFluentDDLDropSequenceBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropSequenceBuilder.GetSequenceName: string;
begin
  Result := FSequenceName;
end;

function TFluentDDLDropSequenceBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropSequenceBuilder.IfExists: IFluentDDLDropSequenceBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropSequenceBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FSequenceName) = '' then
    raise EArgumentException.Create('DDL: sequence name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropSequence(Self as IFluentDDLDropSequenceDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLProcedureBuilder }

{ TFluentDDLFunctionBuilder }

constructor TFluentDDLFunctionBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FOrReplace := False;
end;

function TFluentDDLFunctionBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLFunctionBuilder.GetFunctionName: string;
begin
  Result := FName;
end;

function TFluentDDLFunctionBuilder.GetParams: string;
begin
  Result := FParams;
end;

function TFluentDDLFunctionBuilder.GetReturns: string;
begin
  Result := FReturns;
end;

function TFluentDDLFunctionBuilder.GetBody: string;
begin
  Result := FBody;
end;

function TFluentDDLFunctionBuilder.GetOrReplace: Boolean;
begin
  Result := FOrReplace;
end;

function TFluentDDLFunctionBuilder.Params(const AValue: string): IFluentDDLFunctionBuilder;
begin
  FParams := AValue;
  Result := Self;
end;

function TFluentDDLFunctionBuilder.Returns(const AValue: string): IFluentDDLFunctionBuilder;
begin
  FReturns := AValue;
  Result := Self;
end;

function TFluentDDLFunctionBuilder.Body(const AValue: string): IFluentDDLFunctionBuilder;
begin
  FBody := AValue;
  Result := Self;
end;

function TFluentDDLFunctionBuilder.OrReplace: IFluentDDLFunctionBuilder;
begin
  FOrReplace := True;
  Result := Self;
end;

function TFluentDDLFunctionBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: function name is required');
  if Trim(FReturns) = '' then
    raise EArgumentException.Create('DDL: function returns type is required');
  if Trim(FBody) = '' then
    raise EArgumentException.Create('DDL: function body is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateFunction(Self as IFluentDDLFunctionDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropFunctionBuilder }

constructor TFluentDDLDropFunctionBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FIfExists := False;
end;

function TFluentDDLDropFunctionBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropFunctionBuilder.GetFunctionName: string;
begin
  Result := FName;
end;

function TFluentDDLDropFunctionBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropFunctionBuilder.IfExists: IFluentDDLDropFunctionBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropFunctionBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: function name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropFunction(Self as IFluentDDLDropFunctionDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLProcedureBuilder }

constructor TFluentDDLProcedureBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FOrReplace := False;
end;

function TFluentDDLProcedureBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLProcedureBuilder.GetProcedureName: string;
begin
  Result := FName;
end;

function TFluentDDLProcedureBuilder.GetParams: string;
begin
  Result := FParams;
end;

function TFluentDDLProcedureBuilder.GetBody: string;
begin
  Result := FBody;
end;

function TFluentDDLProcedureBuilder.GetOrReplace: Boolean;
begin
  Result := FOrReplace;
end;

function TFluentDDLProcedureBuilder.Params(const AValue: string): IFluentDDLProcedureBuilder;
begin
  FParams := AValue;
  Result := Self;
end;

function TFluentDDLProcedureBuilder.Body(const AValue: string): IFluentDDLProcedureBuilder;
begin
  FBody := AValue;
  Result := Self;
end;

function TFluentDDLProcedureBuilder.OrReplace: IFluentDDLProcedureBuilder;
begin
  FOrReplace := True;
  Result := Self;
end;

function TFluentDDLProcedureBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: procedure name is required');
  if Trim(FBody) = '' then
    raise EArgumentException.Create('DDL: procedure body is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateProcedure(Self as IFluentDDLProcedureDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropProcedureBuilder }

constructor TFluentDDLDropProcedureBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FIfExists := False;
end;

function TFluentDDLDropProcedureBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropProcedureBuilder.GetProcedureName: string;
begin
  Result := FName;
end;

function TFluentDDLDropProcedureBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropProcedureBuilder.IfExists: IFluentDDLDropProcedureBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropProcedureBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: procedure name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropProcedure(Self as IFluentDDLDropProcedureDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLTriggerBuilder }

constructor TFluentDDLTriggerBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FEvent := teInsert;
  FTime := ttAfter;
end;

function TFluentDDLTriggerBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLTriggerBuilder.GetTriggerName: string;
begin
  Result := FName;
end;

function TFluentDDLTriggerBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLTriggerBuilder.GetEvent: TTriggerEvent;
begin
  Result := FEvent;
end;

function TFluentDDLTriggerBuilder.GetTime: TTriggerTime;
begin
  Result := FTime;
end;

function TFluentDDLTriggerBuilder.GetBody: string;
begin
  Result := FBody;
end;

function TFluentDDLTriggerBuilder.Table(const AValue: string): IFluentDDLTriggerBuilder;
begin
  FTableName := AValue;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.Before: IFluentDDLTriggerBuilder;
begin
  FTime := ttBefore;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.After: IFluentDDLTriggerBuilder;
begin
  FTime := ttAfter;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.OnInsert: IFluentDDLTriggerBuilder;
begin
  FEvent := teInsert;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.OnUpdate: IFluentDDLTriggerBuilder;
begin
  FEvent := teUpdate;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.OnDelete: IFluentDDLTriggerBuilder;
begin
  FEvent := teDelete;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.Body(const AValue: string): IFluentDDLTriggerBuilder;
begin
  FBody := AValue;
  Result := Self;
end;

function TFluentDDLTriggerBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: trigger name is required');
  if Trim(FTableName) = '' then
    raise EArgumentException.Create('DDL: trigger table name is required');
  if Trim(FBody) = '' then
    raise EArgumentException.Create('DDL: trigger body is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.CreateTrigger(Self as IFluentDDLTriggerDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLDropTriggerBuilder }

constructor TFluentDDLDropTriggerBuilder.Create(const ADialect: TFluentSQLDriver; const AName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FName := AName;
  FIfExists := False;
end;

function TFluentDDLDropTriggerBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLDropTriggerBuilder.GetTriggerName: string;
begin
  Result := FName;
end;

function TFluentDDLDropTriggerBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLDropTriggerBuilder.GetIfExists: Boolean;
begin
  Result := FIfExists;
end;

function TFluentDDLDropTriggerBuilder.OnTable(const AValue: string): IFluentDDLDropTriggerBuilder;
begin
  FTableName := AValue;
  Result := Self;
end;

function TFluentDDLDropTriggerBuilder.IfExists: IFluentDDLDropTriggerBuilder;
begin
  FIfExists := True;
  Result := Self;
end;

function TFluentDDLDropTriggerBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: trigger name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.DropTrigger(Self as IFluentDDLDropTriggerDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLTriggerManagementBuilder }

constructor TFluentDDLTriggerManagementBuilder.Create(const ADialect: TFluentSQLDriver; const ATableName, ATriggerName: string; AEnabled: Boolean);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FName := ATriggerName;
  FEnabled := AEnabled;
end;

function TFluentDDLTriggerManagementBuilder.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLTriggerManagementBuilder.GetTriggerName: string;
begin
  Result := FName;
end;

function TFluentDDLTriggerManagementBuilder.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLTriggerManagementBuilder.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TFluentDDLTriggerManagementBuilder.AsString: string;
var
  LSerializer: TFluentDDLSerialize;
begin
  if Trim(FName) = '' then
    raise EArgumentException.Create('DDL: trigger name is required');

  LSerializer := TFluentDDLSerialize.Create;
  try
    Result := LSerializer.ManageTrigger(Self as IFluentDDLTriggerManagementDef);
  finally
    LSerializer.Free;
  end;
end;

{ TFluentDDLTableDrop }

constructor TFluentDDLTableDrop.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
  FDropBuilder := TFluentDDLDropBuilder.Create(ADialect, ATableName);
end;

function TFluentDDLTableDrop.Column(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := TFluentDDLAlterTableDropBuilder.Create(FDialect, FTableName).DropColumn(AName);
end;

function TFluentDDLTableDrop.Constraint(const AName: string): IFluentDDLAlterTableDropBuilder;
begin
  Result := TFluentDDLAlterTableDropBuilder.Create(FDialect, FTableName).DropConstraint(AName);
end;

function TFluentDDLTableDrop.IfExists: IFluentDDLDropBuilder;
begin
  FDropBuilder.IfExists;
  Result := Self;
end;

function TFluentDDLTableDrop.AsString: string;
begin
  Result := FDropBuilder.AsString;
end;

function TFluentDDLTableDrop.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentDDLTableDrop.GetTableName: string;
begin
  Result := FTableName;
end;

function TFluentDDLTableDrop.GetIfExists: Boolean;
begin
  Result := (FDropBuilder as IFluentDDLDropTableDef).GetIfExists;
end;

{ TFluentDDLTableRename }

constructor TFluentDDLTableRename.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
end;

function TFluentDDLTableRename.Column(const AOldColumnName, ANewColumnName: string): IFluentDDLAlterTableRenameColumnBuilder;
begin
  Result := TFluentDDLAlterTableRenameColumnBuilder.Create(FDialect, FTableName, AOldColumnName, ANewColumnName);
end;

{ TFluentDDLTableAlter }

constructor TFluentDDLTableAlter.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
end;

function TFluentDDLTableAlter.Column(const AName: string): IFluentDDLAlterTableAlterColumnBuilder;
begin
  Result := TFluentDDLAlterTableAlterColumnBuilder.Create(FDialect, FTableName, AName);
end;

{ TFluentDDLTable }

constructor TFluentDDLTable.Create(const ADialect: TFluentSQLDriver; const ATableName: string);
begin
  inherited Create;
  FDialect := ADialect;
  FTableName := ATableName;
end;

function TFluentDDLTable.CreateBuilder: IFluentDDLBuilder;
begin
  Result := TFluentDDLBuilder.Create(FDialect, FTableName);
end;

function TFluentDDLTable.Drop: IFluentDDLTableDrop;
begin
  Result := TFluentDDLTableDrop.Create(FDialect, FTableName);
end;

function TFluentDDLTable.Rename(const ANewTableName: string): IFluentDDLAlterTableRenameTableBuilder;
begin
  Result := TFluentDDLAlterTableRenameTableBuilder.Create(FDialect, FTableName, ANewTableName);
end;

function TFluentDDLTable.Rename: IFluentDDLTableRename;
begin
  Result := TFluentDDLTableRename.Create(FDialect, FTableName);
end;

function TFluentDDLTable.Add: IFluentDDLAlterTableAddBuilder;
begin
  Result := TFluentDDLAlterTableAddBuilder.Create(FDialect, FTableName);
end;

function TFluentDDLTable.Alter: IFluentDDLTableAlter;
begin
  Result := TFluentDDLTableAlter.Create(FDialect, FTableName);
end;

function TFluentDDLTable.EnableTrigger(const ATriggerName: string): IFluentDDLTriggerManagementBuilder;
begin
  Result := TFluentDDLTriggerManagementBuilder.Create(FDialect, FTableName, ATriggerName, True);
end;

function TFluentDDLTable.DisableTrigger(const ATriggerName: string): IFluentDDLTriggerManagementBuilder;
begin
  Result := TFluentDDLTriggerManagementBuilder.Create(FDialect, FTableName, ATriggerName, False);
end;

{ TFluentSchema }

constructor TFluentSchema.Create(const ADialect: TFluentSQLDriver);
begin
  FDialect := ADialect;
end;

function TFluentSchema.Table(const ATableName: string): IFluentDDLTable;
begin
  Result := TFluentDDLTable.Create(FDialect, ATableName);
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

function TFluentSchema.CreateSequence(const AName: string): IFluentDDLCreateSequenceBuilder;
begin
  Result := TFluentDDLCreateSequenceBuilder.Create(FDialect, AName);
end;

function TFluentSchema.DropSequence(const AName: string): IFluentDDLDropSequenceBuilder;
begin
  Result := TFluentDDLDropSequenceBuilder.Create(FDialect, AName);
end;

function TFluentSchema.CreateProcedure(const AName: string): IFluentDDLProcedureBuilder;
begin
  Result := TFluentDDLProcedureBuilder.Create(FDialect, AName);
end;

function TFluentSchema.DropProcedure(const AName: string): IFluentDDLDropProcedureBuilder;
begin
  Result := TFluentDDLDropProcedureBuilder.Create(FDialect, AName);
end;

function TFluentSchema.CreateFunction(const AName: string): IFluentDDLFunctionBuilder;
begin
  Result := TFluentDDLFunctionBuilder.Create(FDialect, AName);
end;

function TFluentSchema.DropFunction(const AName: string): IFluentDDLDropFunctionBuilder;
begin
  Result := TFluentDDLDropFunctionBuilder.Create(FDialect, AName);
end;

function TFluentSchema.CreateTrigger(const AName: string): IFluentDDLTriggerBuilder;
begin
  Result := TFluentDDLTriggerBuilder.Create(FDialect, AName);
end;

function TFluentSchema.DropTrigger(const AName: string): IFluentDDLDropTriggerBuilder;
begin
  Result := TFluentDDLDropTriggerBuilder.Create(FDialect, AName);
end;

function TFluentSchema.EnableTrigger(const ATableName, ATriggerName: string): IFluentDDLTriggerManagementBuilder;
begin
  Result := TFluentDDLTriggerManagementBuilder.Create(FDialect, ATableName, ATriggerName, True);
end;

function TFluentSchema.DisableTrigger(const ATableName, ATriggerName: string): IFluentDDLTriggerManagementBuilder;
begin
  Result := TFluentDDLTriggerManagementBuilder.Create(FDialect, ATableName, ATriggerName, False);
end;

end.
