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

unit FluentSQL.FunctionsMySQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
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

function TFluentSQLFunctionsMySQL.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMySQL.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMySQL.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsMySQL.Coalesce(const AValues: array of String): String;
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

function TFluentSQLFunctionsMySQL.CurrentDate: String;
begin
  Result := 'CURDATE()';
end;

function TFluentSQLFunctionsMySQL.CurrentTimestamp: String;
begin
  Result := 'NOW()';
end;

function TFluentSQLFunctionsMySQL.Modulus(const AValue, ADivisor: String): String;
begin
  Result := '(' + AValue + ' % ' + ADivisor + ')';
end;

// MySQL tem LENGTH (bytes) e CHAR_LENGTH (caracteres). Mantido LENGTH, que era
// o que o core ja emitia no padrao A - trocar seria mudanca de comportamento
// alheia a esta tarefa.
function TFluentSQLFunctionsMySQL.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

// MySQL aceita CEIL e CEILING.
function TFluentSQLFunctionsMySQL.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

// Medido em MySQL 8.4.11. ESTE E O DIALETO QUE MAIS DIVERGE, porque o alvo de CAST
// no MySQL nao e "um nome de tipo qualquer": e uma LISTA FECHADA na gramatica. O
// que vale em CREATE TABLE nao vale aqui, e o motor responde com erro de SINTAXE,
// nao de tipo:
//   CAST('123' AS INTEGER) -> ERROR 1064 (42000) ... near 'INTEGER) AS r'
//   CAST('x'   AS TEXT)    -> ERROR 1064 (42000) ... near 'TEXT) AS r'
//   CAST(1     AS BOOLEAN) -> ERROR 1064 (42000) ... near 'BOOLEAN) AS r'
//   CAST('...' AS UUID)    -> ERROR 1064 (42000) ... near 'UUID) AS r'
// E por isto que Cast nao podia continuar no padrao A: a grafia ANSI 'INTEGER' que
// o core emitia e erro de SINTAXE aqui.
//
// dftString/dftText emitem CHAR SEM largura de proposito: medido, CAST AS CHAR nao
// trunca (40 caracteres entram, 40 saem), entao impor CHAR(4000) so criaria um teto
// que hoje nao existe. Largura explicita do chamador e respeitada.
//
// dftBoolean levanta: o MySQL nao tem tipo booleano (BOOLEAN e apelido de
// TINYINT(1) em DDL) e nao aceita BOOLEAN como alvo de CAST. Emitir UNSIGNED no
// lugar devolveria 1/0 - um INTEIRO com cara de booleano, semantica errada em
// silencio, que e exatamente o que esta tarefa existe para nao fazer.
function TFluentSQLFunctionsMySQL.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
begin
  case ADataType of
    dftString, dftText:
      if ALength > 0 then
        LType := 'CHAR(' + IntToStr(ALength) + ')'
      else
        LType := 'CHAR';
    dftInteger:  LType := 'SIGNED';
    dftFloat:    LType := 'DOUBLE';
    dftDate:     LType := 'DATE';
    dftDateTime: LType := 'DATETIME';
    dftBoolean:  raise EFluentSQLFunctionNotSupported.Create('Cast(dftBoolean)',
                   'MySQL (ERROR 1064: BOOLEAN nao e alvo de CAST; UNSIGNED daria ' +
                   'inteiro 1/0, semantica errada em silencio)');
    dftGuid:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftGuid)',
                   'MySQL (ERROR 1064: UUID nao e alvo de CAST; nao ha tipo UUID)');
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'MySQL (ERROR 1064: ARRAY nao e alvo de CAST)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'MySQL (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



