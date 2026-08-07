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

unit FluentSQL.SerializeSQLite;

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
  TFluentSQLSerializerSQLite = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerializer }

/// <summary>
///   Corpo do nucleo + cauda LIMIT/OFFSET no fim, que e onde a gramatica do
///   SQLite as coloca. Antes este metodo nao concatenava paginacao nenhuma: o
///   LIMIT/OFFSET era emitido por TFluentSQLSelectSQLite.Serialize entre o
///   SELECT e a lista de colunas.
/// </summary>
function TFluentSQLSerializerSQLite.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := TUtils.Concat([ComposeSqlCore(AAST),
                           AAST.Select.Qualifiers.SerializePagination]);
  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.






