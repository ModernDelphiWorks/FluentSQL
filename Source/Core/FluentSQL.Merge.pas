{
  ------------------------------------------------------------------------------
  FluentSQL
  DML MERGE implementation and AST state (ESP-076).
  Initial skeleton supporting Into/Using/On/Matched/NotMatched DSL.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.Merge;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  Classes,
  SysUtils,
  FluentSQL.Interfaces;

type
  TFluentSQLMergeMatchClause = class(TInterfacedObject, IFluentSQLMergeMatchClauseDef, 
    IFluentSQLMergeWhenMatched, IFluentSQLMergeWhenNotMatched)
  strict private
    FClauseType: IFluentSQLMergeMatchClauseType;
    FCondition: string;
    FActionType: IFluentSQLMergeActionType;
    FValues: IFluentSQLNameValuePairs;
    FParent: IFluentSQLMerge;
  public
    constructor Create(AParent: IFluentSQLMerge; AType: IFluentSQLMergeMatchClauseType);
    destructor Destroy; override;
    { IFluentSQLMergeMatchClauseDef }
    function GetClauseType: IFluentSQLMergeMatchClauseType;
    function GetCondition: string;
    function GetActionType: IFluentSQLMergeActionType;
    function GetValues: IFluentSQLNameValuePairs;
    { IFluentSQLMergeWhenMatched }
    function Update: IFluentSQLMerge;
    function Delete: IFluentSQLMerge;
    { IFluentSQLMergeWhenNotMatched }
    function Insert: IFluentSQLMerge;
    { DSL helpers }
    procedure SetCondition(const ACondition: string);
  end;

  TFluentSQLMerge = class(TInterfacedObject, IFluentSQLMerge, IFluentSQLMergeDef)
  strict private
    FAST: IFluentSQLAST;
    FDialect: TFluentSQLDriver;
    FTargetTable: string;
    FTargetAlias: string;
    FSourceTable: string;
    FSourceAlias: string;
    FSourceQuery: IFluentSQL;
    FOnCondition: string;
    FMatchedClauses: TInterfaceList;
    function _GetName: string;
  public
    constructor Create(const AAST: IFluentSQLAST);
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: string;
    { IFluentSQLMerge }
    function Into(const ATableName: string): IFluentSQLMerge; overload;
    function Into(const ATableName, AAlias: string): IFluentSQLMerge; overload;
    function Using(const ATableName: string): IFluentSQLMerge; overload;
    function Using(const ATableName, AAlias: string): IFluentSQLMerge; overload;
    function Using(const AQuery: IFluentSQL; const AAlias: string): IFluentSQLMerge; overload;
    function On(const ACondition: string): IFluentSQLMerge; overload;
    function On(const ACondition: array of const): IFluentSQLMerge; overload;
    function WhenMatched: IFluentSQLMergeWhenMatched;
    function WhenNotMatched: IFluentSQLMergeWhenNotMatched;
    function AsString: string;
    { IFluentSQLMergeDef }
    function GetDialect: TFluentSQLDriver;
    function GetTargetTable: string;
    function GetTargetAlias: string;
    function GetSourceTable: string;
    function GetSourceAlias: string;
    function GetSourceQuery: IFluentSQL;
    function GetOnCondition: string;
    function GetMatchedClauses: TInterfaceList;
  end;

implementation

uses
  FluentSQL.NameValue,
  FluentSQL.Utils,
  FluentSQL.Register;

{ TFluentSQLMergeMatchClause }

constructor TFluentSQLMergeMatchClause.Create(AParent: IFluentSQLMerge; AType: IFluentSQLMergeMatchClauseType);
begin
  inherited Create;
  FParent := AParent;
  FClauseType := AType;
  FValues := TFluentSQLNameValuePairs.Create;
end;

destructor TFluentSQLMergeMatchClause.Destroy;
begin
  FValues := nil;
  inherited;
end;

function TFluentSQLMergeMatchClause.Delete: IFluentSQLMerge;
begin
  FActionType := matDelete;
  Result := FParent;
end;

function TFluentSQLMergeMatchClause.GetActionType: IFluentSQLMergeActionType;
begin
  Result := FActionType;
end;

function TFluentSQLMergeMatchClause.GetClauseType: IFluentSQLMergeMatchClauseType;
begin
  Result := FClauseType;
end;

function TFluentSQLMergeMatchClause.GetCondition: string;
begin
  Result := FCondition;
end;

function TFluentSQLMergeMatchClause.GetValues: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

function TFluentSQLMergeMatchClause.Insert: IFluentSQLMerge;
begin
  FActionType := matInsert;
  Result := FParent;
end;

procedure TFluentSQLMergeMatchClause.SetCondition(const ACondition: string);
begin
  FCondition := ACondition;
end;

function TFluentSQLMergeMatchClause.Update: IFluentSQLMerge;
begin
  FActionType := matUpdate;
  Result := FParent;
end;

{ TFluentSQLMerge }

constructor TFluentSQLMerge.Create(const AAST: IFluentSQLAST);
begin
  inherited Create;
  FAST := AAST;
  FDialect := FAST.GetSerializationDialect;
  FMatchedClauses := TInterfaceList.Create;
  FAST._SetMerge(Self);
end;

destructor TFluentSQLMerge.Destroy;
begin
  FMatchedClauses.Free;
  inherited;
end;

function TFluentSQLMerge.AsString: string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.Serialize(FDialect).AsString(FAST);
  finally
    LReg.Free;
  end;
end;

procedure TFluentSQLMerge.Clear;
begin
  FTargetTable := '';
  FTargetAlias := '';
  FSourceTable := '';
  FSourceAlias := '';
  FSourceQuery := nil;
  FOnCondition := '';
  FMatchedClauses.Clear;
end;

function TFluentSQLMerge.IsEmpty: Boolean;
begin
  Result := FTargetTable = '';
end;

function TFluentSQLMerge.Serialize: string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.Serialize(FDialect).Merge(Self);
  finally
    LReg.Free;
  end;
end;

function TFluentSQLMerge._GetName: string;
begin
  Result := 'Merge';
end;

function TFluentSQLMerge.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentSQLMerge.GetMatchedClauses: TInterfaceList;
begin
  Result := FMatchedClauses;
end;

function TFluentSQLMerge.GetOnCondition: string;
begin
  Result := FOnCondition;
end;

function TFluentSQLMerge.GetSourceAlias: string;
begin
  Result := FSourceAlias;
end;

function TFluentSQLMerge.GetSourceQuery: IFluentSQL;
begin
  Result := FSourceQuery;
end;

function TFluentSQLMerge.GetSourceTable: string;
begin
  Result := FSourceTable;
end;

function TFluentSQLMerge.GetTargetAlias: string;
begin
  Result := FTargetAlias;
end;

function TFluentSQLMerge.GetTargetTable: string;
begin
  Result := FTargetTable;
end;

function TFluentSQLMerge.Into(const ATableName: string): IFluentSQLMerge;
begin
  FTargetTable := ATableName;
  Result := Self;
end;

function TFluentSQLMerge.Into(const ATableName, AAlias: string): IFluentSQLMerge;
begin
  FTargetTable := ATableName;
  FTargetAlias := AAlias;
  Result := Self;
end;

function TFluentSQLMerge.On(const ACondition: string): IFluentSQLMerge;
begin
  FOnCondition := ACondition;
  Result := Self;
end;

function TFluentSQLMerge.On(const ACondition: array of const): IFluentSQLMerge;
begin
  FOnCondition := TUtils.SqlArrayOfConstToParameterizedSql(ACondition, FAST.Params);
  Result := Self;
end;

function TFluentSQLMerge.Using(const ATableName: string): IFluentSQLMerge;
begin
  FSourceTable := ATableName;
  Result := Self;
end;

function TFluentSQLMerge.Using(const ATableName, AAlias: string): IFluentSQLMerge;
begin
  FSourceTable := ATableName;
  FSourceAlias := AAlias;
  Result := Self;
end;

function TFluentSQLMerge.Using(const AQuery: IFluentSQL; const AAlias: string): IFluentSQLMerge;
begin
  FSourceQuery := AQuery;
  FSourceAlias := AAlias;
  Result := Self;
end;

function TFluentSQLMerge.WhenMatched: IFluentSQLMergeWhenMatched;
var
  LClause: TFluentSQLMergeMatchClause;
begin
  LClause := TFluentSQLMergeMatchClause.Create(Self, mctMatched);
  FMatchedClauses.Add(LClause);
  Result := LClause;
end;

function TFluentSQLMerge.WhenNotMatched: IFluentSQLMergeWhenNotMatched;
var
  LClause: TFluentSQLMergeMatchClause;
begin
  LClause := TFluentSQLMergeMatchClause.Create(Self, mctNotMatched);
  FMatchedClauses.Add(LClause);
  Result := LClause;
end;

end.
