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

unit FluentSQL.Having;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Interfaces;

type
  TFluentSQLHaving = class(TFluentSQLSection, IFluentSQLHaving)
  strict private
    FExpression: IFluentSQLExpression;
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Serialize: String;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;


implementation

uses
  FluentSQL.Expression,
  FluentSQL.Utils;

{ TFluentSQLHaving }

constructor TFluentSQLHaving.Create;
begin
  inherited Create('Having');
  FExpression := TFluentSQLExpression.Create;
end;

procedure TFluentSQLHaving.Clear;
begin
  FExpression.Clear;
end;

function TFluentSQLHaving._GetExpression: IFluentSQLExpression;
begin
  Result := FExpression;
end;

function TFluentSQLHaving.IsEmpty: Boolean;
begin
  Result := FExpression.IsEmpty;
end;

function TFluentSQLHaving.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['HAVING', FExpression.Serialize]);
end;

procedure TFluentSQLHaving._SetExpression(const Value: IFluentSQLExpression);
begin
  FExpression := Value;
end;

end.




