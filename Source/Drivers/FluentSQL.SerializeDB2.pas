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

unit FluentSQL.SerializeDB2;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.Serialize;

type
  TFluentSQLSerializeDB2 = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

implementation

{ TFluentSQLSerialize }

/// <summary>
///   Corpo do nucleo + cauda de paginacao no fim. Driver DESLIGADO em
///   FluentSQL.inc; segue a Oracle porque TFluentSQLSelectDB2 registra o
///   qualificador da Oracle, e o template com Format deixou de existir la.
/// </summary>
function TFluentSQLSerializeDB2.AsString(const AAST: IFluentSQLAST): String;
begin
  Result := TUtils.Concat([ComposeSqlCore(AAST),
                           AAST.Select.Qualifiers.SerializePagination]);
  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.




