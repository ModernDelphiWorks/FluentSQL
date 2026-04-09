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

unit FluentSQL.Expression;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces;

type
  TFluentSQLExpression = class(TInterfacedObject, IFluentSQLExpression)
  strict private
    FOperation: TExpressionOperation;
    FLeft: IFluentSQLExpression;
    FRight: IFluentSQLExpression;
    FTerm: String;
    function _SerializeWhere(AAddParens: Boolean): String;
    function _SerializeAND: String;
    function _SerializeOR: String;
    function _SerializeOperator: String;
    function _SerializeFunction: String;
  protected
    function GetLeft: IFluentSQLExpression;
    function GetOperation: TExpressionOperation;
    function GetRight: IFluentSQLExpression;
    function GetTerm: String;
    procedure SetLeft(const AValue: IFluentSQLExpression);
    procedure SetOperation(const AValue: TExpressionOperation);
    procedure SetRight(const AValue: IFluentSQLExpression);
    procedure SetTerm(const AValue: String);
  public
    destructor Destroy; override;
    procedure Assign(const ANode: IFluentSQLExpression);
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize(AAddParens: Boolean = False): String;
    property Term: String read GetTerm write SetTerm;
    property Operation: TExpressionOperation read GetOperation write SetOperation;
    property Left: IFluentSQLExpression read GetLeft write SetLeft;
    property Right: IFluentSQLExpression read GetRight write SetRight;
  end;

  TFluentSQLCriteriaExpression = class(TInterfacedObject, IFluentSQLCriteriaExpression)
  strict private
    FExpression: IFluentSQLExpression;
    FLastAnd: IFluentSQLExpression;
    FSQLParams: IFluentSQLParams;
    function _SqlFromArrayOfConst(const AExpression: array of const): String;
  protected
    function FindRightmostAnd(const AExpression: IFluentSQLExpression): IFluentSQLExpression;
  public
    constructor Create(const AExpression: String = ''); overload;
    constructor Create(const AExpression: String; const ASQLParams: IFluentSQLParams); overload;
    constructor Create(const AExpression: IFluentSQLExpression); overload;
    constructor Create(const AExpression: IFluentSQLExpression; const ASQLParams: IFluentSQLParams); overload;
    function AndOpe(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function AndOpe(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function AndOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function AsString: String;
    function Expression: IFluentSQLExpression;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLExpression }

procedure TFluentSQLExpression.Assign(const ANode: IFluentSQLExpression);
begin
  FLeft := ANode.Left;
  FRight := ANode.Right;
  FTerm := ANode.Term;
  FOperation := ANode.Operation;
end;

procedure TFluentSQLExpression.Clear;
begin
  FOperation := opNone;
  FTerm := '';
  FLeft := nil;
  FRight := nil;
end;

destructor TFluentSQLExpression.Destroy;
begin
  FLeft := nil;
  FRight := nil;
  inherited;
end;

function TFluentSQLExpression.GetLeft: IFluentSQLExpression;
begin
  Result := FLeft;
end;

function TFluentSQLExpression.GetOperation: TExpressionOperation;
begin
  Result := FOperation;
end;

function TFluentSQLExpression.GetRight: IFluentSQLExpression;
begin
  Result := FRight;
end;

function TFluentSQLExpression.GetTerm: String;
begin
  Result := FTerm;
end;

function TFluentSQLExpression.IsEmpty: Boolean;
begin
  // Caso no exista a chamada do WHERE  considerado Empty.
  Result := (FOperation = opNone) and (FTerm = '');
end;

function TFluentSQLExpression.Serialize(AAddParens: Boolean): String;
begin
  if IsEmpty then
    Result := ''
  else
    case FOperation of
      opNone:
        Result := _SerializeWhere(AAddParens);
      opAND:
        Result := _SerializeAND;
      opOR:
        Result := _SerializeOR;
      opOperation:
        Result := _SerializeOperator;
      opFunction:
        Result := _SerializeFunction;
      else
        raise Exception.Create('TFluentSQLExpression.Serialize: Unknown operation');
    end;
end;

function TFluentSQLExpression._SerializeAND: String;
begin
  Result := TUtils.Concat([FLeft.Serialize(True),
                           'AND',
                           FRight.Serialize(True)]);
end;

function TFluentSQLExpression._SerializeFunction: String;
begin
  Result := TUtils.Concat([FLeft.Serialize(False),
                           FRight.Serialize(False)]);
end;

function TFluentSQLExpression._SerializeOperator: String;
begin
  Result := '(' + TUtils.Concat([FLeft.Serialize(False),
                                 FRight.Serialize(False)]) + ')';
end;

function TFluentSQLExpression._SerializeOR: String;
begin
  Result := '(' + TUtils.Concat([FLeft.Serialize(True),
                                 'OR',
                                 FRight.Serialize(True)]) + ')';
end;

function TFluentSQLExpression._SerializeWhere(AAddParens: Boolean): String;
begin
  if AAddParens then
    Result := TUtils.concat(['(', FTerm, ')'], '')
  else
    Result := FTerm;
end;

procedure TFluentSQLExpression.SetLeft(const AValue: IFluentSQLExpression);
begin
  FLeft := AValue;
end;

procedure TFluentSQLExpression.SetOperation(const AValue: TExpressionOperation);
begin
  FOperation := AValue;
end;

procedure TFluentSQLExpression.SetRight(const AValue: IFluentSQLExpression);
begin
  FRight := AValue;
end;

procedure TFluentSQLExpression.SetTerm(const AValue: String);
begin
  FTerm := AValue;
end;

{ TFluentSQLCriteriaExpression }

function TFluentSQLCriteriaExpression._SqlFromArrayOfConst(const AExpression: array of const): String;
begin
  if Assigned(FSQLParams) then
    Result := TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FSQLParams)
  else
    Result := TUtils.SqlParamsToStr(AExpression);
