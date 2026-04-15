{
  ------------------------------------------------------------------------------
  FluentSQL
  DDL Serialization Proxy (ESP-037).
  Delegates DDL generation to registered drivers via the Driver/Registry
  architecture. Public surface: TFluentDDLSerialize class only.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.Serialize;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.DDL.SerializeAbstract;

type
  TFluentDDLSerialize = class(TFluentDDLSerializeAbstract, IFluentDDLSerialize)
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; override;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; override;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; override;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; override;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; override;
    function AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string; override;
    function AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string; override;
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; override;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; override;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; override;
    function CreateView(const ADef: IFluentDDLCreateViewDef): string; override;
    function DropView(const ADef: IFluentDDLDropViewDef): string; override;
    function GetDialect: TFluentSQLDriver; override;
  end;

implementation

uses
  FluentSQL.Register;

{ TFluentDDLSerialize }

function TFluentDDLSerialize.CreateTable(const ADef: IFluentDDLTableDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).CreateTable(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.DropTable(const ADef: IFluentDDLDropTableDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).DropTable(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).AlterTableAddColumn(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).AlterTableDropColumn(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).AlterTableRenameColumn(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).AlterTableRenameTable(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).AlterTableAlterColumn(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).CreateIndex(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).DropIndex(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).TruncateTable(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.CreateView(const ADef: IFluentDDLCreateViewDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).CreateView(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.DropView(const ADef: IFluentDDLDropViewDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.DDLSerialize(ADef.Dialect).DropView(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentDDLSerialize.GetDialect: TFluentSQLDriver;
begin
  raise EAbstractError.Create('TFluentDDLSerialize is a proxy; it has no specific dialect. Use a concrete driver.');
end;

end.
