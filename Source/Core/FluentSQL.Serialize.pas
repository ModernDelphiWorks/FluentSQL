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
    function RelationAliasKeyword: String; virtual;
    function DeleteClause(const ADelete: IFluentSQLDelete): String; virtual;
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

  // DeleteClause, e nao AAST.Delete.Serialize: no T-SQL o apelido muda a FORMA
  // da clausula, nao so a palavra que antecede o apelido. Chamada VIRTUAL - e
  // por isso que TFluentSQLSerializerMSSQL alcanca este ponto sem sobrescrever
  // ComposeSqlCore.
  LBase := TUtils.Concat([AAST.Select.Serialize,
                          DeleteClause(AAST.Delete),
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

/// <summary>
///   Forma PADRAO do apelido de relacao: "tabela AS ap".
///
///   Vale para MSSQL, MySQL, Firebird, SQLite, Interbase, DB2 e PostgreSQL - e
///   e o que esses seis ja emitiam antes desta tarefa, entao herdar esta base
///   nao muda uma virgula do SQL deles. Quem diverge sobrescreve; hoje so
///   FluentSQL.SerializeOracle.pas.
///
///   Nao se adotou "emitir sem AS em todos", ainda que os sete aceitem a forma
///   curta: trocar o texto de seis dialetos para consertar um e mais disruptivo
///   que trocar o do unico que esta errado.
///
///   MongoDB herda 'AS' e isso e inofensivo: o serializador de MQL le a
///   propriedade Alias direto (vira "as":"X" no $lookup e chave do $project) e
///   nunca chama TFluentSQLName.Serialize para a relacao.
/// </summary>
function TFluentSQLSerialize.RelationAliasKeyword: String;
begin
  Result := 'AS';
end;

/// <summary>
///   Forma PADRAO da clausula DELETE: o que TFluentSQLDelete.Serialize monta,
///   ou seja "DELETE FROM <relacao>" com o apelido - se houver - ja escrito por
///   TFluentSQLName.Serialize na palavra do dialeto.
///
///   Vale para MySQL, Firebird, SQLite, Interbase, DB2, PostgreSQL e Oracle, e
///   e byte-a-byte o texto que esses dialetos emitiam antes desta tarefa: quem
///   nao sobrescreve nao muda uma virgula. Medido com apelido, em motor real
///   (transcricao em Test Delphi\Common_tests\test.delete.alias.matrix.sql):
///
///     PostgreSQL 16.14  DELETE FROM A AS AP  -> executa
///     MySQL 8.4.11      DELETE FROM A AS AP  -> executa
///     Firebird 5.0.4    DELETE FROM A AS AP  -> executa
///     SQLite 3.53.4     DELETE FROM A AS AP  -> executa
///     DB2 12.1.5.0      DELETE FROM A AS AP  -> executa
///     Oracle 23.26.2    DELETE FROM A AP     -> executa (a palavra ja e ''
///                                               por RelationAliasKeyword)
///
///   O Interbase esta nesta base por HERANCA e nao por medicao: nao ha imagem
///   publica de InterBase e ele nao foi executado.
///
///   Nao se adotou "emitir a forma do T-SQL em todos": ela e a UNICA que os
///   outros seis recusam (medido - PostgreSQL, SQLite, Firebird e Oracle
///   devolvem erro de sintaxe para "DELETE AP FROM A AS AP").
/// </summary>
function TFluentSQLSerialize.DeleteClause(const ADelete: IFluentSQLDelete): String;
begin
  Result := ADelete.Serialize;
end;

end.



