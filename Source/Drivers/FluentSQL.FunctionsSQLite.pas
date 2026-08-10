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
// consulta segue.
//
// ESTE DRIVER E A PROVA DE QUE A INTERSECAO TEM DE SER ESTRITA. dftDate,
// dftDateTime, dftGuid e dftBoolean existem no PostgreSQL, e quatro delas tambem
// no SQL Server; se a API oferecesse a UNIAO, o mesmo Cast(x, dftDate) que roda
// certo no PG chegaria aqui, nao levantaria nada, e devolveria 2026. O bug nao
// apareceria em teste, apareceria em relatorio - e so meses depois. So TEXT,
// INTEGER, REAL e BLOB tem significado real neste motor, e a intersecao dos sete
// e ainda menor: dftString, dftInteger, dftFloat.
//
// Largura e ignorada pelo motor - medido, CAST('abcdefghij' AS TEXT(4)) devolve
// 'abcdefghij' inteiro - entao ALength e deliberadamente descartado aqui em vez de
// emitido como enfeite que mente.
function TFluentSQLFunctionsSQLite.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
begin
  _AssertCastTypeIsPortable(ADataType);
  case ADataType of
    dftString:  LType := 'TEXT';
    dftInteger: LType := 'INTEGER';
    dftFloat:   LType := 'REAL';
  else
    _RaiseCastCellMissing('SQLite', ADataType);
    LType := '';
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



