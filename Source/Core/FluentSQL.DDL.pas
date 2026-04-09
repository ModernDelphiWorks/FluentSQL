{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
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

function NewFluentDDLTable(const ADialect: TFluentSQLDriver; const ATableName: string): IFluentDDLBuilder;

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

end.
