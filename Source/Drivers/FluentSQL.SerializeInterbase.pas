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

unit FluentSQL.SerializeInterbase;

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
  TFluentSQLSerializerInterbase = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerializerInterbase }

function TFluentSQLSerializerInterbase.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := inherited AsString(AAST);
end;

end.




