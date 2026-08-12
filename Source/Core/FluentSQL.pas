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

unit FluentSQL;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Operators,
  FluentSQL.Functions,
  FluentSQL.Interfaces,
  FluentSQL.Cases,
  FluentSQL.Select,
  FluentSQL.Utils,
  FluentSQL.Serialize,
  FluentSQL.Qualifier,
  FluentSQL.Ast,
  FluentSQL.Expression,
  FluentSQL.Register,
  FluentSQL.Params,
  FluentSQL.SerializeMongoDB,
  FluentSQL.Cache.Interfaces,
  FluentSQL.Merge;

type
  TFluentSQLDriver = FluentSQL.Interfaces.TFluentSQLDriver;
  FluentSQLFun = FluentSQL.Functions.TFluentSQLFunctions;

  TFluentSQL = class(TInterfacedObject, IFluentSQL)
  strict private
    class var FDatabaseDafault: TFluentSQLDriver;
    type
      TSection = (secSelect = 0,
                  secDelete = 1,
                  secInsert = 2,
                  secUpdate = 3,
                  secJoin = 4,
                  secWhere= 5,
                  secGroupBy = 6,
                  secHaving = 7,
                  secOrderBy = 8,
                  secMerge = 9);
      TSections = set of TSection;
  strict private
    FActiveSection: TSection;
    FActiveOperator: TOperator;
    FActiveExpr: IFluentSQLCriteriaExpression;
    FActiveValues: IFluentSQLNameValuePairs;
    FDatabase: TFluentSQLDriver;
    FOperator: IFluentSQLOperators;
    FFunction: IFluentSQLFunctions;
    FAST: IFluentSQLAST;
    FRegister: TFluentSQLRegister;
    FCacheProvider: IFluentSQLCacheProvider;
    FCacheTTL: Integer;
    procedure _AssertSection(ASections: TSections);
    procedure _AssertOperator(AOperators: TOperators);
    procedure _AssertHaveName;
    function _NoCorrenteEstaNaLista(const ALista: IFluentSQLNames): Boolean;
    function _CaseExprAncoraNoNoCorrente: Boolean;
    procedure _RecusaCaseExprNoInsert;
    procedure _AssertCaseExprTemOndeAncorar;
    procedure _AssertCaseExprTemOndeAncorarSeNaoAncora;
    procedure _SetSection(ASection: TSection);
    procedure _DefineSectionSelect;
    procedure _DefineSectionDelete;
    procedure _DefineSectionInsert;
    procedure _DefineSectionUpdate;
    procedure _DefineSectionWhere;
    procedure _DefineSectionGroupBy;
    procedure _DefineSectionHaving;
    procedure _DefineSectionOrderBy;
    function _CreateJoin(AjoinType: TJoinType; const ATableName: String): IFluentSQL;
    function _RelationAliasKeyword: String;
    function _InternalSet(const AColumnName, AColumnValue: String): IFluentSQL;
  public
    constructor Create(const ADatabase: TFluentSQLDriver);
    destructor Destroy; override;
    class procedure SetDatabaseDafault(const ADatabase: TFluentSQLDriver);
    function AndOpe(const AExpression: array of const): IFluentSQL; overload;
    function AndOpe(const AExpression: String): IFluentSQL; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Alias(const AAlias: String): IFluentSQL;
    function CaseExpr(const AExpression: String = ''): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function Clear: IFluentSQL;
    function ClearAll: IFluentSQL;
    function All: IFluentSQL;
    function Column(const AColumnName: String = ''): IFluentSQL; overload;
    function Column(const ATableName: String; const AColumnName: String): IFluentSQL; overload;
    function Column(const AColumnsName: array of const): IFluentSQL; overload;
    function Column(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Delete: IFluentSQL;
    function Merge: IFluentSQLMerge;
    function Desc: IFluentSQL;
    function Distinct: IFluentSQL;
    function IsEmpty: Boolean;
    function Expression(const ATerm: String = ''): IFluentSQLCriteriaExpression; overload;
    function Expression(const ATerm: array of const): IFluentSQLCriteriaExpression; overload;
    function From(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function From(const AQuery: IFluentSQL): IFluentSQL; overload;
    function From(const ATableName: String): IFluentSQL; overload;
    function From(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function GroupBy(const AColumnName: String = ''): IFluentSQL;
    function Having(const AExpression: String = ''): IFluentSQL; overload;
    function Having(const AExpression: array of const): IFluentSQL; overload;
    function Having(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Insert: IFluentSQL;
    function AddRow: IFluentSQL;
    function Into(const ATableName: String): IFluentSQL;
    function FullJoin(const ATableName: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String): IFluentSQL; overload;
    function FullJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function OnCond(const AExpression: String): IFluentSQL; overload;
    function OnCond(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: String): IFluentSQL; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function OrderBy(const AColumnName: String = ''): IFluentSQL; overload;
    function OrderBy(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Select(const AColumnName: String = ''): IFluentSQL; overload;
    function Select(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function WithAlias(const AAlias: String): IFluentSQL;
    function Over(const APartitionBy, AOrderBy: String): IFluentSQL;
    function Union(const AQuery: IFluentSQL): IFluentSQL;
    function UnionAll(const AQuery: IFluentSQL): IFluentSQL;
    function Intersect(const AQuery: IFluentSQL): IFluentSQL;
    function SetValue(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Extended; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Double; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Currency; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDate): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDateTime): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TGUID): IFluentSQL; overload;
    function Values(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function Values(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function First(const AValue: Integer): IFluentSQL;
    function Skip(const AValue: Integer): IFluentSQL;
    function Update(const ATableName: String): IFluentSQL;
    function Where(const AExpression: String = ''): IFluentSQL; overload;
    function Where(const AExpression: array of const): IFluentSQL; overload;
    function Where(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    // Operators methods
    function Equal(const AValue: String = ''): IFluentSQL; overload;
    function Equal(const AValue: Extended): IFluentSQL overload;
    function Equal(const AValue: Integer): IFluentSQL; overload;
    function Equal(const AValue: TDate): IFluentSQL; overload;
    function Equal(const AValue: TDateTime): IFluentSQL; overload;
    function Equal(const AValue: TGUID): IFluentSQL; overload;
    function NotEqual(const AValue: String = ''): IFluentSQL; overload;
    function NotEqual(const AValue: Extended): IFluentSQL; overload;
    function NotEqual(const AValue: Integer): IFluentSQL; overload;
    function NotEqual(const AValue: TDate): IFluentSQL; overload;
    function NotEqual(const AValue: TDateTime): IFluentSQL; overload;
    function NotEqual(const AValue: TGUID): IFluentSQL; overload;
    function GreaterThan(const AValue: Extended): IFluentSQL; overload;
    function GreaterThan(const AValue: Integer) : IFluentSQL; overload;
    function GreaterThan(const AValue: String) : IFluentSQL; overload;
    function GreaterThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterThan(const AValue: TDateTime) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: Extended): IFluentSQL; overload;
    function GreaterEqThan(const AValue: Integer) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: String) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDateTime) : IFluentSQL; overload;
    function LessThan(const AValue: Extended): IFluentSQL; overload;
    function LessThan(const AValue: Integer) : IFluentSQL; overload;
    function LessThan(const AValue: String) : IFluentSQL; overload;
    function LessThan(const AValue: TDate): IFluentSQL; overload;
    function LessThan(const AValue: TDateTime) : IFluentSQL; overload;
    function LessEqThan(const AValue: Extended): IFluentSQL; overload;
    function LessEqThan(const AValue: Integer) : IFluentSQL; overload;
    function LessEqThan(const AValue: String) : IFluentSQL; overload;
    function LessEqThan(const AValue: TDate): IFluentSQL; overload;
    function LessEqThan(const AValue: TDateTime) : IFluentSQL; overload;
    function IsNull: IFluentSQL;
    function IsNotNull: IFluentSQL;
    function Like(const AValue: String): IFluentSQL;
    function LikeFull(const AValue: String): IFluentSQL;
    function LikeLeft(const AValue: String): IFluentSQL;
    function LikeRight(const AValue: String): IFluentSQL;
    function NotLike(const AValue: String): IFluentSQL;
    function NotLikeFull(const AValue: String): IFluentSQL;
    function NotLikeLeft(const AValue: String): IFluentSQL;
    function NotLikeRight(const AValue: String): IFluentSQL;
    function InValues(const AValue: TArray<Double>): IFluentSQL; overload;
    function InValues(const AValue: TArray<String>): IFluentSQL; overload;
    function InValues(const AValue: String): IFluentSQL; overload;
    function NotIn(const AValue: TArray<Double>): IFluentSQL; overload;
    function NotIn(const AValue: TArray<String>): IFluentSQL; overload;
    function NotIn(const AValue: String): IFluentSQL; overload;
    function Exists(const ASubQuery: String): IFluentSQL; overload;
    function NotExists(const ASubQuery: String): IFluentSQL; overload;
    // Functions methods
    function Count: IFluentSQL;
    function Lower: IFluentSQL;
    function Min: IFluentSQL;
    function Max: IFluentSQL;
    function Upper: IFluentSQL;
    function SubString(const AStart: Integer; const ALength: Integer): IFluentSQL;
    function Date(const AValue: String): IFluentSQL;
    function Day(const AValue: String): IFluentSQL;
    function Month(const AValue: String): IFluentSQL;
    function Year(const AValue: String): IFluentSQL;
    function Concat(const AValue: array of String): IFluentSQL;
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string): IFluentSQL; overload;
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const): IFluentSQL; overload;
    // Result full command sql
    function AsFun: IFluentSQLFunctions;
    function AsString: String;
    /// <summary>MongoDB (dbnMongoDB): fragmento JSON da secção SELECT (ADR-013 §2b); vazio noutros dialetos.</summary>
    function MongoSelectFragment: String;
    function Params: IFluentSQLParams;
    function WithCache(const AProvider: IFluentSQLCacheProvider): IFluentSQL;
    function WithTTL(const ASeconds: Integer): IFluentSQL;
  end;

function Query(const ADatabase: TFluentSQLDriver): IFluentSQL;
function Schema(const ADatabase: TFluentSQLDriver): IFluentSchema;

function TCQ(const ADatabase: TFluentSQLDriver): IFluentSQL; deprecated 'Use ''FluentSQL.Query'' instead';

function CreateFluentSQL(const ADatabase: TFluentSQLDriver): IFluentSQL; deprecated 'Use ''FluentSQL.Query'' instead';

function Func(const ADatabase: TFluentSQLDriver): IFluentSQLFunctions;


implementation

uses
  FluentSQL.DDL;

{ FluentSQL }

type
  TStaticFuncWrapper = class(TInterfacedObject, IFluentSQLFunctions)
  private
    FRegister: TFluentSQLRegister;
    FFuncs: IFluentSQLFunctions;
  public
    constructor Create(const ADatabase: TFluentSQLDriver);
    destructor Destroy; override;
    property Funcs: IFluentSQLFunctions read FFuncs implements IFluentSQLFunctions;
  end;

constructor TStaticFuncWrapper.Create(const ADatabase: TFluentSQLDriver);
begin
  inherited Create;
  FRegister := TFluentSQLRegister.Create;
  FFuncs := TFluentSQLFunctions.Create(ADatabase, FRegister);
end;

destructor TStaticFuncWrapper.Destroy;
begin
  FFuncs := nil;
  FRegister.Free;
  inherited;
end;

function Func(const ADatabase: TFluentSQLDriver): IFluentSQLFunctions;
begin
  Result := TStaticFuncWrapper.Create(ADatabase);
end;

function Query(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  // A chamada interna para o construtor evita o warning the deprecation 
  Result := TFluentSQL.Create(ADatabase);
end;

function Schema(const ADatabase: TFluentSQLDriver): IFluentSchema;
begin
  Result := TFluentSchema.Create(ADatabase);
end;

function TCQ(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  Result := TFluentSQL.Create(ADatabase);
end;

function CreateFluentSQL(const ADatabase: TFluentSQLDriver): IFluentSQL;
begin
  Result := TFluentSQL.Create(ADatabase);
end;


{ TFluentSQL }

function TFluentSQL.Alias(const AAlias: String): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Alias := AAlias;
  Result := Self;
end;

function TFluentSQL.AsFun: IFluentSQLFunctions;
begin
  Result := FFunction;
end;

function TFluentSQL.ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string): IFluentSQL;
begin
  FAST.AddDialectOnly(ADialect, ASqlFragment);
  Result := Self;
end;

function TFluentSQL.ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const): IFluentSQL;
begin
  Result := ForDialectOnly(ADialect, TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

/// <summary>
///   O PONTO UNICO DE ANCORAGEM DO CASE. As tres sobrecargas de CaseExpr passam
///   por aqui, e por isso a regra e escrita uma vez so.
///
///   CaseExpr decide DUAS coisas, nao uma: o OPERANDO do CASE (o que vem entre
///   "CASE" e o primeiro "WHEN") e o NO da arvore em que o CASE vai morar. Antes
///   desta tarefa as duas eram decididas sem perguntar nada sobre o no corrente:
///
///       if LExpression = '' then
///         LExpression := FAST.ASTName.Name;
///       Result := TFluentSQLCriteriaCase.Create(Self, LExpression);
///       if Assigned(FAST) then
///         FAST.ASTName.CaseExpr := Result.CaseExpr;
///
///   FAST.ASTName e um CURSOR: aponta para o ultimo no tocado pela cadeia
///   fluente. Sobre uma COLUNA aquilo forma um idioma publico e deliberado -
///   "transforme a ultima coluna num CASE simples sobre ela":
///
///       .Select.Column('ID').Column('TIPO').CaseExpr.When('1')...
///       -> SELECT ID, (CASE TIPO WHEN 1 THEN ... END) ...
///
///   Sobre qualquer OUTRO no, as mesmas duas linhas produziam lixo em silencio.
///   MEDIDO POR MUTACAO, e as duas metades sao load-bearing. A base de contagem
///   e SEMPRE a mesma - celulas que passam a falhar nos 11 RUNNERS, com
///   -DDB2 -DINTERBASE:
///     apagar o ATALHO  -> 31 celulas (24 em Common, 11 delas da suite do slot
///                         de valor, a T13)
///     apagar o ANEXO   -> 39 celulas (28 em Common), porque sem ele o CASE nao
///                         chega ao SELECT: sai "SELECT ID, TIPO AS R FROM T",
///                         com o CASE inteiro perdido
///   Nenhuma das duas linhas podia sair. O que faltava era a PERGUNTA.
///
///   ==========================================================================
///   A PERGUNTA E DE NO, NAO DE SECAO - E ESSA DISTINCAO CUSTOU UMA RODADA
///   ==========================================================================
///
///   A primeira tentativa de conserto perguntou "o cursor esta na lista de
///   colunas da secao CORRENTE?", varrendo so FAST.ASTColumns. Parece a mesma
///   coisa. NAO E, e a diferenca e observavel:
///
///     FAST.ASTName    e DURAVEL - atravessa a troca de secao.
///     FAST.ASTColumns e TROCADO por _DefineSectionX POR BAIXO do cursor
///                     (vira nil no Where e no Having, vira outra lista no
///                     GroupBy e no OrderBy).
///
///   Entao, com o cursor parado sobre uma coluna do SELECT, bastava entrar no
///   WHERE para a pergunta passar a responder "nao e coluna" - sobre o MESMO no.
///   Medido, e as duas cadeias abaixo diferem SO na ordem de Column e From:
///
///     .Select.From('T').Column('TIPO').Where('ID').Equal(1)   cursor na COLUNA
///     .Select.Column('TIPO').From('T').Where('ID').Equal(1)   cursor na RELACAO
///
///   A primeira emitia, e emite, "SELECT (CASE TIPO WHEN 1 THEN ...) FROM T
///   WHERE (ID = :p1)" - valido nos sete. A pergunta de secao a RECUSAVA. Pior:
///   com GroupBy('') no lugar do Where, ela mandava o CASE para a clausula
///   errada e o resultado saia VALIDO E DIFERENTE ("SELECT TIPO FROM T GROUP BY
///   (CASE ...)"), ou seja regressao de ruidoso para MUDO.
///
///   Por isso a pergunta varre TODAS as colecoes de coluna, e nao a corrente.
///
///   POR QUE NAO UMA MARCA NO NO, que seria mais direto: nao existe. O
///   TFluentSQLName tem Name, Alias, AliasKeyword e Case, e nada disso diz o
///   papel. AliasKeyword PARECE servir (nasce 'AS' para coluna e recebe
///   _RelationAliasKeyword para relacao) mas foi MEDIDO e nao serve: so a Oracle
///   sobrescreve RelationAliasKeyword, entao nos outros seis dialetos coluna e
///   relacao carregam ambas 'AS'. Criar marca nova seria membro em
///   IFluentSQLName - BREAKING E2291, com dois implementadores - para responder o
///   que tres varreduras curtas ja respondem sem tocar em superficie publica.
///   As listas existem desde TFluentSQLAST.Create e os getters sao puros: varrer
///   nao cria secao nenhuma.
///
///   ==========================================================================
///   PARA ONDE VAI A COLUNA NOVA: ASTColumns, E ISSO FOI MEDIDO
///   ==========================================================================
///
///   O destino NAO e "a lista de projecao". Forcar FAST.Select.Columns quebraria
///   dois casos legitimos, medidos:
///
///     .Select.All.From('T').OrderBy('')  -> ORDER BY (CASE ...)   e o certo
///     .Select.All.From('T').GroupBy('')  -> GROUP BY (CASE ...)   e o certo
///
///   Quem chamou OrderBy quer o CASE no ORDER BY. ASTColumns - a lista da secao
///   corrente - ja era o destino certo; o erro estava no PREDICADO, nao no
///   destino.
///
///   ==========================================================================
///   O ORACULO DE MOTOR
///   ==========================================================================
///
///   Transcricao literal em test.caseexpr.anchor.matrix.sql. SUBMETIDOS 7: seis
///   ATIVOS (PostgreSQL, MySQL, SQL Server, Firebird, Oracle, SQLite) e um SOB
///   DEFINE (DB2, desligado no FluentSQL.inc). InterBase NAO MEDIDO - nao ha
///   imagem publica, e nao foi inferido do Firebird.
///
///   O texto que saia com o cursor na relacao,
///     SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)
///   e RECUSADO por SETE de sete:
///     PostgreSQL 16.14                ERROR: syntax error at or near "CASE"
///     MySQL 8.4.11                    ERROR 1064 (42000)
///     SQL Server 2022 16.0.4265.3     Msg 156 Incorrect syntax near 'CASE'
///     Firebird 5.0.4                  -104 / Token unknown - CASE
///     Oracle AI 26ai Free 23.26.2.0.0 ORA-00907: missing right parenthesis
///     DB2 v12.1.5.0                   SQL0104N / SQLSTATE=42601
///     SQLite 3.53.4                   Parse error near "CASE"
///
///   E A FORMA NOVA NAO PASSA EM TODOS - esta doutrina nao afirma isso, e a
///   distincao e o motivo de o oraculo ter sido reexecutado:
///     projecao SEM estrela ... 7 de 7 aceitam, dado certo
///     projecao COM estrela ... 5 de 7. Firebird e Oracle recusam pela VIRGULA
///                              depois da ESTRELA (o Firebird aponta a coluna 9;
///                              a Oracle devolve ORA-00923), e nao pelo CASE.
///                              "SELECT *, <expr>" ja saia da base por All
///                              seguido de Column: defeito PRE-EXISTENTE, porta
///                              propria, fora do escopo desta tarefa
///     ORDER BY ............... 7 de 7 aceitam
///     GROUP BY ............... 1 de 7. Os outros recusam porque projetar uma
///                              coluna agrupando por outra expressao viola a
///                              regra de GROUP BY - causa da CADEIA DO USUARIO,
///                              e nao da ancoragem
///
///   Uma versao anterior deste oraculo submeteu a Oracle um enunciado COM
///   apelido ("SELECT P.* ... FROM PRODUCTS P") que o FluentSQL nao emite, e a
///   ressalva ficava so dentro do .sql enquanto aqui se afirmava "verbatim". A
///   adaptacao escondia a recusa real. Agora todos os enunciados vao como sao
///   emitidos, e onde o motor recusa a recusa esta transcrita.
///
///   ==========================================================================
///   A REGRA
///   ==========================================================================
///
///       converter SQL invalido silencioso em SQL VALIDO quando o sentido e
///       inequivoco, e em ERRO NOMEADO quando nao e. Nunca em descarte silencioso.
/// </summary>
function TFluentSQL.CaseExpr(const AExpression: String): IFluentSQLCriteriaCase;
var
  LExpression: String;
begin
  LExpression := AExpression;
  if _CaseExprAncoraNoNoCorrente then
  begin
    if LExpression = '' then
      LExpression := FAST.ASTName.Name;
    Result := TFluentSQLCriteriaCase.Create(Self, LExpression);
    FAST.ASTName.CaseExpr := Result.CaseExpr;
    Exit;
  end;
  _AssertCaseExprTemOndeAncorar;
  Result := TFluentSQLCriteriaCase.Create(Self, LExpression);
  FAST.ASTName := FAST.ASTColumns.Add;
  FAST.ASTName.CaseExpr := Result.CaseExpr;
end;

/// <summary>
///   O no do cursor esta NESTA lista? Comparacao de IDENTIDADE de interface, que
///   e o unico discriminador disponivel: o mesmo TFluentSQLName serve para
///   coluna e para relacao, e o que distingue um do outro e a LISTA a que ele
///   pertence.
/// </summary>
function TFluentSQL._NoCorrenteEstaNaLista(const ALista: IFluentSQLNames): Boolean;
var
  LFor: Integer;
begin
  Result := False;
  if not Assigned(ALista) then
    Exit;
  for LFor := 0 to ALista.Count - 1 do
    if ALista[LFor] = FAST.ASTName then
      Exit(True);
end;

/// <summary>
///   O no do cursor e uma COLUNA - em QUALQUER das listas de coluna, e nao so na
///   da secao corrente. A razao de varrer todas esta na doutrina de CaseExpr,
///   logo acima: o cursor e duravel e a lista corrente nao.
///
///   Responde False - e nao levanta - quando nao ha AST ou nao ha cursor. Quem
///   decide o que fazer com o False e o chamador.
///
///   A UNICA saida por excecao daqui e o ramo do INSERT, e ela e deliberada: ver
///   _RecusaCaseExprNoInsert.
/// </summary>
function TFluentSQL._CaseExprAncoraNoNoCorrente: Boolean;
begin
  Result := False;
  if (not Assigned(FAST)) or (not Assigned(FAST.ASTName)) then
    Exit;
  // A QUARTA colecao entra na MESMA varredura, e nao numa guarda a parte: o no
  // ancora nela como ancoraria em qualquer outra, so que ancorar ali nao pode.
  if Assigned(FAST.Insert) and _NoCorrenteEstaNaLista(FAST.Insert.Columns) then
    _RecusaCaseExprNoInsert;
  Result := (Assigned(FAST.Select)  and _NoCorrenteEstaNaLista(FAST.Select.Columns))
         or (Assigned(FAST.GroupBy) and _NoCorrenteEstaNaLista(FAST.GroupBy.Columns))
         or (Assigned(FAST.OrderBy) and _NoCorrenteEstaNaLista(FAST.OrderBy.Columns));
end;

/// <summary>
///   A recusa do INSERT, chamada de DOIS pontos porque sao DUAS perguntas
///   diferentes, e as duas precisam dela:
///
///     _CaseExprAncoraNoNoCorrente ... "o NO do cursor e uma coluna do INSERT?"
///     _AssertCaseExprTemOndeAncorar  "a lista onde eu CRIARIA a coluna nova e
///                                     a do INSERT?"
///
///   A primeira e de NO e a segunda e de DESTINO, e nenhuma cobre a outra.
///   Houve uma versao desta entrega em que existia so a segunda, escrita como
///   FAST.ASTColumns = FAST.Insert.Columns - ou seja, pergunta de SECAO, o mesmo
///   padrao que ja tinha derrubado a primeira rodada. Ela deixava passar, medido:
///
///       Insert.Into('T').Column('A').GroupBy('') + CaseExpr
///       -> INSERT INTO T ( A ) GROUP BY (CASE WHEN 1 THEN 1 END)
///
///   porque o cursor estava numa coluna do INSERT enquanto a lista corrente ja
///   era a do GROUP BY. Com a pergunta de no no lugar, o contra-exemplo morre.
///
///   POR QUE O INSERT E DIFERENTE DAS OUTRAS TRES LISTAS: as colunas do INSERT
///   sao NOMES DE DESTINO - as celulas onde o dado vai ser gravado - e nao
///   expressoes projetadas. Um CASE nao pode ser alvo de gravacao em dialeto
///   nenhum. A lista se parecer com as outras e coincidencia de REPRESENTACAO,
///   nao de significado.
///
///   METADE DISTO NAO E REGRESSAO DESTA ENTREGA, e o registro importa:
///   Insert.Into('T').Column('A') seguido de CaseExpr JA emitia, calado,
///   "INSERT INTO T ( (CASE A WHEN 1 THEN 'X' END) )" na base. O caso sem Column
///   levantava EAccessViolation. Nenhum dos dois tinha comportamento a preservar.
/// </summary>
procedure TFluentSQL._RecusaCaseExprNoInsert;
begin
  raise EArgumentException.Create(
    'IFluentSQL.CaseExpr chamado dentro de um INSERT: as colunas do INSERT sao ' +
    'NOMES DE DESTINO, as celulas onde o dado sera gravado, e um CASE nao pode ' +
    'ser alvo de gravacao em dialeto nenhum. O que sairia - ' +
    '"INSERT INTO T ( (CASE ... END) )" - nao e aceito por motor nenhum. Se o ' +
    'CASE e o VALOR a gravar, ele vai no lado dos valores; se e para projetar, ' +
    'ele vai num SELECT.');
end;

/// <summary>
///   Recusa quando nao ha ONDE criar a coluna nova. Sao dois motivos, e o
///   segundo e de DESTINO e nao de no:
///
///   1. nao ha lista de colunas nenhuma - as secoes que nao projetam (WHERE,
///      JOIN, HAVING, DELETE, UPDATE) e o enunciado que ainda nao abriu secao.
///   2. a lista corrente e a do INSERT, onde a coluna nova nao pode nascer. Esta
///      metade NAO e coberta pela pergunta de no: no Insert.Into('T') sem Column
///      nenhuma, o cursor esta na relacao e nao ha no de coluna a encontrar - o
///      que impede o "INSERT INTO T ( (CASE ...) )" e esta linha aqui.
///
///   Por que recusar em vez de simplesmente nao anexar: nao anexar DESCARTA o
///   CASE em silencio - o chamador montou um CASE inteiro, com WHEN e THEN, e
///   nada dele apareceria no SQL. O que saia antes era pior (o CASE substituia a
///   relacao do FROM ou a do JOIN, apagando o texto dela), mas as duas saidas
///   erradas tem a mesma raiz: a chamada nao tem sentido ali, e fingir que tem e
///   que era o erro.
///
///   A MENSAGEM NAO NOMEIA A SECAO, e a omissao e o conserto de um defeito real:
///   a versao anterior formatava FAST.ASTSection.Name DENTRO do raise - ou seja,
///   desreferenciava um objeto que pode ser nil no exato caminho em que a guarda
///   ja falhou. Medido: Query(dbnFirebird).CaseExpr, sem Select nenhum, levantava
///   EAccessViolation DE DENTRO da guarda. E a mesma figura de "guarda no objeto
///   errado" que esta tarefa existe para matar, e nao ia ficar aqui.
///
///   Isto e BREAKING, e o alcance e conhecido: quebra SO quem ja produzia SQL que
///   motor nenhum aceitava, ou quem ja recebia EAccessViolation.
/// </summary>
procedure TFluentSQL._AssertCaseExprTemOndeAncorar;
begin
  if Assigned(FAST) and Assigned(FAST.Insert) and
     (FAST.ASTColumns = FAST.Insert.Columns) then
    _RecusaCaseExprNoInsert;
  if Assigned(FAST) and Assigned(FAST.ASTColumns) then
    Exit;
  raise EArgumentException.Create(
    'IFluentSQL.CaseExpr chamado numa secao que nao projeta colunas: um CASE ' +
    'precisa de uma lista de colunas onde morar, e aqui nao ha nenhuma. ' +
    'Anexa-lo ao no corrente SUBSTITUIRIA o texto dele - a relacao do FROM ou a ' +
    'do JOIN - e o que sairia nao e CASE de dialeto nenhum; ignora-lo em ' +
    'silencio descartaria o CASE inteiro. Chame CaseExpr onde ha projecao: ' +
    'depois de Select/Column(...), de GroupBy(...) ou de OrderBy(...).');
end;

/// <summary>
///   Antecipa a recusa para os chamadores que GRAVAM antes de delegar. Se o no
///   ancora, nao ha recusa possivel adiante e esta funcao sai calada.
/// </summary>
procedure TFluentSQL._AssertCaseExprTemOndeAncorarSeNaoAncora;
begin
  if _CaseExprAncoraNoNoCorrente then
    Exit;
  _AssertCaseExprTemOndeAncorar;
end;

/// <summary>
///   A recusa corre ANTES de SqlArrayOfConstToParameterizedSql, e a ordem nao e
///   estilo: aquela chamada e quem GRAVA os :pN do array na colecao. Delegar
///   primeiro e recusar depois deixaria o parametro na colecao sem nada no SQL
///   que o referenciasse - e quem liga por POSICAO, que e como todo driver Delphi
///   liga, passaria a ligar errado a partir do buraco.
///
///   O vazamento e desta entrega, nao anterior a ela: antes nao havia recusa
///   nenhuma aqui, entao nao havia caminho que abandonasse parametro. Foi a
///   guarda nova que o criou, e foi o teste da guarda que o pegou (medido
///   Expected [1] but got [2] antes desta linha).
///
///   O INVARIANTE QUE ESTAS DUAS LINHAS SUSTENTAM, e nada alem dele:
///
///       nenhum caminho de recusa DESTA FUNCAO grava parametro.
///
///   A frase e estreita de proposito. Ela NAO diz "nenhum :pN fica orfao", que
///   seria falso e nao e consertavel aqui: na sobrecarga de
///   IFluentSQLCriteriaExpression o argumento e construido pelo CHAMADOR, e os
///   parametros dele ja estao gravados quando esta unidade recebe o controle.
/// </summary>
function TFluentSQL.CaseExpr(const AExpression: array of const): IFluentSQLCriteriaCase;
begin
  _AssertCaseExprTemOndeAncorarSeNaoAncora;
  Result := CaseExpr(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

/// <summary>
///   ESTA SOBRECARGA LEVANTA, E A RECUSA E A ENTREGA - nao um adiamento.
///
///   O corpo original era
///
///       Result := TFluentSQLCriteriaCase.Create(Self, '');
///       Result.AndOpe(AExpression);
///
///   e TFluentSQLCriteriaCase.AndOpe le FLastExpression, que so When preenche.
///   Recem-criado o campo e nil, entao a chamada estourava com EAccessViolation
///   lendo 00000000 em QUALQUER estado - medido em tres (com Column antes,
///   depois de From, com When encadeado depois). A sobrecarga era PUBLICA e 100%
///   inalcancavel, sem um unico teste que a exercitasse.
///
///   POR QUE NAO FOI "CONSERTADA" PARA FUNCIONAR. A saida obvia seria serializar
///   a expressao e delegar a sobrecarga de String. Ela FUNCIONA quando a
///   expressao pertence ao MESMO enunciado, e MENTE quando nao pertence. Medido:
///
///       QA.CaseExpr(QB.Expression(['TIPO', '*', 2]))
///       SQL de QA:  SELECT (CASE TIPO * :p1 WHEN ...) FROM T
///       QA.Params.Count = 0        <- o :p1 citado NAO EXISTE na colecao de QA
///       QB.Params.Count = 1        <- o valor ficou na colecao do outro
///
///   O enunciado sai citando um parametro fantasma. Quem liga por posicao liga
///   errado, e nao ha excecao para o chamador perceber - a mesma classe de dano
///   silencioso que esta tarefa inteira combate, so que introduzida por nos.
///
///   E NAO HA COMO DISTINGUIR OS DOIS CASOS EM RUNTIME:
///   IFluentSQLCriteriaExpression expoe AsString e Expression, e mais nada -
///   nenhum caminho ate o dono ou ate a colecao de origem. Descobrir exigiria
///   alargar a interface (E2291), que e exatamente o pre-requisito que o PR #166
///   ja catalogou sob o nome de FUSAO DE COLECOES DE PARAMETRO.
///
///   Entre estourar com EAccessViolation, mentir em silencio e recusar dizendo o
///   porque, a terceira e a unica honesta. Quando a fusao existir, esta
///   sobrecarga passa a funcionar e a recusa vira aditiva de remover.
/// </summary>
function TFluentSQL.CaseExpr(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase;
begin
  Result := nil;
  raise EArgumentException.Create(
    'IFluentSQL.CaseExpr(IFluentSQLCriteriaExpression) nao esta disponivel. A ' +
    'sobrecarga precisa de FUSAO DE COLECOES DE PARAMETRO, que ainda nao ' +
    'existe: uma expressao construida por OUTRO enunciado carrega os :pN na ' +
    'colecao DELE, e o texto entraria aqui citando parametro que esta colecao ' +
    'nao tem - quem liga por posicao ligaria errado, sem erro nenhum. Nao ha ' +
    'como distinguir em runtime a expressao propria da alheia. Use ' +
    'CaseExpr(const AExpression: String) com o termo, ou a sobrecarga de array ' +
    'of const, que parametriza na colecao certa.');
end;

function TFluentSQL.AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  FActiveOperator := opeAND;
  FActiveExpr.AndOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQL.AndOpe(const AExpression: String): IFluentSQL;
begin
  FActiveOperator := opeAND;
  FActiveExpr.AndOpe(AExpression);
  Result := Self;
end;

function TFluentSQL.AndOpe(const AExpression: array of const): IFluentSQL;
begin
  Result := AndOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.OrOpe(const AExpression: array of const): IFluentSQL;
begin
  Result := OrOpe(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.OrOpe(const AExpression: String): IFluentSQL;
begin
  FActiveOperator := opeOR;
  FActiveExpr.OrOpe(AExpression);
  Result := Self;
end;

function TFluentSQL.OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  FActiveOperator := opeOR;
  FActiveExpr.OrOpe(AExpression.Expression);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: array of const): IFluentSQL;
begin
  // AColumnValue e o lado DIREITO de "COLUNA = ...": posicao de VALOR, nunca de
  // expressao - e o que o proprio _InternalSet afirma com
  // _AssertSection([secInsert, secUpdate]). Por isso NAO usa
  // SqlArrayOfConstToParameterizedSql, onde a RN-P3 deixa string literal: ali
  // .SetValue('NOME', ['x''; DROP TABLE USERS; --']) emitia
  // "VALUES (x'; DROP TABLE USERS; --)" com ZERO parametros, enquanto
  // .SetValue('NIVEL', [7]) ja saia como :p1. O numerico parametrizava e a
  // string nao - assimetria dentro do MESMO slot.
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedValue(AColumnValue, FAST.Params));
end;

function TFluentSQL.SetValue(const AColumnName, AColumnValue: String): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftString);
  Result := Self;
end;

function TFluentSQL.OnCond(const AExpression: String): IFluentSQL;
begin
  Result := AndOpe(AExpression);
end;

function TFluentSQL.OnCond(const AExpression: array of const): IFluentSQL;
begin
  Result := OnCond(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.InValues(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftInteger);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Extended; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Double; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; AColumnValue: Currency; ADecimalPlaces: Integer): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftFloat);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TDate): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftDate);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TDateTime): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue, dftDateTime);
  Result := Self;
