{
  ------------------------------------------------------------------------------
  FluentSQL
  Database-agnostic fluent SQL/MQL script generation library for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

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
    class function _StringVarRecAsParam(const AValue: TVarRec;
      const ASQLParams: IFluentSQLParams): String;
    class function _ArrayOfConstToSql(const AParams: array of const;
      const ASQLParams: IFluentSQLParams; const AStringIsValue: Boolean): String;
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
    /// <summary>
    /// Mesmo layout textual de SqlArrayOfConstToParameterizedSql, mas para posicao
    /// que e comprovadamente VALOR - onde a RN-P3 nao vale, porque ali string nao
    /// tem como ser fragmento de SQL: TODO elemento vira parametro, inclusive
    /// string. Usado por SetValue/Values(array of const), cujo array e o lado
    /// direito de "COLUNA = ..." e nunca uma expressao.
    /// </summary>
    class function SqlArrayOfConstToParameterizedValue(const AParams: array of const;
      const ASQLParams: IFluentSQLParams): String;
    class function DateToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDate): String;
    class function DateTimeToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TDateTime): String;
    class function GuidStrToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: TGUID): String;
    class function BooleanToSQLFormat(const ADriverName: TFluentSQLDriver; const AValue: Boolean): string;
    class procedure SqlArrayOfConstToNameValuePairs(const AParams: array of const;
      const APairs: IFluentSQLNameValuePairs; const ASQLParams: IFluentSQLParams);
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

/// <summary>
///   Converte um TVarRec que NAO e escalar reconhecido (tipicamente string) em
///   placeholder de parametro. So deve ser chamado em posicao que e comprovadamente
///   VALOR - nunca em posicao que possa ser fragmento de SQL.
///
///   O ramo sem ASQLParams e defensivo e inalcancavel pela API publica:
///   TFluentSQLAST cria FParams no construtor (FluentSQL.Ast.pas:133) e nunca o
///   zera antes do Destroy, entao todo caminho que chega aqui vindo de
///   TFluentSQL.Query tem lista de parametros. Ainda assim ele NAO devolve o texto
///   cru: delimita e escapa com QuotedStr (dobra a aspa simples, que e o escape
///   padrao ISO aceito por todos os dialetos suportados). Devolver cru ali seria
///   reabrir exatamente o buraco que esta funcao existe para fechar.
/// </summary>
class function TUtils._StringVarRecAsParam(const AValue: TVarRec;
  const ASQLParams: IFluentSQLParams): String;
begin
  // vtPointer e o que o compilador produz para um `nil` escrito num array of
  // const. _VarRecToString o mapeia por IntToHex e devolveria a string
  // '00000000', que iria para o banco como DADO da coluna - corrupcao
  // silenciosa, e nao o NULL que quem escreveu `nil` obviamente queria.
  //
  // O par nome/valor NAO tem forma de exprimir NULL: o slot par e sempre
  // ligado como parametro, e nao existe hoje marcador de nulidade nesta API.
  // Entre gravar lixo calado e recusar a chamada, a resposta conservadora e
  // recusar - mesma classe e mesmo espirito da guarda de contagem impar
  // abaixo. Dar semantica de NULL ao `nil` e decisao de convencao, nao
  // conserto de defeito, e por isso nao foi feita aqui.
  if AValue.VType = vtPointer then
    raise EArgumentException.Create(
      'Valor nil em posicao de valor: o par nome/valor nao exprime NULL. ' +
      'Antes, o nil virava a string ''00000000'' e era gravado como dado. ' +
      'Se a coluna deve ficar NULL, omita-a da lista de pares.');

  if Assigned(ASQLParams) then
    Result := ASQLParams.Add(_VarRecToString(AValue), dftString)
  else
    Result := QuotedStr(_VarRecToString(AValue));
end;

/// <summary>
///   Motor unico de SqlArrayOfConstToParameterizedSql e
///   SqlArrayOfConstToParameterizedValue. A UNICA diferenca entre os dois e o
///   que fazer com o elemento que nao e escalar reconhecido (tipicamente
///   string): em posicao de EXPRESSAO ele e fragmento de SQL e segue literal
///   (RN-P3); em posicao de VALOR ele e dado e vira parametro.
/// </summary>
class function TUtils._ArrayOfConstToSql(const AParams: array of const;
  const ASQLParams: IFluentSQLParams; const AStringIsValue: Boolean): String;
var
  LFor: Integer;
  LastCh: Char;
  LParam: String;
begin
  if (not Assigned(ASQLParams)) and (not AStringIsValue) then
    Exit(SqlParamsToStr(AParams));
  Result := '';
  for LFor := Low(AParams) to High(AParams) do
  begin
    if not _TryVarRecAsParam(AParams[LFor], ASQLParams, LParam) then
    begin
      if AStringIsValue then
        LParam := _StringVarRecAsParam(AParams[LFor], ASQLParams)
      else
        LParam := _VarRecToString(AParams[LFor]);
    end;
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

class function TUtils.SqlArrayOfConstToParameterizedSql(const AParams: array of const;
  const ASQLParams: IFluentSQLParams): String;
begin
  Result := _ArrayOfConstToSql(AParams, ASQLParams, False);
end;

class function TUtils.SqlArrayOfConstToParameterizedValue(const AParams: array of const;
  const ASQLParams: IFluentSQLParams): String;
begin
  Result := _ArrayOfConstToSql(AParams, ASQLParams, True);
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
    dbnInterbase: Result := FormatDateTime('mm/dd/yyyy hh:nn:ss', AValue);

    dbnMSSQL,
    dbnMySQL,
    dbnSQLite,
    dbnDB2,
    dbnOracle,
    dbnPostgreSQL,
    dbnMongoDB: Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', AValue);
  end;
  Result := QuotedStr(Result);
