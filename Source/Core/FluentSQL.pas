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

unit FluentSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Operators,
  FluentSQL.Functions,
  FluentSQL.Interfaces,
  FluentSQL.Cases,
  FluentSQL.Select,
  FluentSQL.Utils,
  FluentSQL.Serialize,
  FluentSQL.Qualifier,
  FluentSQL.Ast,
  FluentSQL.Expression,
  FluentSQL.Register,
  FluentSQL.Params,
  FluentSQL.SerializeMongoDB,
  FluentSQL.Cache.Interfaces;

type
  TFluentSQLDriver = FluentSQL.Interfaces.TFluentSQLDriver;
  FluentSQLFun = FluentSQL.Functions.TFluentSQLFunctions;

  TFluentSQL = class(TInterfacedObject, IFluentSQL)
  strict private
    class var FDatabaseDafault: TFluentSQLDriver;
    type
      TSection = (secSelect = 0,
                  secDelete = 1,
                  secInsert = 2,
                  secUpdate = 3,
                  secJoin = 4,
                  secWhere= 5,
                  secGroupBy = 6,
                  secHaving = 7,
                  secOrderBy = 8);
      TSections = set of TSection;
  strict private
    FActiveSection: TSection;
    FActiveOperator: TOperator;
    FActiveExpr: IFluentSQLCriteriaExpression;
    FActiveValues: IFluentSQLNameValuePairs;
    FDatabase: TFluentSQLDriver;
    FOperator: IFluentSQLOperators;
    FFunction: IFluentSQLFunctions;
    FAST: IFluentSQLAST;
    FRegister: TFluentSQLRegister;
    FCacheProvider: IFluentSQLCacheProvider;
    FCacheTTL: Integer;
    procedure _AssertSection(ASections: TSections);
    procedure _AssertOperator(AOperators: TOperators);
    procedure _AssertHaveName;
    procedure _SetSection(ASection: TSection);
    procedure _DefineSectionSelect;
    procedure _DefineSectionDelete;
    procedure _DefineSectionInsert;
    procedure _DefineSectionUpdate;
    procedure _DefineSectionWhere;
    procedure _DefineSectionGroupBy;
    procedure _DefineSectionHaving;
    procedure _DefineSectionOrderBy;
    function _CreateJoin(AjoinType: TJoinType; const ATableName: String): IFluentSQL;
    function _InternalSet(const AColumnName, AColumnValue: String): IFluentSQL;
  public
    constructor Create(const ADatabase: TFluentSQLDriver);
    destructor Destroy; override;
    class procedure SetDatabaseDafault(const ADatabase: TFluentSQLDriver);
    function AndOpe(const AExpression: array of const): IFluentSQL; overload;
    function AndOpe(const AExpression: String): IFluentSQL; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Alias(const AAlias: String): IFluentSQL;
    function CaseExpr(const AExpression: String = ''): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function Clear: IFluentSQL;
    function ClearAll: IFluentSQL;
    function All: IFluentSQL;
    function Column(const AColumnName: String = ''): IFluentSQL; overload;
    function Column(const ATableName: String; const AColumnName: String): IFluentSQL; overload;
    function Column(const AColumnsName: array of const): IFluentSQL; overload;
    function Column(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Delete: IFluentSQL;
    function Desc: IFluentSQL;
    function Distinct: IFluentSQL;
    function IsEmpty: Boolean;
    function Expression(const ATerm: String = ''): IFluentSQLCriteriaExpression; overload;
    function Expression(const ATerm: array of const): IFluentSQLCriteriaExpression; overload;
    function From(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function From(const AQuery: IFluentSQL): IFluentSQL; overload;
    function From(const ATableName: String): IFluentSQL; overload;
    function From(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function GroupBy(const AColumnName: String = ''): IFluentSQL;
    function Having(const AExpression: String = ''): IFluentSQL; overload;
    function Having(const AExpression: array of const): IFluentSQL; overload;
    function Having(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Insert: IFluentSQL;
    function AddRow: IFluentSQL;
    function Into(const ATableName: String): IFluentSQL;
    function FullJoin(const ATableName: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String): IFluentSQL; overload;
    function FullJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function OnCond(const AExpression: String): IFluentSQL; overload;
    function OnCond(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: String): IFluentSQL; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function OrderBy(const AColumnName: String = ''): IFluentSQL; overload;
    function OrderBy(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Select(const AColumnName: String = ''): IFluentSQL; overload;
    function Select(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function WithAlias(const AAlias: String): IFluentSQL;
    function Over(const APartitionBy, AOrderBy: String): IFluentSQL;
    function Union(const AQuery: IFluentSQL): IFluentSQL;
    function UnionAll(const AQuery: IFluentSQL): IFluentSQL;
    function Intersect(const AQuery: IFluentSQL): IFluentSQL;
    function SetValue(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Extended; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Double; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Currency; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDate): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDateTime): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TGUID): IFluentSQL; overload;
    function Values(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function Values(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function First(const AValue: Integer): IFluentSQL;
    function Skip(const AValue: Integer): IFluentSQL;
    function Update(const ATableName: String): IFluentSQL;
    function Where(const AExpression: String = ''): IFluentSQL; overload;
    function Where(const AExpression: array of const): IFluentSQL; overload;
    function Where(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    // Operators methods
    function Equal(const AValue: String = ''): IFluentSQL; overload;
    function Equal(const AValue: Extended): IFluentSQL overload;
    function Equal(const AValue: Integer): IFluentSQL; overload;
    function Equal(const AValue: TDate): IFluentSQL; overload;
    function Equal(const AValue: TDateTime): IFluentSQL; overload;
    function Equal(const AValue: TGUID): IFluentSQL; overload;
    function NotEqual(const AValue: String = ''): IFluentSQL; overload;
    function NotEqual(const AValue: Extended): IFluentSQL; overload;
    function NotEqual(const AValue: Integer): IFluentSQL; overload;
    function NotEqual(const AValue: TDate): IFluentSQL; overload;
    function NotEqual(const AValue: TDateTime): IFluentSQL; overload;
    function NotEqual(const AValue: TGUID): IFluentSQL; overload;
    function GreaterThan(const AValue: Extended): IFluentSQL; overload;
    function GreaterThan(const AValue: Integer) : IFluentSQL; overload;
    function GreaterThan(const AValue: String) : IFluentSQL; overload;
    function GreaterThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterThan(const AValue: TDateTime) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: Extended): IFluentSQL; overload;
    function GreaterEqThan(const AValue: Integer) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: String) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDateTime) : IFluentSQL; overload;
    function LessThan(const AValue: Extended): IFluentSQL; overload;
    function LessThan(const AValue: Integer) : IFluentSQL; overload;
    function LessThan(const AValue: String) : IFluentSQL; overload;
    function LessThan(const AValue: TDate): IFluentSQL; overload;
    function LessThan(const AValue: TDateTime) : IFluentSQL; overload;
    function LessEqThan(const AValue: Extended): IFluentSQL; overload;
    function LessEqThan(const AValue: Integer) : IFluentSQL; overload;
    function LessEqThan(const AValue: String) : IFluentSQL; overload;
    function LessEqThan(const AValue: TDate): IFluentSQL; overload;
    function LessEqThan(const AValue: TDateTime) : IFluentSQL; overload;
    function IsNull: IFluentSQL;
    function IsNotNull: IFluentSQL;
    function Like(const AValue: String): IFluentSQL;
    function LikeFull(const AValue: String): IFluentSQL;
    function LikeLeft(const AValue: String): IFluentSQL;
    function LikeRight(const AValue: String): IFluentSQL;
    function NotLike(const AValue: String): IFluentSQL;
    function NotLikeFull(const AValue: String): IFluentSQL;
    function NotLikeLeft(const AValue: String): IFluentSQL;
    function NotLikeRight(const AValue: String): IFluentSQL;
    function InValues(const AValue: TArray<Double>): IFluentSQL; overload;
    function InValues(const AValue: TArray<String>): IFluentSQL; overload;
    function InValues(const AValue: String): IFluentSQL; overload;
    function NotIn(const AValue: TArray<Double>): IFluentSQL; overload;
    function NotIn(const AValue: TArray<String>): IFluentSQL; overload;
    function NotIn(const AValue: String): IFluentSQL; overload;
    function Exists(const AValue: String): IFluentSQL; overload;
    function NotExists(const AValue: String): IFluentSQL; overload;
    // Functions methods
    function Count: IFluentSQL;
    function Lower: IFluentSQL;
    function Min: IFluentSQL;
    function Max: IFluentSQL;
    function Upper: IFluentSQL;
    function SubString(const AStart: Integer; const ALength: Integer): IFluentSQL;
    function Date(const AValue: String): IFluentSQL;
    function Day(const AValue: String): IFluentSQL;
    function Month(const AValue: String): IFluentSQL;
    function Year(const AValue: String): IFluentSQL;
    function Concat(const AValue: array of String): IFluentSQL;
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string): IFluentSQL; overload;
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const): IFluentSQL; overload;
    // Result full command sql
    function AsFun: IFluentSQLFunctions;
    function AsString: String;
    /// <summary>MongoDB (dbnMongoDB): fragmento JSON da secção SELECT (ADR-013 §2b); vazio noutros dialetos.</summary>
    function MongoSelectFragment: String;
    function Params: IFluentSQLParams;
    function WithCache(const AProvider: IFluentSQLCacheProvider): IFluentSQL;
    function WithTTL(const ASeconds: Integer): IFluentSQL;
  end;

function Query(const ADatabase: TFluentSQLDriver): IFluentSQL;
function Schema(const ADatabase: TFluentSQLDriver): IFluentSchema;

function TCQ(const ADatabase: TFluentSQLDriver): IFluentSQL; deprecated 'Use ''FluentSQL.Query'' instead';

function CreateFluentSQL(const ADatabase: TFluentSQLDriver): IFluentSQL; deprecated 'Use ''FluentSQL.Query'' instead';

function Func(const ADatabase: TFluentSQLDriver): IFluentSQLFunctions;


implementation

uses
  FluentSQL.DDL;

{ FluentSQL }

type
  TStaticFuncWrapper = class(TInterfacedObject, IFluentSQLFunctions)
  private
    FRegister: TFluentSQLRegister;
    FFuncs: IFluentSQLFunctions;
  public
    constructor Create(const ADatabase: TFluentSQLDriver);
    destructor Destroy; override;
    property Funcs: IFluentSQLFunctions read FFuncs implements IFluentSQLFunctions;
  end;

constructor TStaticFuncWrapper.Create(const ADatabase: TFluentSQLDriver);
begin
  inherited Create;
  FRegister := TFluentSQLRegister.Create;
  FFuncs := TFluentSQLFunctions.Create(ADatabase, FRegister);
end;

destructor TStaticFuncWrapper.Destroy;
begin
  FFuncs := nil;
  FRegister.Free;
  inherited;
end;

function Func(const ADatabase: TFluentSQLDriver): IFluentSQLFunctions;
begin
  Result := TStaticFuncWrapper.Create(ADatabase);
end;

function Query(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  // A chamada interna para o construtor evita o warning the deprecation 
  Result := TFluentSQL.Create(ADatabase);
end;

function Schema(const ADatabase: TFluentSQLDriver): IFluentSchema;
begin
  Result := TFluentSchema.Create(ADatabase);
end;

function TCQ(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  Result := TFluentSQL.Create(ADatabase);
end;

function CreateFluentSQL(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  Result := TFluentSQL.Create(ADatabase);
end;


{ TFluentSQL }

function TFluentSQL.Alias(const AAlias: String): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Alias := AAlias;
  Result := Self;
end;

function TFluentSQL.AsFun: IFluentSQLFunctions;
begin
  Result := FFunction;
end;

function TFluentSQL.ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string): IFluentSQL;
begin
  FAST.AddDialectOnly(ADialect, ASqlFragment);
  Result := Self;
end;

function TFluentSQL.ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const): IFluentSQL;
begin
  Result := ForDialectOnly(ADialect, TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.CaseExpr(const AExpression: String): IFluentSQLCriteriaCase;
var
  LExpression: String;
begin
  LExpression := AExpression;
  if LExpression = '' then
    LExpression := FAST.ASTName.Name;
  Result := TFluentSQLCriteriaCase.Create(Self, LExpression);
  if Assigned(FAST) then
    FAST.ASTName.CaseExpr := Result.CaseExpr;
end;

function TFluentSQL.CaseExpr(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  Result := CaseExpr(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.CaseExpr(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  Result := TFluentSQLCriteriaCase.Create(Self, '');
  Result.AndOpe(AExpression);
end;

function TFluentSQL.AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  FActiveOperator := opeAND;
  FActiveExpr.AndOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQL.AndOpe(const AExpression: String): IFluentSQL;
begin
  FActiveOperator := opeAND;
  FActiveExpr.AndOpe(AExpression);
  Result := Self;
end;

function TFluentSQL.AndOpe(const AExpression: array of const): IFluentSQL;
begin
  Result := AndOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.OrOpe(const AExpression: array of const): IFluentSQL;
begin
  Result := OrOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.OrOpe(const AExpression: String): IFluentSQL;
begin
  FActiveOperator := opeOR;
  FActiveExpr.OrOpe(AExpression);
  Result := Self;
end;

function TFluentSQL.OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  FActiveOperator := opeOR;
  FActiveExpr.OrOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: array of const): IFluentSQL;
begin
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedSql(AColumnValue, FAST.Params));
end;

function TFluentSQL.SetValue(const AColumnName, AColumnValue: String): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftString);
  Result := Self;
end;

function TFluentSQL.OnCond(const AExpression: String): IFluentSQL;
begin
  Result := AndOpe(AExpression);
end;

function TFluentSQL.OnCond(const AExpression: array of const): IFluentSQL;
begin
  Result := OnCond(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.InValues(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftInteger);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Extended; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Double; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Currency; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TDate): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftDate);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TDateTime): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftDateTime);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TGUID): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue.ToString, dftGuid);
  Result := Self;
