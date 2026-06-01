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

function TFluentSQLSerializerSQLite.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := inherited AsString(AAST);
end;

end.






