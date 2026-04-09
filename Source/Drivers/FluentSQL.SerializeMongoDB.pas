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

unit FluentSQL.SerializeMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Classes,
  StrUtils,
  Variants,
  FluentSQL.Register,
  FluentSQL.Interfaces,
  FluentSQL.Serialize;

type
  TFluentSQLSerializerMongoDB = class(TFluentSQLSerialize)
  public
    function AsString(const AAST: IFluentSQLAST): String; override;
  end;

/// <summary>Fragmento JSON ADR-013 §2b: coleção + projection, alinhado ao serializer principal (sem pseudo-SQL).</summary>
function FluentMongoSelectSerializeFragment(const ASelect: IFluentSQLSelect): String;

implementation

type
  EFluentSQLMongoDBSerialize = class(Exception);

function EscapeJson(const AValue: String): String;
var
  LIdx: Integer;
begin
  Result := '';
  for LIdx := 1 to Length(AValue) do
    case AValue[LIdx] of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
      else Result := Result + AValue[LIdx];
    end;
end;

function JsonString(const AValue: String): String;
begin
  Result := '"' + EscapeJson(AValue) + '"';
end;

function JsonNumber(const AValue: Extended): String;
begin
  Result := StringReplace(FloatToStr(AValue), ',', '.', [rfReplaceAll]);
end;

function JsonValueFromVariant(const AValue: Variant): String;
var
  LType: Integer;
begin
  if VarIsNull(AValue) then
    Exit('null');

  LType := VarType(AValue);
  case LType of
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64:
      Result := VarToStr(AValue);
    varSingle, varDouble, varCurrency:
      Result := JsonNumber(AValue);
    varBoolean:
      if AValue then
        Result := 'true'
      else
        Result := 'false';
    varDate:
      Result := JsonString(FormatDateTime('yyyy-mm-dd hh:nn:ss', VarToDateTime(AValue)));
    else
      Result := JsonString(VarToStr(AValue));
  end;
end;

function StripOuterParentheses(const AValue: String): String;
var
  LText: String;
  LDepth: Integer;
  LIdx: Integer;
  LCanStrip: Boolean;
begin
  LText := Trim(AValue);
  if (Length(LText) < 2) or (LText[1] <> '(') or (LText[Length(LText)] <> ')') then
    Exit(LText);

  LDepth := 0;
  LCanStrip := True;
  for LIdx := 1 to Length(LText) do
  begin
    if LText[LIdx] = '(' then
      Inc(LDepth)
    else if LText[LIdx] = ')' then
      Dec(LDepth);

    if (LDepth = 0) and (LIdx < Length(LText)) then
    begin
      LCanStrip := False;
      Break;
    end;
  end;

  if LCanStrip then
    Result := Trim(Copy(LText, 2, Length(LText) - 2))
  else
    Result := LText;
end;

function FindTopLevelToken(const AText, AToken: String): Integer;
var
  LUpper: String;
  LToken: String;
  LDepth: Integer;
  LIdx: Integer;
begin
  Result := 0;
  LUpper := UpperCase(AText);
  LToken := UpperCase(AToken);
  LDepth := 0;

  for LIdx := 1 to Length(LUpper) - Length(LToken) + 1 do
  begin
    if AText[LIdx] = '(' then
      Inc(LDepth)
    else if AText[LIdx] = ')' then
      Dec(LDepth);

    if (LDepth = 0) and (Copy(LUpper, LIdx, Length(LToken)) = LToken) then
      Exit(LIdx);
  end;
end;

