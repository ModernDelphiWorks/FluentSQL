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

unit FluentSQL.FunctionsInterbase;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsInterbase = class(TFluentSQLFunctionAbstract)
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
    function Ceil(const AValue: String): String; override;
  end;

implementation

uses
  FluentSQL.Register,
  FluentSQL.Interfaces;

{ TFluentSQLFunctionsInterbase }

function TFluentSQLFunctionsInterbase.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsInterbase.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsInterbase.Date(const AVAlue, AFormat: String): String;
begin
  Result := FormatDateTime(AFormat, StrToDateTime(AValue));
end;

function TFluentSQLFunctionsInterbase.Date(const AVAlue: String): String;
begin
  Result := AValue;
end;

function TFluentSQLFunctionsInterbase.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ' FROM ' + IntToStr(AStart) + ' FOR ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsInterbase.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsInterbase.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsInterbase.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AValue + ')';
end;

// Length e Ceil passaram de padrao A para padrao B. Estas duas reproduzem
// LITERALMENTE o que o core emitia antes para o Interbase, para nao alterar o
// comportamento de um driver que esta desligado no .inc e que nao consigo
// exercitar. NAO VERIFIQUEI contra a documentacao do InterBase se LENGTH e CEIL
// existem nele (o Firebird, de linhagem comum, usa CHAR_LENGTH). Revisar antes
// de ligar {$DEFINE INTERBASE}.
function TFluentSQLFunctionsInterbase.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctionsInterbase.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

end.


