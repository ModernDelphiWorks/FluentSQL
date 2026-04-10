{
  ------------------------------------------------------------------------------
  FluentSQL
  Fluent API for building and composing SQL queries in Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2026 Ecosystem - Innovative Tools for Delphi Development

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit FluentSQL.QualifierSQLite;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Qualifier;

type
  TFluentSQLSelectQualifiersSQLite = class(TFluentSQLSelectQualifiers)
  public
    function SerializePagination: String; override;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiersSQLite }

function TFluentSQLSelectQualifiersSQLite.SerializePagination: String;
var
  LFor: Integer;
  LFirst: String;
  LSkip: String;
begin
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    case FQualifiers[LFor].Qualifier of
      sqFirst: LFirst := TUtils.Concat(['LIMIT', IntToStr(FQualifiers[LFor].Value)]);
      sqSkip:  LSkip  := TUtils.Concat(['OFFSET', IntToStr(FQualifiers[LFor].Value)]);
      sqDistinct:
        Continue;
    else
      raise Exception.Create('TFluentSQLSelectQualifiersSQLite.SerializeSelectQualifiers: Unknown qualifier');
    end;
  end;
  Result := TUtils.Concat([Result, LFirst, LSkip]);
end;

end.



