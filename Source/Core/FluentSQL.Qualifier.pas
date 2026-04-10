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

unit FluentSQL.Qualifier;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  TFluentSQLSelectQualifier = class(TInterfacedObject, IFluentSQLSelectQualifier)
  strict private
    FQualifier: TSelectQualifierType;
    FValue: Integer;
    function _GetQualifier: TSelectQualifierType;
    function _GetValue: Integer;
    procedure _SetQualifier(const Value: TSelectQualifierType);
    procedure _SetValue(const Value: Integer);
  public
    property Qualifier: TSelectQualifierType read _GetQualifier write _SetQualifier;
    property Value: Integer read _GetValue write _SetValue;
  end;

  TFluentSQLSelectQualifiers = class(TInterfacedObject, IFluentSQLSelectQualifiers)
  protected
    FExecutingPagination: Boolean;
    FQualifiers: TList<IFluentSQLSelectQualifier>;
    function _GetQualifier(AIdx: Integer): IFluentSQLSelectQualifier;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLSelectQualifier; overload;
    procedure Add(AQualifier: IFluentSQLSelectQualifier); overload;
    procedure Clear;
    function ExecutingPagination: Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
    function SerializePagination: String; virtual; abstract;
    function SerializeDistinct: String;
    property Qualifiers[AIdx: Integer]: IFluentSQLSelectQualifier read _GetQualifier; default;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiers }

function TFluentSQLSelectQualifiers.Add: IFluentSQLSelectQualifier;
begin
  Result := TFluentSQLSelectQualifier.Create;
end;

procedure TFluentSQLSelectQualifiers.Add(AQualifier: IFluentSQLSelectQualifier);
begin
  FQualifiers.Add(AQualifier);
  if AQualifier.Qualifier in [sqFirst, sqSkip] then
    FExecutingPagination := True;
end;

procedure TFluentSQLSelectQualifiers.Clear;
begin
  FExecutingPagination := False;
  FQualifiers.Clear;
end;

function TFluentSQLSelectQualifiers.Count: Integer;
begin
  Result := FQualifiers.Count;
end;

constructor TFluentSQLSelectQualifiers.Create;
begin
  FExecutingPagination := False;
  FQualifiers := TList<IFluentSQLSelectQualifier>.Create;
end;

destructor TFluentSQLSelectQualifiers.Destroy;
begin
  FQualifiers.Free;
  inherited;
end;

function TFluentSQLSelectQualifiers.ExecutingPagination: Boolean;
begin
  Result := FExecutingPagination;
end;

function TFluentSQLSelectQualifiers._GetQualifier(AIdx: Integer): IFluentSQLSelectQualifier;
begin
  Result := FQualifiers[AIdx];
end;

function TFluentSQLSelectQualifiers.IsEmpty: Boolean;
begin
  Result := (Count = 0);
end;

function TFluentSQLSelectQualifiers.SerializeDistinct: String;
var
  LFor: Integer;
begin
  inherited;
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    if FQualifiers[LFor].Qualifier = sqDistinct then
    begin
      Result := TUtils.Concat([Result, 'DISTINCT']);
      Exit;
    end;
  end;
end;

{ TFluentSQLSelectQualifier }

function TFluentSQLSelectQualifier._GetQualifier: TSelectQualifierType;
begin
  Result := FQualifier;
end;

function TFluentSQLSelectQualifier._GetValue: Integer;
begin
  Result := FValue;
end;

procedure TFluentSQLSelectQualifier._SetQualifier(const Value: TSelectQualifierType);
begin
  FQualifier := Value;
end;

procedure TFluentSQLSelectQualifier._SetValue(const Value: Integer);
begin
  FValue := Value;
end;

end.




