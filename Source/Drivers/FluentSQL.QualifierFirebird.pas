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

unit FluentSQL.QualifierFirebird;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersFirebird = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
 end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersFirebird }

/// <summary>
///   O Firebird e o unico dos sete que NAO migrou para OFFSET/FETCH, e a decisao
///   e deliberada: FIRST/SKIP funciona em toda versao - inclusive 2.5, onde
///   OFFSET/FETCH nao existe - e aceita EXPRESSAO, enquanto o OFFSET/FETCH do
///   Firebird so aceita literal ou parametro. Trocar seria perder alcance sem
///   ganhar nada.
///
///   Fragmento de PREFIXO, nao de cauda: a gramatica do Firebird e
///   SELECT [FIRST m] [SKIP n] [DISTINCT|ALL] &lt;colunas&gt; - FIRST/SKIP vem antes
///   do DISTINCT, nao depois. Quem monta nessa ordem e TFluentSQLSelectFirebird.
/// </summary>
function TFluentSQLSelectQualifiersFirebird.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('Firebird');
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FIRST', IntToStr(LPag.First)]);
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'SKIP', IntToStr(LPag.Skip)]);
end;

end.