end;

function TFluentSQL.SetValue(const AColumnName: String; const AColumnValue: TGUID): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := FAST.Params.Add(AColumnValue.ToString, dftGuid);
  Result := Self;
end;

class procedure TFluentSQL.SetDatabaseDafault(const ADatabase: TFluentSQLDriver);
begin
  FDatabaseDafault := ADatabase;
end;

function TFluentSQL.All: IFluentSQL;
begin
  if not (FDatabase in [dbnMongoDB]) then
    Result := Column('*')
  else
    Result := Self;
end;

procedure TFluentSQL._AssertHaveName;
begin
  if not Assigned(FAST.ASTName) then
    raise Exception.Create('TCriteria: Current name is not set');
end;

/// <summary>
///   Como ESTE dialeto escreve o apelido de uma RELACAO. Unico ponto do nucleo
///   que faz a pergunta; From e _CreateJoin marcam o no recem-criado com a
///   resposta, e TFluentSQLName.Serialize so obedece.
///
///   O apelido de COLUNA nao passa por aqui de proposito: TFluentSQLName ja
///   nasce com 'AS', que os sete relacionais aceitam para c_alias - inclusive a
///   Oracle. A MESMA classe serve os dois papeis (Column monta em
///   FAST.ASTColumns, From e _CreateJoin montam em FAST.ASTTableNames e no
///   JoinedTable), entao aplicar a regra da relacao no Serialize sem distinguir
///   quebraria o apelido de coluna junto.
///
///   FRegister.Serialize levanta para dialeto nao registrado, mas nao ha
///   caminho novo de excecao aqui: TFluentSQL.Create ja falha antes, em
///   FRegister.Select, para o mesmo dialeto.
/// </summary>
function TFluentSQL._RelationAliasKeyword: String;
begin
  Result := FRegister.Serialize(FDatabase).RelationAliasKeyword;
