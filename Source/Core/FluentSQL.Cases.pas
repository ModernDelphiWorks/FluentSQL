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

unit FluentSQL.Cases;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces,
  FluentSQL.Expression;

type
  TFluentSQLCaseWhenThen = class(TInterfacedObject, IFluentSQLCaseWhenThen)
  strict private
    FThenExpression: IFluentSQLExpression;
    FWhenExpression: IFluentSQLExpression;
  protected
    function GetThenExpression: IFluentSQLExpression;
    function GetWhenExpression: IFluentSQLExpression;
    procedure SetThenExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenExpression(const AValue: IFluentSQLExpression);
  public
    constructor Create;
    destructor Destroy; override;
    property WhenExpression: IFluentSQLExpression read GetWhenExpression write SetWhenExpression;
    property ThenExpression: IFluentSQLExpression read GetThenExpression write SetThenExpression;
  end;

  TFluentSQLCaseWhenList = class(TInterfacedObject, IFluentSQLCaseWhenList)
  strict private
    FWhenThenList: TList<IFluentSQLCaseWhenThen>;
  protected
    function GetWhenThen(AIdx: Integer): IFluentSQLCaseWhenThen;
    procedure SetWhenThen(AIdx: Integer; const AValue: IFluentSQLCaseWhenThen);
    constructor Create;
  public
    destructor Destroy; override;
    function Add: IFluentSQLCaseWhenThen; overload;
    function Add(const AWhenThen: IFluentSQLCaseWhenThen): Integer; overload;
    function Count: Integer;
    property WhenThen[AIdx: Integer]: IFluentSQLCaseWhenThen read GetWhenThen write SetWhenThen; default;
  end;

  TFluentSQLCase = class(TInterfacedObject, IFluentSQLCase)
  protected
    FCaseExpression: IFluentSQLExpression;
    FElseExpression: IFluentSQLExpression;
    FWhenList: IFluentSQLCaseWhenList;
    function SerializeExpression(const AExpression: IFluentSQLExpression): String;
    function GetCaseExpression: IFluentSQLExpression;
    function GetElseExpression: IFluentSQLExpression;
    function GetWhenList: IFluentSQLCaseWhenList;
    procedure SetCaseExpression(const AValue: IFluentSQLExpression);
    procedure SetElseExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenList(const AValue: IFluentSQLCaseWhenList);
  public
    constructor Create;
    destructor Destroy; override;
    function Serialize: String; virtual;
    property CaseExpression: IFluentSQLExpression read GetCaseExpression write SetCaseExpression;
    property WhenList: IFluentSQLCaseWhenList read GetWhenList write SetWhenList;
    property ElseExpression: IFluentSQLExpression read GetElseExpression write SetElseExpression;
  end;

  TFluentSQLCriteriaCase = class(TInterfacedObject, IFluentSQLCriteriaCase)
  strict private
    FOwner: IFluentSQL;
    FCase: IFluentSQLCase;
    FLastExpression: IFluentSQLCriteriaExpression;
    function _GetCase: IFluentSQLCase;
  public
    constructor Create(const AOwner: IFluentSQL; const AExpression: String);
    destructor Destroy; override;
    function AndOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: String): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: Int64): IFluentSQLCriteriaCase; overload;
    function EndCase: IFluentSQL;
    function OrOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: String): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: Int64): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: String): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: array of const): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    property Value: IFluentSQLCase read _GetCase;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLCase }

constructor TFluentSQLCase.Create;
begin
  FCaseExpression := TFluentSQLExpression.Create;
  FElseExpression := TFluentSQLExpression.Create;
  FWhenList := TFluentSQLCaseWhenList.Create;
end;

destructor TFluentSQLCase.Destroy;
begin
  FCaseExpression := nil;
  FElseExpression := nil;
  FWhenList := nil;
  inherited;
end;

function TFluentSQLCase.GetCaseExpression: IFluentSQLExpression;
begin
  Result := FCaseExpression;
end;

function TFluentSQLCase.GetElseExpression: IFluentSQLExpression;
begin
  Result := FElseExpression;
end;

function TFluentSQLCase.GetWhenList: IFluentSQLCaseWhenList;
begin
  Result := FWhenList;
end;

function TFluentSQLCase.Serialize: String;
var
  LFor: Integer;
  LWhenThen: IFluentSQLCaseWhenThen;
begin
  Result := 'CASE';
  if not FCaseExpression.IsEmpty then
    Result := TUtils.Concat([Result, FCaseExpression.Serialize]);
  for LFor := 0 to FWhenList.Count - 1 do
  begin
    Result := TUtils.Concat([Result, 'WHEN']);
    LWhenThen := FWhenList[LFor];
    if not LWhenThen.WhenExpression.IsEmpty then
      Result := TUtils.Concat([Result, LWhenThen.WhenExpression.Serialize]);
    Result := TUtils.Concat([Result, 'THEN', LWhenThen.ThenExpression.Serialize]);
  end;
  if not FElseExpression.IsEmpty then
    Result := TUtils.Concat([Result, 'ELSE', FElseExpression.Serialize]);
  Result := TUtils.Concat([Result, 'END']);
end;

function TFluentSQLCase.SerializeExpression(const AExpression: IFluentSQLExpression): String;
begin
  Result := AExpression.Serialize;
end;

