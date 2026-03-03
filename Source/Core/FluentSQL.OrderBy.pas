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




