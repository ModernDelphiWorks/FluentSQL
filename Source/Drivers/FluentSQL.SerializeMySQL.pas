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

unit FluentSQL.SerializeMySQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.Serialize;

type
  TFluentSQLSerializerMySQL = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerializer }

function TFluentSQLSerializerMySQL.AsString(const AAST: IFluentSQLAST): String;
var
  LIdx: Integer;
  LTotal: Integer;
begin
  Result := TUtils.Concat([ComposeSqlCore(AAST), AAST.Select.Qualifiers.SerializePagination]);

  if Assigned(AAST) and Assigned(AAST.Params) then
  begin
    LTotal := AAST.Params.Count;
    if (AAST.UnionType <> '') and Assigned(AAST.UnionQuery) then
      LTotal := LTotal + AAST.UnionQuery.Params.Count;
    for LIdx := LTotal downto 1 do
      Result := StringReplace(Result, ':p' + IntToStr(LIdx), '?', [rfReplaceAll]);
  end;

  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.