end;

class function TUtils.DateToSQLFormat(const ADriverName: TFluentSQLDriver;
  const AValue: TDate): String;
begin
  case ADriverName of
    dbnFirebird,
    dbnInterbase: Result := FormatDateTime('mm/dd/yyyy', AValue);

    dbnMSSQL,
    dbnMySQL,
    dbnSQLite,
    dbnDB2,
    dbnOracle,
    dbnPostgreSQL,
    dbnMongoDB: Result := FormatDateTime('yyyy-mm-dd', AValue);
  end;
  Result := QuotedStr(Result);
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

class function TUtils.BooleanToSQLFormat(const ADriverName: TFluentSQLDriver;
  const AValue: Boolean): string;
begin
  case ADriverName of
    dbnMSSQL:
      if AValue then Result := '1' else Result := '0';
  else
    if AValue then Result := 'True' else Result := 'False';
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

class procedure TUtils.SqlArrayOfConstToNameValuePairs(const AParams: array of const;
  const APairs: IFluentSQLNameValuePairs; const ASQLParams: IFluentSQLParams);
var
  I: Integer;
  LName: string;
  LValue: string;
begin
  if not Assigned(APairs) then exit;

  // O array e uma lista de PARES: nome, valor, nome, valor... Contagem impar
  // significa um nome sem valor, e isso nao tem serializacao possivel - saia
  // "VALUES (:p1, )" ou "SET [NOME] = ", ambos recusados pelo motor
  // (SQL Server 2022: Msg 102, Incorrect syntax near ')' e near ';').
  //
  // E erro de programacao do chamador, nao dado do usuario, entao a resposta
  // certa e falhar alto e cedo. Emitir SQL quebrado em silencio nao sobrevive
  // ao padrao desta biblioteca: ela gera 100% texto, e texto invalido so
  // aparece no motor do consumidor, longe da linha que o causou.
  //
  // EArgumentException e a mesma classe que FluentSQL.DDL.pas ja usa para
  // chamada malformada (DDL.pas:908 e :915) - nao inventa vocabulario novo.
  //
  // LISTA VAZIA cai na MESMA regra, e nao no "caso par que passa limpo" que a
  // primeira versao desta guarda afirmou. Zero pares serializa como
  // "UPDATE SET ;" ou "INSERT;", e nenhum dos quatro dialetos que tem MERGE
  // (MSSQL, Oracle, Firebird, PostgreSQL) aceita qualquer das duas - a lista de
  // atribuicoes do UPDATE e obrigatoria, e o INSERT do MERGE exige VALUES(...)
  // ou DEFAULT VALUES. Medido em motor real: ver test.merge.mssql.sql, secao
  // LISTA VAZIA / FORMA SEM ARGUMENTOS.
  if Length(AParams) = 0 then
    raise EArgumentException.Create(
      'Lista de pares nome/valor vazia. UPDATE sem atribuicao e INSERT sem ' +
      'colunas nao sao serializaveis: sairia "UPDATE SET ;" ou "INSERT;", ' +
      'recusado por todos os dialetos com MERGE. Passe ao menos um par ' +
      '(''COLUNA'', <valor>), ou use .Delete se a intencao era outra acao.');

  if Odd(Length(AParams)) then
    raise EArgumentException.CreateFmt(
      'Lista de pares nome/valor malformada: %d elementos. ' +
      'A lista tem de alternar nome e valor (''COLUNA'', <valor>, ...), ' +
      'portanto a contagem tem de ser par. O ultimo nome ficou sem valor.',
      [Length(AParams)]);

  I := Low(AParams);
  while I <= High(AParams) do
  begin
    // Slot IMPAR: nome de coluna. E identificador, nunca parametro - um :pN aqui
    // produziria SQL sintaticamente invalido. Segue literal, como em SetValue.
    //
    // FRONTEIRA CONHECIDA: por ser identificador, este slot NAO passa por
    // parametro, e o delimitador do dialeto nao e escapado pelos QuotedName /
    // Quote atuais. Medido em SQL Server 2022 com nome de coluna
    // "NOME] = 'x'; DROP TABLE USERS; --": a tabela foi dropada. Vale igual na
    // base e nesta branch - nao e regressao. Escape de identificador e decisao
    // de arquitetura propria e esta fora do escopo aqui.
    LName := _VarRecToString(AParams[I]);
    Inc(I);
    if I <= High(AParams) then
    begin
      // Slot PAR: VALOR. Ao contrario de SqlArrayOfConstToParameterizedSql - onde
      // a RN-P3 trata string como fragmento de SQL (identificador, operador) - aqui
      // o array e estritamente uma lista de pares nome/valor: o slot par NAO tem
      // como ser fragmento, so pode ser dado. Portanto TODO valor vira parametro,
      // inclusive string. Deixar a string cair em _VarRecToString colocava o texto
      // do usuario cru dentro do SQL (sem aspas, sem escape) - SQL invalido no caso
      // benigno e injecao no caso hostil.
      //
      // Isto alinha o overload array of const com o overload tipado
      // SetValue(const AColumnName, AColumnValue: String), que ja parametrizava:
      // nao e convencao nova, e a convencao que ja existia sendo aplicada aqui.
      if not _TryVarRecAsParam(AParams[I], ASQLParams, LValue) then
        LValue := _StringVarRecAsParam(AParams[I], ASQLParams);
      Inc(I);
    end
    else
      // Inalcancavel: a guarda de contagem impar no topo ja saiu com excecao.
      // Fica como rede, e nao como comportamento - se algum dia esta linha
      // executar, e porque a guarda foi removida por engano.
      LValue := '';

    with APairs.Add do
    begin
      Name := LName;
      Value := LValue;
    end;
  end;
end;

end.


