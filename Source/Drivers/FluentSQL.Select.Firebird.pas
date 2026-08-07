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

unit FluentSQL.Select.Firebird;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectFirebird = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation


uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.QualifierFirebird;

{ TFluentSQLSelectFirebird }

constructor TFluentSQLSelectFirebird.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersFirebird.Create;
end;

/// <summary>
///   SELECT [FIRST m] [SKIP n] [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;.
///
///   A ordem FIRST/SKIP ANTES do DISTINCT nao e estilo, e a gramatica:
///
///     SELECT [FIRST m] [SKIP n] [{DISTINCT | ALL}] &lt;columns&gt;
///     Firebird 5.0 Language Reference, SELECT.
///
///   A ordem anterior colocava o DISTINCT na frente e o Firebird 5.0.4 recusa a
///   consulta inteira:
///
///     SELECT DISTINCT FIRST 3 SKIP 20 NOME FROM T;
///     -SQL error code = -104 / -Token unknown - line 1, column 23
///
///   contra a mesma consulta na ordem correta, que devolve as tres linhas:
///
///     SELECT FIRST 3 SKIP 20 DISTINCT NOME FROM T;  -> N021, N022, N023
///
///   Medicao completa em Test Delphi\Common_tests\test.pagination.firebird.sql.
/// </summary>
function TFluentSQLSelectFirebird.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FQualifiers.SerializePagination,
                             FQualifiers.SerializeDistinct,
                             FColumns.Serialize,
                             'FROM',
                             FTableNames.Serialize]);
end;

end.


