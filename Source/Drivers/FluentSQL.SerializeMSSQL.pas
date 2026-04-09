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

unit FluentSQL.SerializeMSSQL;

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
  TFluentSQLSerializerMSSQL = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerializer }

function TFluentSQLSerializerMSSQL.AsString(const AAST: IFluentSQLAST): String;
var
  LWhere: String;
begin
  LWhere := AAST.Where.Serialize;
  // Gera sintaxe para caso exista comando de paginação.
  if AAST.Select.Qualifiers.ExecutingPagination then
  begin
    if LWhere = '' then
      LWhere := TUtils.Concat(['WHERE', '(' + AAST.Select.Qualifiers.SerializePagination + ')'])
    else
      LWhere := TUtils.Concat([Result, 'AND', '(' + AAST.Select.Qualifiers.SerializePagination + ')']);
  end;
  Result := TUtils.Concat([AAST.Select.Serialize,
                           AAST.Delete.Serialize,
                           AAST.Insert.Serialize,
                           AAST.Update.Serialize,
                           AAST.Joins.Serialize,
                           LWhere,
                           AAST.GroupBy.Serialize,
                           AAST.Having.Serialize,
                           AAST.OrderBy.Serialize]);
  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.




