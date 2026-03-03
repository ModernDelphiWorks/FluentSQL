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

unit FluentSQL.Update;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Namevalue,
  FluentSQL.Interfaces;

type
  TFluentSQLUpdate = class(TFluentSQLSection, IFluentSQLUpdate)
  strict private
    FTableName: String;
    FValues: IFluentSQLNameValuePairs;
    function _SerializeNameValuePairsForUpdate(const APairs: IFluentSQLNameValuePairs): String;
    function  _GetTableName: String;
    procedure _SetTableName(const value: String);
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Values: IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLUpdate }

procedure TFluentSQLUpdate.Clear;
begin
  FTableName := '';
  FValues.Clear;
end;

constructor TFluentSQLUpdate.Create;
begin
  inherited Create('Update');
  FValues := TFluentSQLNameValuePairs.Create;
end;

function TFluentSQLUpdate._GetTableName: String;
begin
  Result := FTableName;
end;

function TFluentSQLUpdate.IsEmpty: Boolean;
begin
  Result := (TableName = '');
end;

function TFluentSQLUpdate.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['UPDATE', FTableName, 'SET',
      _SerializeNameValuePairsForUpdate(FValues)]);
end;

function TFluentSQLUpdate._SerializeNameValuePairsForUpdate(const APairs: IFluentSQLNameValuePairs): String;
var
  LFor: Integer;
begin
  Result := '';
  for LFor := 0 to APairs.Count -1 do
    Result := TUtils.Concat([Result, TUtils.Concat([APairs[LFor].Name, '=', APairs[LFor].Value])], ', ');
end;

procedure TFluentSQLUpdate._SetTableName(const value: String);
begin
  FTableName := Value;
end;

function TFluentSQLUpdate.Values: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

end.




