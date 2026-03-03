{
               FluentSQL4D: Fluent SQL Framework for Delphi

                          Apache License
                      Version 2.0, January 2004
                   http://www.apache.org/licenses/

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
}

{
  @abstract(FluentSQL4D: Fluent SQL Framework for Delphi)
  @description(A modern and extensible query framework supporting multiple databases)
  @created(03 Apr 2025)
  @author(Isaque Pinheiro)
  @contact(isaquepsp@gmail.com)
  @discord(https://discord.gg/T2zJC8zX)
}

unit FluentSQL.Core;

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
  private
    FName: String;
  protected
    function _GetName: String;
  public
    constructor Create(ASectionName: String);
    procedure Clear; virtual; abstract;
    function IsEmpty: Boolean; virtual; abstract;
    property Name: String read _GetName;
  end;

  TFluentSQLName = class(TInterfacedObject, IFluentSQLName)
  strict private
    FAlias: String;
    FCase: IFluentSQLCase;
    FName: String;
  protected
    function _GetAlias: String;
    function _GetCase: IFluentSQLCase;
    function _GetName: String;
    procedure _SetAlias(const Value: String);
    procedure _SetCase(const Value: IFluentSQLCase);
    procedure _SetName(const Value: String);
  public
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Name: String read _GetName write _SetName;
    property Alias: String read _GetAlias write _SetAlias;
    property CaseExpr: IFluentSQLCase read _GetCase write _SetCase;
  end;

  TFluentSQLNames = class(TInterfacedObject, IFluentSQLNames)
  private
    FColumns: TList<IFluentSQLName>;
    function SerializeName(const AName: IFluentSQLName): String;
    function SerializeDirection(ADirection: TOrderByDirection): String;
  protected
    function GetColumns(AIdx: Integer): IFluentSQLName;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLName; overload; virtual;
    procedure Add(const Value: IFluentSQLName); overload; virtual;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Columns[AIdx: Integer]: IFluentSQLName read GetColumns; default;
  end;

  TFluentSQLNameValue  = class(TInterfacedObject, IFluentSQLNameValue)
  strict private
    FName : String;
    FValue: String;
  protected
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
  protected
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

{ TFluentSQLName }

procedure TFluentSQLName.Clear;
begin
  FName := '';
  FAlias := '';
end;

function TFluentSQLName._GetAlias: String;
begin
  Result := FAlias;
end;

function TFluentSQLName._GetCase: IFluentSQLCase;
begin
  Result := FCase;
end;

function TFluentSQLName._GetName: String;
begin
  Result := FName;
end;

destructor TFluentSQLName.Destroy;
begin
  FCase := nil;
  inherited;
end;

function TFluentSQLName.IsEmpty: Boolean;
begin
  Result := (FName = '') and (FAlias = '');
end;

function TFluentSQLName.Serialize: String;
begin
  if Assigned(FCase) then
    Result := '(' + FCase.Serialize + ')'
  else
    Result := FName;
  if FAlias <> '' then
    Result := Result + ' AS ' + FAlias;
end;

procedure TFluentSQLName._SetAlias(const Value: String);
begin
  FAlias := Value;
end;

procedure TFluentSQLName._SetCase(const Value: IFluentSQLCase);
begin
  FCase := Value;
end;

procedure TFluentSQLName._SetName(const Value: String);
begin
  FName := Value;
end;

{ TFluentSQLNames }

function TFluentSQLNames.Add: IFluentSQLName;
begin
  Result := TFluentSQLName.Create;
  Add(Result);
end;

procedure TFluentSQLNames.Add(const Value: IFluentSQLName);
begin
  FColumns.Add(Value);
end;

procedure TFluentSQLNames.Clear;
begin
  FColumns.Clear;
end;

function TFluentSQLNames.Count: Integer;
begin
  Result := FColumns.Count;
end;

constructor TFluentSQLNames.Create;
begin
  FColumns := TList<IFluentSQLName>.Create;
end;

destructor TFluentSQLNames.Destroy;
begin
  FColumns.Free;
  inherited;
end;

function TFluentSQLNames.GetColumns(AIdx: Integer): IFluentSQLName;
begin
  Result := FColumns[AIdx];
end;

function TFluentSQLNames.IsEmpty: Boolean;
begin
  Result := (Count = 0);
end;

function TFluentSQLNames.Serialize: String;
var
  LFor: Integer;
  LOrderByCol: IFluentSQLOrderByColumn;
begin
  Result := '';
  for LFor := 0 to FColumns.Count -1 do
  begin
    Result := TUtils.Concat([Result, SerializeName(FColumns[LFor])], ', ');
    if Supports(FColumns[LFor], IFluentSQLOrderByColumn, LOrderByCol) then
      Result := TUtils.Concat([Result, SerializeDirection(LOrderByCol.Direction)]);
  end;
end;

function TFluentSQLNames.SerializeDirection(ADirection: TOrderByDirection): String;
begin
  case ADirection of
    dirAscending:  Result := '';
    dirDescending: Result := 'DESC';
  else
    raise Exception.Create('TFluentSQLNames.SerializeDirection: Unknown direction');
  end;
end;

function TFluentSQLNames.SerializeName(const AName: IFluentSQLName): String;
begin
  Result := AName.Serialize;
end;

{ TFluentSQLSection }

constructor TFluentSQLSection.Create(ASectionName: String);
begin
  FName := ASectionName;
end;

function TFluentSQLSection._GetName: String;
begin
  Result := FName;
end;

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





