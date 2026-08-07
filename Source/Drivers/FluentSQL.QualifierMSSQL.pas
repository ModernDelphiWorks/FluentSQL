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
const
  /// <summary>
  ///   Deslocamento que pula TUDO, usado para exprimir First(0) - "me devolva
  ///   zero linhas".
  ///
  ///   O T-SQL nao aceita FETCH com zero: "FETCH NEXT 0 ROWS ONLY" e
  ///   "Msg 10744, The number of rows provided for a FETCH clause must be
  ///   greater then zero". A restricao e do LITERAL, nao da semantica - a mesma
  ///   consulta com o contador vindo de uma variavel BIGINT valendo 0 e aceita e
  ///   devolve zero linhas (caso Z1 do .sql). Ou seja, "zero linhas" e pedido
  ///   legitimo no motor; o que falta e uma forma literal de escreve-lo.
  ///
  ///   Este e o maior BIGINT: pular 2^63-1 linhas devolve o conjunto vazio em
  ///   qualquer tabela concebivel. 2^63 e recusado com "Msg 8115, Arithmetic
  ///   overflow", o que prova que este e o teto. E o mesmo idioma que o
  ///   QualifierMySQL usa em sentido inverso (LIMIT 2^64-1 para "sem teto").
  ///
  ///   DUAS ALTERNATIVAS FORAM MEDIDAS E RECUSADAS, e a medicao esta em
  ///   test.pagination.mssql.sql, parte Z:
  ///
  ///   - "SELECT TOP 0 ..." e a forma obvia e a MAIS BARATA (0 leituras logicas
  ///     contra 767 desta, numa tabela de 200 mil linhas). Foi recusada por
  ///     estar ERRADA em duas combinacoes: nao pode coexistir com OFFSET
  ///     ("Msg 10741, A TOP can not be used in the same query or sub-query as a
  ///     OFFSET"), e num UNION ela limita apenas o PRIMEIRO RAMO - medido,
  ///     "SELECT TOP 0 * FROM T UNION SELECT * FROM U" devolve as 60 linhas de
  ///     U. Forma que acerta em quase todas as combinacoes e erra em uma nao
  ///     serve para uma API que promete a mesma semantica nas sete.
  ///     Alem disso o TOP mora na clausula SELECT, o que devolveria ao
  ///     TFluentSQLSelectMSSQL o conhecimento da paginacao que a T10 tirou de la
  ///     - foi esse acoplamento que fazia UNION e CTE sumirem em silencio.
  ///
  ///   - "FETCH NEXT (SELECT 0) ROWS ONLY" e aceito E barato (0 leituras), mas
  ///     SO quando o OFFSET e o literal 0. Com "OFFSET 1" ou "OFFSET 20" o mesmo
  ///     texto volta a dar Msg 10744. Como First(0) tem que valer junto com
  ///     Skip(n), tambem nao serve.
  ///
  ///   O PRECO desta escolha esta medido e e real: 767 leituras logicas contra 0
  ///   do TOP 0 numa tabela de 200 mil linhas, porque o motor varre para contar
  ///   o que pula. Vale so para First(0), que e um pedido degenerado.
  /// </summary>
  cPULA_TUDO = '9223372036854775807';

function TFluentSQLSelectQualifiersMSSQL.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('MSSQL');
  if not (LPag.HasFirst or LPag.HasSkip) then
    Exit;
  // First(0) e um pedido legitimo e distinto de "sem First" - ver
  // TFluentSQLPagination. Zero linhas e zero linhas com ou sem Skip, entao o
  // deslocamento pedido pelo usuario e absorvido por este.
  if LPag.HasFirst and (LPag.First = 0) then
    Exit(TUtils.Concat(['OFFSET', cPULA_TUDO, 'ROWS']));
  Result := TUtils.Concat(['OFFSET', IntToStr(LPag.Skip), 'ROWS']);
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FETCH NEXT', IntToStr(LPag.First), 'ROWS ONLY']);
end;

end.




