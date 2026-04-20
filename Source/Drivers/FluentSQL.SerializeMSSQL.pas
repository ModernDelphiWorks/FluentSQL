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

unit FluentSQL.SerializeMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils, Classes,
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.Serialize;

type
  TFluentSQLSerializerMSSQL = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
    function Merge(const ADef: IFluentSQLMergeDef): string; override;
    function QuotedName(const AName: string): string; override;
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
  
  if Assigned(AAST.Merge) then
    Result := TUtils.Concat([Result, Merge(AAST.Merge)]);

  Result := Result + DialectOnlySqlSuffix(AAST);
end;

function TFluentSQLSerializerMSSQL.Merge(const ADef: IFluentSQLMergeDef): string;
var
  LClauses: TInterfaceList;
  I: Integer;
  LClause: IFluentSQLMergeMatchClauseDef;
begin
  if not Assigned(ADef) or (ADef.GetTargetTable = '') then
    Exit('');

  Result := 'MERGE INTO ' + QuotedName(ADef.GetTargetTable);
  if ADef.GetTargetAlias <> '' then
    Result := Result + ' AS ' + QuotedName(ADef.GetTargetAlias);

  Result := Result + ' USING ';
  if Assigned(ADef.GetSourceQuery) then
    Result := Result + '(' + ADef.GetSourceQuery.AsString + ')'
  else
    Result := Result + QuotedName(ADef.GetSourceTable);

  if ADef.GetSourceAlias <> '' then
    Result := Result + ' AS ' + QuotedName(ADef.GetSourceAlias);

  Result := Result + ' ON (' + ADef.GetOnCondition + ')';

  LClauses := ADef.GetMatchedClauses;
  for I := 0 to LClauses.Count - 1 do
  begin
    LClause := LClauses[I] as IFluentSQLMergeMatchClauseDef;
    Result := Result + ' WHEN ';
    if LClause.GetClauseType = mctNotMatched then
      Result := Result + 'NOT ';
    Result := Result + 'MATCHED THEN ';
    
    case LClause.GetActionType of
      matUpdate: Result := Result + 'UPDATE';
      matDelete: Result := Result + 'DELETE';
      matInsert: Result := Result + 'INSERT';
    end;
  end;

  if not Result.EndsWith(';') then
    Result := Result + ';';
end;

function TFluentSQLSerializerMSSQL.QuotedName(const AName: string): string;
begin
  if (AName = '*') or AName.Contains('[') or AName.Contains('.') then
    Result := AName
  else
    Result := '[' + AName + ']';
end;

end.