end;

class procedure TFluentSQL.SetDatabaseDafault(const ADatabase: TFluentSQLDriver);
begin
  FDatabaseDafault := ADatabase;
end;

function TFluentSQL.All: IFluentSQL;
begin
  if not (FDatabase in [dbnMongoDB]) then
    Result := Column('*')
  else
    Result := Self;
end;

procedure TFluentSQL._AssertHaveName;
begin
  if not Assigned(FAST.ASTName) then
    raise Exception.Create('TCriteria: Current name is not set');
end;

procedure TFluentSQL._AssertOperator(AOperators: TOperators);
begin
  if not (FActiveOperator in AOperators) then
    raise Exception.Create('TFluentSQL: Not supported in this operator');
end;

procedure TFluentSQL._AssertSection(ASections: TSections);
begin
  if not (FActiveSection in ASections) then
    raise Exception.Create('TFluentSQL: Not supported in this section');
end;

function TFluentSQL.AsString: String;
var
  LKey: string;
  I: Integer;
  LDialectItem: TDialectOnlyFragment;
begin
  FActiveOperator := opeNone;

  if Assigned(FCacheProvider) then
  begin
    // Generate deterministic key based on Dialect and all AST sections to avoid collisions (Review ESP-032 rejection)
    LKey := Format('dialect:%d|select:%s|insert:%s|update:%s|delete:%s|where:%s|joins:%s|groupby:%s|having:%s|orderby:%s|union:%s|alias:%s', [
      Integer(FDatabase),
      FAST.Select.Serialize,
      FAST.Insert.Serialize,
      FAST.Update.Serialize,
      FAST.Delete.Serialize,
      FAST.Where.Serialize,
      FAST.Joins.Serialize,
      FAST.GroupBy.Serialize,
      FAST.Having.Serialize,
      FAST.OrderBy.Serialize,
      FAST.UnionType,
      FAST.WithAlias
    ]);

    if Assigned(FAST.UnionQuery) then
      LKey := LKey + '|unionquery:' + FAST.UnionQuery.AsString;

    for I := 0 to FAST.DialectOnlyCount - 1 do
    begin
      LDialectItem := FAST.GetDialectOnlyItem(I);
      LKey := LKey + Format('|dialectonly:%d:%s', [Integer(LDialectItem.Dialect), LDialectItem.Sql]);
    end;

    LKey := TUtils.GetHash(LKey);

    Result := FCacheProvider.Get(LKey);
    if Result <> '' then
      Exit;
  end;

  Result := FRegister.Serialize(FDatabase).AsString(FAST);

  if Assigned(FCacheProvider) and (Result <> '') then
    FCacheProvider.SetCache(LKey, Result, FCacheTTL);
