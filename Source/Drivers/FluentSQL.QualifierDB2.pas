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

unit FluentSQL.QualifierDB2;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersDB2 = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersDB2 }

/// <summary>
///   Cauda [OFFSET n ROWS] [FETCH FIRST m ROWS ONLY], a forma do DB2 LUW 11.1+.
///   Driver DESLIGADO em FluentSQL.inc e, alem disso, esta classe hoje nao chega
///   a ser instanciada: TFluentSQLSelectDB2 registra TFluentSQLSelectQualifiersOracle.
///   Fica aqui alinhada com os demais para nao voltar a ser a copia do ROWNUM da
///   Oracle - que no DB2 nem sequer existe como pseudocoluna.
/// </summary>
function TFluentSQLSelectQualifiersDB2.SerializePagination: String;
var
  LPag: TFluentSQLPagination;
begin
  Result := '';
  LPag := _Pagination('DB2');
  if LPag.HasSkip then
    Result := TUtils.Concat([Result, 'OFFSET', IntToStr(LPag.Skip), 'ROWS']);
  if LPag.HasFirst then
    Result := TUtils.Concat([Result, 'FETCH FIRST', IntToStr(LPag.First), 'ROWS ONLY']);
end;

end.



