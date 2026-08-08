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

unit FluentSQL.Select.MSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Select;

type
  TFluentSQLSelectMSSQL = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.QualifierMSSQL;

{ TFluentSQLSelectMSSQL }

constructor TFluentSQLSelectMSSQL.Create;
begin
  inherited Create;
  FQualifiers := TFluentSQLSelectQualifiersMSSQL.Create;
end;

/// <summary>
///   SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;. Sem embrulho e sem paginacao.
///
///   Duas coisas sairam daqui, as duas por causa da migracao para OFFSET/FETCH:
///
///   1. O embrulho "SELECT * FROM (%s) AS %s", que existia so para dar escopo ao
///      predicado sobre a coluna ROWNUMBER. Sem ROW_NUMBER() nao ha coluna a
///      filtrar, e sem filtro nao ha subconsulta. O embrulho tambem usava
///      FTableNames[0].Name como alias, o que dava alias repetido em consulta com
///      join e nome de alias invalido quando a origem era uma subconsulta.
///
///   2. O DISTINCT, que vinha DEPOIS da lista de colunas: "SELECT NOME DISTINCT
///      FROM T". Isso nao dependia de paginacao nenhuma - Select.Distinct sozinho
///      ja emitia essa forma, que o SQL Server recusa. O DISTINCT antecede a lista
///      de colunas em T-SQL, como em ANSI.
///
///   UMA coisa VOLTOU para ca, e so uma: o "TOP 0" de First(0). Ele nao e
///   embrulho nem subconsulta - e uma palavra na lista de selecao -, entao nao
///   traz de volta o acoplamento que fazia UNION e CTE sumirem. Vai DEPOIS do
///   DISTINCT, porque a ordem inversa e recusada:
///
///     SELECT DISTINCT TOP 0 NOME FROM T   -> aceito, 0 linhas
///     SELECT TOP 0 DISTINCT NOME FROM T   -> Msg 156, Incorrect syntax near
///                                            the keyword 'DISTINCT'
///
///   Nao ha cauda OFFSET/FETCH junto: o FETCH nao aceita zero (Msg 10744) e o TOP
///   nao coexiste com OFFSET (Msg 10741). Descartar o Skip(n) do usuario aqui e
///   CORRETO - pular n linhas de um conjunto vazio da o mesmo conjunto vazio -, e
///   de quebra dispensa a clausula ORDER BY de preenchimento, que so existia para
///   hospedar o OFFSET/FETCH.
///
///   Medido em test.pagination.mssql.sql, parte Z: o TOP 0 NAO LE a tabela,
///   enquanto a forma com OFFSET a varre inteira. O CONTRASTE e a afirmacao - o
///   numero absoluto de leituras logicas varia com a largura da linha e o
///   tamanho da massa, entao nao e citado aqui.
/// </summary>
function TFluentSQLSelectMSSQL.Serialize: String;
var
  LTop: String;
begin
  if IsEmpty then
    Exit('');
  LTop := '';
  if FQualifiers.RequestsZeroRows then
    LTop := 'TOP 0';
  Result := TUtils.Concat(['SELECT',
                           FQualifiers.SerializeDistinct,
                           LTop,
                           FColumns.Serialize,
                           'FROM',
                           FTableNames.Serialize]);
end;

end.




