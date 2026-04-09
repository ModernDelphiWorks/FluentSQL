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
begin
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    case FQualifiers[LFor].Qualifier of
      sqFirst: LFirst := FQualifiers[LFor].Value;
      sqSkip:  LSkip  := FQualifiers[LFor].Value;
    else
      raise Exception.Create('TFluentSQLSelectQualifiersMSSQL.SerializePagination: Unknown qualifier');
    end;
  end;
  Result := TUtils.Concat([Result,
                           TUtils.Concat(['ROWNUMBER >', IntToStr(LSkip)]),
                           'AND',
                           TUtils.Concat(['ROWNUMBER <=', IntToStr(LFirst + LSkip)])]);
end;

end.




