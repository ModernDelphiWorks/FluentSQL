{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.FunctionsMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctionsMongoDB = class(TFluentSQLFunctionAbstract)
  public
    constructor Create;
  end;

implementation

constructor TFluentSQLFunctionsMongoDB.Create;
begin
  inherited;
end;

end.
