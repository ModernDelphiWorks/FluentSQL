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

// FluentSQL.Register saiu daqui junto com a reentrancia de Merge: era o unico
// uso que restava nesta unit. O despacho por dialeto e feito por quem chama
// (TFluentSQLMerge.Serialize), nao pela implementacao base.

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

/// <summary>
///   Implementacao BASE de MERGE: nao emite nada, levanta.
///
///   Este metodo e o fim da linha, nao um despachante. Quem despacha e
///   TFluentSQLMerge.Serialize (FluentSQL.Merge.pas:292), que ja resolveu o
///   dialeto via Register antes de chamar aqui. A versao anterior repetia esse
///   mesmo LReg.Serialize(ADef.GetDialect).Merge(ADef) - o que, para todo dialeto
///   que NAO sobrescreve Merge, reentrava neste proprio metodo indefinidamente e
///   terminava em EStackOverflow. Medido em e9ed0b9: Firebird, MySQL, SQLite,
///   Oracle e PostgreSQL estouravam a pilha ao serializar qualquer MERGE.
///
///   Hoje so FluentSQL.SerializeMSSQL.pas sobrescreve Merge. Os demais chegam aqui
///   e recebem erro nomeado e tratavel, em vez de crash.
/// </summary>
function TFluentSQLSerialize.Merge(const ADef: IFluentSQLMergeDef): string;
begin
  raise EFluentSQLStatementNotSupported.Create('MERGE', DriverName(ADef.GetDialect));
end;

function TFluentSQLSerialize.QuotedName(const AName: string): string;
begin
  Result := AName;
end;

end.



