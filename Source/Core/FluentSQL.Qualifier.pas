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

unit FluentSQL.Qualifier;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  /// <summary>
  ///   Os limites de paginacao que o usuario pediu, ja separados do sqDistinct e
  ///   ja distinguindo "pediu zero" de "nao pediu". Existe porque os nove drivers
  ///   repetiam o mesmo laco sobre FQualifiers, cada um com um bug diferente:
  ///   quatro esqueciam o sqDistinct e levantavam excecao crua ao ver DISTINCT
  ///   (MySQL, PostgreSQL, Oracle e DB2 explodiam ate SEM paginacao nenhuma),
  ///   tres nao inicializavam as variaveis e liam lixo de pilha, e as mensagens de
  ///   erro citavam o nome de outro driver.
  ///
  ///   HasFirst/HasSkip nao sao (First &lt;&gt; 0): First(0) e Skip(0) sao pedidos
  ///   legitimos e diferentes de "sem clausula".
  /// </summary>
  TFluentSQLPagination = record
    HasFirst: Boolean;
    HasSkip: Boolean;
    First: Integer;
    Skip: Integer;
  end;

  TFluentSQLSelectQualifier = class(TInterfacedObject, IFluentSQLSelectQualifier)
  strict private
    FQualifier: TSelectQualifierType;
    FValue: Integer;
    function _GetQualifier: TSelectQualifierType;
    function _GetValue: Integer;
    procedure _SetQualifier(const Value: TSelectQualifierType);
    procedure _SetValue(const Value: Integer);
  public
    property Qualifier: TSelectQualifierType read _GetQualifier write _SetQualifier;
    property Value: Integer read _GetValue write _SetValue;
  end;

  TFluentSQLSelectQualifiers = class(TInterfacedObject, IFluentSQLSelectQualifiers)
  protected
    FExecutingPagination: Boolean;
    FQualifiers: TList<IFluentSQLSelectQualifier>;
    function _GetQualifier(AIdx: Integer): IFluentSQLSelectQualifier;
    /// <summary>
    ///   Le a lista de qualificadores uma unica vez e devolve os limites pedidos.
    ///   sqDistinct e ignorado DE PROPOSITO: quem o emite e SerializeDistinct, e
    ///   tratar DISTINCT como qualificador desconhecido aqui era o que fazia
    ///   Select.Distinct levantar excecao em quatro dialetos.
    ///   Qualquer outro membro do enum vira EFluentSQLQualifierNotSupported, com
    ///   o nome do dialeto que recusou.
    /// </summary>
    function _Pagination(const ADialect: String): TFluentSQLPagination;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: IFluentSQLSelectQualifier; overload;
    procedure Add(AQualifier: IFluentSQLSelectQualifier); overload;
    procedure Clear;
    function ExecutingPagination: Boolean;
    function RequestsZeroRows: Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
    function SerializePagination: String; virtual; abstract;
    function SerializeDistinct: String;
    property Qualifiers[AIdx: Integer]: IFluentSQLSelectQualifier read _GetQualifier; default;
  end;

implementation

uses
  FluentSQL.Utils;

{ TFluentSQLSelectQualifiers }

function TFluentSQLSelectQualifiers.Add: IFluentSQLSelectQualifier;
begin
  Result := TFluentSQLSelectQualifier.Create;
end;

procedure TFluentSQLSelectQualifiers.Add(AQualifier: IFluentSQLSelectQualifier);
begin
  FQualifiers.Add(AQualifier);
  if AQualifier.Qualifier in [sqFirst, sqSkip] then
    FExecutingPagination := True;
end;

procedure TFluentSQLSelectQualifiers.Clear;
begin
  FExecutingPagination := False;
  FQualifiers.Clear;
end;

function TFluentSQLSelectQualifiers.Count: Integer;
begin
  Result := FQualifiers.Count;
end;

constructor TFluentSQLSelectQualifiers.Create;
begin
  FExecutingPagination := False;
  FQualifiers := TList<IFluentSQLSelectQualifier>.Create;
end;

destructor TFluentSQLSelectQualifiers.Destroy;
begin
  FQualifiers.Free;
  inherited;
end;

function TFluentSQLSelectQualifiers.ExecutingPagination: Boolean;
begin
  Result := FExecutingPagination;
end;

function TFluentSQLSelectQualifiers._GetQualifier(AIdx: Integer): IFluentSQLSelectQualifier;
begin
  Result := FQualifiers[AIdx];
end;

/// <summary>
///   Nao usa _Pagination de proposito: _Pagination levanta para qualificador
///   desconhecido, e esta pergunta e feita durante a montagem do SELECT, antes
///   de o driver decidir o que sabe emitir. Aqui so interessa saber se existe um
///   sqFirst valendo zero.
/// </summary>
function TFluentSQLSelectQualifiers.RequestsZeroRows: Boolean;
var
  LFor: Integer;
begin
  Result := False;
  for LFor := 0 to Count - 1 do
    if (FQualifiers[LFor].Qualifier = sqFirst) and (FQualifiers[LFor].Value = 0) then
      Exit(True);
end;

function TFluentSQLSelectQualifiers._Pagination(const ADialect: String): TFluentSQLPagination;
var
  LFor: Integer;
begin
  Result.HasFirst := False;
  Result.HasSkip := False;
  Result.First := 0;
  Result.Skip := 0;
  for LFor := 0 to Count - 1 do
  begin
    case FQualifiers[LFor].Qualifier of
      sqFirst:
        begin
          Result.First := FQualifiers[LFor].Value;
          Result.HasFirst := True;
        end;
      sqSkip:
        begin
          Result.Skip := FQualifiers[LFor].Value;
          Result.HasSkip := True;
        end;
      sqDistinct:
        Continue;
    else
      raise EFluentSQLQualifierNotSupported.Create(
        Ord(FQualifiers[LFor].Qualifier), ADialect);
    end;
  end;
end;

function TFluentSQLSelectQualifiers.IsEmpty: Boolean;
begin
  Result := (Count = 0);
end;

function TFluentSQLSelectQualifiers.SerializeDistinct: String;
var
  LFor: Integer;
begin
  inherited;
  Result := '';
  for LFor := 0 to Count -1 do
  begin
    if FQualifiers[LFor].Qualifier = sqDistinct then
    begin
      Result := TUtils.Concat([Result, 'DISTINCT']);
      Exit;
    end;
  end;
end;

{ TFluentSQLSelectQualifier }

function TFluentSQLSelectQualifier._GetQualifier: TSelectQualifierType;
begin
  Result := FQualifier;
end;

function TFluentSQLSelectQualifier._GetValue: Integer;
begin
  Result := FValue;
end;

procedure TFluentSQLSelectQualifier._SetQualifier(const Value: TSelectQualifierType);
begin
  FQualifier := Value;
end;

procedure TFluentSQLSelectQualifier._SetValue(const Value: Integer);
begin
  FValue := Value;
end;

end.




