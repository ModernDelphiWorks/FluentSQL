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

unit FluentSQL.Operators;


{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  StrUtils,
  Variants,
  FluentSQL.Interfaces,
  FluentSQL.Utils,
  FluentSQL.Params;
  
type
  TFluentSQLOperator = class(TInterfacedObject, IFluentSQLOperator)
  strict private
    FDatabase: TFluentSQLDriver;
    FParams: IFluentSQLParams;
    function _GetColumnName: String;
    function _GetCompare: TFluentSQLOperatorCompare;
    function _GetParams: IFluentSQLParams;
    function _GetValue: Variant;
    function _GetDataType: TFluentSQLDataFieldType;
    function _ArrayValueToString: String;
    function _ParamListFromArray: String;
    procedure _SetColumnName(const Value: String);
    procedure _SetCompare(const Value: TFluentSQLOperatorCompare);
    procedure _SetParams(const Value: IFluentSQLParams);
    procedure _SetValue(const Value: Variant);
    procedure _SetdataType(const Value: TFluentSQLDataFieldType);
  protected
    FColumnName: String;
    FCompare: TFluentSQLOperatorCompare;
    FValue: Variant;
    FDataType: TFluentSQLDataFieldType;
    function GetOperator: String;
    function GetCompareValue: String; virtual;
  public
    constructor Create(const ADatabase: TFluentSQLDriver); overload;
    destructor Destroy; override;
    property ColumnName:String read _GetColumnName write _SetColumnName;
    property Compare: TFluentSQLOperatorCompare read _GetCompare write _SetCompare;
    property Value: Variant read _GetValue write _SetValue;
    property DataType: TFluentSQLDataFieldType read _GetDataType write _SetdataType;
    function AsString: String;
    property Params: IFluentSQLParams read _GetParams write _SetParams;
  end;

  TFluentSQLOperators = class(TInterfacedObject, IFluentSQLOperators)
  private
    FDatabase: TFluentSQLDriver;
    FParams: IFluentSQLParams;
    function _CreateOperator(const AColumnName: String;
      const AValue: Variant;
      const ACompare: TFluentSQLOperatorCompare;
      const ADataType: TFluentSQLDataFieldType): IFluentSQLOperator;
  public
    constructor Create(const ADatabase: TFluentSQLDriver; const AParams: IFluentSQLParams = nil);
    destructor Destroy; override;
    function IsEqual(const AValue: Extended) : String; overload;
    function IsEqual(const AValue: Integer): String; overload;
    function IsEqual(const AValue: String): String; overload;
    function IsEqual(const AValue: TDate): String; overload;
    function IsEqual(const AValue: TDateTime): String; overload;
    function IsEqual(const AValue: TGUID): String; overload;
    function IsNotEqual(const AValue: Extended): String; overload;
    function IsNotEqual(const AValue: Integer): String; overload;
    function IsNotEqual(const AValue: String): String; overload;
    function IsNotEqual(const AValue: TDate): String; overload;
    function IsNotEqual(const AValue: TDateTime): String; overload;
    function IsNotEqual(const AValue: TGUID): String; overload;
    function IsGreaterThan(const AValue: Extended): String; overload;
    function IsGreaterThan(const AValue: Integer): String; overload;
    function IsGreaterThan(const AValue: TDate): String; overload;
    function IsGreaterThan(const AValue: TDateTime): String; overload;
    function IsGreaterEqThan(const AValue: Extended): String; overload;
    function IsGreaterEqThan(const AValue: Integer): String; overload;
    function IsGreaterEqThan(const AValue: TDate): String; overload;
    function IsGreaterEqThan(const AValue: TDateTime): String; overload;
    function IsLessThan(const AValue: Extended): String; overload;
    function IsLessThan(const AValue: Integer): String; overload;
    function IsLessThan(const AValue: TDate): String; overload;
    function IsLessThan(const AValue: TDateTime): String; overload;
    function IsLessEqThan(const AValue: Extended): String; overload;
    function IsLessEqThan(const AValue: Integer) : String; overload;
    function IsLessEqThan(const AValue: TDate) : String; overload;
    function IsLessEqThan(const AValue: TDateTime) : String; overload;
    function IsNull: String;
    function IsNotNull: String;
    function IsLike(const AValue: String): String;
    function IsLikeFull(const AValue: String): String;
    function IsLikeLeft(const AValue: String): String;
    function IsLikeRight(const AValue: String): String;
    function IsNotLike(const AValue: String): String;
    function IsNotLikeFull(const AValue: String): String;
    function IsNotLikeLeft(const AValue: String): String;
    function IsNotLikeRight(const AValue: String): String;
    function IsIn(const AValue: TArray<Double>): String; overload;
    function IsIn(const AValue: TArray<String>): String; overload;
    function IsIn(const AValue: String): String; overload;
    function IsNotIn(const AValue: TArray<Double>): String; overload;
    function IsNotIn(const AValue: TArray<String>): String; overload;
    function IsNotIn(const AValue: String): String; overload;
    function IsExists(const AValue: String): String; overload;
    function IsNotExists(const AValue: String): String; overload;
  end;

implementation

{ TFluentSQLOperator }

function TFluentSQLOperator.AsString: String;
begin
  Result := TUtils.Concat([FColumnName, GetOperator, GetCompareValue] );
end;

constructor TFluentSQLOperator.Create(const ADatabase: TFluentSQLDriver);
begin
  FDatabase := ADatabase;
end;

destructor TFluentSQLOperator.Destroy;
begin

  inherited;
end;

function TFluentSQLOperator._GetColumnName: String;
begin
  Result := FColumnName;
end;

function TFluentSQLOperator._GetCompare: TFluentSQLOperatorCompare;
begin
  Result := FCompare;
end;

function TFluentSQLOperator._GetParams: IFluentSQLParams;
begin
  Result := FParams;
end;

function TFluentSQLOperator.GetCompareValue: String;
begin
  Result := '';
  if VarIsNull(FValue) then
    Exit;
  
  if Assigned(FParams) then
  begin
    case FCompare of
      fcLike, fcNotLike:
        Result := FParams.Add(FValue, FDataType);
      fcLikeFull, fcNotLikeFull:
        Result := FParams.Add('%' + VarToStr(FValue) + '%', dftString);
      fcLikeLeft, fcNotLikeLeft:
        Result := FParams.Add('%' + VarToStr(FValue), dftString);
      fcLikeRight, fcNotLikeRight:
        Result := FParams.Add(VarToStr(FValue) + '%', dftString);
      fcIn, fcNotIn:
        if FDataType = dftText then
          Result := '(' + VarToStr(FValue) + ')'
        else if FDataType = dftArray then
          Result := _ParamListFromArray
        else
          Result := FParams.Add(FValue, FDataType);
      else
        Result := FParams.Add(FValue, FDataType);
    end;
    Exit;
  end;

  case FDataType of
    dftString:
      begin
        Result := VarToStrDef(FValue, EmptyStr);
        case FCompare of
          fcLike,
          fcNotLike:      Result := QuotedStr(TUtils.Concat([Result], EmptyStr));
          fcLikeFull,
          fcNotLikeFull:  Result := QuotedStr(TUtils.Concat(['%', Result, '%'], EmptyStr));
          fcLikeLeft,
          fcNotLikeLeft:  Result := QuotedStr(TUtils.Concat(['%', Result], EmptyStr));
          fcLikeRight,
          fcNotLikeRight: Result := QuotedStr(TUtils.Concat([Result, '%'], EmptyStr));
        end;
//        Result := QuotedStr(Result);
      end;
    dftInteger:  Result := VarToStrDef(FValue, EmptyStr);
    dftFloat:    Result := ReplaceStr(FloatToStr(FValue), ',', '.');
    dftDate:     Result := TUtils.DateToSQLFormat(FDatabase, VarToDateTime(FValue));
    dftDateTime: Result := TUtils.DateTimeToSQLFormat(FDatabase, VarToDateTime(FValue));
    dftGuid:     Result := TUtils.GuidStrToSQLFormat(FDatabase, StringToGUID(FValue));
    dftArray:    Result := _ArrayValueToString;
    dftBoolean:  result := BoolToStr(FValue);
    dftText:     Result := '(' + FValue + ')';
  end;
end;

function TFluentSQLOperator._GetDataType: TFluentSQLDataFieldType;
begin
  Result := FDataType;
end;

function TFluentSQLOperator.GetOperator: String;
begin
  case FCompare of
    fcEqual        : Result := '=';
    fcNotEqual     : Result := '<>';
    fcGreater      : Result := '>';
    fcGreaterEqual : Result := '>=';
    fcLess         : Result := '<';
    fcLessEqual    : Result := '<=';
    fcIn           : Result := 'IN';
    fcNotIn        : Result := 'NOT IN';
    fcIsNull       : Result := 'is null';
    fcIsNotNull    : Result := 'is not null';
    fcBetween      : Result := 'between';
    fcNotBetween   : Result := 'not between';
    fcExists       : Result := 'exists';
    fcNotExists    : Result := 'not exists';
    fcLike,
    fcLikeFull,
    fcLikeLeft,
    fcLikeRight    : Result := 'like';
    fcNotLike,
    fcNotLikeFull,
    fcNotLikeLeft,
    fcNotLikeRight : Result := 'not like';
  end;
end;

function TFluentSQLOperator._GetValue: Variant;
begin
  Result := FValue;
end;

procedure TFluentSQLOperator._SetColumnName(const Value: String);
begin
  FColumnName := Value;
end;

procedure TFluentSQLOperator._SetCompare(const Value: TFluentSQLOperatorCompare);
begin
  FCompare := Value;
end;

procedure TFluentSQLOperator._SetParams(const Value: IFluentSQLParams);
begin
  FParams := Value;
end;

procedure TFluentSQLOperator._SetdataType(const Value: TFluentSQLDataFieldType);
begin
  FDataType := Value;
end;

procedure TFluentSQLOperator._SetValue(const Value: Variant);
begin
  FValue := Value;
end;

function TFluentSQLOperator._ParamListFromArray: String;
var
  LFor: Integer;
  LValue: Variant;
  LValues: array of Variant;
begin
  Result := '(';
  LValues := FValue;
  for LFor := 0 to Length(LValues) - 1 do
  begin
    LValue := LValues[LFor];
    if LFor > 0 then
      Result := Result + ', ';
    Result := Result + FParams.Add(LValue, dftUnknown);
  end;
  Result := Result + ')';
end;

function TFluentSQLOperator._ArrayValueToString: String;
var
  LFor: Integer;
  LValue: Variant;
  LValues: array of Variant;
begin
  Result := '(';
  LValues := FValue;
  for LFor := 0 to Length(LValues) - 1 do
  begin
    LValue := LValues[LFor];
    if LFor > 0 then
      Result := Result + ', ';
    
    if Assigned(FParams) then
      Result := Result + FParams.Add(LValue, dftUnknown) // dftUnknown será tratado pelo variant no Add
    else
    begin
      if VarTypeAsText(VarType(LValue)) = 'OleStr' then
        Result := Result + QuotedStr(VarToStr(LValue))
      else
        Result := Result + ReplaceStr(VarToStr(LValue), ',', '.');
    end;
  end;
  Result := Result + ')';
end;

{ TFluentSQLOperators }

function TFluentSQLOperators._CreateOperator(const AColumnName: String;
  const AValue: Variant;
  const ACompare: TFluentSQLOperatorCompare;
  const ADataType: TFluentSQLDataFieldType): IFluentSQLOperator;
begin
  Result := TFluentSQLOperator.Create(FDatabase);
  Result.Params := FParams;
  Result.ColumnName := AColumnName;
  Result.Compare := ACompare;
  Result.Value := AValue;
  Result.DataType := ADataType;
end;

function TFluentSQLOperators.IsEqual(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcEqual, dftInteger).AsString;
end;

function TFluentSQLOperators.IsEqual(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcEqual, dftFloat).AsString;
end;

constructor TFluentSQLOperators.Create(const ADatabase: TFluentSQLDriver; const AParams: IFluentSQLParams);
begin
  FDatabase := ADatabase;
  FParams := AParams;
end;

function TFluentSQLOperators.IsEqual(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcEqual, dftString).AsString;
end;

function TFluentSQLOperators.IsExists(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcExists, dftText).AsString;
end;

function TFluentSQLOperators.IsGreaterEqThan(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcGreaterEqual, dftFloat).AsString;
end;

function TFluentSQLOperators.IsGreaterEqThan(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcGreaterEqual, dftInteger).AsString;
end;

function TFluentSQLOperators.IsGreaterThan(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcGreater, dftInteger).AsString;
end;

function TFluentSQLOperators.IsIn(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcIn, dftText).AsString;
end;

function TFluentSQLOperators.IsIn(const AValue: TArray<String>): String;
begin
  Result := _CreateOperator('', AValue, fcIn, dftArray).AsString;
end;

function TFluentSQLOperators.IsIn(const AValue: TArray<Double>): String;
begin
  Result := _CreateOperator('', AValue, fcIn, dftArray).AsString;
end;

function TFluentSQLOperators.IsGreaterThan(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcGreater, dftFloat).AsString;
end;

function TFluentSQLOperators.IsLessEqThan(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcLessEqual, dftFloat).AsString;
end;

function TFluentSQLOperators.IsLessEqThan(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcLessEqual, dftInteger).AsString;
end;

function TFluentSQLOperators.IsLessThan(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcLess, dftFloat).AsString;
end;

function TFluentSQLOperators.IsLessThan(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcLess, dftInteger).AsString;
end;

function TFluentSQLOperators.IsLike(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcLike, dftString).AsString;
end;

function TFluentSQLOperators.IsLikeFull(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcLikeFull, dftString).AsString;
end;

function TFluentSQLOperators.IsLikeLeft(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcLikeLeft, dftString).AsString;
end;

function TFluentSQLOperators.IsLikeRight(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcLikeRight, dftString).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: Extended): String;
begin
  Result := _CreateOperator('', AValue, fcNotEqual, dftFloat).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotEqual, dftString).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcNotEqual, dftDate).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcNotEqual, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsNotExists(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotExists, dftText).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: Integer): String;
