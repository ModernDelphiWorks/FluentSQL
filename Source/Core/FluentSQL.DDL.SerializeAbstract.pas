{
  ------------------------------------------------------------------------------
  FluentSQL
  Abstract base class for DDL serialization (ESP-037).
  Follows the project's "Helpful Abstract" pattern for better Developer Experience.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.DDL.SerializeAbstract;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,
  FluentSQL.Interfaces;

const
  ABSTRACT_METHOD_ERROR = 'Abstract method "%s" called in %s. ' +
                          'Derived classes must override this method to provide a concrete implementation.';

type
  TFluentDDLSerializeAbstract = class(TInterfacedObject, IFluentDDLSerialize)
  protected
    function MapConstraints(const ACol: IFluentDDLColumn): string; virtual;
    function MapLogicalType(const ACol: IFluentDDLColumn): string; overload; virtual;
    function MapLogicalType(const AType: TDDLLogicalType; const AArg: Integer = 0): string; overload; virtual; abstract;
    function GetDialect: TFluentSQLDriver; virtual; abstract;
    function Quote(const AName: string): string; virtual;
    function GetLiteralValue(const AValue: string; const ALogicalType: TDDLLogicalType = dltVarChar): string; virtual;
    function GetComputedDefinition(const ACol: IFluentDDLColumn): string; virtual;
    function GetColumnDefinition(const ACol: IFluentDDLColumn): string;
    function GetColumnDefinitionList(const ADef: IFluentDDLTableDef): string;
    function GetColumnNameList(const ADef: IFluentDDLCreateIndexDef): string;
  public
    function CreateTable(const ADef: IFluentDDLTableDef): string; virtual;
    function DropTable(const ADef: IFluentDDLDropTableDef): string; virtual;
    function AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string; virtual;
    function AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string; virtual;
    function AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string; virtual;
    function AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string; virtual;
    function AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string; virtual;
    function CreateIndex(const ADef: IFluentDDLCreateIndexDef): string; virtual;
    function DropIndex(const ADef: IFluentDDLDropIndexDef): string; virtual;
    function TruncateTable(const ADef: IFluentDDLTruncateTableDef): string; virtual;
  end;

implementation

uses
  DateUtils,
  FluentSQL.Utils;

{ TFluentDDLSerializeAbstract }

function TFluentDDLSerializeAbstract.MapConstraints(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
  if ACol.DefaultValue <> '' then
    Result := Result + ' DEFAULT ' + GetLiteralValue(ACol.DefaultValue, ACol.LogicalType);
  if ACol.NotNull then
    Result := Result + ' NOT NULL';
  if ACol.IsPrimaryKey then
    Result := Result + ' PRIMARY KEY';
  if ACol.IsUnique then
    Result := Result + ' UNIQUE';
  if ACol.CheckCondition <> '' then
    Result := Result + ' CHECK (' + ACol.CheckCondition + ')';
  if ACol.ReferenceTable <> '' then
  begin
    Result := Result + ' REFERENCES ' + Quote(ACol.ReferenceTable);
    if ACol.ReferenceColumn <> '' then
      Result := Result + '(' + Quote(ACol.ReferenceColumn) + ')';
  end;
end;

function TFluentDDLSerializeAbstract.MapLogicalType(const ACol: IFluentDDLColumn): string;
begin
  Result := MapLogicalType(ACol.LogicalType, ACol.TypeArg);
end;

function TFluentDDLSerializeAbstract.Quote(const AName: string): string;
begin
  Result := AName;
end;

function TFluentDDLSerializeAbstract.GetLiteralValue(const AValue: string;
  const ALogicalType: TDDLLogicalType): string;
var
  LDate: TDateTime;
  LGUID: TGUID;
begin
  case ALogicalType of
    dltBoolean:
      if (SameText(AValue, 'True') or SameText(AValue, 'False') or
          SameText(AValue, 'T') or SameText(AValue, 'F') or SameText(AValue, '1') or SameText(AValue, '0')) then
      begin
        Exit(TUtils.BooleanToSQLFormat(GetDialect, SameText(AValue, 'True') or SameText(AValue, 'T') or SameText(AValue, '1')));
      end;

    dltDate:
      if TryStrToDate(AValue, LDate) then
        Exit(TUtils.DateToSQLFormat(GetDialect, LDate))
      else if (Length(AValue) = 10) and (AValue[5] = '-') and (AValue[8] = '-') then
      begin
        try
          LDate := EncodeDate(StrToInt(Copy(AValue, 1, 4)), StrToInt(Copy(AValue, 6, 2)), StrToInt(Copy(AValue, 9, 2)));
          Exit(TUtils.DateToSQLFormat(GetDialect, LDate));
        except
          // Fallback
        end;
      end;

    dltDateTime:
      if TryStrToDateTime(AValue, LDate) then
        Exit(TUtils.DateTimeToSQLFormat(GetDialect, LDate))
      else if (Length(AValue) >= 19) and (AValue[5] = '-') and (AValue[8] = '-') and (AValue[11] = ' ') then
      begin
        try
          LDate := EncodeDateTime(
            StrToInt(Copy(AValue, 1, 4)), StrToInt(Copy(AValue, 6, 2)), StrToInt(Copy(AValue, 9, 2)),
            StrToInt(Copy(AValue, 12, 2)), StrToInt(Copy(AValue, 15, 2)), StrToInt(Copy(AValue, 18, 2)), 0);
          Exit(TUtils.DateTimeToSQLFormat(GetDialect, LDate));
        except
          // Fallback
        end;
      end;

    dltGuid:
      try
        LGUID := StringToGUID(AValue);
        Exit(TUtils.GuidStrToSQLFormat(GetDialect, LGUID));
      except
        // Ignorar erro de parsing e retornar o valor original
      end;
  end;

  Result := AValue;
end;

function TFluentDDLSerializeAbstract.GetComputedDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := '';
end;

function TFluentDDLSerializeAbstract.GetColumnDefinition(const ACol: IFluentDDLColumn): string;
begin
  Result := Quote(ACol.Name) + ' ' + MapLogicalType(ACol) + GetComputedDefinition(ACol) + MapConstraints(ACol);
end;

function TFluentDDLSerializeAbstract.GetColumnDefinitionList(const ADef: IFluentDDLTableDef): string;
var
  LI: Integer;
begin
  Result := '';
  for LI := 0 to ADef.GetColumnCount - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + GetColumnDefinition(ADef.GetColumn(LI));
  end;
end;

function TFluentDDLSerializeAbstract.GetColumnNameList(const ADef: IFluentDDLCreateIndexDef): string;
var
  LI: Integer;
begin
  Result := '';
  for LI := 0 to ADef.GetColumnCount - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Quote(ADef.GetColumnName(LI));
  end;
end;

function TFluentDDLSerializeAbstract.CreateTable(const ADef: IFluentDDLTableDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CreateTable', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.DropTable(const ADef: IFluentDDLDropTableDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['DropTable', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.AlterTableAddColumn(const ADef: IFluentDDLAlterTableAddColumnDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['AlterTableAddColumn', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.AlterTableDropColumn(const ADef: IFluentDDLAlterTableDropColumnDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['AlterTableDropColumn', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.AlterTableRenameColumn(const ADef: IFluentDDLAlterTableRenameColumnDef): string;
begin
    raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['AlterTableRenameColumn', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.AlterTableAlterColumn(const ADef: IFluentDDLAlterTableAlterColumnDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['AlterTableAlterColumn', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.AlterTableRenameTable(const ADef: IFluentDDLAlterTableRenameTableDef): string;
begin
  if not Assigned(ADef) then
    Exit('');
  Result := 'ALTER TABLE ' + Quote(ADef.OldTableName) + ' RENAME TO ' + Quote(ADef.NewTableName);
end;

function TFluentDDLSerializeAbstract.CreateIndex(const ADef: IFluentDDLCreateIndexDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CreateIndex', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.DropIndex(const ADef: IFluentDDLDropIndexDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['DropIndex', Self.ClassName]);
end;

function TFluentDDLSerializeAbstract.TruncateTable(const ADef: IFluentDDLTruncateTableDef): string;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['TruncateTable', Self.ClassName]);
end;

end.
