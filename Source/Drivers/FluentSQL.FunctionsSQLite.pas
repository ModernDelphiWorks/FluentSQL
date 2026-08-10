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

unit FluentSQL.FunctionsSQLite;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
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
    function Length(const AValue: String): String; override;
    function Trim(const AValue: String): String; override;
    function LTrim(const AValue: String): String; override;
    function RTrim(const AValue: String): String; override;
    function Coalesce(const AValues: array of String): String; override;
    function CurrentDate: String; override;
    function CurrentTimestamp: String; override;
    function Ceil(const AValue: String): String; override;
    function Modulus(const AValue, ADivisor: String): String; override;
    function Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType;
      const ALength: Integer = 0): String; overload; override;
  end;

implementation

uses
  FluentSQL.Register;

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

// LENGTH, TRIM, LTRIM, RTRIM e COALESCE sao funcoes do core do SQLite,
// disponiveis em qualquer build.
function TFluentSQLFunctionsSQLite.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsSQLite.Coalesce(const AValues: array of String): String;
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

// CURRENT_DATE / CURRENT_TIMESTAMP sao palavras-chave do SQLite (UTC).
function TFluentSQLFunctionsSQLite.CurrentDate: String;
begin
  Result := 'CURRENT_DATE';
end;

function TFluentSQLFunctionsSQLite.CurrentTimestamp: String;
begin
  Result := 'CURRENT_TIMESTAMP';
end;

// ATENCAO: CEIL/CEILING no SQLite exigem 3.35.0+ compilado com
// SQLITE_ENABLE_MATH_FUNCTIONS. Mesma condicao que ja vale para FLOOR e para o
// comportamento anterior deste driver, entao nao ha regressao aqui.
function TFluentSQLFunctionsSQLite.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

// SQLite tem o operador % no core (nao tem MOD()).
function TFluentSQLFunctionsSQLite.Modulus(const AValue, ADivisor: String): String;
begin
  Result := '(' + AValue + ' % ' + ADivisor + ')';
end;

// Medido em SQLite 3.53.4. O SQLite e o caso PERIGOSO desta matriz: ele nunca
// recusa um alvo de CAST. Qualquer palavra e aceita e resolvida pelas regras de
// AFINIDADE, entao um mapeamento ingenuo nao gera erro - gera DADO ERRADO:
//   CAST('2026-08-10'          AS DATE)     -> 2026     (typeof integer)
//   CAST('2026-08-10 12:34:56' AS DATETIME) -> 2026     (typeof integer)
//   CAST('true'                AS BOOLEAN)  -> 0
//   CAST('6F9619FF-8B86-...'   AS UUID)     -> 6
//   CAST('abc'                 AS BANANA)   -> aceito, afinidade integer
// Nenhuma dessas linhas levanta. A data vira o ano, o GUID vira o digito 6, e a
// consulta segue. Por isso dftDate/dftDateTime/dftGuid/dftBoolean LEVANTAM aqui,
// mesmo o motor "aceitando": erro nomeado e melhor que SQL que o motor aceita com
// semantica errada.
//
// So TEXT, INTEGER, REAL e BLOB tem significado real. Largura e ignorada pelo
// motor - medido, CAST('abcdefghij' AS TEXT(4)) devolve 'abcdefghij' inteiro -
// entao ALength e deliberadamente descartado em vez de emitido como enfeite.
function TFluentSQLFunctionsSQLite.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
begin
  case ADataType of
    dftString, dftText: LType := 'TEXT';
    dftInteger:         LType := 'INTEGER';
    dftFloat:           LType := 'REAL';
    dftDate:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftDate)',
                   'SQLite (nao ha tipo DATE; CAST(''2026-08-10'' AS DATE) devolve ' +
                   '2026 por afinidade numerica, sem erro)');
    dftDateTime: raise EFluentSQLFunctionNotSupported.Create('Cast(dftDateTime)',
                   'SQLite (nao ha tipo DATETIME; CAST devolve 2026 por afinidade ' +
                   'numerica, sem erro)');
    dftGuid:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftGuid)',
                   'SQLite (nao ha tipo UUID; CAST do GUID textual devolve 6)');
    dftBoolean:  raise EFluentSQLFunctionNotSupported.Create('Cast(dftBoolean)',
                   'SQLite (nao ha tipo BOOLEAN; CAST(''true'' AS BOOLEAN) devolve 0)');
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'SQLite (nao ha tipo ARRAY; a palavra seria aceita e resolvida ' +
                   'por afinidade numerica)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'SQLite (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



