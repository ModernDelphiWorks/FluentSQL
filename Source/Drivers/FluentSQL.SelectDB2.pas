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

unit FluentSQL.SelectDB2;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectDB2 = class(TFluentSQLSelect)
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

{ TFluentSQLSelectDB2 }

constructor TFluentSQLSelectDB2.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersOracle.Create;
end;

/// <summary>
///   SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;. Mesma correcao de ordem do
///   Oracle e do MSSQL: o DISTINCT antecede a lista de colunas. Driver DESLIGADO
///   em FluentSQL.inc.
/// </summary>
function TFluentSQLSelectDB2.Serialize: String;
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



