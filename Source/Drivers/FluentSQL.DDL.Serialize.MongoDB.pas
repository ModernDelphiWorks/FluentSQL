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
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
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

function TFluentDDLSerializerMongoDB.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
var
  I: Integer;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: collection name is required for create index');

  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MongoDB: index name is required');

  if ADef.GetColumnCount = 0 then
    raise EArgumentException.Create('DDL MongoDB: at least one column is required for create index');

  Result := '{"createIndexes":"' + ADef.TableName + '","indexes":[';
  Result := Result + '{"key":{';

  for I := 0 to ADef.GetColumnCount - 1 do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + '"' + ADef.GetColumnName(I) + '":1';
  end;

  Result := Result + '},"name":"' + ADef.IndexName + '"';

  if ADef.GetIsUnique then
    Result := Result + ',"unique":true';

  Result := Result + '}]}';
end;

function TFluentDDLSerializerMongoDB.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: collection name is required for drop index');

  if Trim(ADef.IndexName) = '' then
    raise EArgumentException.Create('DDL MongoDB: index name is required for drop index');

  Result := '{"dropIndexes":"' + ADef.TableName + '","index":"' + ADef.IndexName + '"}';
end;

function TFluentDDLSerializerMongoDB.AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.OldTableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: old collection name is required');

  if Trim(ADef.NewTableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: new collection name is required');

  Result := '{"renameCollection":"' + ADef.OldTableName + '","to":"' + ADef.NewTableName + '"}';
end;

function TFluentDDLSerializerMongoDB.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');

  if Trim(ADef.TableName) = '' then
    raise EArgumentException.Create('DDL MongoDB: collection name is required');

  Result := '{"delete":"' + ADef.TableName + '","deletes":[{"q":{},"limit":0}]}';
end;

initialization

end.
