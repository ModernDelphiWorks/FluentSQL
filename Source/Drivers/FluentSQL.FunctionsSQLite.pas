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

unit FluentSQL.FunctionsSQLite;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsSQLite = class(TFluentSQLFunctionAbstract)
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

{ TFluentSQLFunctionsSQLite }

function TFluentSQLFunctionsSQLite.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsSQLite.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsSQLite.Date(const AValue, AFormat: String): String;
begin
  Result := 'DATE(' + FormatDateTime(AFormat, StrToDate(AValue)) + ')';
end;

function TFluentSQLFunctionsSQLite.Date(const AValue: String): String;
begin
  Result := 'DATE(' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.Day(const AValue: String): String;
begin
  Result := 'STRFTIME(%d, ' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.Month(const AValue: String): String;
begin
  Result := 'STRFTIME(%m, ' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsSQLite.Year(const AValue: String): String;
begin
  Result := 'STRFTIME(%Y, ' + AValue + ')';
end;

end.



