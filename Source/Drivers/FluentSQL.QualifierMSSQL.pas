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

unit FluentSQL.QualifierMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersMSSQL = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersMSSQL }

function TFluentSQLSelectQualifiersMSSQL.SerializePagination: String;
var
  LFor: Integer;
  LFirst: Integer;
  LSkip: Integer;
  LHasFirst: Boolean;
  LHasSkip: Boolean;
begin
  // LFirst/LSkip nasciam sem valor: pedir so First(n) ou so Skip(n) emitia o
  // lixo que estivesse na pilha como limite de linha (o compilador ja avisava,
  // W1036). Cada limite agora so entra no SQL se tiver sido pedido, que e a
  // mesma regra do TFluentSQLSelectQualifiersOracle.
  LFirst := 0;
  LSkip := 0;
  LHasFirst := False;
  LHasSkip := False;
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    case FQualifiers[LFor].Qualifier of
      sqFirst:
        begin
          LFirst := FQualifiers[LFor].Value;
          LHasFirst := True;
        end;
      sqSkip:
        begin
          LSkip := FQualifiers[LFor].Value;
          LHasSkip := True;
        end;
    else
      raise Exception.Create('TFluentSQLSelectQualifiersMSSQL.SerializePagination: Unknown qualifier');
    end;
  end;
  if LHasFirst and LHasSkip then
    Result := TUtils.Concat([TUtils.Concat(['ROWNUMBER >', IntToStr(LSkip)]),
                             'AND',
                             TUtils.Concat(['ROWNUMBER <=', IntToStr(LFirst + LSkip)])])
  else if LHasFirst then
    Result := TUtils.Concat(['ROWNUMBER <=', IntToStr(LFirst)])
  else if LHasSkip then
    Result := TUtils.Concat(['ROWNUMBER >', IntToStr(LSkip)]);
end;

end.