end;

function TFluentSQL.MongoSelectFragment: String;
begin
  if FDatabase <> dbnMongoDB then
    Exit('');
  Result := FluentMongoSelectSerializeFragment(FAST.Select);
end;

function TFluentSQL.Params: IFluentSQLParams;
begin
  if (FAST.UnionType <> '') and Assigned(FAST.UnionQuery) then
    Result := TFluentSQLMergedParams.Create(FAST.Params, FAST.UnionQuery.Params)
  else
    Result := FAST.Params;
end;

function TFluentSQL.Column(const AColumnName: String): IFluentSQL;
begin
  if Assigned(FAST) then
  begin
    FAST.ASTName := FAST.ASTColumns.Add;
    FAST.ASTName.Name := AColumnName;
  end
  else
    raise Exception.CreateFmt('Current section [%s] does not support COLUMN.', [FAST.ASTSection.Name]);
  Result := Self;
end;

function TFluentSQL.Column(const ATableName: String; const AColumnName: String): IFluentSQL;
begin
  Result := Column(ATableName + '.' + AColumnName);
end;

function TFluentSQL.Clear: IFluentSQL;
begin
  FAST.ASTSection.Clear;
  Result := Self;
end;

function TFluentSQL.ClearAll: IFluentSQL;
begin
  FAST.Clear;
  Result := Self;
