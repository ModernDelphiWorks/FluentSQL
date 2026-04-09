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

unit FluentSQL.Ast;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Interfaces,
  FluentSQL.Register,
  FluentSQL.Params;

type
  TFluentSQLAST = class(TInterfacedObject, IFluentSQLAST)
  strict private
    FSerializationDialect: TFluentSQLDriver;
    FDialectOnly: TArray<TDialectOnlyFragment>;
    FRegister: TFluentSQLRegister;
    FParams: IFluentSQLParams;
    FASTColumns: IFluentSQLNames;
    FASTSection: IFluentSQLSection;
    FASTName: IFluentSQLName;
    FASTTableNames: IFluentSQLNames;
    FSelect: IFluentSQLSelect;
    FInsert: IFluentSQLInsert;
    FUpdate: IFluentSQLUpdate;
    FDelete : IFluentSQLDelete;
    FGroupBy: IFluentSQLGroupBy;
    FHaving: IFluentSQLHaving;
    FJoins: IFluentSQLJoins;
    FOrderBy: IFluentSQLOrderBy;
    FWhere: IFluentSQLWhere;
    FWithAlias: String;
    FUnionType: String;
    FUnionQuery: IFluentSQL;
    function _GetASTColumns: IFluentSQLNames;
    procedure _SetASTColumns(const Value: IFluentSQLNames);
    function _GetASTSection: IFluentSQLSection;
    procedure _SetASTSection(const Value: IFluentSQLSection);
    function _GetASTName: IFluentSQLName;
    procedure _SetASTName(const Value: IFluentSQLName);
    function _GetASTTableNames: IFluentSQLNames;
    procedure _SetASTTableNames(const Value: IFluentSQLNames);
    function _GetParams: IFluentSQLParams;
    function _GetWithAlias: String;
    procedure _SetWithAlias(const Value: String);
    function _GetUnionType: String;
    procedure _SetUnionType(const Value: String);
    function _GetUnionQuery: IFluentSQL;
    procedure _SetUnionQuery(const Value: IFluentSQL);
    function GetSerializationDialect: TFluentSQLDriver;
    procedure AddDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string);
    function DialectOnlyCount: Integer;
    function GetDialectOnlyItem(AIndex: Integer): TDialectOnlyFragment;
  public
    constructor Create(const ADatabase: TFluentSQLDriver; const ARegister: TFluentSQLRegister);
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Select: IFluentSQLSelect;
    function Delete: IFluentSQLDelete;
    function Insert: IFluentSQLInsert;
    function Update: IFluentSQLUpdate;
    function Joins: IFluentSQLJoins;
    function Where: IFluentSQLWhere;
    function GroupBy: IFluentSQLGroupBy;
    function Having: IFluentSQLHaving;
    function OrderBy: IFluentSQLOrderBy;
    property ASTColumns: IFluentSQLNames read _GetASTColumns write _SetASTColumns;
    property ASTSection: IFluentSQLSection read _GetASTSection write _SetASTSection;
    property ASTName: IFluentSQLName read _GetASTName write _SetASTName;
    property ASTTableNames: IFluentSQLNames read _GetASTTableNames write _SetASTTableNames;
    property Params: IFluentSQLParams read _GetParams;
    property WithAlias: String read _GetWithAlias write _SetWithAlias;
    property UnionType: String read _GetUnionType write _SetUnionType;
    property UnionQuery: IFluentSQL read _GetUnionQuery write _SetUnionQuery;
  end;

implementation

uses
  FluentSQL.Select,
  FluentSQL.OrderBy,
  FluentSQL.Where,
  FluentSQL.Delete,
  FluentSQL.Joins,
  FluentSQL.GroupBy,
  FluentSQL.Having,
  FluentSQL.Insert,
  FluentSQL.Update;

{ TFluentSQLAST }

procedure TFluentSQLAST.Clear;
begin
  FParams.Clear;
  FSelect.Clear;
  FDelete.Clear;
  FInsert.Clear;
  FUpdate.Clear;
  FJoins.Clear;
  FWhere.Clear;
  FGroupBy.Clear;
  FHaving.Clear;
  FOrderBy.Clear;
  FWithAlias := '';
  FUnionType := '';
  FUnionQuery := nil;
  SetLength(FDialectOnly, 0);
end;

constructor TFluentSQLAST.Create(const ADatabase: TFluentSQLDriver; const ARegister: TFluentSQLRegister);
begin
  FSerializationDialect := ADatabase;
  FRegister := ARegister;
  FParams := TFluentSQLParams.Create;
  FDelete := TFluentSQLDelete.Create;
  FInsert := TFluentSQLInsert.Create;
  FUpdate := TFluentSQLUpdate.Create;
  FJoins := TFluentSQLJoins.Create;
  FSelect := FRegister.Select(ADatabase);
  FWhere := FRegister.Where(ADatabase);
  if FWhere = nil then
    FWhere := TFluentSQLWhere.Create;
  FGroupBy := TFluentSQLGroupBy.Create;
  FHaving := TFluentSQLHaving.Create;
  FOrderBy := TFluentSQLOrderBy.Create;