end;

procedure TFluentSQL._AssertOperator(AOperators: TOperators);
begin
  if not (FActiveOperator in AOperators) then
    raise Exception.Create('TFluentSQL: Not supported in this operator');
end;

procedure TFluentSQL._AssertSection(ASections: TSections);
begin
  if not (FActiveSection in ASections) then
    raise Exception.Create('TFluentSQL: Not supported in this section');
end;

function TFluentSQL.AsString: String;
var
  LKey: string;
  I: Integer;
  LDialectItem: TDialectOnlyFragment;
begin
  FActiveOperator := opeNone;

  if Assigned(FCacheProvider) then
  begin
    // Generate deterministic key based on Dialect and all AST sections to avoid collisions (Review ESP-032 rejection)
    LKey := Format('dialect:%d|select:%s|insert:%s|update:%s|delete:%s|where:%s|joins:%s|groupby:%s|having:%s|orderby:%s|union:%s|alias:%s', [
      Integer(FDatabase),
      FAST.Select.Serialize,
      FAST.Insert.Serialize,
      FAST.Update.Serialize,
      FAST.Delete.Serialize,
      FAST.Where.Serialize,
      FAST.Joins.Serialize,
      FAST.GroupBy.Serialize,
      FAST.Having.Serialize,
      FAST.OrderBy.Serialize,
      FAST.UnionType,
      FAST.WithAlias,
      TUtils.BooleanToSQLFormat(FDatabase, Assigned(FAST.Merge))
    ]);

    if Assigned(FAST.UnionQuery) then
      LKey := LKey + '|unionquery:' + FAST.UnionQuery.AsString;

    for I := 0 to FAST.DialectOnlyCount - 1 do
    begin
      LDialectItem := FAST.GetDialectOnlyItem(I);
      LKey := LKey + Format('|dialectonly:%d:%s', [Integer(LDialectItem.Dialect), LDialectItem.Sql]);
    end;

    LKey := TUtils.GetHash(LKey);

    Result := FCacheProvider.Get(LKey);
    if Result <> '' then
      Exit;
  end;

  Result := FRegister.Serialize(FDatabase).AsString(FAST);

  if Assigned(FCacheProvider) and (Result <> '') then
    FCacheProvider.SetCache(LKey, Result, FCacheTTL);
