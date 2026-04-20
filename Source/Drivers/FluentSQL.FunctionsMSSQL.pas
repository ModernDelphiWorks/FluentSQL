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
    function Trim(const AValue: String): String; override;
    function LTrim(const AValue: String): String; override;
    function RTrim(const AValue: String): String; override;
    function Coalesce(const AValues: array of String): String; override;
    function CurrentDate: String; override;
    function CurrentTimestamp: String; override;
    function Modulus(const AValue, ADivisor: String): String; override;
    function Round(const AValue: String; const ADecimals: Integer): String; override;
    function Floor(const AValue: String): String; override;
    function Ceil(const AValue: String): String; override;
    function Abs(const AValue: String): String; override;
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


function TFluentSQLFunctionsMSSQL.Day(const AValue: String): String;
begin
  Result := 'DAY(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Month(const AValue: String): String;
begin
  Result := 'MONTH(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'FORMAT(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsMSSQL.Date(const AVAlue: String): String;
begin
  Result := 'CAST(' + AValue + ' AS DATE)';
end;

function TFluentSQLFunctionsMSSQL.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Coalesce(const AValues: array of String): String;
var
  LFor: Integer;
begin
  Result := 'COALESCE(';
  for LFor := Low(AValues) to High(AValues) do
  begin
    Result := Result + AValues[LFor];
    if LFor < High(AValues) then
      Result := Result + ', ';
  end;
  Result := Result + ')';
end;

function TFluentSQLFunctionsMSSQL.CurrentDate: String;
begin
  Result := 'CAST(GETDATE() AS DATE)';
end;

function TFluentSQLFunctionsMSSQL.CurrentTimestamp: String;
begin
  Result := 'GETDATE()';
end;

function TFluentSQLFunctionsMSSQL.Modulus(const AValue, ADivisor: String): String;
begin
  Result := '(' + AValue + ' % ' + ADivisor + ')';
end;

function TFluentSQLFunctionsMSSQL.Round(const AValue: String; const ADecimals: Integer): String;
begin
  Result := 'ROUND(' + AValue + ', ' + IntToStr(ADecimals) + ')';
end;

function TFluentSQLFunctionsMSSQL.Floor(const AValue: String): String;
begin
  Result := 'FLOOR(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Ceil(const AValue: String): String;
begin
  Result := 'CEILING(' + AValue + ')';
end;

function TFluentSQLFunctionsMSSQL.Abs(const AValue: String): String;
begin
  Result := 'ABS(' + AValue + ')';
end;

end.



