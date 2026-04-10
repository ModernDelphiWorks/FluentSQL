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

unit FluentSQL.Section;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  TFluentSQLSection = class(TInterfacedObject, IFluentSQLSection)
  strict private
    FName: String;
    function _GetName: String;
  public
    constructor Create(ASectionName: String);
    procedure Clear; virtual; abstract;
    function IsEmpty: Boolean; virtual; abstract;
    property Name: String read _GetName;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSection }

constructor TFluentSQLSection.Create(ASectionName: String);
begin
  FName := ASectionName;
end;

function TFluentSQLSection._GetName: String;
begin
  Result := FName;
end;

end.




