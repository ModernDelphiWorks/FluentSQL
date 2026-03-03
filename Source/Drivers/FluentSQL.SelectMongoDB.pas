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

unit FluentSQL.SelectMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectMongoDB = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation


uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.QualifierMongoDB;

{ TFluentSQLSelectMongoDB }

constructor TFluentSQLSelectMongoDB.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersMongodb.Create;
end;

function TFluentSQLSelectMongoDB.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
  begin
    Result := FTableNames.Serialize + '.find( {'
            + FColumns.Serialize + '} )';
    Result := LowerCase(Result);
  end;
//                             FQualifiers.SerializeDistinct,
//                             FQualifiers.SerializePagination,
end;

end.




