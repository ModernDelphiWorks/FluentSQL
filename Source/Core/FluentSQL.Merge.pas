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

unit FluentSQL.Merge;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  Classes,
  SysUtils,
  FluentSQL.Interfaces;

type
  TFluentSQLMerge = class;

  TFluentSQLMergeMatchClause = class(TInterfacedObject, IFluentSQLMergeMatchClauseDef,
    IFluentSQLMergeWhenMatched, IFluentSQLMergeWhenNotMatched)
  strict private
    FClauseType: IFluentSQLMergeMatchClauseType;
    FCondition: string;
    FActionType: IFluentSQLMergeActionType;
    FValues: IFluentSQLNameValuePairs;
    FParent: IFluentSQLMerge;
    FOwner: TFluentSQLMerge;
    FAST: IFluentSQLAST;
    /// <summary>
    ///   Fecha a clausula: fixa a acao e SO ENTAO a registra no MERGE pai.
    ///   Registrar aqui, e nao em WhenMatched/WhenNotMatched, e o que torna a
    ///   guarda de lista malformada util: quem engolir a EArgumentException e
    ///   chamar AsString nao encontra uma clausula pela metade no texto.
    /// </summary>
    function _Apply(const AAction: IFluentSQLMergeActionType): IFluentSQLMerge;
    /// <summary>
    ///   Mensagem unica das duas formas sem argumentos, que emitiam
    ///   "UPDATE SET ;" e "INSERT;" - invalidas em todo dialeto que tem MERGE.
    /// </summary>
    procedure _RaiseNoValues(const AMethod, ABrokenSql: string);
  public
    constructor Create(AParent: TFluentSQLMerge; const AAST: IFluentSQLAST; AType: IFluentSQLMergeMatchClauseType);
    destructor Destroy; override;
    { IFluentSQLMergeMatchClauseDef }
    function GetClauseType: IFluentSQLMergeMatchClauseType;
    function GetCondition: string;
    function GetActionType: IFluentSQLMergeActionType;
    function GetValues: IFluentSQLNameValuePairs;
    { IFluentSQLMergeWhenMatched }
    function Update(const AValues: array of const): IFluentSQLMerge; overload;
    function Update: IFluentSQLMerge; overload;
    function Delete: IFluentSQLMerge;
    { IFluentSQLMergeWhenNotMatched }
    function Insert(const AValues: array of const): IFluentSQLMerge; overload;
    function Insert: IFluentSQLMerge; overload;
    { DSL helpers }
    procedure SetCondition(const ACondition: string);
  end;

  TFluentSQLMerge = class(TInterfacedObject, IFluentSQLMerge, IFluentSQLMergeDef)
  strict private
    FAST: IFluentSQLAST;
    FDialect: TFluentSQLDriver;
    FTargetTable: string;
    FTargetAlias: string;
    FSourceTable: string;
    FSourceAlias: string;
    FSourceQuery: IFluentSQL;
    FOnCondition: string;
    FMatchedClauses: TInterfaceList;
    function _GetName: string;
  public
    /// <summary>
    ///   Chamado pela clausula quando (e so quando) ela ja tem acao valida.
    ///   Ver TFluentSQLMergeMatchClause._Apply.
    /// </summary>
    procedure _RegisterClause(const AClause: IFluentSQLMergeMatchClauseDef);
    constructor Create(const AAST: IFluentSQLAST);
    destructor Destroy; override;
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: string;
    { IFluentSQLMerge }
    function Into(const ATableName: string): IFluentSQLMerge; overload;
    function Into(const ATableName, AAlias: string): IFluentSQLMerge; overload;
    function Using(const ATableName: string): IFluentSQLMerge; overload;
    function Using(const ATableName, AAlias: string): IFluentSQLMerge; overload;
    function Using(const AQuery: IFluentSQL; const AAlias: string): IFluentSQLMerge; overload;
    function On(const ACondition: string): IFluentSQLMerge; overload;
    function On(const ACondition: array of const): IFluentSQLMerge; overload;
    function WhenMatched: IFluentSQLMergeWhenMatched;
    function WhenNotMatched: IFluentSQLMergeWhenNotMatched;
    function AsString: string;
    { IFluentSQLMergeDef }
    function GetDialect: TFluentSQLDriver;
    function GetTargetTable: string;
    function GetTargetAlias: string;
    function GetSourceTable: string;
    function GetSourceAlias: string;
    function GetSourceQuery: IFluentSQL;
    function GetOnCondition: string;
    function GetMatchedClauses: TInterfaceList;
  end;

implementation

uses
  FluentSQL.NameValue,
  FluentSQL.Utils,
  FluentSQL.Register;

{ TFluentSQLMergeMatchClause }

constructor TFluentSQLMergeMatchClause.Create(AParent: TFluentSQLMerge; const AAST: IFluentSQLAST; AType: IFluentSQLMergeMatchClauseType);
begin
  inherited Create;
  FParent := AParent;
  // Mesma instancia de FParent, na forma concreta, so para alcancar
  // _RegisterClause sem inchar IFluentSQLMerge com um metodo de uso interno.
  // A vida util e garantida por FParent, que conta referencia.
  FOwner := AParent;
  FAST := AAST;
  FClauseType := AType;
  FValues := TFluentSQLNameValuePairs.Create;
