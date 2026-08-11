{
  ------------------------------------------------------------------------------
  FluentSQL
  Database-agnostic fluent SQL/MQL script generation library for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

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
  FluentSQL.Cache.Interfaces,
  FluentSQL.Merge;

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
                  secOrderBy = 8,
                  secMerge = 9);
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
    function _RelationAliasKeyword: String;
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
    function Merge: IFluentSQLMerge;
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
    function Exists(const ASubQuery: String): IFluentSQL; overload;
    function NotExists(const ASubQuery: String): IFluentSQL; overload;
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
  // AColumnValue e o lado DIREITO de "COLUNA = ...": posicao de VALOR, nunca de
  // expressao - e o que o proprio _InternalSet afirma com
  // _AssertSection([secInsert, secUpdate]). Por isso NAO usa
  // SqlArrayOfConstToParameterizedSql, onde a RN-P3 deixa string literal: ali
  // .SetValue('NOME', ['x''; DROP TABLE USERS; --']) emitia
  // "VALUES (x'; DROP TABLE USERS; --)" com ZERO parametros, enquanto
  // .SetValue('NIVEL', [7]) ja saia como :p1. O numerico parametrizava e a
  // string nao - assimetria dentro do MESMO slot.
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedValue(AColumnValue, FAST.Params));
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

/// <summary>
///   Como ESTE dialeto escreve o apelido de uma RELACAO. Unico ponto do nucleo
///   que faz a pergunta; From e _CreateJoin marcam o no recem-criado com a
///   resposta, e TFluentSQLName.Serialize so obedece.
///
///   O apelido de COLUNA nao passa por aqui de proposito: TFluentSQLName ja
///   nasce com 'AS', que os sete relacionais aceitam para c_alias - inclusive a
///   Oracle. A MESMA classe serve os dois papeis (Column monta em
///   FAST.ASTColumns, From e _CreateJoin montam em FAST.ASTTableNames e no
///   JoinedTable), entao aplicar a regra da relacao no Serialize sem distinguir
///   quebraria o apelido de coluna junto.
///
///   FRegister.Serialize levanta para dialeto nao registrado, mas nao ha
///   caminho novo de excecao aqui: TFluentSQL.Create ja falha antes, em
///   FRegister.Select, para o mesmo dialeto.
/// </summary>
function TFluentSQL._RelationAliasKeyword: String;
begin
  Result := FRegister.Serialize(FDatabase).RelationAliasKeyword;
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
      FAST.WithAlias,
      TUtils.BooleanToSQLFormat(FDatabase, Assigned(FAST.Merge))
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

/// <summary>
///   Porta unica dos QUATRO tipos de juncao: InnerJoin, LeftJoin, RightJoin e
///   FullJoin delegam todos aqui. Uma guarda, quatro construcoes fechadas.
///
///   ⭐ POR QUE O JOIN NAO ENTRA NO DELETE. A razao NAO e "o texto emitido nao
///   executa" - essa e verdadeira e e a menor das duas. A que decide e o DANO
///   SILENCIOSO, medido em motor real (transcricao com digest de imagem, versao
///   perguntada ao motor e contagem antes/depois em
///   Test Delphi\Common_tests\test.delete.join.matrix.sql):
///
///     Delete.From('A','X').LeftJoin('B','Y').OnCond('Y.AID = X.ID')   sem Where
///     -> forma nativa "DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID"
///     -> DOIS dos sete motores EXECUTAM, reportam sucesso e deixam
///        A: 4 -> 0     B: 2 -> 2        apagaram a tabela inteira
///
///   Na juncao EXTERNA a condicao e DECORATIVA: nao filtra nada, porque a
///   juncao preserva toda linha da relacao da esquerda. Quem escreveu aquilo
///   achava estar filtrando. Mesma classe do achado do Oracle no PR #160 -
///   apagar MAIS do que se pediu, sem erro; la era a relacao errada, aqui e a
///   relacao certa por inteiro.
///
///   POR QUE A FAMILIA TODA, e nao so o LEFT: dentro do DELETE os membros nao
///   significam a mesma coisa - o InnerJoin FILTRA (a forma nativa apaga 2 das
///   4), o LeftJoin NAO (apaga 4 das 4). Liberar so o InnerJoin criaria uma
///   distincao que a superficie fluente nao insinua e que gramatica nenhuma dos
///   sete espelha: 5 dos 7 recusam os dois por parse, 2 dos 7 aceitam os dois.
///
///   O QUE SE PERDE, dito sem maquiagem: para o InnerJoin ISOLADO existe forma
///   portavel, medida e aceita pelos SETE - "DELETE FROM A WHERE EXISTS (SELECT
///   1 FROM B WHERE ...)". A INTERSECAO NAO E VAZIA, e este comentario nao
///   finge que seja. Entregar so ela e tarefa propria, ja catalogada, com o
///   custo medido: o WHERE precisa migrar para DENTRO da subconsulta, porque
///   pode citar a relacao juntada ("WHERE (Y.Status = ?)" e alcancavel), e isso
///   nao e mudanca local - e ComposeSqlCore deixando de emitir Where.Serialize
///   na posicao de sempre para UMA secao.
///
///   O "ON" PENDURADO tambem morre aqui, e por cima. Sem OnCond o texto saia
///   "... INNER JOIN B AS Y ON", com ON e sem predicado - nao e produto
///   cartesiano, e sentenca TRUNCADA, e os sete a recusam (o DB2 e o que nomeia
///   melhor: espera "<boolean_predicate>"). A CAUSA continua de pe e e de OUTRA
///   tarefa: TFluentSQLJoins.Serialize (FluentSQL.Joins.pas) concatena 'ON'
///   incondicionalmente e TUtils.Concat descarta a condicao vazia, o que produz
///   o mesmo ON pendurado TAMBEM NO SELECT, que esta guarda nao toca.
///
///   POR QUE AQUI E NAO NUM SERIALIZADOR: falha na chamada que errou e nao la
///   adiante no AsString; vale para os dialetos todos sem uma linha por driver;
///   e nao acrescenta membro a IFluentSQLSerialize.
///
///   POR QUE NAO _AssertSection: aquele levanta Exception cru com "Not
///   supported in this section". Quem recebe esta recusa precisa do TIPO
///   proprio, para distinguir de outros erros do builder, e da mensagem que
///   aponta a saida - recusar sem saida seria pior que o defeito.
///
///   A guarda le a secao ATIVA, nao uma marca pegajosa: trocar para SELECT na
///   mesma instancia libera o JOIN de novo (travado por
///   test.delete.join.TTestDeleteJoin.TestSelectDepoisDeDeleteLiberaOJoin).
/// </summary>
function TFluentSQL._CreateJoin(AjoinType: TJoinType; const ATableName: String): IFluentSQL;
var
  LJoin: IFluentSQLJoin;
