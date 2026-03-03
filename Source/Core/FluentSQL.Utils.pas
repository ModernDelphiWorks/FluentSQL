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

unit FluentSQL.Utils;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces;

type
  TUtils = class
  private
    class function _AddToList(const AList, ADelimiter, ANewElement: String): String;
    class function _VarRecToString(const AValue: TVarRec): String;
  public
    class function Concat(const AElements: array of String; const ADelimiter: String = ' '): String;
    class function SqlParamsToStr(const AParams: array of const): String;
    class function DateToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDate): String;
    class function DateTimeToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDateTime): String;
    class function GuidStrToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TGUID): String;
  end;

implementation

class function TUtils.Concat(const AElements: array of String;
  const ADelimiter: String): String;
var
  LValue: String;
begin
  Result := '';
  for LValue in AElements do
    if LValue <> '' then
      Result := _AddToList(Result, ADelimiter, LValue);
end;

class function TUtils.DateTimeToSQLFormat(const ADriverName: TFluentSQLDriver;
  const AValue: TDateTime): String;
begin
  case ADriverName of
    dbnFirebird,
    dbnAbsoluteDB,
    dbnInterbase: Result := FormatDateTime('mm/dd/yyyy hh:nn:ss', AValue);

    dbnMSSQL,
    dbnMySQL,
    dbnSQLite,
    dbnDB2,
    dbnOracle,
    dbnInformix,
    dbnPostgreSQL,
    dbnADS,
    dbnASA,
    dbnMongoDB,
    dbnElevateDB,
    dbnNexusDB: Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', AValue);
  end;

end;

class function TUtils.DateToSQLFormat(const ADriverName: TFluentSQLDriver;
  const AValue: TDate): String;
begin
  case ADriverName of
    dbnFirebird,
    dbnAbsoluteDB,
    dbnInterbase: Result := FormatDateTime('mm/dd/yyyy', AValue);

    dbnMSSQL,
    dbnMySQL,
    dbnSQLite,
    dbnDB2,
    dbnOracle,
    dbnInformix,
    dbnPostgreSQL,
    dbnADS,
    dbnASA,
    dbnMongoDB,
    dbnElevateDB,
    dbnNexusDB: Result := FormatDateTime('yyyy-mm-dd', AValue);
  end;
end;

class function TUtils.GuidStrToSQLFormat(const ADriverName: TFluentSQLDriver;
  const AValue: TGUID): String;
begin
  case ADriverName of
    dbnFirebird,
    dbnInterbase: Result := Format('CHAR_TO_UUID(''%s'')', [AValue.ToString]);

    else
      raise Exception.Create('Conversão de Guid no formato String não implementada.');
  end;
end;

class function TUtils._AddToList(const AList, ADelimiter, ANewElement: String): String;
begin
  Result := AList;
  if Result <> '' then
    Result := Result + ADelimiter;
  Result := Result + ANewElement;
end;

class function TUtils.SqlParamsToStr(const AParams: array of const): String;
var
  LFor: Integer;
  LastCh: Char;
  LParam: String;
begin
  Result := '';
  for LFor := Low(AParams) to High(AParams) do
  begin
    LParam := _VarRecToString(AParams[LFor]);
    if Result = '' then
      LastCh := ' '
    else
      LastCh := Result[Length(Result)];
    if (LastCh <> '.') and (LastCh <> '(') and (LastCh <> ' ') and (LastCh <> ':') and
       (LParam <> ',') and (LParam <> '.') and (LParam <> ')') then
      Result := Result + ' ';
    Result := Result + LParam;
  end;
end;

class function TUtils._VarRecToString(const AValue: TVarRec): String;
const
  BoolChars: array [Boolean] of String = ('F', 'T');
{$IFNDEF FPC}
type
  PtrUInt = Integer;
{$ENDIF}
begin
  case AValue.VType of
    vtInteger:    Result := IntToStr(AValue.VInteger);
    vtBoolean:    Result := BoolChars[AValue.VBoolean];
    vtChar:       Result := Char(AValue.VChar);
    vtExtended:   Result := FloatToStr(AValue.VExtended^);
    {$IFNDEF NEXTGEN}
    vtString:     Result := String(AValue.VString^);
    {$ENDIF}
    vtPointer:    Result := IntToHex(PtrUInt(AValue.VPointer),8);
    vtPChar:      Result := String(AValue.VPChar^);
    {$IFDEF AUTOREFCOUNT}
    vtObject:     Result := TObject(AValue.VObject).ClassName;
    {$ELSE}
    vtObject:     Result := AValue.VObject.ClassName;
    {$ENDIF}
    vtClass:      Result := AValue.VClass.ClassName;
    vtWideChar:   Result := String(AValue.VWideChar);
    vtPWideChar:  Result := String(AValue.VPWideChar^);
    vtAnsiString: Result := String(AValue.VAnsiString);
    vtCurrency:   Result := CurrToStr(AValue.VCurrency^);
    vtVariant:    Result := String(AValue.VVariant^);
    vtWideString: Result := String(AValue.VWideString);
    vtInt64:      Result := IntToStr(AValue.VInt64^);
    {$IFDEF UNICODE}
    vtUnicodeString: Result := String(AValue.VUnicodeString);
    {$ENDIF}
  else
    raise Exception.Create('VarRecToString: Unsupported parameter type');
  end;
end;

end.


