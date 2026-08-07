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

unit FluentSQL.QualifierMySQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersMySQL = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersMySQL }

const
  /// <summary>
  ///   No MySQL o OFFSET nao existe sem LIMIT: a gramatica e
  ///   "LIMIT {[offset,] row_count | row_count OFFSET offset}", entao "OFFSET n"
  ///   sozinho e erro de sintaxe - era exatamente o que este driver emitia para
  ///   Skip sem First. O teto usado aqui NAO e invencao: e a receita do proprio
  ///   manual para "recuperar todas as linhas a partir de um deslocamento".
  ///
  ///     "To retrieve all rows from a certain offset up to the end of the result
  ///      set, you can use some large number for the second parameter."
  ///     https://dev.mysql.com/doc/refman/8.4/en/select.html
  ///
  ///   O valor e 2^64-1, o maior BIGINT UNSIGNED, que e o tipo do row_count.
  /// </summary>
  cSEM_TETO = '18446744073709551615';

/// <summary>Cauda de paginacao do MySQL: [LIMIT m] [OFFSET n], no fim da consulta.</summary>
function TFluentSQLSelectQualifiersMySQL.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('MySQL');
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'LIMIT', IntToStr(LPag.First)])
  else if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'LIMIT', cSEM_TETO]);
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'OFFSET', IntToStr(LPag.Skip)]);
end;

end.