end;

destructor TFluentSQLMergeMatchClause.Destroy;
begin
  FValues := nil;
  inherited;
end;

function TFluentSQLMergeMatchClause._Apply(const AAction: IFluentSQLMergeActionType): IFluentSQLMerge;
begin
  FActionType := AAction;
  FOwner._RegisterClause(Self);
  Result := FParent;
end;

procedure TFluentSQLMergeMatchClause._RaiseNoValues(const AMethod, ABrokenSql: string);
begin
  raise EArgumentException.CreateFmt(
    '%s sem pares nome/valor nao e serializavel: sairia "%s". ' +
    'Nenhum dos dialetos que tem MERGE (MSSQL, Oracle, Firebird, PostgreSQL) ' +
    'aceita essa forma - a lista de atribuicoes do UPDATE e obrigatoria, e o ' +
    'INSERT do MERGE exige VALUES(...) ou DEFAULT VALUES. Use ' +
    '%s([''COLUNA'', <valor>, ...]).',
    [AMethod, ABrokenSql, AMethod]);
end;

function TFluentSQLMergeMatchClause.Delete: IFluentSQLMerge;
begin
  // DELETE e a unica acao que nao precisa de pares: "WHEN MATCHED THEN DELETE"
  // e completo por si so.
  Result := _Apply(matDelete);
end;

function TFluentSQLMergeMatchClause.GetActionType: IFluentSQLMergeActionType;
begin
  Result := FActionType;
end;

function TFluentSQLMergeMatchClause.GetClauseType: IFluentSQLMergeMatchClauseType;
begin
  Result := FClauseType;
end;

function TFluentSQLMergeMatchClause.GetCondition: string;
begin
  Result := FCondition;
end;

function TFluentSQLMergeMatchClause.GetValues: IFluentSQLNameValuePairs;
begin
  Result := FValues;
end;

function TFluentSQLMergeMatchClause.Insert(const AValues: array of const): IFluentSQLMerge;
begin
  // Valida ANTES de _Apply: se a lista for malformada a clausula nem chega a
  // ser registrada, e o AsString de quem engolir a excecao sai sem ela.
  TUtils.SqlArrayOfConstToNameValuePairs(AValues, FValues, FAST.Params);
  Result := _Apply(matInsert);
end;

function TFluentSQLMergeMatchClause.Insert: IFluentSQLMerge;
begin
  _RaiseNoValues('Insert', 'WHEN NOT MATCHED THEN INSERT;');
  Result := nil;
end;

procedure TFluentSQLMergeMatchClause.SetCondition(const ACondition: string);
begin
  FCondition := ACondition;
end;

function TFluentSQLMergeMatchClause.Update(const AValues: array of const): IFluentSQLMerge;
begin
  // Valida ANTES de _Apply - ver Insert(array of const).
  TUtils.SqlArrayOfConstToNameValuePairs(AValues, FValues, FAST.Params);
  Result := _Apply(matUpdate);
end;

function TFluentSQLMergeMatchClause.Update: IFluentSQLMerge;
begin
  _RaiseNoValues('Update', 'WHEN MATCHED THEN UPDATE SET ;');
  Result := nil;
end;

{ TFluentSQLMerge }

constructor TFluentSQLMerge.Create(const AAST: IFluentSQLAST);
begin
  inherited Create;
  FAST := AAST;
  FDialect := FAST.GetSerializationDialect;
  FMatchedClauses := TInterfaceList.Create;
  FAST._SetMerge(Self);
end;

destructor TFluentSQLMerge.Destroy;
begin
  FMatchedClauses.Free;
  inherited;
end;

function TFluentSQLMerge.AsString: string;
var
  LReg: TFluentSQLRegister;
begin
  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.Serialize(FDialect).AsString(FAST);
  finally
    LReg.Free;
  end;
end;

procedure TFluentSQLMerge.Clear;
begin
  FTargetTable := '';
  FTargetAlias := '';
  FSourceTable := '';
  FSourceAlias := '';
  FSourceQuery := nil;
  FOnCondition := '';
  FMatchedClauses.Clear;
end;

function TFluentSQLMerge.IsEmpty: Boolean;
begin
  Result := FTargetTable = '';
end;

