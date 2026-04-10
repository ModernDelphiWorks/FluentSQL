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

unit FluentSQL.FunctionsPostgreSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsPostgreSQL = class(TFluentSQLFunctionAbstract)
  public
    constructor Create;
    function SubString(const AVAlue: String; const AStart, ALength: Integer): String; override;
    function Date(const AVAlue: String; const AFormat: String): String; overload; override;
    function Date(const AVAlue: String): String; overload; override;
    function Day(const AValue: String): String; override;
    function Month(const AValue: String): String; override;
    function Year(const AValue: String): String; override;
    function Concat(const AValue: array of String): String; override;
  end;

implementation

uses
  FluentSQL.Register,
  FluentSQL.Interfaces;

{ TFluentSQLFunctionsPostgreSQL }

function TFluentSQLFunctionsPostgreSQL.Concat(const AValue: array of String): String;
var
  LFor: Integer;
  LIni: Integer;
  LFin: Integer;
begin
  Result := '';
  LIni := Low(AValue);
  LFin := High(AValue);

  for LFor := LIni to LFin do
  begin
    Result := Result + AValue[LFor];
    if LFor < LFin then
      Result := Result + ' || ';
  end;
end;

constructor TFluentSQLFunctionsPostgreSQL.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsPostgreSQL.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Date(const AVAlue: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ''dd/MM/yyyy'')';
end;

function TFluentSQLFunctionsPostgreSQL.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBSTRING(' + AValue + ' FROM ' + IntToStr(AStart) + ' FOR ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AValue + ')';
end;

end.



