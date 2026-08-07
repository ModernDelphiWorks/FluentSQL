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

unit FluentSQL.Select.SQLite;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectSQLite = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.QualifierSQLite;

{ TFluentSQLSelectSQLite }

constructor TFluentSQLSelectSQLite.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersSQLite.Create;
end;

/// <summary>
///   SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;, sem paginacao nenhuma.
///
///   O LIMIT/OFFSET saia daqui, entre o SELECT e a lista de colunas, produzindo
///   "SELECT LIMIT 10 OFFSET 20 * FROM T" - posicao errada na gramatica, SQL
///   invalido em TODA consulta paginada, com ou sem WHERE. No SQLite LIMIT e
///   OFFSET sao as ULTIMAS clausulas do SELECT; quem as concatena agora e
///   TFluentSQLSerializerSQLite.AsString.
/// </summary>
function TFluentSQLSelectSQLite.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FQualifiers.SerializeDistinct,
                             FColumns.Serialize,
                             'FROM',
                             FTableNames.Serialize]);
end;

end.



