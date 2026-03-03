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

unit FluentSQL.GroupBy;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Name,
  FluentSQL.Interfaces;

type
  TFluentSQLGroupBy = class(TFluentSQLSection, IFluentSQLGroupBy)
  strict private
    FColumns: IFluentSQLNames;
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Columns: IFluentSQLNames;
    function Serialize: String;
  end;

implementation

uses
  FluentSQL.Utils;

{ TGpSQLGroupBy }

constructor TFluentSQLGroupBy.Create;
begin
  inherited Create('GroupBy');
  FColumns := TFluentSQLNames.Create;
end;

procedure TFluentSQLGroupBy.Clear;
begin
  FColumns.Clear;
end;

function TFluentSQLGroupBy.Columns: IFluentSQLNames;
begin
  Result := FColumns;
end;

function TFluentSQLGroupBy.IsEmpty: Boolean;
begin
  Result := FColumns.IsEmpty;
end;

function TFluentSQLGroupBy.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['GROUP BY', FColumns.Serialize]);
end;

end.




