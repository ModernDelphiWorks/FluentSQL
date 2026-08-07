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

unit FluentSQL.QualifierSQLite;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersSQLite = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersSQLite }

const
  /// <summary>
  ///   No SQLite o OFFSET nao e clausula independente: "the OFFSET clause ... may
  ///   only follow a LIMIT clause" (sqlite.org/lang_select.html). Skip sem First
  ///   precisa entao de um LIMIT, e a propria doc define o que significa um LIMIT
  ///   negativo:
  ///
  ///     "If the expression has a negative value, then there is no upper bound
  ///      on the number of rows returned."
  ///     https://sqlite.org/lang_select.html
  ///
  ///   -1 e o menor negativo e o idioma consagrado. NAO usar a forma com virgula
  ///   ("LIMIT n, m"): ela existe, mas os operandos vem TROCADOS em relacao a
  ///   "LIMIT m OFFSET n", e a doc pede para nao usa-la.
  /// </summary>
  cSEM_TETO = '-1';

/// <summary>Cauda de paginacao do SQLite: [LIMIT m] [OFFSET n], no FIM da consulta.</summary>
function TFluentSQLSelectQualifiersSQLite.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('SQLite');
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'LIMIT', IntToStr(LPag.First)])
  else if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'LIMIT', cSEM_TETO]);
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'OFFSET', IntToStr(LPag.Skip)]);
end;

end.



