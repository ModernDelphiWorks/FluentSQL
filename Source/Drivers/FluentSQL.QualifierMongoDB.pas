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

unit FluentSQL.QualifierMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersMongoDB = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

{ TFluentSQLSelectQualifiersMongoDB }

/// <summary>
///   Vazio DE PROPOSITO, e este comentario existe para que ninguem "conserte"
///   isto de novo.
///
///   O MongoDB nao tem cauda textual de paginacao: nao existe um sufixo para
///   concatenar num SELECT. Os limites viram campos do documento de comando, e
///   quem os emite e FluentSQL.SerializeMongoDB.pas, lendo os mesmos
///   AAST.Select.Qualifiers em duas formas:
///
///     - comando "find":     "limit": m, "skip": n
///     - pipeline "aggregate": {"$skip": n} ANTES de {"$limit": m}
///
///   A ordem $skip -> $limit no pipeline nao e estilo: e o que permite ao
///   otimizador coalescer $sort/$skip/$limit num unico estagio.
///
///   O corpo anterior era o laco do Firebird comentado, com tres variaveis
///   declaradas e nunca usadas (H2164 em toda compilacao) e uma mensagem de erro
///   citando o driver errado. Parecia paginacao esquecida; nao era.
/// </summary>
function TFluentSQLSelectQualifiersMongoDB.SerializePagination: String;
begin
  Result := '';
end;

end.



