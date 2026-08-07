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

unit FluentSQL.Select.Oracle;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectOracle = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Interfaces,
  FluentSQL.Register,
  FluentSQL.QualifierOracle;

{ TFluentSQLSelectOracle }

constructor TFluentSQLSelectOracle.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersOracle.Create;
end;

/// <summary>
///   SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;. O DISTINCT vinha DEPOIS da
///   lista de colunas ("SELECT NOME DISTINCT FROM T"), forma que a Oracle recusa
///   com ORA-00923. Nao dependia de paginacao: Select.Distinct sozinho ja saia
///   assim - so nao se via porque SerializePagination levantava excecao antes.
/// </summary>
function TFluentSQLSelectOracle.Serialize: String;
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



