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

function TFluentSQLSelectOracle.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FColumns.Serialize,
                             FQualifiers.SerializeDistinct,
                             'FROM',
                             FTableNames.Serialize]);
end;

end.