begin
  Result := _CreateOperator('', AValue, fcNotEqual, dftInteger).AsString;
end;

function TFluentSQLOperators.IsNotLike(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotLike, dftString).AsString;
end;

function TFluentSQLOperators.IsNotLikeFull(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotLikeFull, dftString).AsString;
end;

function TFluentSQLOperators.IsNotLikeLeft(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotLikeLeft, dftString).AsString;
end;

function TFluentSQLOperators.IsNotLikeRight(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotLikeRight, dftString).AsString;
end;

function TFluentSQLOperators.IsNotNull: String;
begin
  Result := _CreateOperator('', Null, fcIsNotNull, dftUnknown).AsString;
end;

function TFluentSQLOperators.IsNull: String;
begin
  Result := _CreateOperator('', Null, fcIsNull, dftUnknown).AsString;
end;

function TFluentSQLOperators.IsNotIn(const AValue: TArray<String>): String;
begin
  Result := _CreateOperator('', AValue, fcNotIn, dftArray).AsString;
end;

function TFluentSQLOperators.IsNotIn(const AValue: TArray<Double>): String;
begin
  Result := _CreateOperator('', AValue, fcNotIn, dftArray).AsString;
end;

function TFluentSQLOperators.IsNotIn(const AValue: String): String;
begin
  Result := _CreateOperator('', AValue, fcNotIn, dftText).AsString;
