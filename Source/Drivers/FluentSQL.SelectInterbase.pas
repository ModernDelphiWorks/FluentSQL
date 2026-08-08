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

unit FluentSQL.SelectInterbase;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Select;

type
  TFluentSQLSelectInterbase = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation


uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.QualifierInterbase;

{ TFluentSQLSelectInterbase }

constructor TFluentSQLSelectInterbase.Create;
begin
  inherited;
  FQualifiers := TFluentSQLSelectQualifiersInterbase.Create;
end;

/// <summary>
///   SELECT [FIRST m] [SKIP n] [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;, a mesma
///   ordem gramatical do Firebird de que o Interbase descende. Driver DESLIGADO
///   em FluentSQL.inc; acompanha o Firebird para nao ficar com a ordem que
///   aquele motor recusa com -104.
/// </summary>
function TFluentSQLSelectInterbase.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FQualifiers.SerializePagination,
                             FQualifiers.SerializeDistinct,
                             FColumns.Serialize,
                             'FROM',
                             FTableNames.Serialize]);
end;

end.