procedure TFluentSQLCase.SetCaseExpression(const AValue: IFluentSQLExpression);
begin
  FCaseExpression := AValue;
end;

procedure TFluentSQLCase.SetElseExpression(const AValue: IFluentSQLExpression);
begin
  FElseExpression := AValue;
end;

procedure TFluentSQLCase.SetWhenList(const AValue: IFluentSQLCaseWhenList);
begin
  FWhenList := AValue;
end;

{ TFluentSQLCaseWhenList }

constructor TFluentSQLCaseWhenList.Create;
begin
  FWhenThenList := TList<IFluentSQLCaseWhenThen>.Create;
end;

destructor TFluentSQLCaseWhenList.Destroy;
begin
  FWhenThenList.Free;
  inherited;
end;

function TFluentSQLCaseWhenList.Add: IFluentSQLCaseWhenThen;
begin
  Result := TFluentSQLCaseWhenThen.Create;
  Add(Result);
end;

function TFluentSQLCaseWhenList.Add(const AWhenThen: IFluentSQLCaseWhenThen): Integer;
begin
  Result := FWhenThenList.Add(AWhenThen);
end;

function TFluentSQLCaseWhenList.Count: Integer;
begin
  Result := FWhenThenList.Count;
end;

function TFluentSQLCaseWhenList.GetWhenThen(AIdx: Integer): IFluentSQLCaseWhenThen;
begin
  Result := FWhenThenList[AIdx];
end;

procedure TFluentSQLCaseWhenList.SetWhenThen(AIdx: Integer; const AValue: IFluentSQLCaseWhenThen);
begin
  FWhenThenList[AIdx] := AValue;
end;

{ TFluentSQLCaseWhenThen }

constructor TFluentSQLCaseWhenThen.Create;
begin
  FWhenExpression := TFluentSQLExpression.Create;
  FThenExpression := TFluentSQLExpression.Create;
end;

destructor TFluentSQLCaseWhenThen.Destroy;
begin
  FThenExpression := nil;
  FWhenExpression := nil;
  inherited;
end;

function TFluentSQLCaseWhenThen.GetThenExpression: IFluentSQLExpression;
begin
  Result := FThenExpression;
end;

function TFluentSQLCaseWhenThen.GetWhenExpression: IFluentSQLExpression;
begin
  Result := FWhenExpression;
end;

procedure TFluentSQLCaseWhenThen.SetThenExpression(const AValue: IFluentSQLExpression);
begin
  FThenExpression := AValue;
end;

procedure TFluentSQLCaseWhenThen.SetWhenExpression(const AValue: IFluentSQLExpression);
begin
  FWhenExpression := AValue;
end;

{ TFluentSQLCriteriaCase }

function TFluentSQLCriteriaCase.AndOpe(const AExpression: String): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(AExpression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.AndOpe(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(AExpression);
  Result := Self;
end;

constructor TFluentSQLCriteriaCase.Create(const AOwner: IFluentSQL; const AExpression: String);
begin
  FOwner := AOwner;
  FCase := TFluentSQLCase.Create;
  if AExpression <> '' then
    FCase.CaseExpression.Term := AExpression;
end;

destructor TFluentSQLCriteriaCase.Destroy;
begin
  FOwner := nil;
  FCase := nil;
  FLastExpression := nil;
  inherited;
end;

function TFluentSQLCriteriaCase.ElseIf(const AValue: String): IFluentSQLCriteriaCase;
begin
  FLastExpression := TFluentSQLCriteriaExpression.Create(AValue);
  FCase.ElseExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.ElseIf(const AValue: int64): IFluentSQLCriteriaCase;
begin
  Result := ElseIf(IntToStr(AValue));
end;

function TFluentSQLCriteriaCase.EndCase: IFluentSQL;
begin
  Result := FOwner;
end;

function TFluentSQLCriteriaCase._GetCase: IFluentSQLCase;
begin
  Result := FCase;
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: String): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(AExpression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(AExpression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.IfThen(const AValue: int64): IFluentSQLCriteriaCase;
begin
  Result := IfThen(IntToStr(AValue));
end;

function TFluentSQLCriteriaCase.When(const ACondition: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
var
  LWhenThen: IFluentSQLCaseWhenThen;
begin
  FLastExpression := ACondition;
  LWhenThen := FCase.WhenList.Add;
  LWhenThen.WhenExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.IfThen(const AValue: String): IFluentSQLCriteriaCase;
begin
  Assert(FCase.WhenList.Count > 0, 'TFluentSQLCriteriaCase.IfThen: Missing When');
  FLastExpression := TFluentSQLCriteriaExpression.Create(AValue);
  FCase.WhenList[FCase.WhenList.Count-1].ThenExpression := FLastExpression.Expression;
  Result := Self;
end;

function TFluentSQLCriteriaCase.When(const ACondition: array of const): IFluentSQLCriteriaCase;
begin
  Result := When(TUtils.SqlParamsToStr(ACondition));
end;

function TFluentSQLCriteriaCase.When(const ACondition: String): IFluentSQLCriteriaCase;
begin
  Result := When(TFluentSQLCriteriaExpression.Create(ACondition));
end;

function TFluentSQLCriteriaCase.OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  FLastExpression.OrOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQLCriteriaCase.AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  FLastExpression.AndOpe(AExpression.Expression);
  Result := Self;
end;

end.