end;

function TFluentSQLOperators.IsEqual(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcEqual, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsEqual(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcEqual, dftDate).AsString;
end;

function TFluentSQLOperators.IsGreaterEqThan(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcGreaterEqual, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsGreaterEqThan(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcGreaterEqual, dftDate).AsString;
end;

function TFluentSQLOperators.IsGreaterThan(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcGreater, dftDate).AsString;
end;

function TFluentSQLOperators.IsGreaterThan(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcGreater, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsLessEqThan(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcLessEqual, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsLessEqThan(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcLessEqual, dftDate).AsString;
end;

function TFluentSQLOperators.IsLessThan(const AValue: TDateTime): String;
begin
  Result := _CreateOperator('', AValue, fcLess, dftDateTime).AsString;
end;

function TFluentSQLOperators.IsLessThan(const AValue: TDate): String;
begin
  Result := _CreateOperator('', AValue, fcLess, dftDate).AsString;
end;

destructor TFluentSQLOperators.Destroy;
begin
  inherited;
end;

function TFluentSQLOperators.IsEqual(const AValue: TGUID): String;
begin
  Result := _CreateOperator('', AValue.ToString, fcEqual, dftGuid).AsString;
end;

function TFluentSQLOperators.IsNotEqual(const AValue: TGUID): String;
begin
  Result := _CreateOperator('', AValue.ToString, fcNotEqual, dftGuid).AsString;
end;

end.




