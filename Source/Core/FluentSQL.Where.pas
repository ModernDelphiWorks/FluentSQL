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

unit FluentSQL.Where;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Section,
  FluentSQL.Expression,
  FluentSQL.Interfaces;

type
  TFluentSQLWhere = class(TFluentSQLSection, IFluentSQLWhere)
  private
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
  protected
    FExpression: IFluentSQLExpression;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; override;
    function Serialize: String; virtual;
    function IsEmpty: Boolean; override;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLWhere }

procedure TFluentSQLWhere.Clear;
begin
  Expression.Clear;
end;

constructor TFluentSQLWhere.Create;
begin
  inherited Create('Where');
  FExpression := TFluentSQLExpression.Create;
end;

destructor TFluentSQLWhere.Destroy;
begin
  inherited;
end;

function TFluentSQLWhere._GetExpression: IFluentSQLExpression;
begin
  Result := FExpression;
end;

function TFluentSQLWhere.IsEmpty: Boolean;
begin
  Result := FExpression.IsEmpty;
end;

function TFluentSQLWhere.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['WHERE', FExpression.Serialize]);
end;

procedure TFluentSQLWhere._SetExpression(const Value: IFluentSQLExpression);
begin
  FExpression := Value;
end;

end.




