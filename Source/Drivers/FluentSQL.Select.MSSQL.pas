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

unit FluentSQL.Select.MSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Select;

type
  TFluentSQLSelectMSSQL = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.QualifierMSSQL;

{ TFluentSQLSelectMSSQL }

constructor TFluentSQLSelectMSSQL.Create;
begin
  inherited Create;
  FQualifiers := TFluentSQLSelectQualifiersMSSQL.Create;
end;

/// <summary>
///   SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;. Sem embrulho e sem paginacao.
///
///   Duas coisas sairam daqui, as duas por causa da migracao para OFFSET/FETCH:
///
///   1. O embrulho "SELECT * FROM (%s) AS %s", que existia so para dar escopo ao
///      predicado sobre a coluna ROWNUMBER. Sem ROW_NUMBER() nao ha coluna a
///      filtrar, e sem filtro nao ha subconsulta. O embrulho tambem usava
///      FTableNames[0].Name como alias, o que dava alias repetido em consulta com
///      join e nome de alias invalido quando a origem era uma subconsulta.
///
///   2. O DISTINCT, que vinha DEPOIS da lista de colunas: "SELECT NOME DISTINCT
///      FROM T". Isso nao dependia de paginacao nenhuma - Select.Distinct sozinho
///      ja emitia essa forma, que o SQL Server recusa. O DISTINCT antecede a lista
///      de colunas em T-SQL, como em ANSI.
/// </summary>
function TFluentSQLSelectMSSQL.Serialize: String;
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




