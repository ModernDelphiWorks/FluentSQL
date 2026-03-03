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

unit FluentSQL.Having;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Interfaces;

type
  TFluentSQLHaving = class(TFluentSQLSection, IFluentSQLHaving)
  strict private
    FExpression: IFluentSQLExpression;
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
  public
    constructor Create;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Serialize: String;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;


implementation

uses
  FluentSQL.Expression,
  FluentSQL.Utils;

{ TFluentSQLHaving }

constructor TFluentSQLHaving.Create;
begin
  inherited Create('Having');
  FExpression := TFluentSQLExpression.Create;
end;

procedure TFluentSQLHaving.Clear;
begin
  FExpression.Clear;
end;

function TFluentSQLHaving._GetExpression: IFluentSQLExpression;
begin
  Result := FExpression;
end;

function TFluentSQLHaving.IsEmpty: Boolean;
begin
  Result := FExpression.IsEmpty;
end;

function TFluentSQLHaving.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['HAVING', FExpression.Serialize]);
end;

procedure TFluentSQLHaving._SetExpression(const Value: IFluentSQLExpression);
begin
  FExpression := Value;
end;

end.