function NormalizeFieldName(const AFieldName: String): String;
begin
  Result := Trim(AFieldName);
  if Pos('.', Result) > 0 then
    Result := Copy(Result, LastDelimiter('.', Result) + 1, MaxInt);
  Result := StringReplace(Result, '`', '', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  Result := StringReplace(Result, '[', '', [rfReplaceAll]);
  Result := StringReplace(Result, ']', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

function TryGetParamValue(const AAST: IFluentSQLAST; const AToken: String; out AValue: Variant): Boolean;
var
  LParamName: String;
  LIdx: Integer;
begin
  Result := False;
  LParamName := Trim(AToken);
  if LParamName = '' then
    Exit;
  if LParamName[1] = ':' then
    LParamName := Copy(LParamName, 2, MaxInt);

  for LIdx := 0 to AAST.Params.Count - 1 do
    if SameText(AAST.Params[LIdx].Name, LParamName) then
    begin
      AValue := AAST.Params[LIdx].Value;
      Exit(True);
    end;
end;

function ParseTokenToVariant(const AAST: IFluentSQLAST; const AToken: String): Variant;
var
  LToken: String;
  LFloat: Extended;
  LInt: Int64;
begin
  LToken := Trim(AToken);
  if (LToken <> '') and (LToken[1] = ':') and TryGetParamValue(AAST, LToken, Result) then
    Exit;

  if (Length(LToken) >= 2) and (LToken[1] = '''') and (LToken[Length(LToken)] = '''') then
    Exit(Copy(LToken, 2, Length(LToken) - 2));

  if SameText(LToken, 'NULL') then
    Exit(Null);
  if SameText(LToken, 'TRUE') then
    Exit(True);
  if SameText(LToken, 'FALSE') then
    Exit(False);

  if TryStrToInt64(LToken, LInt) then
    Exit(LInt);

  if TryStrToFloat(StringReplace(LToken, '.', ',', [rfReplaceAll]), LFloat) then
    Exit(LFloat);

  Result := LToken;
end;

function ParseInValues(const AAST: IFluentSQLAST; const AToken: String): String;
var
  LText: String;
  LValues: TStringList;
  LIdx: Integer;
begin
  LText := Trim(AToken);
  if (Length(LText) >= 2) and (LText[1] = '(') and (LText[Length(LText)] = ')') then
    LText := Copy(LText, 2, Length(LText) - 2);

  LValues := TStringList.Create;
  try
    LValues.StrictDelimiter := True;
    LValues.Delimiter := ',';
    LValues.DelimitedText := LText;
    Result := '[';
    for LIdx := 0 to LValues.Count - 1 do
    begin
      if LIdx > 0 then
        Result := Result + ',';
      Result := Result + JsonValueFromVariant(ParseTokenToVariant(AAST, LValues[LIdx]));
    end;
    Result := Result + ']';
  finally
    LValues.Free;
  end;
end;

function LikeToRegex(const AValue: String): String;
var
  LIdx: Integer;
  LText: String;
  LCh: Char;
begin
  LText := AValue;
  Result := '';
  if (LText <> '') and (LText[1] <> '%') then
    Result := '^';

  for LIdx := 1 to Length(LText) do
  begin
    LCh := LText[LIdx];
    case LCh of
      '%': Result := Result + '.*';
      '_': Result := Result + '.';
      '\', '^', '$', '.', '|', '?', '*', '+', '(', ')', '[', '{':
        Result := Result + '\' + LCh;
      else
        Result := Result + LCh;
    end;
  end;

  if (LText <> '') and (LText[Length(LText)] <> '%') then
    Result := Result + '$';
end;

function ParseConditionToMongo(const AAST: IFluentSQLAST; const AExpression: String): String;
const
  COperators: array[0..9] of String = (
    ' NOT LIKE ', ' LIKE ', ' NOT IN ', ' IN ', ' >= ',
    ' <= ', ' <> ', ' = ', ' > ', ' < '
  );
var
  LExpr: String;
  LUpper: String;
  LField: String;
  LValueToken: String;
  LParamValue: Variant;
  LPos: Integer;
  LOp: String;
  LRegex: String;
begin
  LExpr := Trim(StripOuterParentheses(AExpression));
  LUpper := UpperCase(LExpr);

  LPos := Pos(' IS NOT NULL', LUpper);
  if LPos > 0 then
  begin
    LField := NormalizeFieldName(Copy(LExpr, 1, LPos - 1));
    Exit('{' + JsonString(LField) + ':{"$ne":null}}');
  end;

  LPos := Pos(' IS NULL', LUpper);
  if LPos > 0 then
  begin
    LField := NormalizeFieldName(Copy(LExpr, 1, LPos - 1));
    Exit('{' + JsonString(LField) + ':null}');
  end;

  for LPos := Low(COperators) to High(COperators) do
  begin
    LOp := COperators[LPos];
    if Pos(LOp, LUpper) > 0 then
    begin
      LField := NormalizeFieldName(Copy(LExpr, 1, Pos(LOp, LUpper) - 1));
      LValueToken := Trim(Copy(LExpr, Pos(LOp, LUpper) + Length(LOp), MaxInt));

      if LOp = ' = ' then
        Exit('{' + JsonString(LField) + ':' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}');
      if LOp = ' <> ' then
        Exit('{' + JsonString(LField) + ':{"$ne":' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}}');
      if LOp = ' > ' then
        Exit('{' + JsonString(LField) + ':{"$gt":' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}}');
      if LOp = ' >= ' then
        Exit('{' + JsonString(LField) + ':{"$gte":' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}}');
      if LOp = ' < ' then
        Exit('{' + JsonString(LField) + ':{"$lt":' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}}');
      if LOp = ' <= ' then
        Exit('{' + JsonString(LField) + ':{"$lte":' + JsonValueFromVariant(ParseTokenToVariant(AAST, LValueToken)) + '}}');
      if LOp = ' IN ' then
        Exit('{' + JsonString(LField) + ':{"$in":' + ParseInValues(AAST, LValueToken) + '}}');
      if LOp = ' NOT IN ' then
        Exit('{' + JsonString(LField) + ':{"$nin":' + ParseInValues(AAST, LValueToken) + '}}');
      if (LOp = ' LIKE ') or (LOp = ' NOT LIKE ') then
      begin
        LParamValue := ParseTokenToVariant(AAST, LValueToken);
        LRegex := LikeToRegex(VarToStr(LParamValue));
        if LOp = ' LIKE ' then
          Exit('{' + JsonString(LField) + ':{"$regex":' + JsonString(LRegex) + '}}')
        else
          Exit('{' + JsonString(LField) + ':{"$not":{"$regex":' + JsonString(LRegex) + '}}}');
      end;
    end;
  end;

  raise EFluentSQLMongoDBSerialize.CreateFmt('MongoDB serializer: condição não suportada: %s', [LExpr]);
end;

function ParseExpressionToMongo(const AAST: IFluentSQLAST; const AExpression: String): String;
var
  LExpr: String;
  LPos: Integer;
  LUpper: String;
  LRemain: String;
begin
  LExpr := Trim(StripOuterParentheses(AExpression));
  if LExpr = '' then
    Exit('{}');

  LUpper := UpperCase(LExpr);
  if (Length(LUpper) >= 5) and (Copy(LUpper, 1, 4) = 'NOT ') then
  begin
    LRemain := Trim(Copy(LExpr, 5, MaxInt));
    if LRemain <> '' then
      Exit('{"$nor":[' + ParseExpressionToMongo(AAST, LRemain) + ']}');
  end;

  LPos := FindTopLevelToken(LExpr, ' OR ');
  if LPos > 0 then
    Exit('{"$or":['
      + ParseExpressionToMongo(AAST, Copy(LExpr, 1, LPos - 1))
      + ','
      + ParseExpressionToMongo(AAST, Copy(LExpr, LPos + 4, MaxInt))
      + ']}');

  LPos := FindTopLevelToken(LExpr, ' AND ');
  if LPos > 0 then
    Exit('{"$and":['
      + ParseExpressionToMongo(AAST, Copy(LExpr, 1, LPos - 1))
      + ','
      + ParseExpressionToMongo(AAST, Copy(LExpr, LPos + 5, MaxInt))
      + ']}');

  Result := ParseConditionToMongo(AAST, LExpr);
end;

function BuildProjectionForSelect(const ASelect: IFluentSQLSelect): String;
var
  LIdx: Integer;
  LField: String;
  LFirst: Boolean;
begin
  if not Assigned(ASelect) then
    Exit('{}');

  Result := '{';
  LFirst := True;
  for LIdx := 0 to ASelect.Columns.Count - 1 do
  begin
    LField := NormalizeFieldName(ASelect.Columns[LIdx].Name);
    if (LField = '') or SameText(LField, '*') or (Pos('(', LField) > 0) then
      Continue;

    if not LFirst then
      Result := Result + ',';
    Result := Result + JsonString(LField) + ':1';
    LFirst := False;
  end;
  Result := Result + '}';
end;

function BuildProjection(const AAST: IFluentSQLAST): String;
begin
  if not Assigned(AAST.Select) then
    Exit('{}');
  Result := BuildProjectionForSelect(AAST.Select);
end;

function BuildSort(const AAST: IFluentSQLAST): String;
var
  LIdx: Integer;
  LField: String;
  LFirst: Boolean;
  LDirection: Integer;
begin
  if not Assigned(AAST.OrderBy) or AAST.OrderBy.Columns.IsEmpty then
    Exit('');

  Result := '{';
  LFirst := True;
  for LIdx := 0 to AAST.OrderBy.Columns.Count - 1 do
  begin
    LField := NormalizeFieldName(AAST.OrderBy.Columns[LIdx].Name);
    if LField = '' then
      Continue;

    if (AAST.OrderBy.Columns[LIdx] as IFluentSQLOrderByColumn).Direction = dirDescending then
      LDirection := -1
    else
      LDirection := 1;

    if not LFirst then
      Result := Result + ',';
    Result := Result + JsonString(LField) + ':' + IntToStr(LDirection);
    LFirst := False;
  end;
  Result := Result + '}';
end;

function BuildMongoDocumentFromNameValues(const AAST: IFluentSQLAST;
  const APairs: IFluentSQLNameValuePairs): String;
var
  LIdx: Integer;
  LField: String;
  LFirst: Boolean;
begin
  Result := '{';
  LFirst := True;
  if Assigned(APairs) then
    for LIdx := 0 to APairs.Count - 1 do
    begin
      LField := NormalizeFieldName(APairs[LIdx].Name);
      if LField = '' then
        Continue;
      if not LFirst then
        Result := Result + ',';
      Result := Result + JsonString(LField) + ':'
        + JsonValueFromVariant(ParseTokenToVariant(AAST, APairs[LIdx].Value));
      LFirst := False;
    end;
  Result := Result + '}';
end;

function SerializeMongoInsert(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LCnt: Integer;
  LIdx: Integer;
  LDocs: String;
begin
  LCollection := NormalizeFieldName(AAST.Insert.TableName);
  if LCollection = '' then
    LCollection := Trim(AAST.Insert.TableName);

  LCnt := AAST.Insert.SerializedRowCount;
  if LCnt <= 0 then
  begin
    Result := '{'
      + JsonString('insertOne') + ':{'
      + JsonString('collection') + ':' + JsonString(LCollection) + ','
      + JsonString('document') + ':' + BuildMongoDocumentFromNameValues(AAST, AAST.Insert.Values)
      + '}}';
    Exit;
  end;

  if LCnt = 1 then
  begin
    Result := '{'
      + JsonString('insertOne') + ':{'
      + JsonString('collection') + ':' + JsonString(LCollection) + ','
      + JsonString('document') + ':' + BuildMongoDocumentFromNameValues(AAST, AAST.Insert.SerializedRow(0))
      + '}}';
    Exit;
  end;

  LDocs := '';
  for LIdx := 0 to LCnt - 1 do
  begin
    if LIdx > 0 then
      LDocs := LDocs + ',';
    LDocs := LDocs + BuildMongoDocumentFromNameValues(AAST, AAST.Insert.SerializedRow(LIdx));
  end;

  Result := '{'
    + JsonString('insertMany') + ':{'
    + JsonString('collection') + ':' + JsonString(LCollection) + ','
    + JsonString('documents') + ':[' + LDocs + ']'
    + '}}';
end;

function SerializeMongoUpdate(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LFilter: String;
begin
  LCollection := NormalizeFieldName(AAST.Update.TableName);
  if LCollection = '' then
    LCollection := Trim(AAST.Update.TableName);
  if Assigned(AAST.Where) and not AAST.Where.Expression.IsEmpty then
    LFilter := ParseExpressionToMongo(AAST, AAST.Where.Expression.Serialize)
  else
    LFilter := '{}';
  Result := '{'
    + JsonString('updateMany') + ':{'
    + JsonString('collection') + ':' + JsonString(LCollection) + ','
    + JsonString('filter') + ':' + LFilter + ','
    + JsonString('update') + ':{"$set":' + BuildMongoDocumentFromNameValues(AAST, AAST.Update.Values) + '}'
    + '}}';
end;

function SerializeMongoDelete(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LFilter: String;
begin
  if not Assigned(AAST.Delete) or (AAST.Delete.TableNames.Count = 0) then
    raise EFluentSQLMongoDBSerialize.Create('MongoDB serializer: deleteMany requires a collection (FROM)');

  LCollection := NormalizeFieldName(AAST.Delete.TableNames[0].Name);
  if LCollection = '' then
    LCollection := Trim(AAST.Delete.TableNames[0].Name);

  if Assigned(AAST.Where) and not AAST.Where.Expression.IsEmpty then
    LFilter := ParseExpressionToMongo(AAST, AAST.Where.Expression.Serialize)
  else
    LFilter := '{}';

  Result := '{'
    + JsonString('deleteMany') + ':{'
    + JsonString('collection') + ':' + JsonString(LCollection) + ','
    + JsonString('filter') + ':' + LFilter
    + '}}';
end;

function FluentMongoSelectSerializeFragment(const ASelect: IFluentSQLSelect): String;
var
  LCollection: String;
begin
  if (not Assigned(ASelect)) or ASelect.IsEmpty then
    Exit('');
  if ASelect.TableNames.Count = 0 then
    Exit('');

  LCollection := NormalizeFieldName(ASelect.TableNames[0].Name);
  if LCollection = '' then
    LCollection := Trim(ASelect.TableNames[0].Name);

  Result := '{'
    + JsonString('collection') + ':' + JsonString(LCollection) + ','
    + JsonString('projection') + ':' + BuildProjectionForSelect(ASelect)
    + '}';
end;

function TFluentSQLSerializerMongoDB.AsString(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LFilter: String;
  LProjection: String;
  LSort: String;
  LLimit: Integer;
  LSkip: Integer;
  LIdx: Integer;
begin
  if not Assigned(AAST) then
    Exit('');

  if (AAST.WithAlias <> '') or (AAST.UnionType <> '') then
    raise EFluentSQLMongoDBSerialize.Create('MongoDB serializer: CTE (WITH) and UNION/INTERSECT are not supported for dbnMongoDB');

  if Assigned(AAST.Insert) and (not AAST.Insert.IsEmpty) then
    Result := SerializeMongoInsert(AAST)
  else if Assigned(AAST.Update) and (not AAST.Update.IsEmpty) then
    Result := SerializeMongoUpdate(AAST)
  else if Assigned(AAST.Delete) and (not AAST.Delete.IsEmpty) then
    Result := SerializeMongoDelete(AAST)
  else if not Assigned(AAST.Select) or (AAST.Select.TableNames.Count = 0) then
    Result := '{}'
  else
  begin
    LCollection := NormalizeFieldName(AAST.Select.TableNames[0].Name);
    if LCollection = '' then
      LCollection := Trim(AAST.Select.TableNames[0].Name);

    if Assigned(AAST.Where) and not AAST.Where.Expression.IsEmpty then
      LFilter := ParseExpressionToMongo(AAST, AAST.Where.Expression.Serialize)
    else
      LFilter := '{}';

    LProjection := BuildProjection(AAST);
    LSort := BuildSort(AAST);
    LLimit := -1;
    LSkip := -1;
    for LIdx := 0 to AAST.Select.Qualifiers.Count - 1 do
      case AAST.Select.Qualifiers[LIdx].Qualifier of
        sqFirst: LLimit := AAST.Select.Qualifiers[LIdx].Value;
        sqSkip: LSkip := AAST.Select.Qualifiers[LIdx].Value;
      end;

    Result := '{'
      + JsonString('find') + ':' + JsonString(LCollection) + ','
      + JsonString('filter') + ':' + LFilter + ','
      + JsonString('projection') + ':' + LProjection;

    if LSort <> '' then
      Result := Result + ',' + JsonString('sort') + ':' + LSort;
    if LLimit >= 0 then
      Result := Result + ',' + JsonString('limit') + ':' + IntToStr(LLimit);
    if LSkip >= 0 then
      Result := Result + ',' + JsonString('skip') + ':' + IntToStr(LSkip);

    Result := Result + '}';
  end;

  Result := Result + DialectOnlySqlSuffix(AAST);
end;

end.





