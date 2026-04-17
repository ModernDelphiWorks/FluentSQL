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

function NormalizeFieldName(const AFieldName: String; AIncludeAlias: Boolean = False): String;
var
  LDotPos: Integer;
begin
  Result := Trim(AFieldName);
  LDotPos := LastDelimiter('.', Result);
  if (Pos('.', Result) > 0) and (not AIncludeAlias) then
    Result := Copy(Result, LDotPos + 1, MaxInt);
  
  Result := StringReplace(Result, '`', '', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  Result := StringReplace(Result, '[', '', [rfReplaceAll]);
  Result := StringReplace(Result, ']', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

function MongoField(const AFieldName: String): String;
begin
  Result := NormalizeFieldName(AFieldName);
  if (Result <> '') and (Result <> '*') and (Result[1] <> '$') then
    Result := '$' + Result;
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

procedure ParseJoinCondition(const ACondition: String; const AJoinedAlias: String; const AMainTable, AMainAlias: String; out ALocalField, AForeignField: String);
var
  LExpr: String;
  LPos: Integer;
  LPart1, LPart2: String;
  LIsMain: Boolean;
begin
  LExpr := Trim(ACondition);
  LPos := Pos('=', LExpr);
  if LPos = 0 then
    raise EFluentSQLMongoDBSerialize.CreateFmt('MongoDB Join: condição inválida (esperado "="): %s', [ACondition]);

  LPart1 := Trim(Copy(LExpr, 1, LPos - 1));
  LPart2 := Trim(Copy(LExpr, LPos + 1, MaxInt));

  // Determine which side belongs to the joined collection (foreignField)
  if StartsText(AJoinedAlias + '.', LPart1) then
  begin
    AForeignField := NormalizeFieldName(LPart1);
    ALocalField := LPart2;
  end
  else if StartsText(AJoinedAlias + '.', LPart2) then
  begin
    AForeignField := NormalizeFieldName(LPart2);
    ALocalField := LPart1;
  end
  else
  begin
    // Fallback logic
    if Pos('.', LPart2) > 0 then
    begin
      AForeignField := NormalizeFieldName(LPart2);
      ALocalField := LPart1;
    end
    else
    begin
      AForeignField := NormalizeFieldName(LPart2);
      ALocalField := LPart1;
    end;
  end;

  // Process ALocalField: preserve alias only if NOT the main table identity (chained joins)
  LIsMain := False;
  if (AMainAlias <> '') and StartsText(AMainAlias + '.', ALocalField) then
    LIsMain := True
  else if (AMainTable <> '') and StartsText(AMainTable + '.', ALocalField) then
    LIsMain := True;

  if LIsMain then
    ALocalField := NormalizeFieldName(ALocalField)
  else if Pos('.', ALocalField) > 0 then
    ALocalField := NormalizeFieldName(ALocalField, True)
  else
    ALocalField := NormalizeFieldName(ALocalField);

  AForeignField := NormalizeFieldName(AForeignField);
end;

function BuildProjection(const AAST: IFluentSQLAST; AIsAggregation: Boolean = False): String;
var
  LIdx: Integer;
  LField: String;
  LAlias: String;
  LFirst: Boolean;
  LSource: String;
  LProjected: TStringList;
  LStages: String;
  LHasJoins: Boolean;
  LColName: String;
  LDotPos: Integer;
  LTableAlias: String;
begin
  if not Assigned(AAST.Select) then
    Exit('{}');

  LHasJoins := Assigned(AAST.Joins) and (not AAST.Joins.IsEmpty);
  LProjected := TStringList.Create;
  try
    for LIdx := 0 to AAST.Select.Columns.Count - 1 do
    begin
      LField := AAST.Select.Columns[LIdx].Name;
      LAlias := AAST.Select.Columns[LIdx].Alias;

      if AIsAggregation and (StartsText('AGG:', LField) or
                             StartsText('SUM(', LField) or
                             StartsText('COUNT(', LField) or
                             StartsText('MIN(', LField) or
                             StartsText('MAX(', LField) or
                             StartsText('AVG(', LField) or
                             StartsText('AVERAGE(', LField)) then
      begin
        if LAlias = '' then LAlias := 'agg' + IntToStr(LIdx);
        LProjected.Add(JsonString(LAlias) + ':1');
        Continue;
      end;

      LColName := NormalizeFieldName(LField);
      if (LColName = '') or SameText(LColName, '*') then
        Continue;

      // Se houver ( e no for agregado, pula (pode ser subquery no suportada)
      if (Pos('(', LColName) > 0) then
        Continue;

      if LAlias = '' then LAlias := LColName;

      if AIsAggregation then
      begin
        if (AAST.GroupBy.Columns.Count > 0) then
        begin
          // Map _id back to field name if it was grouped
          LSource := '$_id';
          if AAST.GroupBy.Columns.Count > 1 then
            LSource := '$_id.' + LColName;
          
          LProjected.Add(JsonString(LAlias) + ':' + JsonString(LSource));
        end
        else if LHasJoins then
        begin
        LDotPos := Pos('.', LField);
        if LDotPos > 0 then
        begin
          LTableAlias := Copy(LField, 1, LDotPos - 1);
          // If the alias refers to the main table and is not renamed, use :1
          if (AAST.Select.TableNames.Count > 0) and SameText(LTableAlias, AAST.Select.TableNames[0].Alias) then
          begin
            if SameText(LAlias, LColName) then
               LProjected.Add(JsonString(LAlias) + ':1')
            else
               LProjected.Add(JsonString(LAlias) + ':' + JsonString('$' + LColName));
          end
          else
            LProjected.Add(JsonString(LAlias) + ':' + JsonString('$' + LTableAlias + '.' + LColName));
        end
        else
        begin
          if SameText(LAlias, LColName) then
            LProjected.Add(JsonString(LAlias) + ':1')
          else
            LProjected.Add(JsonString(LAlias) + ':' + JsonString('$' + LColName));
        end;
      end
      else
        LProjected.Add(JsonString(LAlias) + ':1');
      end
      else
        LProjected.Add(JsonString(LAlias) + ':1');
    end;

    if AIsAggregation then
      LProjected.Add(JsonString('_id') + ':0');

    LStages := '';
    for LIdx := 0 to LProjected.Count - 1 do
    begin
      if LIdx > 0 then LStages := LStages + ',';
      LStages := LStages + LProjected[LIdx];
    end;
    Result := '{' + LStages + '}';
  finally
    LProjected.Free;
  end;
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

function IsAggregation(const AAST: IFluentSQLAST): Boolean;
var
  LIdx: Integer;
  LName: String;
begin
  Result := False;
  if not Assigned(AAST.Select) then
    Exit;

  if (Assigned(AAST.GroupBy) and (not AAST.GroupBy.Columns.IsEmpty)) or
     (Assigned(AAST.Having) and (not AAST.Having.Expression.IsEmpty)) or
     (Assigned(AAST.Joins) and (not AAST.Joins.IsEmpty)) or
     (AAST.UnionType <> '') then
    Exit(True);

  for LIdx := 0 to AAST.Select.Columns.Count - 1 do
  begin
    LName := AAST.Select.Columns[LIdx].Name;
    if StartsText('AGG:', LName) or
       StartsText('SUM(', LName) or
       StartsText('COUNT(', LName) or
       StartsText('MIN(', LName) or
       StartsText('MAX(', LName) or
       StartsText('AVG(', LName) or
       StartsText('AVERAGE(', LName) then
      Exit(True);
  end;
end;

function ParseAggregateToMongo(const AAgg: String): String;
var
  LParts: TArray<String>;
  LFunc: String;
  LField: String;
  LTemp: String;
begin
  LTemp := AAgg;
  if LTemp.ToUpper.StartsWith('AGG:') then
  begin
    LTemp := LTemp.Substring(4);
    LParts := LTemp.Split([':']);
  end
  else
  begin
    // Format: FUNCTION(FIELD)
    LParts := LTemp.Split(['(', ')']);
  end;

  if Length(LParts) < 2 then
    Exit('{}');

  LFunc := LParts[0].Trim;
  LField := LParts[1].Trim;

  if SameText(LFunc, 'COUNT') then
    Result := '{"$sum":1}'
  else if SameText(LFunc, 'SUM') then
    Result := '{"$sum":' + JsonString(MongoField(LField)) + '}'
  else if SameText(LFunc, 'MIN') then
    Result := '{"$min":' + JsonString(MongoField(LField)) + '}'
  else if SameText(LFunc, 'MAX') then
    Result := '{"$max":' + JsonString(MongoField(LField)) + '}'
  else if SameText(LFunc, 'AVG') or SameText(LFunc, 'AVERAGE') then
    Result := '{"$avg":' + JsonString(MongoField(LField)) + '}'
  else
    Result := '{}';
end;

function BuildGroupStage(const AAST: IFluentSQLAST): String;
var
  LIdx: Integer;
  LFirst: Boolean;
  LId: String;
  LField: String;
  LAlias: String;
  LName: String;
begin
  // Build _id
  if AAST.GroupBy.Columns.Count = 0 then
    LId := 'null'
  else if AAST.GroupBy.Columns.Count = 1 then
    LId := JsonString(MongoField(AAST.GroupBy.Columns[0].Name))
  else
  begin
    LId := '{';
    for LIdx := 0 to AAST.GroupBy.Columns.Count - 1 do
    begin
      if LIdx > 0 then LId := LId + ',';
      LField := NormalizeFieldName(AAST.GroupBy.Columns[LIdx].Name);
      LId := LId + JsonString(LField) + ':' + JsonString(MongoField(LField));
    end;
    LId := LId + '}';
  end;

  Result := '{"$group":{"_id":' + LId;

  // Build accumulators from Select
  for LIdx := 0 to AAST.Select.Columns.Count - 1 do
  begin
    LName := AAST.Select.Columns[LIdx].Name;
    if StartsText('AGG:', LName) or
       StartsText('SUM(', LName) or
       StartsText('COUNT(', LName) or
       StartsText('MIN(', LName) or
       StartsText('MAX(', LName) or
       StartsText('AVG(', LName) or
       StartsText('AVERAGE(', LName) then
    begin
      LAlias := AAST.Select.Columns[LIdx].Alias;
      if LAlias = '' then
        LAlias := 'agg' + IntToStr(LIdx);
      Result := Result + ',' + JsonString(LAlias) + ':' + ParseAggregateToMongo(LName);
    end;
  end;

  Result := Result + '}}';
end;

function SerializeMongoPipeline(const AAST: IFluentSQLAST): String;
var
  LPipeline: TStringList;
  LIdx: Integer;
  LSort: String;
  LLimit: Integer;
  LSkip: Integer;
  LJoin: IFluentSQLJoin;
  LTargetTable: String;
  LTargetAlias: String;
  LLocalField: String;
  LForeignField: String;
  LMainAlias: String;
  LMainTable: String;
  LPreserve: String;
  LCurrentAST: IFluentSQLAST;
  LUnionAST: IFluentSQLAST;
  LUnionPipeline: String;
  LTargetColl: String;
begin
  LPipeline := TStringList.Create;
  try
    // 1. $match (WHERE)
    if Assigned(AAST.Where) and not AAST.Where.Expression.IsEmpty then
      LPipeline.Add('{"$match":' + ParseExpressionToMongo(AAST, AAST.Where.Expression.Serialize) + '}');

    // 1.1 $lookup / $unwind (Joins)
    if Assigned(AAST.Joins) and (not AAST.Joins.IsEmpty) then
    begin
      for LIdx := 0 to AAST.Joins.Count - 1 do
      begin
        LJoin := AAST.Joins[LIdx] as IFluentSQLJoin;
        LTargetTable := NormalizeFieldName(LJoin.JoinedTable.Name);
        LTargetAlias := LJoin.JoinedTable.Alias;
        if LTargetAlias = '' then LTargetAlias := LTargetTable;

        LMainAlias := '';
        LMainTable := '';
        if Assigned(AAST.Select) and (AAST.Select.TableNames.Count > 0) then
        begin
          LMainAlias := AAST.Select.TableNames[0].Alias;
          LMainTable := AAST.Select.TableNames[0].Name;
        end;

        ParseJoinCondition(LJoin.Condition.Serialize, LTargetAlias, LMainTable, LMainAlias, LLocalField, LForeignField);

        LPipeline.Add('{"$lookup":{'
          + '"from":' + JsonString(LTargetTable) + ','
          + '"localField":' + JsonString(LLocalField) + ','
          + '"foreignField":' + JsonString(LForeignField) + ','
          + '"as":' + JsonString(LTargetAlias)
          + '}}');

        LPreserve := 'false';
        if LJoin.JoinType = jtLEFT then LPreserve := 'true';

        LPipeline.Add('{"$unwind":{'
          + '"path":' + JsonString('$' + LTargetAlias) + ','
          + '"preserveNullAndEmptyArrays":' + LPreserve
          + '}}');
      end;
    end;

    // 2. $group
    if Assigned(AAST.GroupBy) and (not AAST.GroupBy.Columns.IsEmpty) then
      LPipeline.Add(BuildGroupStage(AAST));

    // 3. $match (HAVING)
    if Assigned(AAST.Having) and not AAST.Having.Expression.IsEmpty then
      LPipeline.Add('{"$match":' + ParseExpressionToMongo(AAST, AAST.Having.Expression.Serialize) + '}');

    // 4. $project
    LPipeline.Add('{"$project":' + BuildProjection(AAST, True) + '}');

    // 4.1 $unionWith (Unions) - ESP-069
    LCurrentAST := AAST;
    while (LCurrentAST.UnionType <> '') and Assigned(LCurrentAST.UnionQuery) do
    begin
      LUnionAST := LCurrentAST.UnionQuery as IFluentSQLAST;
      LTargetColl := NormalizeFieldName(LUnionAST.Select.TableNames[0].Name);
      // Recursive call for the union branch pipeline
      LUnionPipeline := SerializeMongoPipeline(LUnionAST);

      LPipeline.Add('{"$unionWith":{'
        + '"coll":' + JsonString(LTargetColl) + ','
        + '"pipeline":' + LUnionPipeline
        + '}}');

      LCurrentAST := LUnionAST;
    end;

    // 5. $sort
    LSort := BuildSort(AAST);
    if LSort <> '' then
      LPipeline.Add('{"$sort":' + LSort + '}');

    // 6. $skip / 7. $limit
    LSkip := -1;
    LLimit := -1;
    for LIdx := 0 to AAST.Select.Qualifiers.Count - 1 do
      case AAST.Select.Qualifiers[LIdx].Qualifier of
        sqFirst: LLimit := AAST.Select.Qualifiers[LIdx].Value;
        sqSkip: LSkip := AAST.Select.Qualifiers[LIdx].Value;
      end;

    if LSkip >= 0 then
      LPipeline.Add('{"$skip":' + IntToStr(LSkip) + '}');
    if LLimit >= 0 then
      LPipeline.Add('{"$limit":' + IntToStr(LLimit) + '}');

    Result := '[';
    for LIdx := 0 to LPipeline.Count - 1 do
    begin
      if LIdx > 0 then Result := Result + ',';
      Result := Result + LPipeline[LIdx];
    end;
    Result := Result + ']';
  finally
    LPipeline.Free;
  end;
end;

function SerializeMongoAggregate(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LPipeline: String;
begin
  LCollection := NormalizeFieldName(AAST.Select.TableNames[0].Name);
  if LCollection = '' then
    LCollection := Trim(AAST.Select.TableNames[0].Name);

  LPipeline := SerializeMongoPipeline(AAST);

  Result := '{'
    + JsonString('aggregate') + ':' + JsonString(LCollection) + ','
    + JsonString('pipeline') + ':' + LPipeline + ','
    + JsonString('cursor') + ':{}'
    + '}';
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

function _HasAggregates(const AAST: IFluentSQLAST): Boolean;
var
  LIdx: Integer;
begin
  Result := False;
  for LIdx := 0 to AAST.Select.Columns.Count - 1 do
    if StartsText('AGG:', AAST.Select.Columns[LIdx].Name) or
       StartsText('SUM(', AAST.Select.Columns[LIdx].Name) or
       StartsText('COUNT(', AAST.Select.Columns[LIdx].Name) or
       StartsText('MIN(', AAST.Select.Columns[LIdx].Name) or
       StartsText('MAX(', AAST.Select.Columns[LIdx].Name) or
       StartsText('AVG(', AAST.Select.Columns[LIdx].Name) or
       StartsText('AVERAGE(', AAST.Select.Columns[LIdx].Name) then
      Exit(True);
end;

function TFluentSQLSerializerMongoDB.AsString(const AAST: IFluentSQLAST): String;
var
  LCollection: String;
  LFilter: String;
  LProjection: String;
  LSort: String;
  LLimit, LSkip: Integer;
  LIdx: Integer;
begin
  if (AAST.GroupBy.Columns.Count > 0) or 
     (Assigned(AAST.Joins) and (not AAST.Joins.IsEmpty)) or 
     _HasAggregates(AAST) then
  begin
    Result := SerializeMongoAggregate(AAST);
    Exit;
  end;

  LCollection := '';

  if (AAST.WithAlias <> '') or (FindTopLevelToken(AAST.UnionType, 'INTERSECT') > 0) then
    raise EFluentSQLMongoDBSerialize.Create('MongoDB serializer: CTE (WITH) and INTERSECT/EXCEPT are not supported for dbnMongoDB');

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
    if IsAggregation(AAST) then
    begin
      Result := SerializeMongoAggregate(AAST);
      Exit;
    end;

    LCollection := NormalizeFieldName(AAST.Select.TableNames[0].Name);
    if LCollection = '' then
      LCollection := Trim(AAST.Select.TableNames[0].Name);

    if Assigned(AAST.Where) and not AAST.Where.Expression.IsEmpty then
      LFilter := ParseExpressionToMongo(AAST, AAST.Where.Expression.Serialize)
    else
      LFilter := '{}';

    LProjection := BuildProjection(AAST, False);
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





