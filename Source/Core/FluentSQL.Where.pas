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

unit FluentSQL.Where;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Expression,
  FluentSQL.Interfaces;

type
  TFluentSQLWhere = class(TFluentSQLSection, IFluentSQLWhere)
  private
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
  protected
    FExpression: IFluentSQLExpression;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; override;
    function Serialize: String; virtual;
    function IsEmpty: Boolean; override;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLWhere }

procedure TFluentSQLWhere.Clear;
begin
  Expression.Clear;
end;

constructor TFluentSQLWhere.Create;
begin
  inherited Create('Where');
  FExpression := TFluentSQLExpression.Create;
end;

destructor TFluentSQLWhere.Destroy;
begin
  inherited;
end;

function TFluentSQLWhere._GetExpression: IFluentSQLExpression;
begin
  Result := FExpression;
end;

function TFluentSQLWhere.IsEmpty: Boolean;
begin
  Result := FExpression.IsEmpty;
end;

function TFluentSQLWhere.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['WHERE', FExpression.Serialize]);
end;

procedure TFluentSQLWhere._SetExpression(const Value: IFluentSQLExpression);
begin
  FExpression := Value;
end;

end.




