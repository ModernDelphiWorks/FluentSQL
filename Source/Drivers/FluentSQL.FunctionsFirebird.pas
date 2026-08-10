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

unit FluentSQL.FunctionsFirebird;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
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

// Firebird nao tem LENGTH() no core; a funcao de tamanho em caracteres e
// CHAR_LENGTH (FB 2.1+). LENGTH so existe via UDF do ib_udf.
function TFluentSQLFunctionsFirebird.Length(const AValue: String): String;
begin
  Result := 'CHAR_LENGTH(' + AValue + ')';
end;

// Firebird 2.1+ implementa TRIM padrao SQL; nao ha LTRIM/RTRIM no core, usa-se
// TRIM(LEADING|TRAILING FROM ...).
function TFluentSQLFunctionsFirebird.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsFirebird.LTrim(const AValue: String): String;
begin
  Result := 'TRIM(LEADING FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsFirebird.RTrim(const AValue: String): String;
begin
  Result := 'TRIM(TRAILING FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsFirebird.Coalesce(const AValues: array of String): String;
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

function TFluentSQLFunctionsFirebird.CurrentDate: String;
begin
  Result := 'CURRENT_DATE';
end;

function TFluentSQLFunctionsFirebird.CurrentTimestamp: String;
begin
  Result := 'CURRENT_TIMESTAMP';
end;

// Firebird 2.1+ aceita CEIL e CEILING; CEIL e a forma curta.
function TFluentSQLFunctionsFirebird.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

// Firebird 2.1+ tem MOD(a, b); nao ha operador % .
function TFluentSQLFunctionsFirebird.Modulus(const AValue, ADivisor: String): String;
begin
  Result := 'MOD(' + AValue + ', ' + ADivisor + ')';
end;

// Medido em Firebird 5.0.4 (LI-V5.0.4.1812); transcricao literal dos erros em
// Test Delphi\Common_tests\test.cast.matrix.sql.
//
// LARGURA E OBRIGATORIA para VARCHAR: 'CAST(x AS VARCHAR)' NAO trunca calado como
// no SQL Server, nem passa como no PostgreSQL - e erro de sintaxe:
//   SQLSTATE = 42000 / -SQL error code = -104 / -Token unknown - line 1, column 78
// E, com largura, o estouro tambem e ERRO e nao truncamento silencioso:
//   CAST('<40 chars>' AS VARCHAR(20))
//   SQLSTATE = 22001 / -string right truncation / -expected length 20, actual 40
// Ou seja, o Firebird nunca corrompe calado aqui - por isso a largura default
// generosa (4000) e segura.
//
// dftGuid e dftArray levantam: 'UUID' e 'ARRAY' nao sao nomes de tipo conhecidos,
// e o motor responde
//   -SQL error code = -607 / -Specified domain or source column UUID does not exist
// O Firebird guarda GUID como CHAR(16) CHARACTER SET OCTETS e converte por
// UUID_TO_CHAR/CHAR_TO_UUID; nao ha CAST direto de/para a forma textual com
// hifens, entao qualquer grafia que puséssemos aqui mentiria sobre o valor.
function TFluentSQLFunctionsFirebird.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
  LLength: Integer;
begin
  LLength := ALength;
  if LLength <= 0 then
    LLength := cFluentSQLCastDefaultLength;
  case ADataType of
    dftString:   LType := 'VARCHAR(' + IntToStr(LLength) + ')';
    dftInteger:  LType := 'INTEGER';
    dftFloat:    LType := 'DOUBLE PRECISION';
    dftDate:     LType := 'DATE';
    dftText:     LType := 'BLOB SUB_TYPE TEXT';
    dftDateTime: LType := 'TIMESTAMP';
    dftBoolean:  LType := 'BOOLEAN';
    dftGuid:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftGuid)',
                   'Firebird (nao ha tipo UUID; CAST AS UUID da -607. GUID e ' +
                   'CHAR(16) CHARACTER SET OCTETS, convertido por CHAR_TO_UUID)');
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'Firebird (CAST AS ARRAY da -607; array nao e alvo de CAST)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'Firebird (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