end;

function TFluentSQL.MongoSelectFragment: String;
begin
  if FDatabase <> dbnMongoDB then
    Exit('');
  Result := FluentMongoSelectSerializeFragment(FAST.Select);
end;

function TFluentSQL.Params: IFluentSQLParams;
begin
  if (FAST.UnionType <> '') and Assigned(FAST.UnionQuery) then
    Result := TFluentSQLMergedParams.Create(FAST.Params, FAST.UnionQuery.Params)
  else
    Result := FAST.Params;
end;

function TFluentSQL.Column(const AColumnName: String): IFluentSQL;
begin
  if Assigned(FAST) then
  begin
    FAST.ASTName := FAST.ASTColumns.Add;
    FAST.ASTName.Name := AColumnName;
  end
  else
    raise Exception.CreateFmt('Current section [%s] does not support COLUMN.', [FAST.ASTSection.Name]);
  Result := Self;
end;

function TFluentSQL.Column(const ATableName: String; const AColumnName: String): IFluentSQL;
begin
  Result := Column(ATableName + '.' + AColumnName);
end;

function TFluentSQL.Clear: IFluentSQL;
begin
  FAST.ASTSection.Clear;
  Result := Self;
end;

function TFluentSQL.ClearAll: IFluentSQL;
begin
  FAST.Clear;
  Result := Self;