end;

function TFluentSQL.Column(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  if Assigned(FAST.ASTColumns) then
  begin
    FAST.ASTName := FAST.ASTColumns.Add;
    FAST.ASTName.CaseExpr := ACaseExpression.CaseExpr;
  end
  else
    raise Exception.CreateFmt('Current section [%s] does not support COLUMN.', [FAST.ASTSection.Name]);
  Result := Self;
end;

function TFluentSQL.Concat(const AValue: array of String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Concat(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Concat(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.Count: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Count(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Column(const AColumnsName: array of const): IFluentSQL;
begin
  Result := Column(TUtils.SqlArrayOfConstToParameterizedSql(AColumnsName, FAST.Params));
end;

constructor TFluentSQL.Create(const ADatabase: TFluentSQLDriver);
begin
  FDatabase := ADatabase;
  FRegister := TFluentSQLRegister.Create;
  FAST := TFluentSQLAST.Create(FDatabase, FRegister);
  FOperator := TFluentSQLOperators.Create(FDatabase, FAST.Params);
  FFunction := TFluentSQLFunctions.Create(FDatabase, FRegister);
  FAST.Clear;
  FActiveOperator := opeNone;
  FCacheTTL := 3600; // Default TTL: 1 hour
end;

function TFluentSQL.WithCache(const AProvider: IFluentSQLCacheProvider): IFluentSQL;
begin
  FCacheProvider := AProvider;
  Result := Self;
end;

function TFluentSQL.WithTTL(const ASeconds: Integer): IFluentSQL;
begin
  FCacheTTL := ASeconds;
  Result := Self;
end;

function TFluentSQL._CreateJoin(AjoinType: TJoinType; const ATableName: String): IFluentSQL;
var
  LJoin: IFluentSQLJoin;
begin
  FActiveSection := secJoin;
  LJoin := FAST.Joins.Add;
  LJoin.JoinType := AjoinType;
  FAST.ASTName := LJoin.JoinedTable;
  FAST.ASTName.Name := ATableName;
  FAST.ASTSection := LJoin;
  FAST.ASTColumns := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(LJoin.Condition, FAST.Params);
  Result := Self;
end;

function TFluentSQL.Date(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Date(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Date(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.Day(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Day(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Day(AValue));
  end;
  Result := Self;
end;

procedure TFluentSQL._DefineSectionDelete;
begin
  ClearAll();
  FAST.ASTSection := FAST.Delete;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := FAST.Delete.TableNames;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionGroupBy;
begin
  FAST.ASTSection := FAST.GroupBy;
  FAST.ASTColumns := FAST.GroupBy.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionHaving;
begin
  FAST.ASTSection := FAST.Having;
  FAST.ASTColumns   := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(FAST.Having.Expression, FAST.Params);
  FAST.ASTTableNames := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionInsert;
begin
  ClearAll();
  FAST.ASTSection := FAST.Insert;
  FAST.ASTColumns := FAST.Insert.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := FAST.Insert.Values;
end;

procedure TFluentSQL._DefineSectionOrderBy;
begin
  FAST.ASTSection := FAST.OrderBy;
  FAST.ASTColumns := FAST.OrderBy.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionSelect;
begin
  ClearAll();
  FAST.ASTSection := FAST.Select;
  FAST.ASTColumns := FAST.Select.Columns;
  FAST.ASTTableNames := FAST.Select.TableNames;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionUpdate;
begin
  ClearAll();
  FAST.ASTSection := FAST.Update;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := FAST.Update.Values;
end;

procedure TFluentSQL._DefineSectionWhere;
begin
  FAST.ASTSection := FAST.Where;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(FAST.Where.Expression, FAST.Params);
  FActiveValues := nil;
end;

function TFluentSQL.Delete: IFluentSQL;
begin
  _SetSection(secDelete);
  Result := Self;
end;

function TFluentSQL.Desc: IFluentSQL;
begin
  _AssertSection([secOrderBy]);
  Assert(FAST.ASTColumns.Count > 0, 'TCriteria.Desc: No columns set up yet');
  (FAST.OrderBy.Columns[FAST.OrderBy.Columns.Count -1] as IFluentSQLOrderByColumn).Direction := dirDescending;
  Result := Self;
end;

destructor TFluentSQL.Destroy;
begin
  FActiveExpr := nil;
  FActiveValues := nil;
  FOperator := nil;
  FFunction := nil;
  FAST := nil;
  inherited;
end;

function TFluentSQL.Distinct: IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqDistinct;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  if AValue = '' then
    FActiveExpr.Fun(FOperator.IsEqual(AValue))
  else
    FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Exists(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsExists(AValue));
  Result := Self;
end;

function TFluentSQL.Expression(const ATerm: array of const): IFluentSQLCriteriaExpression;
begin
  Result := TFluentSQLCriteriaExpression.Create(
    TUtils.SqlArrayOfConstToParameterizedSql(ATerm, FAST.Params),
    FAST.Params);
end;

function TFluentSQL.Expression(const ATerm: String): IFluentSQLCriteriaExpression;
begin
  Result := TFluentSQLCriteriaExpression.Create(ATerm, FAST.Params);
end;

function TFluentSQL.From(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  Result := From('(' + AExpression.AsString + ')');
end;

function TFluentSQL.From(const AQuery: IFluentSQL): IFluentSQL;
begin
  Result := From('(' + AQuery.AsString + ')');
end;

function TFluentSQL.From(const ATableName: String): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete]);
  FAST.ASTName := FAST.ASTTableNames.Add;
  FAST.ASTName.Name := ATableName;
  Result := Self;
end;

function TFluentSQL.FullJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtFULL, ATableName);
end;

function TFluentSQL.GreaterThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GroupBy(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secGroupBy);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Having(const AExpression: String): IFluentSQL;
begin
  _SetSection(secHaving);
  if AExpression = '' then
    Result := Self
  else
    Result := AndOpe(AExpression);
end;

function TFluentSQL.Having(const AExpression: array of const): IFluentSQL;
begin
  Result := Having(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.Having(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  _SetSection(secHaving);
  Result := AndOpe(AExpression);
end;

function TFluentSQL.InnerJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtINNER, ATableName);
end;

function TFluentSQL.InnerJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  InnerJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.Insert: IFluentSQL;
begin
  _SetSection(secInsert);
  Result := Self;
end;

function TFluentSQL.AddRow: IFluentSQL;
begin
  _AssertSection([secInsert]);
  FAST.Insert.AddRow;
  Result := Self;
end;

function TFluentSQL._InternalSet(const AColumnName, AColumnValue: String): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := AColumnValue;
  Result := Self;
end;

function TFluentSQL.Into(const ATableName: String): IFluentSQL;
begin
  _AssertSection([secInsert]);
  FAST.Insert.TableName := ATableName;
  Result := Self;
end;

function TFluentSQL.IsEmpty: Boolean;
begin
  Result := FAST.ASTSection.IsEmpty;
end;

function TFluentSQL.InValues(const AValue: TArray<String>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.InValues(const AValue: TArray<Double>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.IsNotNull: IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotNull);
  Result := Self;
end;

function TFluentSQL.IsNull: IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNull);
  Result := Self;
end;

function TFluentSQL.LeftJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtLEFT, ATableName);
end;

function TFluentSQL.LeftJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  LeftJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.Like(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLike(AValue));
  Result := Self;
end;

function TFluentSQL.LikeFull(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeFull(AValue));
  Result := Self;
end;

function TFluentSQL.LikeLeft(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeLeft(AValue));
  Result := Self;
end;

function TFluentSQL.LikeRight(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeRight(AValue));
  Result := Self;
end;

function TFluentSQL.Lower: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Lower(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Max: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Max(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Min: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Min(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Month(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Month(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Month(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotExists(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotExists(AValue));
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: TArray<String>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: TArray<Double>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.NotLike(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLike(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeFull(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeFull(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeLeft(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeLeft(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeRight(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeRight(AValue));
  Result := Self;
end;

function TFluentSQL.OrderBy(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  _SetSection(secOrderBy);
  Result := Column(ACaseExpression);
end;

function TFluentSQL.RightJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  RightJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.RightJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtRIGHT, ATableName);
end;

function TFluentSQL.OrderBy(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secOrderBy);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Select(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secSelect);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Select(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  _SetSection(secSelect);
  Result := Column(ACaseExpression);
end;

procedure TFluentSQL._SetSection(ASection: TSection);
begin
  case ASection of
    secSelect:  _DefineSectionSelect;
    secDelete:  _DefineSectionDelete;
    secInsert:  _DefineSectionInsert;
    secUpdate:  _DefineSectionUpdate;
    secWhere:   _DefineSectionWhere;
    secGroupBy: _DefineSectionGroupBy;
    secHaving:  _DefineSectionHaving;
    secOrderBy: _DefineSectionOrderBy;
  else
      raise Exception.Create('TCriteria.SetSection: Unknown section');
  end;
  FActiveSection := ASection;
end;

function TFluentSQL.WithAlias(const AAlias: String): IFluentSQL;
begin
  FAST.WithAlias := AAlias;
  Result := Self;
end;

function TFluentSQL.Over(const APartitionBy, AOrderBy: String): IFluentSQL;
var
  LOverStr: String;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  LOverStr := ' OVER (';
  if APartitionBy <> '' then
    LOverStr := LOverStr + 'PARTITION BY ' + APartitionBy;
  if AOrderBy <> '' then
  begin
    if APartitionBy <> '' then
      LOverStr := LOverStr + ' ';
    LOverStr := LOverStr + 'ORDER BY ' + AOrderBy;
  end;
  LOverStr := LOverStr + ')';
  FAST.ASTName.Name := FAST.ASTName.Name + LOverStr;
  Result := Self;
end;

function TFluentSQL.Union(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'UNION';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.UnionAll(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'UNION ALL';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.Intersect(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'INTERSECT';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.First(const AValue: Integer): IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect, secWhere, secOrderBy, secGroupBy, secHaving]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqFirst;
  LQualifier.Value := AValue;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.Skip(const AValue: Integer): IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect, secWhere, secOrderBy, secGroupBy, secHaving]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqSkip;
  LQualifier.Value := AValue;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.SubString(const AStart, ALength: Integer): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.SubString(FAST.ASTName.Name, AStart, ALength);
  Result := Self;
end;

function TFluentSQL.Update(const ATableName: String): IFluentSQL;
begin
  _SetSection(secUpdate);
  FAST.Update.TableName := ATableName;
  Result := Self;
end;

function TFluentSQL.Upper: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Upper(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Values(const AColumnName: String; const AColumnValue: array of const): IFluentSQL;
begin
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedSql(AColumnValue, FAST.Params));
end;

function TFluentSQL.Values(const AColumnName, AColumnValue: String): IFluentSQL;
begin
  Result := SetValue(AColumnName, AColumnValue);
end;

function TFluentSQL.Where(const AExpression: String): IFluentSQL;
begin
  _SetSection(secWhere);
  FActiveOperator := opeWhere;
  if AExpression = '' then
    Result := Self
  else
    Result := AndOpe(AExpression);
end;

function TFluentSQL.Where(const AExpression: array of const): IFluentSQL;
begin
  Result := Where(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.Where(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  _SetSection(secWhere);
  FActiveOperator := opeWhere;
  Result := AndOpe(AExpression);
end;

function TFluentSQL.Year(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Year(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Year(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.From(const ATableName, AAlias: String): IFluentSQL;
begin
  From(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.FullJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  FullJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TGUID): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TGUID): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

end.






