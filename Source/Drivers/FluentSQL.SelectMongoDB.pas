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
  FluentSQL.QualifierMongoDB,
  FluentSQL.SerializeMongoDB;

{ TFluentSQLSelectMongoDB }

constructor TFluentSQLSelectMongoDB.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersMongodb.Create;
end;

function TFluentSQLSelectMongoDB.Serialize: String;
begin
  Result := FluentMongoSelectSerializeFragment(Self);
end;

end.




