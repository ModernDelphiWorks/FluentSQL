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
    function Modulus(const AValue, ADivisor: String): String; override;
    function Abs(const AValue: String): String; override;
    function Schema(const AName: string): IFluentSQLSchemaBuilder; override;
    function Merge: IFluentSQLMerge; override;
  end;

implementation

uses FluentSQL;

{ TFluentSQLFunctions

  ============================================================================
  DOIS PADROES CONVIVEM AQUI. LEIA ANTES DE ADICIONAR UMA FUNCAO NOVA.
  ============================================================================

  PADRAO A - o core emite SQL ANSI direto, sem consultar o driver.
    Ex.: Result := 'COUNT(' + AValue + ')';
    Use APENAS quando a forma ANSI for comprovadamente valida nos 7 dialetos
    ativos (Firebird, MSSQL, MySQL, SQLite, Oracle, PostgreSQL, MongoDB).
    Hoje em A: Count, Sum, Min, Max, Average, Abs, Upper, Lower, Cast, Round,
               Floor.
    Custo de manutencao: zero. Risco: se um dialeto divergir, o core emite SQL
    invalido EM SILENCIO - foi exatamente o que aconteceu com CEIL no MSSQL.

  PADRAO B - o core delega ao driver registrado.
    Ex.: Result := FRegister.Functions(FDatabase).Trim(AValue);
    Obrigatorio sempre que UM dialeto que seja divirja da forma ANSI.
    Hoje em B: Length, Ceil, Trim, LTrim, RTrim, SubString, Concat, Coalesce,
               Date, Day, Month, Year, CurrentDate, CurrentTimestamp, Modulus.

  ADICIONAR UMA FUNCAO NO PADRAO B custa 6 pontos de toque, TODOS obrigatorios:
    1. FluentSQL.Interfaces.pas ......... assinatura em IFluentSQLFunctions
    2. FluentSQL.FunctionsAbstract.pas .. virtual + corpo que levanta
    3. FluentSQL.Functions.pas .......... override delegando ao FRegister
    4. CADA Source\Drivers\FluentSQL.Functions*.pas ... implementacao real
    5. FluentSQL.pas .................... metodo publico (_AssertSection/_AssertHaveName)
    6. MongoDB ......................... ver nota abaixo

  Pular o item 4 compila limpo e explode em EAbstractError na primeira consulta.

  NOTA MONGODB: TFluentSQLFunctionsMongoDB NAO deve emitir MQL para funcoes
  escalares. O FluentSQL.SerializeMongoDB.pas so sabe consumir nome de campo e
  os prefixos de agregacao ('AGG:' e as formas ANSI 'SUM('/'COUNT('/...). Um
  documento MQL do tipo $toUpper devolvido daqui seria tratado como nome de
  campo e viraria MQL invalido em silencio. Por isso as escalares levantam
  EFluentSQLFunctionNotSupported: erro honesto e melhor que MQL indefensavel. }

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

// PADRAO B: nao ha forma ANSI unica. MSSQL usa LEN, Firebird usa CHAR_LENGTH.
function TFluentSQLFunctions.Length(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Length(AValue);
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

// PADRAO B: T-SQL nao tem CEIL, so CEILING.
function TFluentSQLFunctions.Ceil(const AValue: String): String;
begin
  Result := FRegister.Functions(FDatabase).Ceil(AValue);
end;

function TFluentSQLFunctions.Schema(const AName: string): IFluentSQLSchemaBuilder;
begin
  Result := FluentSQL.Schema(FDatabase).Schema(AName);
end;

function TFluentSQLFunctions.Merge: IFluentSQLMerge;
begin
  // Forward to a helper or implement here. For now, we'll need a way to get a Merge builder.
  // In FluentSQL.pas we will add a Query(FDatabase).Merge entry if needed, 
  // but Func.Merge is the required entry point.
  // We'll implement TFluentSQLMerge in FluentSQL.pas and provide a factory.
  Result := TFluentSQL.Create(FDatabase).Merge;
end;

end.




