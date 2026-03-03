{
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

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

unit FluentSQL.Functions;

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.Register,
  FluentSQL.FunctionsAbstract;

type
  TFluentSQLFunctions = class(TFluentSQLFunctionAbstract, IFluentSQLFunctions)
  strict private
    FDatabase: TFluentSQLDriver;
    FRegister: TFluentSQLRegister;
  public
    class function QFunc(const AValue: String): String;
    constructor Create(const ADatabase: TFluentSQLDriver;
      const ARegister: TFluentSQLRegister);
    destructor Destroy; override;
    // Aggregation functions
    function Count(const AValue: String): String; override;
    function Sum(const AValue: String): String; override;
    function Min(const AValue: String): String; override;
    function Max(const AValue: String): String; override;
    function Average(const AValue: String): String; override;
    // String functions
    function Upper(const AValue: String): String; override;
    function Lower(const AValue: String): String; override;
    function Length(const AValue: String): String; override;
    function Trim(const AValue: String): String; override;
    function LTrim(const AValue: String): String; override;
    function RTrim(const AValue: String): String; override;
    function SubString(const AValue: String; const AFrom, AFor: Integer): String; override;
    function Concat(const AValue: array of String): String; override;
    // Null handling
    function Coalesce(const AValues: array of String): String; override;
    // Type conversion
    function Cast(const AExpression: String; const ADataType: String): String; override;
    // Date functions
    function Date(const AValue: String; const AFormat: String): String; overload; override;
    function Date(const AValue: String): String; overload; override;
    function Day(const AValue: String): String; override;
    function Month(const AValue: String): String; override;
    function Year(const AValue: String): String; override;
    function CurrentDate: String; override;
    function CurrentTimestamp: String; override;
    // Numeric functions
    function Round(const AValue: String; const ADecimals: Integer): String; override;
    function Floor(const AValue: String): String; override;
    function Ceil(const AValue: String): String; override;
    function Modulus(const AValue, ADivisor: String): String;
    function Abs(const AValue: String): String;
  end;

implementation

{ TFluentSQLFunctions }

constructor TFluentSQLFunctions.Create(const ADatabase: TFluentSQLDriver;
  const ARegister: TFluentSQLRegister);
begin
  FDatabase := ADatabase;
  FRegister := ARegister;
end;

destructor TFluentSQLFunctions.Destroy;
begin
  FRegister := nil;
  inherited;
end;

class function TFluentSQLFunctions.QFunc(const AValue: String): String;
begin
  Result := '''' + AValue + '''';
end;

function TFluentSQLFunctions.Count(const AValue: String): String;
begin
  Result := 'COUNT(' + AValue + ')';
end;

function TFluentSQLFunctions.Sum(const AValue: String): String;
begin
  Result := 'SUM(' + AValue + ')';
end;

function TFluentSQLFunctions.Min(const AValue: String): String;
begin
  Result := 'MIN(' + AValue + ')';
end;

function TFluentSQLFunctions.Max(const AValue: String): String;
begin
  Result := 'MAX(' + AValue + ')';
end;

function TFluentSQLFunctions.Abs(const AValue: String): String;
begin
  Result := 'ABS(' + AValue + ')';
end;

function TFluentSQLFunctions.Average(const AValue: String): String;
begin
  Result := 'AVG(' + AValue + ')';
end;

function TFluentSQLFunctions.Upper(const AValue: String): String;
begin
  Result := 'UPPER(' + AValue + ')';
end;

function TFluentSQLFunctions.Lower(const AValue: String): String;
begin
  Result := 'LOWER(' + AValue + ')';
end;

function TFluentSQLFunctions.Length(const AValue: String): String;
begin
  Result := 'LENGTH(' + AValue + ')';
end;

function TFluentSQLFunctions.Trim(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Trim(AValue);
end;

function TFluentSQLFunctions.LTrim(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).LTrim(AValue);
end;

function TFluentSQLFunctions.RTrim(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).RTrim(AValue);
end;

function TFluentSQLFunctions.SubString(const AValue: String; const AFrom, AFor: Integer): String;
begin
  Result := FRegister.Functions(FDatabase).SubString(AValue, AFrom, AFor);
end;

function TFluentSQLFunctions.Concat(const AValue: array of String): String;
begin
  Result := FRegister.Functions(FDatabase).Concat(AValue);
end;

function TFluentSQLFunctions.Coalesce(const AValues: array of String): String;
begin
  Result := FRegister.Functions(FDatabase).Coalesce(AValues);
end;

function TFluentSQLFunctions.Cast(const AExpression: String; const ADataType: String): String;
begin
  Result := 'CAST(' + AExpression + ' AS ' + ADataType + ')';
end;

function TFluentSQLFunctions.Date(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Date(AValue);
end;

function TFluentSQLFunctions.Date(const AValue, AFormat: String): String;
begin
  Result := FRegister.Functions(FDatabase).Date(AValue, AFormat);
end;

function TFluentSQLFunctions.Day(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Day(AValue);
end;

function TFluentSQLFunctions.Modulus(const AValue, ADivisor: String): String;
begin
  Result := FRegister.Functions(FDatabase).Modulus(AValue, ADivisor);
end;

function TFluentSQLFunctions.Month(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Month(AValue);
end;

function TFluentSQLFunctions.Year(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Year(AValue);
end;

function TFluentSQLFunctions.CurrentDate: String;
begin
  Result := FRegister.Functions(FDatabase).CurrentDate;
end;

function TFluentSQLFunctions.CurrentTimestamp: String;
begin
  Result := FRegister.Functions(FDatabase).CurrentTimestamp;
end;

function TFluentSQLFunctions.Round(const AValue: String; const ADecimals: Integer): String;
begin
  Result := 'ROUND(' + AValue + ', ' + IntToStr(ADecimals) + ')';
end;

function TFluentSQLFunctions.Floor(const AValue: String): String;
begin
  Result := 'FLOOR(' + AValue + ')';
end;

function TFluentSQLFunctions.Ceil(const AValue: String): String;
begin
  Result := 'CEIL(' + AValue + ')';
end;

end.