end;

function TFluentSQL.Column(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  if Assigned(FAST.ASTColumns) then
  begin
    FAST.ASTName := FAST.ASTColumns.Add;
    FAST.ASTName.CaseExpr := ACaseExpression.CaseExpr;
  end
  else
    raise Exception.CreateFmt('Current section [%s] does not support COLUMN.', [FAST.ASTSection.Name]);
  Result := Self;
end;

function TFluentSQL.Concat(const AValue: array of String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Concat(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Concat(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.Count: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Count(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Column(const AColumnsName: array of const): IFluentSQL;
begin
  Result := Column(TUtils.SqlArrayOfConstToParameterizedSql(AColumnsName, FAST.Params));
end;

constructor TFluentSQL.Create(const ADatabase: TFluentSQLDriver);
begin
  FDatabase := ADatabase;
  FRegister := TFluentSQLRegister.Create;
  FAST := TFluentSQLAST.Create(FDatabase, FRegister);
  FOperator := TFluentSQLOperators.Create(FDatabase, FAST.Params);
  FFunction := TFluentSQLFunctions.Create(FDatabase, FRegister);
  FAST.Clear;
  FActiveOperator := opeNone;
  FCacheTTL := 3600; // Default TTL: 1 hour
end;

function TFluentSQL.WithCache(const AProvider: IFluentSQLCacheProvider): IFluentSQL;
begin
  FCacheProvider := AProvider;
  Result := Self;
end;

function TFluentSQL.WithTTL(const ASeconds: Integer): IFluentSQL;
begin
  FCacheTTL := ASeconds;
  Result := Self;
end;

/// <summary>
///   Porta unica dos QUATRO tipos de juncao: InnerJoin, LeftJoin, RightJoin e
///   FullJoin delegam todos aqui.
///
///   ⚠️ PORTA UNICA NAO E CONSTRUCAO FECHADA, e confundir as duas foi
///   exatamente o erro da primeira versao desta guarda. Que os quatro tipos
///   passem por aqui garante que a guarda VE todos eles; NAO garante que ela os
///   RECUSE em toda cadeia que os alcance. O que ela le - e nao por onde ela
///   esta - e o que fecha a construcao. Ver o bloco sobre a marca duravel,
///   abaixo.
///
///   ⭐ POR QUE O JOIN NAO ENTRA NO DELETE. A razao NAO e "o texto emitido nao
///   executa" - essa e verdadeira e e a menor das duas. A que decide e o DANO
///   SILENCIOSO, medido em motor real (transcricao com digest de imagem, versao
///   perguntada ao motor e contagem antes/depois em
///   Test Delphi\Common_tests\test.delete.join.matrix.sql):
///
///     Delete.From('A','X').LeftJoin('B','Y').OnCond('Y.AID = X.ID')   sem Where
///     -> forma nativa "DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID"
///     -> DOIS dos sete motores EXECUTAM, reportam sucesso e deixam
///        A: 4 -> 0     B: 2 -> 2        apagaram a tabela inteira
///
///   Na juncao EXTERNA a condicao e DECORATIVA: nao filtra nada, porque a
///   juncao preserva toda linha da relacao da esquerda. Quem escreveu aquilo
///   achava estar filtrando. Mesma classe do achado do Oracle no PR #160 -
///   apagar MAIS do que se pediu, sem erro; la era a relacao errada, aqui e a
///   relacao certa por inteiro.
///
///   POR QUE A FAMILIA TODA, e nao so o LEFT: dentro do DELETE os membros nao
///   significam a mesma coisa - o InnerJoin FILTRA (a forma nativa apaga 2 das
///   4), o LeftJoin NAO (apaga 4 das 4). Liberar so o InnerJoin criaria uma
///   distincao que a superficie fluente nao insinua e que gramatica nenhuma dos
///   sete espelha: 5 dos 7 recusam os dois por parse, 2 dos 7 aceitam os dois.
///
///   O QUE SE PERDE, dito sem maquiagem: para o InnerJoin ISOLADO existe forma
///   portavel, medida e aceita pelos SETE - "DELETE FROM A WHERE EXISTS (SELECT
///   1 FROM B WHERE ...)". A INTERSECAO NAO E VAZIA, e este comentario nao
///   finge que seja. Entregar so ela e tarefa propria, ja catalogada, com o
///   custo medido: o WHERE precisa migrar para DENTRO da subconsulta, porque
///   pode citar a relacao juntada ("WHERE (Y.Status = ?)" e alcancavel), e isso
///   nao e mudanca local - e ComposeSqlCore deixando de emitir Where.Serialize
///   na posicao de sempre para UMA secao.
///
///   O "ON" PENDURADO tambem morre aqui, e por cima. Sem OnCond o texto saia
///   "... INNER JOIN B AS Y ON", com ON e sem predicado - nao e produto
///   cartesiano, e sentenca TRUNCADA, e os sete a recusam (o DB2 e o que nomeia
///   melhor: espera "<boolean_predicate>"). A CAUSA continua de pe e e de OUTRA
///   tarefa: TFluentSQLJoins.Serialize (FluentSQL.Joins.pas) concatena 'ON'
///   incondicionalmente e TUtils.Concat descarta a condicao vazia, o que produz
///   o mesmo ON pendurado TAMBEM NO SELECT, que esta guarda nao toca.
///
///   POR QUE AQUI E NAO NUM SERIALIZADOR: falha na chamada que errou e nao la
///   adiante no AsString; vale para os dialetos todos sem uma linha por driver;
///   e nao acrescenta membro a IFluentSQLSerialize.
///
///   POR QUE NAO _AssertSection: aquele levanta Exception cru com "Not
///   supported in this section". Quem recebe esta recusa precisa do TIPO
///   proprio, para distinguir de outros erros do builder, e da mensagem que
///   aponta a saida - recusar sem saida seria pior que o defeito.
///
///   ⚠️ A PERGUNTA CERTA E "ESTE STATEMENT E UM DELETE?", NAO "O CURSOR ESTA
///   AGORA NA SECAO DELETE?". A primeira versao desta guarda lia so
///   FActiveSection, e ISSO ERA O FURO - nao uma virtude, como o comentario
///   anterior chegou a afirmar. A cadeia fluente e LIVRE: qualquer chamada que
///   troque a secao entre o From e o join desarmava a leitura do cursor.
///   Where faz _SetSection(secWhere), OrderBy faz _SetSection(secOrderBy),
///   GroupBy idem - e Where('') nao emite UMA LETRA, nem aparece na saida:
///
///     Delete.From('A','X').Where('').LeftJoin('B','Y').OnCond('Y.AID = X.ID')
///     -> DELETE X FROM A AS X LEFT JOIN B AS Y ON Y.AID = X.ID
///
///   que e byte a byte a sentenca medida em A: 4 -> 0. O agravante: Where e
///   EXATAMENTE a chamada que a mensagem desta guarda recomenda como saida -
///   a saida apontada e o desvio eram a mesma porta.
///
///   Por isso a guarda le DUAS coisas, e nenhuma cobre a outra:
///
///     FAST.Delete.IsEmpty = False  e a marca DURAVEL. Quem a estabelece e
///       _DefineSectionDelete (via From, que alimenta Delete.TableNames) e quem
///       a limpa e ClearAll - chamado por _DefineSectionSelect, Insert e Update.
///       Sobrevive a Where/OrderBy/GroupBy, que NAO chamam ClearAll.
///     FActiveSection = secDelete  cobre o DELETE ainda SEM From, onde a marca
///       duravel ainda nao existe (Delete.InnerJoin(...) direto).
///
///   O QUE CONTINUA LIBERADO, e tem de continuar: trocar para SELECT (ou INSERT
///   ou UPDATE) na mesma instancia limpa a marca e devolve o JOIN. Travado por
///   TestSelectDepoisDeDeleteLiberaOJoin e
///   TestInsertDepoisDeDeleteLimpaAMarcaDuravel.
/// </summary>
function TFluentSQL._CreateJoin(AjoinType: TJoinType; const ATableName: String): IFluentSQL;
var
  LJoin: IFluentSQLJoin;
begin
  if (FActiveSection = secDelete) or (not FAST.Delete.IsEmpty) then
    raise EFluentSQLConstructNotSupported.Create(
      'JOIN em DELETE',
      'Medido em motor real: dos sete, cinco recusam o texto por parse e dois ' +
      'o executam - e sao esses dois o problema. Com LeftJoin e sem WHERE, a ' +
      'forma nativa apaga a tabela inteira (4 de 4 linhas) e reporta sucesso, ' +
      'porque na juncao externa a condicao nao filtra nada. Perde-se a tabela ' +
      'em silencio. O InnerJoin filtra e o LeftJoin nao, entao nao ha traducao ' +
      'unica para a familia, e liberar so o InnerJoin seria uma distincao que ' +
      'a API nao insinua.',
      'Restrinja a relacao alvo pelo WHERE com subconsulta - ' +
      'Where(...).Exists(''SELECT 1 FROM B WHERE ...''), que sai verbatim e e ' +
      'aceita pelos sete. Se o que se queria era apagar de duas relacoes, sao ' +
      'duas instrucoes.');
  FActiveSection := secJoin;
  LJoin := FAST.Joins.Add;
  LJoin.JoinType := AjoinType;
  FAST.ASTName := LJoin.JoinedTable;
  FAST.ASTName.AliasKeyword := _RelationAliasKeyword;
  FAST.ASTName.Name := ATableName;
  FAST.ASTSection := LJoin;
  FAST.ASTColumns := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(LJoin.Condition, FAST.Params);
  Result := Self;
end;

function TFluentSQL.Date(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Date(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Date(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.Day(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Day(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Day(AValue));
  end;
  Result := Self;
end;

procedure TFluentSQL._DefineSectionDelete;
begin
  ClearAll();
  FAST.ASTSection := FAST.Delete;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := FAST.Delete.TableNames;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionGroupBy;
begin
  FAST.ASTSection := FAST.GroupBy;
  FAST.ASTColumns := FAST.GroupBy.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionHaving;
begin
  FAST.ASTSection := FAST.Having;
  FAST.ASTColumns   := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(FAST.Having.Expression, FAST.Params);
  FAST.ASTTableNames := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionInsert;
begin
  ClearAll();
  FAST.ASTSection := FAST.Insert;
  FAST.ASTColumns := FAST.Insert.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := FAST.Insert.Values;
end;

procedure TFluentSQL._DefineSectionOrderBy;
begin
  FAST.ASTSection := FAST.OrderBy;
  FAST.ASTColumns := FAST.OrderBy.Columns;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionSelect;
begin
  ClearAll();
  FAST.ASTSection := FAST.Select;
  FAST.ASTColumns := FAST.Select.Columns;
  FAST.ASTTableNames := FAST.Select.TableNames;
  FActiveExpr := nil;
  FActiveValues := nil;
end;

procedure TFluentSQL._DefineSectionUpdate;
begin
  ClearAll();
  FAST.ASTSection := FAST.Update;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := nil;
  FActiveExpr := nil;
  FActiveValues := FAST.Update.Values;
end;

procedure TFluentSQL._DefineSectionWhere;
begin
  FAST.ASTSection := FAST.Where;
  FAST.ASTColumns := nil;
  FAST.ASTTableNames := nil;
  FActiveExpr := TFluentSQLCriteriaExpression.Create(FAST.Where.Expression, FAST.Params);
  FActiveValues := nil;
end;

function TFluentSQL.Delete: IFluentSQL;
begin
  _SetSection(secDelete);
  Result := Self;
end;

/// <summary>
///   Desc marca a ULTIMA coluna do ORDER BY, logo exige que exista uma.
///
///   A guarda era um Assert (FluentSQL.pas:838 antes desta mudanca) e tinha
///   dois problemas independentes:
///
///   1. Assert some com {$C-}, o default de release. Sem ele, .OrderBy().Desc
///      cai em Columns[-1] e o erro que chega ao chamador e um
///      EArgumentOutOfRangeException de dentro da TList, sem nome de metodo.
///   2. Afirmava sobre FAST.ASTColumns e indexava FAST.OrderBy.Columns. Hoje as
///      duas sao o MESMO objeto enquanto a secao e secOrderBy - quem as liga e
///      _DefineSectionOrderBy (FluentSQL.pas:794, "FAST.ASTColumns :=
///      FAST.OrderBy.Columns") e _SetSection nao tem caminho de saida que
///      desfaca isso antes do _AssertSection([secOrderBy]) daqui. Ou seja: a
///      afirmacao NAO estava medindo colecao errada na pratica. Continuava
///      sendo o nome errado para ler, e passa a citar a colecao que de fato
///      indexa.
///
///   Nao ha Asc para receber a mesma guarda: a interface nao tem esse metodo
///   (dirAscending e o default de TFluentSQLOrderByColumn). Desc e o unico
///   modificador de direcao da API.
/// </summary>
function TFluentSQL.Desc: IFluentSQL;
begin
  _AssertSection([secOrderBy]);
  if FAST.OrderBy.Columns.Count = 0 then
    raise EArgumentException.Create(
      'IFluentSQL.Desc chamado sem nenhuma coluna no ORDER BY: Desc marca a ' +
      'ultima coluna da clausula, e nao ha ultima. Passe a coluna em OrderBy ' +
      '(".OrderBy(''NOME'').Desc") em vez de ".OrderBy().Desc".');
  (FAST.OrderBy.Columns[FAST.OrderBy.Columns.Count -1] as IFluentSQLOrderByColumn).Direction := dirDescending;
  Result := Self;
end;

destructor TFluentSQL.Destroy;
begin
  FActiveExpr := nil;
  FActiveValues := nil;
  FOperator := nil;
  FFunction := nil;
  FAST := nil;
  inherited;
end;

function TFluentSQL.Distinct: IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqDistinct;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  if AValue = '' then
    FActiveExpr.Fun(FOperator.IsEqual(AValue))
  else
    FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Exists(const ASubQuery: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsExists(ASubQuery));
  Result := Self;
end;

function TFluentSQL.Expression(const ATerm: array of const): IFluentSQLCriteriaExpression;
begin
  Result := TFluentSQLCriteriaExpression.Create(
    TUtils.SqlArrayOfConstToParameterizedSql(ATerm, FAST.Params),
    FAST.Params);
end;

function TFluentSQL.Expression(const ATerm: String): IFluentSQLCriteriaExpression;
begin
  Result := TFluentSQLCriteriaExpression.Create(ATerm, FAST.Params);
end;

function TFluentSQL.From(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  Result := From('(' + AExpression.AsString + ')');
end;

function TFluentSQL.From(const AQuery: IFluentSQL): IFluentSQL;
begin
  Result := From('(' + AQuery.AsString + ')');
end;

/// <summary>
///   No SELECT, From acumula relacoes e vira a lista separada por virgula do
///   FROM - forma valida e antiga. No DELETE, a MESMA chamada acumulava do
///   mesmo jeito e produzia "DELETE FROM A AS X, B AS Y", que NENHUM dos sete
///   motores relacionais analisa. Medido, transcricao literal em
///   Test Delphi\Common_tests\test.delete.multirelacao.matrix.sql:
///
///     SQL Server 2022 16.0.4265.3  Msg 156 / Msg 102
///     Oracle 23.26.2.0.0           ORA-03048
///     PostgreSQL 16.14             syntax error at or near ","
///     MySQL 8.4.11                 ERROR 1064
///     Firebird 5.0.4               SQL error code = -104
///     SQLite 3.53.4                near ",": syntax error
///     DB2 12.1.5.0                 SQL0104N
///
///   Nao ha o que emitir no lugar, e NAO por falta de esforco: as formas
///   multi-relacao nativas nao querem dizer a mesma coisa umas que as outras.
///   "DELETE X FROM A X JOIN B Y" (T-SQL) e "DELETE FROM A USING B" (PostgreSQL
///   e Oracle 23ai) apagam de UMA relacao filtrando pela outra; "DELETE X, Y
///   FROM A X JOIN B Y" (MySQL) apaga das DUAS - e o T-SQL RECUSA essa segunda
///   (Msg 102, medido). Traduzir uma chamada para formas de semantica diferente
///   por dialeto seria trocar SQL que nao executa por SQL que executa APAGANDO
///   COISAS DIFERENTES conforme o banco.
///
///   E a API nao tem como saber qual das duas foi pedida: nao ha designador de
///   alvo, nao ha condicao de juncao propria da secao, nao ha marcador de
///   relacao auxiliar. Duas chamadas de From num DELETE nao expressam nada.
///
///   A GUARDA ESTA AQUI, e nao no serializador, por tres razoes: falha na
///   chamada que errou e nao la adiante no AsString; vale para os dialetos
///   todos sem uma linha por driver; e nao acrescenta membro a
///   IFluentSQLSerialize.
///
///   O QUE ELA FECHA, COM PRECISAO: a LISTA DE RELACOES DO FROM da secao
///   DELETE. Este e o unico ponto de entrada que alimenta FAST.ASTTableNames -
///   IFluentSQL nao publica o AST, entao IFluentSQLDelete.TableNames.Add nao e
///   alcancavel por consumidor.
///
///   O QUE ELA NAO FECHA: a segunda relacao que entra por _CreateJoin (nesta
///   mesma unit, em "function TFluentSQL._CreateJoin(AjoinType: TJoinType;
///   const ATableName: String): IFluentSQL"), que nao passa por ASTTableNames e
///   por isso nunca e vista por esta contagem. Essa porta tem GUARDA PROPRIA,
///   la mesmo, e hoje recusa - leia o comentario dela antes de mexer em
///   qualquer uma das duas.
///
///   ⚠️ A PREVISAO QUE ESTE COMENTARIO CARREGAVA ESTAVA ERRADA, e fica escrito
///   porque um mantenedor que a lesse iria REVERTER a guarda do JOIN achando
///   que cumpria um plano. O texto anterior dizia que "a do JOIN e TRADUZIVEL e
///   nao recusavel" e que "quem for mexer la NAO deve copiar a decisao daqui".
///
///   O que o desmentiu: a revisao de entao mediu SO o InnerJoin. Medindo os
///   quatro tipos, com LeftJoin e sem WHERE a forma nativa APAGA A TABELA
///   INTEIRA - A: 4 -> 0 - e reporta SUCESSO, nos dois motores que a analisam,
///   porque na juncao externa a condicao nao filtra nada. InnerJoin filtra,
///   LeftJoin nao: a familia nao tem UMA semantica, e traduzi-la escolheria
///   pelo usuario entre dois resultados medidos como diferentes. A porta foi
///   RECUSADA, nao traduzida.
///
///   Continua verdadeiro o que aquela previsao acertava: para o InnerJoin
///   ISOLADO existe forma portavel aceita pelos sete. Isso e tarefa propria - a
///   intersecao NAO e vazia. Matriz em
///   Test Delphi\Common_tests\test.delete.join.matrix.sql.
/// </summary>
function TFluentSQL.From(const ATableName: String): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete]);
  if (FActiveSection = secDelete) and (FAST.ASTTableNames.Count > 0) then
    raise EFluentSQLConstructNotSupported.Create(
      'DELETE com mais de uma relacao',
      'Emita um DELETE por relacao, ou restrinja a unica relacao alvo pelo ' +
      'WHERE - inclusive com subconsulta, que e portavel nos sete. Se o que ' +
      'se queria era apagar de duas tabelas, sao duas instrucoes.');
  FAST.ASTName := FAST.ASTTableNames.Add;
  FAST.ASTName.AliasKeyword := _RelationAliasKeyword;
  FAST.ASTName.Name := ATableName;
  Result := Self;
end;

function TFluentSQL.FullJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtFULL, ATableName);
end;

function TFluentSQL.GreaterThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GroupBy(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secGroupBy);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Having(const AExpression: String): IFluentSQL;
begin
  _SetSection(secHaving);
  if AExpression = '' then
    Result := Self
  else
    Result := AndOpe(AExpression);
end;

function TFluentSQL.Having(const AExpression: array of const): IFluentSQL;
begin
  Result := Having(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.Having(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  _SetSection(secHaving);
  Result := AndOpe(AExpression);
end;

function TFluentSQL.InnerJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtINNER, ATableName);
end;

function TFluentSQL.InnerJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  InnerJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.Insert: IFluentSQL;
begin
  _SetSection(secInsert);
  Result := Self;
end;

function TFluentSQL.AddRow: IFluentSQL;
begin
  _AssertSection([secInsert]);
  FAST.Insert.AddRow;
  Result := Self;
end;

function TFluentSQL._InternalSet(const AColumnName, AColumnValue: String): IFluentSQL;
var
  LPair: IFluentSQLNameValue;
begin
  _AssertSection([secInsert, secUpdate]);
  LPair := FActiveValues.Add;
  LPair.Name := AColumnName;
  LPair.Value := AColumnValue;
  Result := Self;
end;

function TFluentSQL.Into(const ATableName: String): IFluentSQL;
begin
  _AssertSection([secInsert]);
  FAST.Insert.TableName := ATableName;
  Result := Self;
end;

function TFluentSQL.IsEmpty: Boolean;
begin
  Result := FAST.ASTSection.IsEmpty;
end;

function TFluentSQL.InValues(const AValue: TArray<String>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.InValues(const AValue: TArray<Double>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsIn(AValue));
  Result := Self;
end;

function TFluentSQL.IsNotNull: IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotNull);
  Result := Self;
end;

function TFluentSQL.IsNull: IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNull);
  Result := Self;
end;

function TFluentSQL.LeftJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtLEFT, ATableName);
end;

function TFluentSQL.LeftJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  LeftJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.Like(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLike(AValue));
  Result := Self;
end;

function TFluentSQL.LikeFull(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeFull(AValue));
  Result := Self;
end;

function TFluentSQL.LikeLeft(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeLeft(AValue));
  Result := Self;
end;

function TFluentSQL.LikeRight(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLikeRight(AValue));
  Result := Self;
end;

function TFluentSQL.Lower: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Lower(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Max: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Max(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Min: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Min(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Month(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Month(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Month(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: Extended): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: Integer): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotExists(const ASubQuery: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotExists(ASubQuery));
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: TArray<String>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: TArray<Double>): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.NotLike(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLike(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeFull(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeFull(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeLeft(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeLeft(AValue));
  Result := Self;
end;

function TFluentSQL.NotLikeRight(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotLikeRight(AValue));
  Result := Self;
end;

function TFluentSQL.OrderBy(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  _SetSection(secOrderBy);
  Result := Column(ACaseExpression);
end;

function TFluentSQL.RightJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  RightJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.RightJoin(const ATableName: String): IFluentSQL;
begin
  Result := _CreateJoin(jtRIGHT, ATableName);
end;

function TFluentSQL.Merge: IFluentSQLMerge;
begin
  _SetSection(secMerge);
  Result := TFluentSQLMerge.Create(FAST);
end;

function TFluentSQL.OrderBy(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secOrderBy);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Select(const AColumnName: String): IFluentSQL;
begin
  _SetSection(secSelect);
  if AColumnName = '' then
    Result := Self
  else
    Result := Column(AColumnName);
end;

function TFluentSQL.Select(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL;
begin
  _SetSection(secSelect);
  Result := Column(ACaseExpression);
end;

procedure TFluentSQL._SetSection(ASection: TSection);
begin
  case ASection of
    secSelect:  _DefineSectionSelect;
    secDelete:  _DefineSectionDelete;
    secInsert:  _DefineSectionInsert;
    secUpdate:  _DefineSectionUpdate;
    secWhere:   _DefineSectionWhere;
    secGroupBy: _DefineSectionGroupBy;
    secHaving:  _DefineSectionHaving;
    secOrderBy: _DefineSectionOrderBy;
    secMerge:   ; // MERGE is handled by its own builder but we must allow the section
  else
      raise Exception.Create('TCriteria.SetSection: Unknown section');
  end;
  FActiveSection := ASection;
end;

function TFluentSQL.WithAlias(const AAlias: String): IFluentSQL;
begin
  FAST.WithAlias := AAlias;
  Result := Self;
end;

function TFluentSQL.Over(const APartitionBy, AOrderBy: String): IFluentSQL;
var
  LOverStr: String;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  LOverStr := ' OVER (';
  if APartitionBy <> '' then
    LOverStr := LOverStr + 'PARTITION BY ' + APartitionBy;
  if AOrderBy <> '' then
  begin
    if APartitionBy <> '' then
      LOverStr := LOverStr + ' ';
    LOverStr := LOverStr + 'ORDER BY ' + AOrderBy;
  end;
  LOverStr := LOverStr + ')';
  FAST.ASTName.Name := FAST.ASTName.Name + LOverStr;
  Result := Self;
end;

function TFluentSQL.Union(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'UNION';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.UnionAll(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'UNION ALL';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.Intersect(const AQuery: IFluentSQL): IFluentSQL;
begin
  FAST.UnionType := 'INTERSECT';
  FAST.UnionQuery := AQuery;
  Result := Self;
end;

function TFluentSQL.First(const AValue: Integer): IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect, secWhere, secOrderBy, secGroupBy, secHaving]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqFirst;
  LQualifier.Value := AValue;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.Skip(const AValue: Integer): IFluentSQL;
var
  LQualifier: IFluentSQLSelectQualifier;
begin
  _AssertSection([secSelect, secWhere, secOrderBy, secGroupBy, secHaving]);
  LQualifier := FAST.Select.Qualifiers.Add;
  LQualifier.Qualifier := sqSkip;
  LQualifier.Value := AValue;
  // Esse m�todo tem que Add o Qualifier j� todo parametrizado.
  FAST.Select.Qualifiers.Add(LQualifier);
  Result := Self;
end;

function TFluentSQL.SubString(const AStart, ALength: Integer): IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.SubString(FAST.ASTName.Name, AStart, ALength);
  Result := Self;
end;

function TFluentSQL.Update(const ATableName: String): IFluentSQL;
begin
  _SetSection(secUpdate);
  FAST.Update.TableName := ATableName;
  Result := Self;
end;

function TFluentSQL.Upper: IFluentSQL;
begin
  _AssertSection([secSelect, secDelete, secJoin]);
  _AssertHaveName;
  FAST.ASTName.Name := FFunction.Upper(FAST.ASTName.Name);
  Result := Self;
end;

function TFluentSQL.Values(const AColumnName: String; const AColumnValue: array of const): IFluentSQL;
begin
  // Mesmo slot de VALOR de SetValue(array of const) - ver o comentario la.
  Result := _InternalSet(AColumnName, TUtils.SqlArrayOfConstToParameterizedValue(AColumnValue, FAST.Params));
end;

function TFluentSQL.Values(const AColumnName, AColumnValue: String): IFluentSQL;
begin
  Result := SetValue(AColumnName, AColumnValue);
end;

function TFluentSQL.Where(const AExpression: String): IFluentSQL;
begin
  _SetSection(secWhere);
  FActiveOperator := opeWhere;
  if AExpression = '' then
    Result := Self
  else
    Result := AndOpe(AExpression);
end;

function TFluentSQL.Where(const AExpression: array of const): IFluentSQL;
begin
  Result := Where(TUtils.SqlArrayOfConstToParameterizedSql(AExpression, FAST.Params));
end;

function TFluentSQL.Where(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL;
begin
  _SetSection(secWhere);
  FActiveOperator := opeWhere;
  Result := AndOpe(AExpression);
end;

function TFluentSQL.Year(const AValue: String): IFluentSQL;
begin
  _AssertSection([secSelect, secJoin, secWhere]);
  _AssertHaveName;
  case FActiveSection of
    secSelect: FAST.ASTName.Name := FFunction.Year(AValue);
    secWhere: FActiveExpr.Fun(FFunction.Year(AValue));
  end;
  Result := Self;
end;

function TFluentSQL.From(const ATableName, AAlias: String): IFluentSQL;
begin
  From(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.FullJoin(const ATableName, AAlias: String): IFluentSQL;
begin
  FullJoin(ATableName).Alias(AAlias);
  Result := Self;
end;

function TFluentSQL.NotIn(const AValue: String): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotIn(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterEqThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.GreaterThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsGreaterThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessEqThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessEqThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.LessThan(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsLessThan(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TDate): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TDateTime): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

function TFluentSQL.Equal(const AValue: TGUID): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsEqual(AValue));
  Result := Self;
end;

function TFluentSQL.NotEqual(const AValue: TGUID): IFluentSQL;
begin
  _AssertOperator([opeWhere, opeAND, opeOR]);
  FActiveExpr.Ope(FOperator.IsNotEqual(AValue));
  Result := Self;
end;

end.






