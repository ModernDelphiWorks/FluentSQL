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

// Length e Ceil passaram de padrao A para padrao B (antes o core emitia
// LENGTH(...) e CEIL(...) para todo dialeto).
//
// NAO CONSIGO DEFENDER NENHUMA DAS DUAS FORMAS PARA O INTERBASE. O InterBase
// divergiu do tronco comum antes de o Firebird 2.1 introduzir CHAR_LENGTH e
// CEIL/CEILING; no InterBase, funcoes de tamanho e arredondamento vinham
// historicamente da UDF ib_udf, que so existe se o administrador a tiver
// declarado no banco. Emitir LENGTH(...) ou CEIL(...) aqui seria repetir
// exatamente o defeito do CEIL no MSSQL que a T3 existiu para matar - SQL que
// o motor rejeita, gerado em silencio.
//
// Ate alguem verificar contra a documentacao do InterBase e implementar a forma
// real, estas duas levantam erro nomeado. Erro honesto e melhor que SQL
// indefensavel, ainda mais agora que a documentacao ensina a ligar
// {$DEFINE INTERBASE}.
function TFluentSQLFunctionsInterbase.Length(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Length',
    'InterBase (forma correta nao verificada; Firebird usa CHAR_LENGTH)');
end;

function TFluentSQLFunctionsInterbase.Ceil(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Ceil',
    'InterBase (forma correta nao verificada; Firebird usa CEIL desde a 2.1)');
end;

end.


