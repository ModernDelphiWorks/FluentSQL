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

unit FluentSQL.OrderBy;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Name,
  FluentSQL.Utils,
  FluentSQL.Interfaces;

type
  TFluentSQLOrderByColumn = class(TFluentSQLName, IFluentSQLOrderByColumn)
  strict private
    FDirection: TOrderByDirection;
  protected
    function _GetDirection: TOrderByDirection;
    procedure _SetDirection(const Value: TOrderByDirection);
  public
    property Direction: TOrderByDirection read _GetDirection write _SetDirection;
  end;

  TFluentSQLOrderByColumns = class(TFluentSQLNames)
  public
    function Add: IFluentSQLName; override;
  end;

  TFluentSQLOrderBy = class(TFluentSQLSection, IFluentSQLOrderBy)
  strict private
    FColumns: IFluentSQLNames;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    function Serialize: String;
    function IsEmpty: Boolean; override;
    function Columns: IFluentSQLNames;
  end;

implementation

{ TFluentSQLOrderByColumn }

function TFluentSQLOrderByColumn._GetDirection: TOrderByDirection;
begin
  Result := FDirection;
end;

procedure TFluentSQLOrderByColumn._SetDirection(const Value: TOrderByDirection);
begin
  FDirection := Value;
end;

{ TFluentSQLOrderByColumns }

function TFluentSQLOrderByColumns.Add: IFluentSQLName;
begin
  Result := TFluentSQLOrderByColumn.Create;
  Add(Result);
end;

{ TFluentSQLOrderBy }

procedure TFluentSQLOrderBy.Clear;
begin
  Columns.Clear;
end;

function TFluentSQLOrderBy.Columns: IFluentSQLNames;
begin
  Result := FColumns;
end;

constructor TFluentSQLOrderBy.Create;
begin
  inherited Create('OrderBy');
  FColumns := TFluentSQLOrderByColumns.Create;
end;

destructor TFluentSQLOrderBy.Destroy;
begin
  FColumns := nil;
  inherited;
end;

function TFluentSQLOrderBy.IsEmpty: Boolean;
begin
  Result := Columns.IsEmpty;
end;

function TFluentSQLOrderBy.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['ORDER BY', FColumns.Serialize]);
end;

end.




