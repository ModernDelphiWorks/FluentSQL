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

unit FluentSQL.QualifierMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersMSSQL = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersMSSQL }

/// <summary>
///   Cauda <offset_fetch> do SQL Server 2012+:
///   OFFSET n ROWS [FETCH NEXT m ROWS ONLY].
///
///   O OFFSET e SEMPRE emitido, mesmo quando o usuario so pediu First(m): no
///   T-SQL o FETCH nao existe sozinho. Medido, nao deduzido -
///   "SELECT ID FROM T ORDER BY (SELECT NULL) FETCH NEXT 3 ROWS ONLY" devolve
///   "Msg 153: Invalid usage of the option NEXT in the FETCH statement" (caso K
///   de test.pagination.mssql.sql). Por isso First sozinho vira
///   "OFFSET 0 ROWS FETCH NEXT m ROWS ONLY", que e a forma minima valida.
///   A Oracle nao precisa disso porque la os dois membros sao independentes.
///
///   Esta cauda substitui o par ROW_NUMBER() + subconsulta + predicado
///   "ROWNUMBER > n AND ROWNUMBER <= n+m". A forma velha nao era so mais longa:
///   como a paginacao virava um WHERE, ela ficava presa DENTRO do corpo montado
///   por TFluentSQLSerializerMSSQL.AsString, que nunca passava por
///   ComposeSqlCore - e por isso UNION e WITH (CTE) sumiam do SQL EM SILENCIO,
///   e Distinct levantava excecao. Como cauda, a paginacao passa a ser
///   concatenada DEPOIS do que o nucleo montou, e as tres combinacoes voltam
///   sozinhas.
///
///   A clausula ORDER BY que o <offset_fetch> exige NAO e montada aqui: quem a
///   monta e o serializador, que e o unico que enxerga o ORDER BY do usuario, o
///   DISTINCT e o UNION.
/// </summary>
function TFluentSQLSelectQualifiersMSSQL.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('MSSQL');
  if not (LPag.HasFirst or LPag.HasSkip) then
    Exit;
  // First(0) NAO sai por aqui, e o motivo e gramatical: o T-SQL nao aceita FETCH
  // com zero ("Msg 10744, The number of rows provided for a FETCH clause must be
  // greater then zero"), e a forma que exprime o conjunto vazio - SELECT TOP 0 -
  // mora na clausula SELECT, nao na cauda. Quem a emite e TFluentSQLSelectMSSQL.
  //
  // Descartar aqui o OFFSET pedido pelo usuario e CORRETO e nao e perda: pular n
  // linhas de um conjunto vazio da o mesmo conjunto vazio. Foi justamente manter
  // o OFFSET que fazia o TOP 0 parecer inviavel - "Msg 10741, A TOP can not be
  // used in the same query or sub-query as a OFFSET" so acontece se os dois
  // forem emitidos juntos.
  //
  // A UNICA excecao e consulta com UNION/UNION ALL/EXCEPT/INTERSECT, onde o TOP
  // limita so um ramo; la o serializador acrescenta a cauda de "pular tudo",
  // porque so ele enxerga a operacao de conjunto.
  if RequestsZeroRows then
    Exit('');
  Result := TUtils.Concat(['OFFSET', IntToStr(LPag.Skip), 'ROWS']);
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FETCH NEXT', IntToStr(LPag.First), 'ROWS ONLY']);
end;

end.




