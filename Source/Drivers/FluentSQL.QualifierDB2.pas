{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
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

function TFluentSQLSelectQualifiersDB2.SerializePagination: String;
var
  LFor: Integer;
  LFirst: String;
  LSkip: String;
begin
  LFirst := '';
  LSkip := '';
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    case FQualifiers[LFor].Qualifier of
      sqFirst: LFirst := TUtils.Concat(['WHERE ROWNUM <=', IntToStr(FQualifiers[LFor].Value)]);
      sqSkip:  LSkip  := TUtils.Concat(['AND ROWINI >', IntToStr(FQualifiers[LFor].Value)]);
    else
      raise Exception.Create('TFluentSQLSelectQualifiersOracle.SerializeSelectQualifiers: Unknown qualifier');
    end;
  end;
  if (LFirst <> '') or (LSkip <> '') then
  begin
    Result := 'SELECT * FROM (SELECT T.*, ROWNUM AS ROWINI FROM (%s) T)';
    Result := TUtils.Concat([Result, LFirst, LSkip]);
  end;
end;

end.



