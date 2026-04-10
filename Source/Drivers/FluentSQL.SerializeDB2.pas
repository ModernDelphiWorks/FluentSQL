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

unit FluentSQL.SerializeDB2;

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
  TFluentSQLSerializeDB2 = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerialize }

function TFluentSQLSerializeDB2.AsString(const AAST: IFluentSQLAST): String;
var
  LSerializePagination: String;
begin
  Result := ComposeSqlCore(AAST);
  LSerializePagination := AAST.Select.Qualifiers.SerializePagination;
  if LSerializePagination <> '' then
    Result := Format(LSerializePagination, [Result]);
  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.




