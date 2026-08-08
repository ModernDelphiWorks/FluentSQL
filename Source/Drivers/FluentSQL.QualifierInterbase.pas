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

unit FluentSQL.QualifierInterbase;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersinterbase = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersinterbase }

/// <summary>
///   Prefixo FIRST/SKIP, mesma gramatica do Firebird de que o Interbase descende.
///   Driver DESLIGADO em FluentSQL.inc; acompanha a forma canonica do Firebird
///   para nao divergir em silencio quando alguem o religar.
/// </summary>
function TFluentSQLSelectQualifiersinterbase.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('Interbase');
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FIRST', IntToStr(LPag.First)]);
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'SKIP', IntToStr(LPag.Skip)]);
end;

end.



