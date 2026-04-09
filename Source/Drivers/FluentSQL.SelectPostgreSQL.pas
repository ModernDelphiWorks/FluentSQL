{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.SelectPostgreSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectPostgreSQL = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.QualifierPostgresql;

{ TFluentSQLSelectPostgreSQL }

constructor TFluentSQLSelectPostgreSQL.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersPostgreSQL.Create;
end;

function TFluentSQLSelectPostgreSQL.Serialize: String;
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