begin
  if FActiveSection = secDelete then
    raise EFluentSQLConstructNotSupported.Create(
      'JOIN em DELETE',
      'Medido em motor real: dos sete, cinco recusam o texto por parse e dois ' +
      'o executam - e sao esses dois o problema. Com LeftJoin e sem WHERE, a ' +
      'forma nativa apaga a tabela inteira (4 de 4 linhas) e reporta sucesso, ' +
      'porque na juncao externa a condicao nao filtra nada. Perde-se a tabela ' +
      'em silencio. O InnerJoin filtra e o LeftJoin nao, entao nao ha traducao ' +
      'unica para a familia, e liberar so o InnerJoin seria uma distincao que ' +
      'a API nao insinua.',
      'Restrinja a relacao alvo pelo WHERE com subconsulta - ' +
      'Where(...).Exists(''SELECT 1 FROM B WHERE ...''), que sai verbatim e e ' +
      'aceita pelos sete. Se o que se queria era apagar de duas relacoes, sao ' +
      'duas instrucoes.');
  FActiveSection := secJoin;
  LJoin := FAST.Joins.Add;
  LJoin.JoinType := AjoinType;
  FAST.ASTName := LJoin.JoinedTable;
  FAST.ASTName.AliasKeyword := _RelationAliasKeyword;
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

/// <summary>
///   Desc marca a ULTIMA coluna do ORDER BY, logo exige que exista uma.
///
///   A guarda era um Assert (FluentSQL.pas:838 antes desta mudanca) e tinha
///   dois problemas independentes:
///
///   1. Assert some com {$C-}, o default de release. Sem ele, .OrderBy().Desc
///      cai em Columns[-1] e o erro que chega ao chamador e um
///      EArgumentOutOfRangeException de dentro da TList, sem nome de metodo.
///   2. Afirmava sobre FAST.ASTColumns e indexava FAST.OrderBy.Columns. Hoje as
///      duas sao o MESMO objeto enquanto a secao e secOrderBy - quem as liga e
///      _DefineSectionOrderBy (FluentSQL.pas:794, "FAST.ASTColumns :=
///      FAST.OrderBy.Columns") e _SetSection nao tem caminho de saida que
///      desfaca isso antes do _AssertSection([secOrderBy]) daqui. Ou seja: a
///      afirmacao NAO estava medindo colecao errada na pratica. Continuava
///      sendo o nome errado para ler, e passa a citar a colecao que de fato
///      indexa.
///
///   Nao ha Asc para receber a mesma guarda: a interface nao tem esse metodo
///   (dirAscending e o default de TFluentSQLOrderByColumn). Desc e o unico
///   modificador de direcao da API.
/// </summary>
function TFluentSQL.Desc: IFluentSQL;
begin
  _AssertSection([secOrderBy]);
  if FAST.OrderBy.Columns.Count = 0 then
    raise EArgumentException.Create(
      'IFluentSQL.Desc chamado sem nenhuma coluna no ORDER BY: Desc marca a ' +
      'ultima coluna da clausula, e nao ha ultima. Passe a coluna em OrderBy ' +
      '(".OrderBy(''NOME'').Desc") em vez de ".OrderBy().Desc".');
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

