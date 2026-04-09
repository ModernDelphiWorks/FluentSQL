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

unit FluentSQL.Delete;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Name,
  FluentSQL.Section,
  FluentSQL.Interfaces;

type
  TFluentSQLDelete = class(TFluentSQLSection, IFluentSQLDelete)
  strict private
    FTableNames: IFluentSQLNames;
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function TableNames: IFluentSQLNames;
    function Serialize: String;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLDelete }

procedure TFluentSQLDelete.Clear;
begin
  FTableNames.Clear;
end;

constructor TFluentSQLDelete.Create;
begin
  inherited Create('Delete');
  FTableNames := TFluentSQLNames.Create;
end;

function TFluentSQLDelete.IsEmpty: Boolean;
begin
  Result := FTableNames.IsEmpty;
end;

function TFluentSQLDelete.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['DELETE FROM', FTableNames.Serialize]);
end;

function TFluentSQLDelete.TableNames: IFluentSQLNames;
begin
  Result := FTableNames;
end;

end.







