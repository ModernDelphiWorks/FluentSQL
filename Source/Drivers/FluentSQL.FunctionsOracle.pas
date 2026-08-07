{
  ------------------------------------------------------------------------------
  FluentSQL
  Database-agnostic fluent SQL/MQL script generation library for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.FunctionsOracle;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsOracle = class(TFluentSQLFunctionAbstract)
  public
    constructor Create;
    function SubString(const AVAlue: String; const AStart, ALength: Integer): String; override;
    function Date(const AVAlue: String; const AFormat: String): String; overload; override;
    function Date(const AVAlue: String): String; overload; override;
    function Day(const AValue: String): String; override;
    function Month(const AValue: String): String; override;
    function Year(const AValue: String): String; override;
    function Concat(const AValue: array of String): String; override;
    function Length(const AValue: String): String; override;
    function Trim(const AValue: String): String; override;
    function LTrim(const AValue: String): String; override;
    function RTrim(const AValue: String): String; override;
    function Coalesce(const AValues: array of String): String; override;
    function CurrentDate: String; override;
    function CurrentTimestamp: String; override;
    function Ceil(const AValue: String): String; override;
    function Modulus(const AValue, ADivisor: String): String; override;
  end;

implementation

uses
  FluentSQL.Register,
  FluentSQL.Interfaces;

{ TFluentSQLFunctionsOracle }

function TFluentSQLFunctionsOracle.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsOracle.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsOracle.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsOracle.Date(const AVAlue: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ''dd/MM/yyyy'')';
end;

function TFluentSQLFunctionsOracle.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AVAlue + ')';
end;

function TFluentSQLFunctionsOracle.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AVAlue + ')';
end;

function TFluentSQLFunctionsOracle.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBSTR(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsOracle.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AVAlue + ')';
end;

// LENGTH, TRIM, LTRIM, RTRIM, COALESCE e MOD sao built-ins do Oracle.
function TFluentSQLFunctionsOracle.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Coalesce(const AValues: array of String): String;
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

// Oracle: CURRENT_DATE traz data COM hora. Para manter a semantica dos demais
// dialetos (data sem hora, como CAST(GETDATE() AS DATE) no MSSQL) usa-se
// TRUNC(SYSDATE), que e o idioma canonico no Oracle.
function TFluentSQLFunctionsOracle.CurrentDate: String;
begin
  Result := 'TRUNC(SYSDATE)';
end;

function TFluentSQLFunctionsOracle.CurrentTimestamp: String;
begin
  Result := 'SYSTIMESTAMP';
end;

// Oracle tem CEIL; nao tem CEILING.
function TFluentSQLFunctionsOracle.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Modulus(const AValue, ADivisor: String): String;
begin
  Result := 'MOD(' + AValue + ', ' + ADivisor + ')';
end;

end.



