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

unit FluentSQL.FunctionsOracle;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsOracle = class(TFluentSQLFunctionAbstract)
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

{ TFluentSQLFunctionsOracle }

function TFluentSQLFunctionsOracle.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsOracle.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsOracle.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsOracle.Date(const AVAlue: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ''dd/MM/yyyy'')';
end;

function TFluentSQLFunctionsOracle.Day(const AValue: String): String;
begin
  Result := 'EXTRACT(DAY FROM ' + AVAlue + ')';
end;

function TFluentSQLFunctionsOracle.Month(const AValue: String): String;
begin
  Result := 'EXTRACT(MONTH FROM ' + AVAlue + ')';
end;

function TFluentSQLFunctionsOracle.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBSTR(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsOracle.Year(const AValue: String): String;
begin
  Result := 'EXTRACT(YEAR FROM ' + AVAlue + ')';
end;

// LENGTH, TRIM, LTRIM, RTRIM, COALESCE e MOD sao built-ins do Oracle.
function TFluentSQLFunctionsOracle.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Trim(const AValue: String): String;
begin
  Result := 'TRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.LTrim(const AValue: String): String;
begin
  Result := 'LTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.RTrim(const AValue: String): String;
begin
  Result := 'RTRIM(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Coalesce(const AValues: array of String): String;
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

// Oracle: CURRENT_DATE traz data COM hora. Para manter a semantica dos demais
// dialetos (data sem hora, como CAST(GETDATE() AS DATE) no MSSQL) usa-se
// TRUNC(SYSDATE), que e o idioma canonico no Oracle.
function TFluentSQLFunctionsOracle.CurrentDate: String;
begin
  Result := 'TRUNC(SYSDATE)';
end;

function TFluentSQLFunctionsOracle.CurrentTimestamp: String;
begin
  Result := 'SYSTIMESTAMP';
end;

// Oracle tem CEIL; nao tem CEILING.
function TFluentSQLFunctionsOracle.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

function TFluentSQLFunctionsOracle.Modulus(const AValue, ADivisor: String): String;
begin
  Result := 'MOD(' + AValue + ', ' + ADivisor + ')';
end;

// Medido em Oracle AI Database 26ai Free Release 23.26.2.0.0. ATENCAO A TAG: a
// imagem gvenzl/oracle-free:23-slim NAO entrega 23c, entrega 23.26.2.0.0.
//
// LARGURA E OBRIGATORIA para VARCHAR2 - sem ela nao e truncamento, e erro de
// sintaxe, e a mensagem nem menciona comprimento:
//   CAST('...' AS VARCHAR2)      ORA-00906: missing left parenthesis
// O teto e 4000 (VARCHAR2 em SQL):
//   CAST('ab' AS VARCHAR2(4001)) ORA-00910: specified length too long for its datatype
//
// dftText LEVANTA e esta e a divergencia menos obvia da matriz: CLOB existe na
// Oracle mas NAO e alvo valido de CAST -
//   CAST('abcdefghij' AS CLOB)   ORA-22849: Type CLOB is not supported for this
//                                function or operator.
// A forma Oracle e TO_CLOB(...), que e outra funcao e nao cabe em Cast.
//
// dftGuid LEVANTA por motivo de VALOR, nao de tipo: o equivalente Oracle e
// RAW(16), e RAW(16) aceita hex puro mas recusa a forma textual com hifens, que e
// a que um GUID carrega em qualquer consumidor -
//   CAST('6F9619FF8B86D011B42D00C04FC964FF'     AS RAW(16))  ok
//   CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS RAW(16))  ORA-01465: invalid hex number
// Emitir RAW(16) daria SQL que passa no teste com hex puro e explode quando o GUID
// vier na forma normal - pior que recusar.
//
// dftBoolean e BOOLEAN e SO funciona porque este motor e 23ai+; em 19c e anterior
// nao ha BOOLEAN em SQL. O FluentSQL nao tem como saber a versao do servidor, entao
// esta celula assume 23ai - registrado como risco no relatorio da T17.
function TFluentSQLFunctionsOracle.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
var
  LType: String;
  LLength: Integer;
begin
  LLength := ALength;
  if LLength <= 0 then
    LLength := cFluentSQLCastDefaultLength;
  case ADataType of
    dftString:   LType := 'VARCHAR2(' + IntToStr(LLength) + ')';
    dftInteger:  LType := 'INTEGER';
    dftFloat:    LType := 'BINARY_DOUBLE';
    dftDate:     LType := 'DATE';
    dftDateTime: LType := 'TIMESTAMP';
    dftBoolean:  LType := 'BOOLEAN';
    dftText:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftText)',
                   'Oracle (ORA-22849: Type CLOB is not supported for this function ' +
                   'or operator; a forma Oracle e TO_CLOB, nao CAST)');
    dftGuid:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftGuid)',
                   'Oracle (nao ha tipo GUID; RAW(16) recusa a forma textual com ' +
                   'hifens com ORA-01465: invalid hex number)');
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'Oracle (ORA-00902: invalid datatype; ARRAY nao e alvo de CAST)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'Oracle (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



