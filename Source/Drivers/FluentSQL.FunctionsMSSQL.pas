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

unit FluentSQL.FunctionsMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsMSSQL = class(TFluentSQLFunctionAbstract)
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

{ TFluentSQLFunctionsMSSQL }

function TFluentSQLFunctionsMSSQL.Concat(const AValue: array of String): String;
var
  LFor: Integer;
  LIni: Integer;
  LFin: Integer;
const
  cCONCAT = 'CONCAT(%s)';
begin
  Result := '';
  LIni := Low(AValue);
  LFin := High(AValue);

  for LFor := LIni to LFin do
  begin
    Result := Result + AValue[LFor];
    if LFor < LFin then
      Result := Result + ', ';
  end;
  Result := Format(cCONCAT, [Result]);
end;

constructor TFluentSQLFunctionsMSSQL.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsMSSQL.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsMSSQL.Year(const AValue: String): String;
begin
  Result := 'YEAR(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Date(const AVAlue, AFormat: String): String;
begin
  Result := FormatDateTime(AFormat, StrToDateTime(AValue));
end;

function TFluentSQLFunctionsMSSQL.Date(const AVAlue: String): String;
begin
  Result := AValue;
end;

function TFluentSQLFunctionsMSSQL.Day(const AValue: String): String;
begin
  Result := 'DAY(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Month(const AValue: String): String;
begin
  Result := 'MONTH(' + AValue + ')';
end;

end.



