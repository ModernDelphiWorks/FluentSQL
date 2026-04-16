{
  ------------------------------------------------------------------------------
  FluentSQL
  MongoDB DDL (Collection Lifecycle) serialization driver.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize.MongoDB;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerializerMongoDB = class(TFluentDDLSerializeAbstract)
  protected
    function MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string; override;
    function GetDialect: TFluentSQLDriver; override;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
  end;

implementation

{ TFluentDDLSerializerMongoDB }

function TFluentDDLSerializerMongoDB.GetDialect: TFluentSQLDriver;
begin
  Result := dbnMongoDB;
end;

function TFluentDDLSerializerMongoDB.MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer): string;
begin
  { MongoDB is schema-less by default. Column mapping is out of scope for ESP-063. }
  Result := '';
end;

function TFluentDDLSerializerMongoDB.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: collection name is required');

  Result := '{"create":"' + ADef.TableName + '"}';
end;

function TFluentDDLSerializerMongoDB.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: collection name is required');

  Result := '{"drop":"' + ADef.TableName + '"}';
end;

initialization

end.
