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

unit FluentSQL.FunctionsMySQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsMySQL = class(TFluentSQLFunctionAbstract)
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

{ TFluentSQLFunctionsMySQL }

function TFluentSQLFunctionsMySQL.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsMySQL.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsMySQL.Date(const AVAlue: String; const AFormat: String): String;
begin
  Result := 'DATE_FORMAT(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsMySQL.Date(const AVAlue: String): String;
begin
  Result := 'DATE_FORMAT(' + AValue + ', ''yyyy-MM-dd'')';
end;

function TFluentSQLFunctionsMySQL.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsMySQL.Day(const AValue: String): String;
begin
  Result := 'DAY(' + AValue + ')';
end;

function TFluentSQLFunctionsMySQL.Month(const AValue: String): String;
begin
  Result := 'MONTH(' + AValue + ')';
end;

function TFluentSQLFunctionsMySQL.Year(const AValue: String): String;
begin
  Result := 'YEAR(' + AValue + ')';
end;

end.



