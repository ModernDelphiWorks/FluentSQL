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

unit FluentSQL.NameValue;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  TFluentSQLNameValue  = class(TInterfacedObject, IFluentSQLNameValue)
  strict private
    FName : String;
    FValue: String;
    function _GetName: String;
    function _GetValue: String;
    procedure _SetName(const Value: String);
    procedure _SetValue(const Value: String);
  public
    procedure Clear;
    function IsEmpty: Boolean;
    property Name: String read _GetName write _SetName;
    property Value: String read _GetValue write _SetValue;
  end;

  TFluentSQLNameValuePairs = class(TInterfacedObject, IFluentSQLNameValuePairs)
  strict private
    FList: TList<IFluentSQLNameValue>;
    function _GetItem(AIdx: Integer): IFluentSQLNameValue;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLNameValue; overload;
    procedure Add(const ANameValue: IFluentSQLNameValue); overload;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    property Item[AIdx: Integer]: IFluentSQLNameValue read _GetItem; default;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLNameValue }

procedure TFluentSQLNameValue.Clear;
begin
  FName := '';
  FValue := '';
end;

function TFluentSQLNameValue._GetName: String;
begin
  Result := FName;
end;

function TFluentSQLNameValue._GetValue: String;
begin
  Result := FValue;
end;

function TFluentSQLNameValue.IsEmpty: Boolean;
begin
  Result := (FName <> '');
end;

procedure TFluentSQLNameValue._SetName(const Value: String);
begin
  FName := Value;
end;

procedure TFluentSQLNameValue._SetValue(const Value: String);
begin
  FValue := Value;
end;

{ TFluentSQLNameValuePairs }

function TFluentSQLNameValuePairs.Add: IFluentSQLNameValue;
begin
  Result := TFluentSQLNameValue.Create;
  Add(Result);
end;

procedure TFluentSQLNameValuePairs.Add(const ANameValue: IFluentSQLNameValue);
begin
  FList.Add(ANameValue);
end;

procedure TFluentSQLNameValuePairs.Clear;
begin
  FList.Clear;
end;

function TFluentSQLNameValuePairs.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TFluentSQLNameValuePairs.Create;
begin
  FList := TList<IFluentSQLNameValue>.Create;
end;

destructor TFluentSQLNameValuePairs.Destroy;
begin
  FList.Free;
  inherited;
end;

function TFluentSQLNameValuePairs._GetItem(AIdx: Integer): IFluentSQLNameValue;
begin
  Result := FList[AIdx];
end;

function TFluentSQLNameValuePairs.IsEmpty: Boolean;
begin
  Result := (Count = 0);
end;

end.




