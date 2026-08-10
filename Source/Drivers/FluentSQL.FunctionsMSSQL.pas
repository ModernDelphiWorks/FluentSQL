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

unit FluentSQL.FunctionsMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
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
    function Length(const AValue: String): String; override;
    function Ceil(const AValue: String): String; override;
    function Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType;
      const ALength: Integer = 0): String; overload; override;
  end;

implementation

uses
  FluentSQL.Register;

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

// T-SQL nao tem LENGTH; a funcao de tamanho e LEN (que descarta espacos a
// direita) - CHAR_LENGTH tambem nao existe.
function TFluentSQLFunctionsMSSQL.Length(const AValue: String): String;
begin
  Result := 'LEN(' + AValue + ')';
end;

// T-SQL nao tem CEIL, so CEILING. Este override existia desde sempre mas era
// inalcancavel: Ceil estava no padrao A, emitindo CEIL(...) no core.
function TFluentSQLFunctionsMSSQL.Ceil(const AValue: String): String;
begin
  Result := 'CEILING(' + AValue + ')';
end;

// Medido em Microsoft SQL Server 2022 (RTM-CU26) 16.0.4265.3.
//
// ESTE E O DIALETO QUE JUSTIFICA A LARGURA EXPLICITA. Um mapeamento ingenuo
// dftString -> 'NVARCHAR' compila, roda, NAO da erro e CORROMPE:
//   SELECT LEN(CAST('<40 chars>' AS NVARCHAR)), CAST('<40 chars>' AS NVARCHAR)
//     len_varchar  len_nvarchar  v
//     30           30            123456789012345678901234567890
// 40 caracteres entram, 30 saem, sem erro e sem aviso - o comprimento default de
// CAST/CONVERT no T-SQL e 30. Trocar a incoerencia de API de hoje por isso seria
// estritamente pior que nao mexer. Por isso a largura vai SEMPRE explicita.
//
// O teto e 4000: CAST('ab' AS NVARCHAR(4001)) da
//   Msg 131 ... The size (4001) given to the convert specification 'nvarchar'
//   exceeds the maximum allowed for any data type (4000).
// Para texto sem teto o alvo e NVARCHAR(MAX), que e o dftText.
//
// dftBoolean e BIT (T-SQL nao tem BOOLEAN: "Msg 243 ... Type BOOLEAN is not a
// defined system type."), e dftArray levanta pela mesma mensagem com ARRAY.
function TFluentSQLFunctionsMSSQL.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
  LLength: Integer;
begin
  LLength := ALength;
  if LLength <= 0 then
    LLength := cFluentSQLCastDefaultLength;
  case ADataType of
    dftString:   LType := 'NVARCHAR(' + IntToStr(LLength) + ')';
    dftInteger:  LType := 'INT';
    dftFloat:    LType := 'FLOAT';
    dftDate:     LType := 'DATE';
    dftText:     LType := 'NVARCHAR(MAX)';
    dftDateTime: LType := 'DATETIME';
    dftGuid:     LType := 'UNIQUEIDENTIFIER';
    dftBoolean:  LType := 'BIT';
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'SQL Server (Msg 243: Type ARRAY is not a defined system type)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'SQL Server (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



