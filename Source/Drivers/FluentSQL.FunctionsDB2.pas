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

unit FluentSQL.FunctionsDB2;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsDB2 = class(TFluentSQLFunctionAbstract)
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
    function Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType;
      const ALength: Integer = 0): String; overload; override;
  end;

implementation

uses
  FluentSQL.Register;

{ TFluentSQLFunctionsDB2 }

function TFluentSQLFunctionsDB2.Concat(const AValue: array of String): String;
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

constructor TFluentSQLFunctionsDB2.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsDB2.Date(const AVAlue, AFormat: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ' + AFormat + ')';
end;

function TFluentSQLFunctionsDB2.Date(const AVAlue: String): String;
begin
  Result := 'TO_DATE(' + AValue + ', ''dd/MM/yyyy'')';
end;

function TFluentSQLFunctionsDB2.Day(const AValue: String): String;
begin
  Result := 'DAY(' + AVAlue + ')';
end;

function TFluentSQLFunctionsDB2.Month(const AValue: String): String;
begin
  Result := 'MONTH(' + AVAlue + ')';
end;

function TFluentSQLFunctionsDB2.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  Result := 'SUBString(' + AValue + ', ' + IntToStr(AStart) + ', ' + IntToStr(ALength) + ')';
end;

function TFluentSQLFunctionsDB2.Year(const AValue: String): String;
begin
  Result := 'YEAR(' + AVAlue + ')';
end;

// Length e Ceil passaram de padrao A para padrao B; DB2 tem LENGTH e CEIL
// (tambem CEILING) como built-ins, entao a saida e identica a que o core emitia.
function TFluentSQLFunctionsDB2.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctionsDB2.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

// Medido em DB2 v12.1.5.0 (DB2/LINUXX8664), driver DESLIGADO em FluentSQL.inc -
// medido assim mesmo, para que ligar {$DEFINE DB2} nao encontre celula inventada.
//
// dftString emite VARCHAR SEM largura, como o PostgreSQL e ao contrario de
// Firebird/Oracle/SQL Server. Medido: CAST(REPEAT('x',300) AS VARCHAR) devolve
// LENGTH 300 - o DB2 nao impoe teto default nem trunca calado, entao acrescentar
// VARCHAR(4000) so criaria um teto que hoje nao existe.
//
// dftText e CLOB, e aqui o DB2 diverge da Oracle: la CLOB nao e alvo de CAST
// (ORA-22849), aqui CAST('abcdefghij' AS CLOB) devolve LENGTH 10 normalmente.
//
// dftGuid e dftArray levantam - o DB2 nao conhece nenhum dos dois nomes:
//   CAST('...' AS UUID)   SQL0204N  "UUID" is an undefined name.  SQLSTATE=42704
//   CAST('x'   AS ARRAY)  SQL0204N  "ARRAY" is an undefined name. SQLSTATE=42704
// (O DB2 guarda GUID como CHAR(16) FOR BIT DATA, que tem o mesmo problema da
// RAW(16) da Oracle: recusa a forma textual com hifens.)
function TFluentSQLFunctionsDB2.Cast(const AExpression: String;
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
    dftFloat:    LType := 'DOUBLE';
    dftDate:     LType := 'DATE';
    dftText:     LType := 'CLOB';
    dftDateTime: LType := 'TIMESTAMP';
    dftBoolean:  LType := 'BOOLEAN';
    dftGuid:     raise EFluentSQLFunctionNotSupported.Create('Cast(dftGuid)',
                   'DB2 (SQL0204N: "UUID" is an undefined name; GUID e CHAR(16) FOR ' +
                   'BIT DATA e nao aceita a forma textual com hifens)');
    dftArray:    raise EFluentSQLFunctionNotSupported.Create('Cast(dftArray)',
                   'DB2 (SQL0204N: "ARRAY" is an undefined name)');
  else
    raise EFluentSQLFunctionNotSupported.Create('Cast(dftUnknown)',
      'DB2 (dftUnknown nao e tipo; nao ha grafia a emitir)');
  end;
  Result := 'CAST(' + AExpression + ' AS ' + LType + ')';
end;

end.



