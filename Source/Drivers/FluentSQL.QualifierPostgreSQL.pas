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

unit FluentSQL.QualifierPostgreSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersPostgreSQL = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersPostgreSQL }

/// <summary>
///   Cauda de paginacao do PostgreSQL: [LIMIT m] [OFFSET n], nesta ordem, no fim
///   da consulta. E o unico dos sete em que LIMIT e OFFSET sao clausulas de fato
///   INDEPENDENTES - "OFFSET n" sozinho e valido e o manual o documenta assim
///   ("The OFFSET clause ... it is possible to use both"). Por isso Skip sem
///   First nao precisa de teto artificial, ao contrario do MySQL e do SQLite.
/// </summary>
function TFluentSQLSelectQualifiersPostgreSQL.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('PostgreSQL');
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'LIMIT', IntToStr(LPag.First)]);
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'OFFSET', IntToStr(LPag.Skip)]);
end;

end.



