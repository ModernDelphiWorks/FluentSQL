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

unit FluentSQL.Serialize;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Utils;

type
  TFluentSQLSerialize = class(TInterfacedObject, IFluentSQLSerialize)
  public
    /// <summary>SQL body without ESP-016 dialect tail (WITH/UNION included).</summary>
    function ComposeSqlCore(const AAST: IFluentSQLAST): String;
    function AsString(const AAST: IFluentSQLAST): String; virtual;
    function Merge(const ADef: IFluentSQLMergeDef): string; virtual;
    function QuotedName(const AName: string): string; virtual;
  end;

/// <summary>Suffix emitted only for fragments whose dialect matches the query serialization dialect (ADR-016).</summary>
function DialectOnlySqlSuffix(const AAST: IFluentSQLAST): String;

implementation

uses
  FluentSQL.Register;

function UnionRemapBranchSQL(const ABranchSQL: string; APrimaryParamCount,
  ABranchParamCount: Integer): string;
var
  I: Integer;
  LOld, LNew: string;
begin
  Result := ABranchSQL;
  if ABranchParamCount <= 0 then
    Exit;
  for I := ABranchParamCount downto 1 do
  begin
    LOld := ':p' + IntToStr(I);
    LNew := ':p' + IntToStr(APrimaryParamCount + I);
    Result := StringReplace(Result, LOld, LNew, [rfReplaceAll]);
  end;
end;

function DialectOnlySqlSuffix(const AAST: IFluentSQLAST): String;
var
  LTarget: TFluentSQLDriver;
  I: Integer;
  LItem: TDialectOnlyFragment;
begin
  Result := '';
  if not Assigned(AAST) then
    Exit;
  LTarget := AAST.GetSerializationDialect;
  for I := 0 to AAST.DialectOnlyCount - 1 do
  begin
    LItem := AAST.GetDialectOnlyItem(I);
    if LItem.Dialect = LTarget then
      Result := Result + LItem.Sql;
  end;
end;

function TFluentSQLSerialize.ComposeSqlCore(const AAST: IFluentSQLAST): String;
var
  LBase: String;
  LUnion: String;
begin
  if not Assigned(AAST) then
    Exit('');

  LBase := TUtils.Concat([AAST.Select.Serialize,
                          AAST.Delete.Serialize,
                          AAST.Insert.Serialize,
                          AAST.Update.Serialize,
                          AAST.Joins.Serialize,
                          AAST.Where.Serialize,
                          AAST.GroupBy.Serialize,
                          AAST.Having.Serialize,
                          AAST.OrderBy.Serialize]);
  
  if Assigned(AAST.Merge) then
    LBase := TUtils.Concat([LBase, AAST.Merge.Serialize]);

  if AAST.WithAlias <> '' then
    Result := 'WITH ' + AAST.WithAlias + ' AS (' + LBase + ') SELECT * FROM ' + AAST.WithAlias
  else
    Result := LBase;

  if (AAST.UnionType <> '') and Assigned(AAST.UnionQuery) then
  begin
    LUnion := AAST.UnionQuery.AsString;
    LUnion := UnionRemapBranchSQL(LUnion, AAST.Params.Count, AAST.UnionQuery.Params.Count);
    Result := Result + ' ' + AAST.UnionType + ' ' + LUnion;
  end;
end;

function TFluentSQLSerialize.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := ComposeSqlCore(AAST) + DialectOnlySqlSuffix(AAST);
end;

function TFluentSQLSerialize.Merge(const ADef: IFluentSQLMergeDef): string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.Serialize(ADef.GetDialect).Merge(ADef);
  finally
    LReg.Free;
  end;
end;

function TFluentSQLSerialize.QuotedName(const AName: string): string;
begin
  Result := AName;
end;

end.



