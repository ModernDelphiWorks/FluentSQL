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

end.