/// <summary>
///   Um MERGE sem NENHUMA clausula WHEN nao e serializavel: sai so o cabecalho,
///   "MERGE INTO [T] AS [t] USING [S] AS [s] ON (...);", que e a instrucao pela
///   metade. Saia calado - o erro so aparecia no banco do consumidor.
///
///   Medido em execucao real antes de decidir a forma, e nenhum motor aceita:
///     SQL Server 2022 16.0.4265.3  Msg 102, Incorrect syntax near ';'
///     Oracle Free 23               ORA-02000: missing WHEN keyword
///     PostgreSQL 16.14             syntax error at or near ";"
///     Firebird 5.0.4               -104 Unexpected end of command
///     MySQL 8.4.11 / SQLite 3.53.4 recusam a palavra MERGE, que nao existe la
///   Controle: o MESMO texto com "WHEN MATCHED THEN UPDATE SET D = 'z'" e
///   aceito por MSSQL, Oracle, PostgreSQL e Firebird - logo a recusa e da
///   forma sem WHEN, nao do MERGE.
///
///   A guarda fica AQUI, no nucleo, e nao no serializador do MSSQL, porque a
///   regra e da instrucao e nao do dialeto: os quatro motores que tem MERGE
///   exigem ao menos uma clausula. No driver ela teria de ser repetida em cada
///   dialeto que ganhasse serializador de MERGE - a mesma armadilha de "N
///   pontos de toque" que ja custa caro nesta base.
///
///   CONSEQUENCIA DE ORDEM, declarada de proposito: como isto roda ANTES do
///   despacho por dialeto, um MERGE sem WHEN montado sobre MySQL recebe esta
///   excecao e nao a EFluentSQLStatementNotSupported. As duas sao verdadeiras;
///   esta e a que aponta a linha que o consumidor escreveu.
/// </summary>
function TFluentSQLMerge.Serialize: string;
var
  LReg: TFluentSQLRegister;
begin
  if (FTargetTable <> '') and (FMatchedClauses.Count = 0) then
    raise EArgumentException.Create(
      'MERGE sem nenhuma clausula WHEN nao e serializavel: sairia so o ' +
      'cabecalho "MERGE INTO ... USING ... ON (...);", que e a instrucao pela ' +
      'metade. Nenhum motor com MERGE aceita essa forma (SQL Server Msg 102, ' +
      'Oracle ORA-02000 missing WHEN keyword). Acrescente ao menos um ' +
      '.WhenMatched.Update([...]) / .Delete ou .WhenNotMatched.Insert([...]).');

  LReg := TFluentSQLRegister.Create;
  try
    Result := LReg.Serialize(FDialect).Merge(Self);
  finally
    LReg.Free;
  end;
end;

function TFluentSQLMerge._GetName: string;
begin
  Result := 'Merge';
end;

function TFluentSQLMerge.GetDialect: TFluentSQLDriver;
begin
  Result := FDialect;
end;

function TFluentSQLMerge.GetMatchedClauses: TInterfaceList;
begin
  Result := FMatchedClauses;
end;

function TFluentSQLMerge.GetOnCondition: string;
begin
  Result := FOnCondition;
end;

function TFluentSQLMerge.GetSourceAlias: string;
begin
  Result := FSourceAlias;
end;

function TFluentSQLMerge.GetSourceQuery: IFluentSQL;
begin
  Result := FSourceQuery;
end;

function TFluentSQLMerge.GetSourceTable: string;
begin
  Result := FSourceTable;
end;

function TFluentSQLMerge.GetTargetAlias: string;
begin
  Result := FTargetAlias;
end;

function TFluentSQLMerge.GetTargetTable: string;
begin
  Result := FTargetTable;
end;

function TFluentSQLMerge.Into(const ATableName: string): IFluentSQLMerge;
begin
  FTargetTable := ATableName;
  Result := Self;
end;

function TFluentSQLMerge.Into(const ATableName, AAlias: string): IFluentSQLMerge;
begin
  FTargetTable := ATableName;
  FTargetAlias := AAlias;
  Result := Self;
end;

function TFluentSQLMerge.On(const ACondition: string): IFluentSQLMerge;
begin
  FOnCondition := ACondition;
  Result := Self;
end;

function TFluentSQLMerge.On(const ACondition: array of const): IFluentSQLMerge;
begin
  FOnCondition := TUtils.SqlArrayOfConstToParameterizedSql(ACondition, FAST.Params);
  Result := Self;
end;

function TFluentSQLMerge.Using(const ATableName: string): IFluentSQLMerge;
begin
  FSourceTable := ATableName;
  Result := Self;
end;

function TFluentSQLMerge.Using(const ATableName, AAlias: string): IFluentSQLMerge;
begin
  FSourceTable := ATableName;
  FSourceAlias := AAlias;
  Result := Self;
end;

function TFluentSQLMerge.Using(const AQuery: IFluentSQL; const AAlias: string): IFluentSQLMerge;
begin
  FSourceQuery := AQuery;
  FSourceAlias := AAlias;
  Result := Self;
end;

procedure TFluentSQLMerge._RegisterClause(const AClause: IFluentSQLMergeMatchClauseDef);
begin
  FMatchedClauses.Add(AClause);
end;

function TFluentSQLMerge.WhenMatched: IFluentSQLMergeWhenMatched;
begin
  // A clausula NAO entra em FMatchedClauses aqui. Enquanto nao houver acao
  // valida (Update com pares, Insert com pares ou Delete) ela nao existe para o
  // serializador - ver TFluentSQLMergeMatchClause._Apply.
  Result := TFluentSQLMergeMatchClause.Create(Self, FAST, mctMatched);
end;

function TFluentSQLMerge.WhenNotMatched: IFluentSQLMergeWhenNotMatched;
begin
  Result := TFluentSQLMergeMatchClause.Create(Self, FAST, mctNotMatched);
end;

end.
