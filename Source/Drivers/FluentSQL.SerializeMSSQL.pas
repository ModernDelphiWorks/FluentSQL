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
    ///   O ORDER BY que o &lt;offset_fetch&gt; do T-SQL EXIGE, quando o usuario nao
    ///   pediu nenhum. Devolve '' quando o usuario pediu - nesse caso o ORDER BY
    ///   dele ja esta no fim do corpo montado por ComposeSqlCore, que e
    ///   exatamente a posicao de que o OFFSET/FETCH precisa.
    ///
    ///   Que a clausula seja obrigatoria e MEDIDO, nao deduzido:
    ///     SELECT ID FROM T OFFSET 20 ROWS FETCH NEXT 3 ROWS ONLY;
    ///     -> Msg 102, Incorrect syntax near '20'.  (caso L do .sql)
    ///
    ///   O preenchimento NAO e um so, porque nao existe um que sirva sempre:
    ///
    ///   - (SELECT NULL) e o preferido. Nao acrescenta operador Sort ao plano -
    ///     o plano medido e Top(OFFSET/TOP) sobre Compute Scalar(NULL) sobre o
    ///     scan, sem Sort. Nao conserta determinismo nenhum, e nao deve ser lido
    ///     como se consertasse: e preenchimento gramatical.
    ///
    ///   - Com DISTINCT ou com UNION ele NAO e aceito, e a recusa e do motor:
    ///       SELECT DISTINCT NOME FROM T ORDER BY (SELECT NULL) OFFSET ...
    ///         -> Msg 145, ORDER BY items must appear in the select list if
    ///            SELECT DISTINCT is specified.
    ///       SELECT * FROM T UNION SELECT * FROM U ORDER BY (SELECT NULL) OFFSET ...
    ///         -> Msg 104, ORDER BY items must appear in the select list if the
    ///            statement contains a UNION, INTERSECT or EXCEPT operator.
    ///     Nos dois casos a regra e a mesma: sob DISTINCT/UNION o item do ORDER
    ///     BY tem que estar na lista de selecao. O unico item que SEMPRE esta e
    ///     o ordinal, e ORDER BY 1 foi medido valido nos cinco casos (simples,
    ///     DISTINCT, DISTINCT *, GROUP BY, CTE e UNION).
    ///
    ///     ORDER BY 1 CUSTA um operador Sort, e por isso nao vira o preenchimento
    ///     universal: ele so entra onde (SELECT NULL) e recusado. E tambem impoe
    ///     uma ordenacao pela primeira coluna que o usuario nao pediu - o que sob
    ///     DISTINCT/UNION e o preco de a consulta existir, ja que a alternativa e
    ///     nao emitir paginacao nenhuma.
    ///
    ///   Todas as medicoes, com o docker run e a saida bruta:
    ///   Test Delphi\Common_tests\test.pagination.mssql.sql - Msg 102 no caso L,
    ///   Msg 145 no E, Msg 104 no G, e os dois planos lado a lado no caso S.
    ///   NAO confundir com test.pagination.filter.mssql.sql, que e o oraculo da
    ///   T9 e mede outra coisa (a sobrevivencia do predicado); la nao ha caso L,
    ///   nem E, nem G.
    /// </summary>
    function PaginationOrderBy(const AAST: IFluentSQLAST): String;
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
    function Merge(const ADef: IFluentSQLMergeDef): string; override;
    function QuotedName(const AName: string): string; override;
  end;

implementation

{ TFluentSQLSerializer }

function TFluentSQLSerializerMSSQL.PaginationOrderBy(const AAST: IFluentSQLAST): String;
begin
  if AAST.OrderBy.Serialize <> '' then
    Exit('');
  if (AAST.Select.Qualifiers.SerializeDistinct <> '') or (AAST.UnionType <> '') then
    Result := 'ORDER BY 1'
  else
    Result := 'ORDER BY (SELECT NULL)';
end;

/// <summary>
///   Corpo montado por ComposeSqlCore + cauda de paginacao.
///
///   Este metodo montava o corpo SOZINHO, repetindo a lista de secoes do nucleo
///   e por isso NUNCA passando por ComposeSqlCore. Duas consequencias, ambas
///   silenciosas: consulta com Union perdia o UNION e o ramo inteiro, e consulta
///   com WithAlias perdia a CTE - o SQL saia valido e incompleto, sem erro.
///   Delegar a ComposeSqlCore devolve as duas de graca.
///
///   A paginacao deixou de ser predicado (ROWNUMBER) e virou cauda, entao ela e
///   concatenada DEPOIS de tudo - inclusive depois do UNION e do SELECT externo
///   da CTE, que e onde o OFFSET/FETCH pertence.
///
///   O que sumiu junto:
///     - a injecao de "ROW_NUMBER() OVER(...) AS ROWNUMBER" em
///       AAST.Select.Columns. Era a unica escrita no AST feita durante a
///       serializacao, e era ela que fazia AsString nao ser idempotente: duas
///       chamadas na mesma IFluentSQL acumulavam duas colunas ROWNUMBER.
///     - o encadeamento WHERE/AND, que so existia para pendurar o predicado da
///       paginacao no filtro do usuario.
/// </summary>
function TFluentSQLSerializerMSSQL.AsString(const AAST: IFluentSQLAST): String;
var
  LPagination: String;
begin
  Result := ComposeSqlCore(AAST);

  // O MERGE nao e repetido aqui: ComposeSqlCore ja concatena AAST.Merge.Serialize,
  // que resolve para este mesmo TFluentSQLSerializerMSSQL.Merge via o Register.
  LPagination := AAST.Select.Qualifiers.SerializePagination;
  if LPagination <> '' then
    Result := TUtils.Concat([Result, PaginationOrderBy(AAST), LPagination]);

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




