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

function TFluentSQLSelectSQLite.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FQualifiers.SerializeDistinct,
                             FQualifiers.SerializePagination,
                             FColumns.Serialize,
                             'FROM',
                             FTableNames.Serialize]);
end;

end.



