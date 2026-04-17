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

unit FluentSQL.FunctionsMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsMongoDB = class(TFluentSQLFunctionAbstract)
  public
    constructor Create;
    function Count(const AValue: String): String; override;
    function Sum(const AValue: String): String; override;
    function Min(const AValue: String): String; override;
    function Max(const AValue: String): String; override;
    function Average(const AValue: String): String; override;
  end;

implementation

constructor TFluentSQLFunctionsMongoDB.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsMongoDB.Count(const AValue: String): String;
begin
  Result := 'AGG:COUNT:' + AValue;
end;

function TFluentSQLFunctionsMongoDB.Sum(const AValue: String): String;
begin
  Result := 'AGG:SUM:' + AValue;
end;

function TFluentSQLFunctionsMongoDB.Min(const AValue: String): String;
begin
  Result := 'AGG:MIN:' + AValue;
end;

function TFluentSQLFunctionsMongoDB.Max(const AValue: String): String;
begin
  Result := 'AGG:MAX:' + AValue;
end;

function TFluentSQLFunctionsMongoDB.Average(const AValue: String): String;
begin
  Result := 'AGG:AVG:' + AValue;
end;

end.
