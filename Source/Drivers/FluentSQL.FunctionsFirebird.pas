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

unit FluentSQL.FunctionsFirebird;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsFirebird = class(TFluentSQLFunctionAbstract)
  public
    function SubString(const AValue: String; const AStart, ALength: Integer): String; override;
    function Date(const AValue: String; const AFormat: String): String; overload; override;
    function Date(const AValue: String): String; overload; override;
    function Day(const AValue: String): String; override;
    function Month(const AValue: String): String; override;
    function Year(const AValue: String): String; override;
    function Concat(const AValue: array of String): String; override;
  end;

implementation

uses
  FluentSQL.Register,
  FluentSQL.Interfaces;

{ TFluentSQLFunctionsFirebird }

function TFluentSQLFunctionsFirebird.Concat(const AValue: array of String): String;
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

function TFluentSQLFunctionsFirebird.Date(const AValue: String; const AFormat: String): String;
begin
  Result := FormatDateTime(AFormat, StrToDateTime(AValue));
end;

function TFluentSQLFunctionsFirebird.Date(const AValue: String): String;
begin
  Result := AValue;
end;

function TFluentSQLFunctionsFirebird.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsFirebird.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsFirebird.SubString(const AValue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ' FROM ' + IntToStr(AStart) + ' FOR ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsFirebird.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AValue + ')';
end;

end.



