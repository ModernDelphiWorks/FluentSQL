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
  strict private
    /// <summary>
    ///   Janela do ROW_NUMBER() que numera as linhas da paginacao.
    ///
    ///   Quando o usuario pediu um ORDER BY, a janela TEM que usar a ordenacao
    ///   dele: e a ordenacao do usuario que define o que e "pagina 2". Numerar
    ///   por outra coisa e depois ordenar o resultado devolve a pagina errada -
    ///   SQL valido, dado errado, sem erro nenhum. Este e o unico ponto deste
    ///   metodo que muda o RESULTADO da consulta.
    ///
    ///   Sem ORDER BY do usuario sai ORDER BY (SELECT NULL). Isso NAO conserta
    ///   determinismo, e nao deve ser lido como se consertasse. E preenchimento
    ///   exigido pela GRAMATICA: no OVER o order_by_clause "is required" e a
    ///   clausula offset_fetch so existe como sub-clausula do ORDER BY - nao ha
    ///   como emitir nada. (SELECT NULL) e CURRENT_TIMESTAMP, a forma anterior,
    ///   empatam TODAS as linhas igualmente e produzem PLANO IDENTICO, sem
    ///   operador Sort; entre os dois a escolha e de legibilidade, porque
    ///   CURRENT_TIMESTAMP sugere uma ordenacao que nao existe. NEWID() foi
    ///   descartado por ser avaliado por linha e custar um Sort sem comprar
    ///   unicidade em troca.
    ///
    ///   O que da paginacao estavel entre execucoes e ordenar por CHAVE UNICA -
    ///   a doc da Microsoft condiciona a isso, tanto em ROW_NUMBER quanto em
    ///   OFFSET/FETCH. O FluentSQL NAO impoe unicidade, por decisao de projeto,
    ///   e tambem nao exige OrderBy para paginar: 6 dos 7 dialetos aceitam
    ///   paginar sem ordenacao, e exigir seria inventar restricao que os bancos
    ///   nao tem. Paginar sem ordenar devolve subconjunto arbitrario, o que e
    ///   semantica do SQL e nao defeito deste driver.
    ///
    ///   Os quatro planos medidos lado a lado, com as URLs da documentacao:
    ///   Test Delphi\Common_tests\test.pagination.filter.mssql.sql, caso P.
    /// </summary>
    function PaginationWindow(const AAST: IFluentSQLAST): String;
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
    function Merge(const ADef: IFluentSQLMergeDef): string; override;
    function QuotedName(const AName: string): string; override;
  end;

implementation

{ TFluentSQLSerializer }

function TFluentSQLSerializerMSSQL.PaginationWindow(const AAST: IFluentSQLAST): String;
var
  LOrderBy: String;
begin
  LOrderBy := AAST.OrderBy.Serialize;
  if LOrderBy = '' then
    LOrderBy := 'ORDER BY (SELECT NULL)';
  Result := 'ROW_NUMBER() OVER(' + LOrderBy + ') AS ROWNUMBER';
end;

function TFluentSQLSerializerMSSQL.AsString(const AAST: IFluentSQLAST): String;
var
  LWhere: String;
begin
  if AAST.Select.Qualifiers.ExecutingPagination then
    AAST.Select.Columns.Add.Name := PaginationWindow(AAST);
  LWhere := AAST.Where.Serialize;
  // Gera sintaxe para caso exista comando de paginação.
  if AAST.Select.Qualifiers.ExecutingPagination then
  begin
    if LWhere = '' then
      LWhere := TUtils.Concat(['WHERE', '(' + AAST.Select.Qualifiers.SerializePagination + ')'])
    else
      // O predicado do usuario JA esta em LWhere, com a palavra WHERE incluida.
      // Encadear a partir de LWhere (e nao de Result, que aqui ainda e '') e o
      // que preserva o filtro e mantem o WHERE na frente do AND.
      LWhere := TUtils.Concat([LWhere, 'AND', '(' + AAST.Select.Qualifiers.SerializePagination + ')']);
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
  I, J: Integer;
  LClause: IFluentSQLMergeMatchClauseDef;
  LPairs: IFluentSQLNameValuePairs;
  LCols, LVals: string;
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
    Result := Result + 'MATCHED';

    if LClause.GetCondition <> '' then
      Result := Result + ' AND ' + LClause.GetCondition;

    Result := Result + ' THEN ';

    case LClause.GetActionType of
      matUpdate:
      begin
        Result := Result + 'UPDATE SET ';
        LPairs := LClause.GetValues;
        for J := 0 to LPairs.Count - 1 do
        begin
          if J > 0 then Result := Result + ', ';
          Result := Result + QuotedName(LPairs[J].Name) + ' = ' + LPairs[J].Value;
        end;
      end;
      matDelete: Result := Result + 'DELETE';
      matInsert:
      begin
        Result := Result + 'INSERT';
        LPairs := LClause.GetValues;
        if LPairs.Count > 0 then
        begin
          LCols := '';
          LVals := '';
          for J := 0 to LPairs.Count - 1 do
          begin
            if J > 0 then
            begin
              LCols := LCols + ', ';
              LVals := LVals + ', ';
            end;
            LCols := LCols + QuotedName(LPairs[J].Name);
            LVals := LVals + LPairs[J].Value;
          end;
          Result := Result + ' (' + LCols + ') VALUES (' + LVals + ')';
        end;
      end;
    end;
  end;

  if (Result <> '') and (not Result.EndsWith(';')) then
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




