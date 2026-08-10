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

unit FluentSQL.FunctionsPostgreSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsPostgreSQL = class(TFluentSQLFunctionAbstract)
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

{ TFluentSQLFunctionsPostgreSQL }

function TFluentSQLFunctionsPostgreSQL.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsPostgreSQL.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsPostgreSQL.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Date(const AVAlue: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ''dd/MM/yyyy'')';
end;

function TFluentSQLFunctionsPostgreSQL.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBSTRING(' + AValue + ' FROM ' + IntToStr(AStart) + ' FOR ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsPostgreSQL.Coalesce(const AValues: array of String): String;
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

function TFluentSQLFunctionsPostgreSQL.CurrentDate: String;
begin
  Result := 'CURRENT_DATE';
end;

function TFluentSQLFunctionsPostgreSQL.CurrentTimestamp: String;
begin
  Result := 'CURRENT_TIMESTAMP';
end;

function TFluentSQLFunctionsPostgreSQL.Modulus(const AValue, ADivisor: String): String;
begin
  Result := 'MOD(' + AValue + ', ' + ADivisor + ')';
end;

// PostgreSQL tem LENGTH e CHAR_LENGTH (equivalentes para tipos texto).
function TFluentSQLFunctionsPostgreSQL.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

// PostgreSQL aceita CEIL e CEILING.
function TFluentSQLFunctionsPostgreSQL.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

// Medido em PostgreSQL 16.14. E o dialeto mais completo da matriz: das dez celulas
// do enum so dftArray e dftUnknown nao tem alvo.
//
// dftString emite VARCHAR SEM largura DE PROPOSITO, e isto e o INVERSO da regra do
// SQL Server. Medido:
//   CAST('<40 chars>'  AS VARCHAR)    -> 40 caracteres, nada truncado
//   CAST('abcdefghij'  AS VARCHAR(4)) -> 'abcd', truncado EM SILENCIO
// Ou seja, aqui a largura e que INTRODUZ corrupcao. Emitir VARCHAR(4000) "por
// consistencia" com Firebird/Oracle colocaria um teto de 4000 onde hoje nao ha teto
// nenhum. Largura so vai se o chamador pedir explicitamente.
//
// dftArray levanta porque nao existe alvo generico: 'ARRAY' sozinho e erro de
// sintaxe (ERROR: syntax error at or near "ARRAY"); o PostgreSQL exige o tipo do
// ELEMENTO - INTEGER[], TEXT[] - e o enum nao carrega essa informacao. Quem precisa
// disso usa a sobrecarga Cast(String, String), que e o escape hatch.
function TFluentSQLFunctionsPostgreSQL.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
begin
  case ADataType of
    dftString:
      if ALength > 0 then
        LType := 'VARCHAR(' + IntToStr(ALength) + ')'
      else
        LType := 'VARCHAR';
    dftInteger:  LType := 'INTEGER';
    dftFloat:    LType := 'DOUBLE PRECISION';
    dftDate:     LType := 'DATE';
    dftText:     LType := 'TEXT';
    dftDateTime: LType := 'TIMESTAMP';
    dftGuid:     LType := 'UUID';
    dftBoolean:  LType := 'BOOLEAN';
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'PostgreSQL (ARRAY sozinho e erro de sintaxe; o motor exige o ' +
                   'tipo do elemento, como INTEGER[], que o enum nao carrega)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'PostgreSQL (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