end;

function TFluentSQLAST.Delete: IFluentSQLDelete;
begin
  Result := FDelete;
end;

destructor TFluentSQLAST.Destroy;
begin
  FASTColumns := nil;
  FASTSection := nil;
  FASTName := nil;
  FASTTableNames := nil;
  FSelect := nil;
  FInsert := nil;
  FUpdate := nil;
  FDelete  := nil;
  FGroupBy := nil;
  FHaving := nil;
  FJoins := nil;
  FOrderBy := nil;
  FWhere := nil;
  FParams := nil;
  FRegister := nil;
  inherited;
end;

function TFluentSQLAST._GetASTColumns: IFluentSQLNames;
begin
  Result := FASTColumns;
end;

function TFluentSQLAST._GetASTName: IFluentSQLName;
begin
  Result := FASTName;
end;

function TFluentSQLAST._GetASTSection: IFluentSQLSection;
begin
  Result := FASTSection;
end;

function TFluentSQLAST._GetASTTableNames: IFluentSQLNames;
begin
  Result := FASTTableNames;
end;

function TFluentSQLAST._GetParams: IFluentSQLParams;
begin
  Result := FParams;
end;

function TFluentSQLAST._GetWithAlias: String;
begin
  Result := FWithAlias;
end;

procedure TFluentSQLAST._SetWithAlias(const Value: String);
begin
  FWithAlias := Value;
end;

function TFluentSQLAST._GetUnionType: String;
begin
  Result := FUnionType;
end;

procedure TFluentSQLAST._SetUnionType(const Value: String);
begin
  FUnionType := Value;
end;

function TFluentSQLAST._GetUnionQuery: IFluentSQL;
begin
  Result := FUnionQuery;
end;

procedure TFluentSQLAST._SetUnionQuery(const Value: IFluentSQL);
begin
  FUnionQuery := Value;
end;

function TFluentSQLAST.GetSerializationDialect: TFluentSQLDriver;
begin
  Result := FSerializationDialect;
end;

procedure TFluentSQLAST.AddDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string);
var
  L: Integer;
begin
  L := Length(FDialectOnly);
  SetLength(FDialectOnly, L + 1);
  FDialectOnly[L].Dialect := ADialect;
  FDialectOnly[L].Sql := ASqlFragment;
end;

function TFluentSQLAST.DialectOnlyCount: Integer;
begin
  Result := Length(FDialectOnly);
end;

function TFluentSQLAST.GetDialectOnlyItem(AIndex: Integer): TDialectOnlyFragment;
begin
  Result := FDialectOnly[AIndex];
end;

function TFluentSQLAST.GroupBy: IFluentSQLGroupBy;
begin
  Result := FGroupBy;
end;

function TFluentSQLAST.Having: IFluentSQLHaving;
begin
  Result := FHaving;
end;

function TFluentSQLAST.Insert: IFluentSQLInsert;
begin
  Result := FInsert;
end;

function TFluentSQLAST.IsEmpty: Boolean;
begin
  Result := FSelect.IsEmpty and
            FJoins.IsEmpty and
            FWhere.IsEmpty and
            FGroupBy.IsEmpty and
            FHaving.IsEmpty and
            FOrderBy.IsEmpty;
end;

function TFluentSQLAST.Joins: IFluentSQLJoins;
begin
  Result := FJoins;
end;

function TFluentSQLAST.OrderBy: IFluentSQLOrderBy;
begin
  Result := FOrderBy;
end;

function TFluentSQLAST.Select: IFluentSQLSelect;
begin
  Result := FSelect;
end;

procedure TFluentSQLAST._SetASTColumns(const Value: IFluentSQLNames);
begin
  FASTColumns := Value;
end;

procedure TFluentSQLAST._SetASTName(const Value: IFluentSQLName);
begin
  FASTName := Value;
end;

procedure TFluentSQLAST._SetASTSection(const Value: IFluentSQLSection);
begin
  FASTSection := Value;
end;

procedure TFluentSQLAST._SetASTTableNames(const Value: IFluentSQLNames);
begin
  FASTTableNames := Value;
end;

function TFluentSQLAST.Update: IFluentSQLUpdate;
begin
  Result := FUpdate;
end;

function TFluentSQLAST.Where: IFluentSQLWhere;
begin
  Result := FWhere;
end;

end.





