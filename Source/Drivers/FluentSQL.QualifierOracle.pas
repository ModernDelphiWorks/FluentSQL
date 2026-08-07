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

unit FluentSQL.QualifierOracle;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersOracle = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersOracle }

/// <summary>
///   Cauda do row_limiting_clause (Oracle 12.1+):
///   [OFFSET n ROWS] [FETCH NEXT m ROWS ONLY]. Os dois membros sao OPCIONAIS e
///   independentes na gramatica do SELECT, entao Skip sozinho e First sozinho
///   saem completos, sem preenchimento artificial - ao contrario do SQL Server,
///   onde FETCH exige OFFSET.
///
///   Substitui o encadeamento ROWNUM/ROWINI que embrulhava a consulta em duas
///   subconsultas. O que a forma velha fazia de errado, alem de ser mais longa:
///
///     1. Skip sem First emitia "...) AND ROWINI > 20" - AND sem WHERE, ORA-00920.
///     2. "WHERE ROWNUM <= m AND ROWINI > n" depende da ordem em que o otimizador
///        aplica os predicados, porque ROWNUM so e atribuido a linhas que JA
///        passaram pelo filtro.
///     3. O embrulho "SELECT * FROM (SELECT T.*, ...)" quebra com ORA-00918
///        (column ambiguously defined) sempre que a consulta interna e um join
///        com nomes de coluna repetidos - defeito que some junto com o embrulho.
///
///   A propria doc da Oracle prefere esta forma: o row_limiting_clause "provides
///   superior support" em relacao ao ROWNUM.
/// </summary>
function TFluentSQLSelectQualifiersOracle.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('Oracle');
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'OFFSET', IntToStr(LPag.Skip), 'ROWS']);
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FETCH NEXT', IntToStr(LPag.First), 'ROWS ONLY']);
end;

end.