end;

function TFluentSQLCriteriaExpression.AndOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
  LRoot: IFluentSQLExpression;
begin
  LRoot := FExpression;
  if LRoot.IsEmpty then
  begin
    LRoot.Assign(AExpression);
    FLastAnd := LRoot;
  end
  else
  begin
    LNode := TFluentSQLExpression.Create;
    LNode.Assign(LRoot);
    LRoot.Left := LNode;
    LRoot.Operation := opAND;
    LRoot.Right := AExpression;
    FLastAnd := LRoot.Right;
  end;
  Result := Self;
end;

function TFluentSQLCriteriaExpression.AndOpe(const AExpression: String): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Term := AExpression;
  Result := AndOpe(LNode);
end;

function TFluentSQLCriteriaExpression.AndOpe(const AExpression: array of const): IFluentSQLCriteriaExpression;
begin
  Result := AndOpe(_SqlFromArrayOfConst(AExpression));
end;

function TFluentSQLCriteriaExpression.AsString: String;
begin
  Result := FExpression.Serialize;
end;

constructor TFluentSQLCriteriaExpression.Create(const AExpression: IFluentSQLExpression);
begin
  FExpression := AExpression;
  FSQLParams := nil;
  FLastAnd := FindRightmostAnd(AExpression);
end;

constructor TFluentSQLCriteriaExpression.Create(const AExpression: IFluentSQLExpression;
  const ASQLParams: IFluentSQLParams);
begin
  FExpression := AExpression;
  FSQLParams := ASQLParams;
  FLastAnd := FindRightmostAnd(AExpression);
end;

function TFluentSQLCriteriaExpression.Expression: IFluentSQLExpression;
begin
  Result := FExpression;
end;

constructor TFluentSQLCriteriaExpression.Create(const AExpression: String);
begin
  FExpression := TFluentSQLExpression.Create;
  FSQLParams := nil;
  if AExpression <> '' then
    AndOpe(AExpression);
end;

constructor TFluentSQLCriteriaExpression.Create(const AExpression: String; const ASQLParams: IFluentSQLParams);
begin
  FExpression := TFluentSQLExpression.Create;
  FSQLParams := ASQLParams;
  if AExpression <> '' then
    AndOpe(AExpression);
end;

function TFluentSQLCriteriaExpression.FindRightmostAnd(const AExpression: IFluentSQLExpression): IFluentSQLExpression;
begin
  if AExpression.Operation = opNone then
    Result := FExpression
  else
  if AExpression.Operation = opOR then
    Result := FExpression
  else
    Result := FindRightmostAnd(AExpression.Right);
end;

function TFluentSQLCriteriaExpression.Fun(const AExpression: array of const): IFluentSQLCriteriaExpression;
begin
  Result := Fun(_SqlFromArrayOfConst(AExpression));
end;

function TFluentSQLCriteriaExpression.Fun(const AExpression: String): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Term := AExpression;
  Result := Fun(LNode);
end;

function TFluentSQLCriteriaExpression.Fun(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Assign(FLastAnd);
  FLastAnd.Left := LNode;
  FLastAnd.Operation := opFunction;
  FLastAnd.Right := AExpression;
  Result := Self;
end;

function TFluentSQLCriteriaExpression.OrOpe(const AExpression: array of const): IFluentSQLCriteriaExpression;
begin
  Result := OrOpe(_SqlFromArrayOfConst(AExpression));
end;

function TFluentSQLCriteriaExpression.OrOpe(const AExpression: String): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Term := AExpression;
  Result := OrOpe(LNode);
end;

function TFluentSQLCriteriaExpression.Ope(const AExpression: array of const): IFluentSQLCriteriaExpression;
begin
  Result := Ope(_SqlFromArrayOfConst(AExpression));
end;

function TFluentSQLCriteriaExpression.Ope(const AExpression: String): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Term := AExpression;
  Result := Ope(LNode);
end;

function TFluentSQLCriteriaExpression.Ope(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
begin
  LNode := TFluentSQLExpression.Create;
  LNode.Assign(FLastAnd);
  FLastAnd.Left := LNode;
  FLastAnd.Operation := opOperation;
  FLastAnd.Right := AExpression;
  Result := Self;
end;

function TFluentSQLCriteriaExpression.OrOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression;
var
  LNode: IFluentSQLExpression;
  LRoot: IFluentSQLExpression;
begin
  LRoot := FLastAnd;
  LNode := TFluentSQLExpression.Create;
  LNode.Assign(LRoot);
  LRoot.Left := LNode;
  LRoot.Operation := opOR;
  LRoot.Right := AExpression;
  FLastAnd := LRoot.Right;
  Result := Self;
end;

end.