function TFluentSQL.Exists(const ASubQuery: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsExists(ASubQuery));
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

/// <summary>
///   No SELECT, From acumula relacoes e vira a lista separada por virgula do
///   FROM - forma valida e antiga. No DELETE, a MESMA chamada acumulava do
///   mesmo jeito e produzia "DELETE FROM A AS X, B AS Y", que NENHUM dos sete
///   motores relacionais analisa. Medido, transcricao literal em
///   Test Delphi\Common_tests\test.delete.multirelacao.matrix.sql:
///
///     SQL Server 2022 16.0.4265.3  Msg 156 / Msg 102
///     Oracle 23.26.2.0.0           ORA-03048
///     PostgreSQL 16.14             syntax error at or near ","
///     MySQL 8.4.11                 ERROR 1064
///     Firebird 5.0.4               SQL error code = -104
///     SQLite 3.53.4                near ",": syntax error
///     DB2 12.1.5.0                 SQL0104N
///
///   Nao ha o que emitir no lugar, e NAO por falta de esforco: as formas
///   multi-relacao nativas nao querem dizer a mesma coisa umas que as outras.
///   "DELETE X FROM A X JOIN B Y" (T-SQL) e "DELETE FROM A USING B" (PostgreSQL
///   e Oracle 23ai) apagam de UMA relacao filtrando pela outra; "DELETE X, Y
///   FROM A X JOIN B Y" (MySQL) apaga das DUAS - e o T-SQL RECUSA essa segunda
///   (Msg 102, medido). Traduzir uma chamada para formas de semantica diferente
///   por dialeto seria trocar SQL que nao executa por SQL que executa APAGANDO
///   COISAS DIFERENTES conforme o banco.
///
///   E a API nao tem como saber qual das duas foi pedida: nao ha designador de
///   alvo, nao ha condicao de juncao propria da secao, nao ha marcador de
///   relacao auxiliar. Duas chamadas de From num DELETE nao expressam nada.
///
///   A GUARDA ESTA AQUI, e nao no serializador, por tres razoes: falha na
///   chamada que errou e nao la adiante no AsString; vale para os dialetos
///   todos sem uma linha por driver; e nao acrescenta membro a
///   IFluentSQLSerialize.
///
///   O QUE ELA FECHA, COM PRECISAO: a LISTA DE RELACOES DO FROM da secao
///   DELETE. Este e o unico ponto de entrada que alimenta FAST.ASTTableNames -
///   IFluentSQL nao publica o AST, entao IFluentSQLDelete.TableNames.Add nao e
///   alcancavel por consumidor.
///
///   O QUE ELA NAO FECHA, e que ninguem deve ler que fecha: a secao DELETE NAO
///   esta selada. _CreateJoin (nesta mesma unit, em
///   "function TFluentSQL._CreateJoin(AjoinType: TJoinType; const ATableName:
///   String): IFluentSQL") e um SEGUNDO ponto de entrada publico que poe outra
///   relacao num DELETE: ele nao chama _AssertSection e nao passa por
///   ASTTableNames, entao Delete.From('A').InnerJoin('B').OnCond(...) continua
///   emitindo "DELETE FROM A INNER JOIN B ON ...".
///
///   E OUTRA construcao, por OUTRA porta, E COM OUTRA RESPOSTA - registrada
///   como divida na Parte 8 de
///   Test Delphi\Common_tests\test.delete.multirelacao.matrix.sql. Ao contrario
///   do caso desta guarda, a do JOIN e TRADUZIVEL e nao recusavel: medido pela
///   revisao desta tarefa, "DELETE X FROM A AS X INNER JOIN B AS Y ON ..." e
///   ACEITO pelo SQL Server. Quem for mexer la NAO deve copiar a decisao daqui.
/// </summary>
function TFluentSQL.From(const ATableName: String): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete]);
  if (FActiveSection = secDelete) and (FAST.ASTTableNames.Count > 0) then
    raise EFluentSQLConstructNotSupported.Create(
      'DELETE com mais de uma relacao',
      'Emita um DELETE por relacao, ou restrinja a unica relacao alvo pelo ' +
      'WHERE - inclusive com subconsulta, que e portavel nos sete. Se o que ' +
      'se queria era apagar de duas tabelas, sao duas instrucoes.');
  FAST.ASTName := FAST.ASTTableNames.Add;
  FAST.ASTName.AliasKeyword := _RelationAliasKeyword;
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

function TFluentSQL.NotExists(const ASubQuery: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotExists(ASubQuery));
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

function TFluentSQL.Merge: IFluentSQLMerge;
begin
  _SetSection(secMerge);
  Result := TFluentSQLMerge.Create(FAST);
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
    secMerge:   ; // MERGE is handled by its own builder but we must allow the section
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
  // Mesmo slot de VALOR de SetValue(array of const) - ver o comentario la.
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedValue(AColumnValue, FAST.Params));
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






