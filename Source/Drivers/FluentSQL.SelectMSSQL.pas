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

unit FluentSQL.SelectMSSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Select;

type
  TFluentSQLSelectMSSQL = class(TFluentSQLSelect)
  public
    constructor Create; override;
    function Serialize: String; override;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.Register,
  FluentSQL.QualifierMSSQL;

{ TFluentSQLSelectMSSQL }

constructor TFluentSQLSelectMSSQL.Create;
begin
  inherited Create;
  FQualifiers := TFluentSQLSelectQualifiersMSSQL.Create;
end;

function TFluentSQLSelectMSSQL.Serialize: String;
var
  LFor: Integer;

  function DoSerialize: String;
  begin
    Result := TUtils.Concat(['SELECT',
                             FColumns.Serialize,
                             FQualifiers.SerializeDistinct,
                             'FROM',
                             FTableNames.Serialize]);
  end;

const
  cSELECT = 'SELECT * FROM (%s) AS %s';

begin
  if IsEmpty then
    Result := ''
  else
  begin
    if FQualifiers.ExecutingPagination then
    begin
      FColumns.Add.Name := 'ROW_NUMBER() OVER(ORDER BY CURRENT_TIMESTAMP) AS ROWNUMBER';
      Result := Format(cSELECT, [DoSerialize, FTableNames[0].Name]);
    end
    else
      Result := DoSerialize;
  end;
end;

end.




