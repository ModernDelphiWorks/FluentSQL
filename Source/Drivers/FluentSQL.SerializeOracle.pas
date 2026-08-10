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

unit FluentSQL.SerializeOracle;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.Serialize;

type
  TFluentSQLSerializeOracle = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
    function RelationAliasKeyword: String; override;
  end;

implementation

{ TFluentSQLSerialize }

/// <summary>
///   Corpo do nucleo + cauda row_limiting_clause no fim.
///
///   Antes a paginacao vinha como TEMPLATE ("SELECT * FROM (SELECT T.*, ROWNUM
///   AS ROWINI FROM (%s) T) WHERE ROWNUM ...") e este metodo aplicava Format
///   sobre o corpo, embrulhando a consulta inteira em duas subconsultas. Com
///   OFFSET/FETCH nao ha embrulho: basta concatenar. Some junto a armadilha do
///   ORA-00918, em que "SELECT T.*" sobre um join com nomes de coluna repetidos
///   derruba a consulta com "column ambiguously defined".
/// </summary>
function TFluentSQLSerializeOracle.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := TUtils.Concat([ComposeSqlCore(AAST),
                           AAST.Select.Qualifiers.SerializePagination]);
  Result := Result + DialectOnlySqlSuffix(AAST);
end;

/// <summary>
///   Na Oracle o apelido de RELACAO vem SEM palavra nenhuma antes: "T AP", nao
///   "T AS AP".
///
///   A doc do SELECT da Oracle define t_alias (apelido de tabela, view ou
///   subconsulta) sem citar AS em momento algum, e define c_alias (apelido de
///   coluna) dizendo "The AS keyword is optional". Declara opcional onde e
///   permitido e omite onde nao e.
///
///   MEDIDO em Oracle AI Database 26ai Free Release 23.26.2.0.0 (imagem
///   gvenzl/oracle-free:23-slim), com a transcricao completa em
///   Test Delphi\Common_tests\test.alias.oracle.sql:
///
///     SELECT * FROM A AS AP                      -> ORA-03048
///     SELECT * FROM A LEFT JOIN B AS X ON (...)  -> ORA-02000
///     DELETE FROM A AS AP WHERE (...)            -> ORA-03048
///     SELECT A.NOME AS N FROM A                  -> ACEITO (o contraste)
///
///   Nao e ORA-00933, que era o palpite corrente: os dois codigos acima sao os
///   que este motor devolveu.
/// </summary>
function TFluentSQLSerializeOracle.RelationAliasKeyword: String;
begin
  Result := '';
end;

end.




