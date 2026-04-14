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

unit FluentSQL.Utils;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  {$ifndef fpc}
  System.Hash,
  {$endif}
  FluentSQL.Interfaces;

type
  TUtils = class
  private
    class function _AddToList(const AList, ADelimiter, ANewElement: String): String;
    class function _VarRecToString(const AValue: TVarRec): String;
    class function _TryVarRecAsParam(const AValue: TVarRec; const ASQLParams: IFluentSQLParams;
      out APlaceholder: String): Boolean;
  public
    class function Concat(const AElements: array of String; const ADelimiter: String = ' '): String;
    class function SqlParamsToStr(const AParams: array of const): String;
    /// <summary>
    /// Builds the same textual layout as SqlParamsToStr, but replaces scalar VarRec kinds
    /// (integer, int64, extended, currency, boolean, numeric/date Variant) with FAST.Params.Add placeholders.
    /// String-like VarRec entries remain literal fragments (identifiers, operators, SQL text) per RN-P3.
    /// </summary>
    class function SqlArrayOfConstToParameterizedSql(const AParams: array of const;
      const ASQLParams: IFluentSQLParams): String;
    class function DateToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDate): String;
    class function DateTimeToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDateTime): String;
    class function GuidStrToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TGUID): String;
    class function GetHash(const AString: String): String;
  end;

implementation

uses
  Variants;

class function TUtils._TryVarRecAsParam(const AValue: TVarRec; const ASQLParams: IFluentSQLParams;
  out APlaceholder: String): Boolean;
var
  V: Variant;
begin
  Result := False;
  APlaceholder := '';
  if not Assigned(ASQLParams) then
    Exit;
  case AValue.VType of
    vtInteger:
      begin
        APlaceholder := ASQLParams.Add(AValue.VInteger, dftInteger);
        Result := True;
      end;
    vtInt64:
      begin
        APlaceholder := ASQLParams.Add(AValue.VInt64^, dftInteger);
        Result := True;
      end;
    vtBoolean:
      begin
        APlaceholder := ASQLParams.Add(AValue.VBoolean, dftBoolean);
        Result := True;
      end;
    vtExtended:
      begin
        APlaceholder := ASQLParams.Add(AValue.VExtended^, dftFloat);
        Result := True;
      end;
    vtCurrency:
      begin
        APlaceholder := ASQLParams.Add(AValue.VCurrency^, dftFloat);
        Result := True;
      end;
    vtVariant:
      begin
        V := AValue.VVariant^;
        case VarType(V) of
          varSmallInt, varInteger, varByte, varWord, varLongWord, varInt64, varShortInt:
            begin
              APlaceholder := ASQLParams.Add(V, dftInteger);
              Result := True;
            end;
          varSingle, varDouble, varCurrency:
            begin
              APlaceholder := ASQLParams.Add(V, dftFloat);
              Result := True;
            end;
          varBoolean:
            begin
              APlaceholder := ASQLParams.Add(V, dftBoolean);
              Result := True;
            end;
          varDate:
            begin
              APlaceholder := ASQLParams.Add(V, dftDateTime);
              Result := True;
            end;
        else
          Result := False;
        end;
      end;
{$IFDEF CPU64}
    vtNativeInt:
      begin
        APlaceholder := ASQLParams.Add(NativeInt(AValue.VNativeInt), dftInteger);
        Result := True;
      end;
    vtNativeUInt:
      begin
        APlaceholder := ASQLParams.Add(Int64(AValue.VNativeUInt), dftInteger);
        Result := True;
      end;
{$ENDIF}
  else
    Result := False;
  end;
end;

class function TUtils.SqlArrayOfConstToParameterizedSql(const AParams: array of const;
  const ASQLParams: IFluentSQLParams): String;
var
  LFor: Integer;
  LastCh: Char;
  LParam: String;
begin
  if not Assigned(ASQLParams) then
    Exit(SqlParamsToStr(AParams));
  Result := '';
  for LFor := Low(AParams) to High(AParams) do
  begin
    if not _TryVarRecAsParam(AParams[LFor], ASQLParams, LParam) then
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

    dbnMSSQL,
    dbnPostgreSQL,
    dbnSQLite,
    dbnMySQL: Result := Format('''%s''', [AValue.ToString]);

    else
      raise Exception.Create('Conversao de Guid no formato String para este dialeto nao implementada.');
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

class function TUtils.GetHash(const AString: String): String;
begin
  {$ifndef fpc}
  Result := THashBobJenkins.GetHashString(AString);
  {$else}
  // Simplified hash for FPC if System.Hash is not available
  Result := IntToHex(Cardinal(AString.GetHashCode), 8);
  {$endif}
end;

end.


