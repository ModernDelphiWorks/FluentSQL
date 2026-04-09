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

unit FluentSQL.Interfaces;


{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

type
  TExpressionOperation = (opNone, opAND, opOR, opOperation, opFunction);
  TOperator = (opeNone, opeWhere, opeAND, opeOR);
  TOperators = set of TOperator;
  TFluentSQLDriver = (dbnMSSQL, dbnMySQL, dbnFirebird, dbnSQLite, dbnInterbase, dbnDB2,
                   dbnOracle, dbnInformix, dbnPostgreSQL, dbnADS, dbnASA,
                   dbnAbsoluteDB, dbnMongoDB, dbnElevateDB, dbnNexusDB);

  /// <summary>ESP-016: one opt-in fragment registered for a specific engine; not portable SQL.</summary>
  TDialectOnlyFragment = record
    Dialect: TFluentSQLDriver;
    Sql: string;
  end;

  TFluentSQLDataFieldType = (dftUnknown, dftString, dftInteger, dftFloat, dftDate,
    dftArray, dftText, dftDateTime, dftGuid, dftBoolean);

  IFluentSQL = interface;
  IFluentSQLAST = interface;
  IFluentSQLFunctions = interface;

  IFluentSQLParam = interface
    ['{3320078D-5B6A-4A8E-8C79-D8763B8F8942}']
    function GetName: string;
    function GetValue: Variant;
    function GetDataType: TFluentSQLDataFieldType;
    property Name: string read GetName;
    property Value: Variant read GetValue;
    property DataType: TFluentSQLDataFieldType read GetDataType;
  end;

  IFluentSQLParams = interface
    ['{842C3F24-B832-475D-85B7-3E5A35985860}']
    function Add(const AValue: Variant; ADataType: TFluentSQLDataFieldType): string;
    function GetItem(AIndex: Integer): IFluentSQLParam;
    function Count: Integer;
    procedure Clear;
    property Items[AIndex: Integer]: IFluentSQLParam read GetItem; default;
  end;

  IFluentSQLExpression = interface
    ['{D1DA5991-9755-485A-A031-9C25BC42A2AA}']
    function GetLeft: IFluentSQLExpression;
    function GetOperation: TExpressionOperation;
    function GetRight: IFluentSQLExpression;
    function GetTerm: String;
    procedure SetLeft(const value: IFluentSQLExpression);
    procedure SetOperation(const value: TExpressionOperation);
    procedure SetRight(const value: IFluentSQLExpression);
    procedure SetTerm(const value: String);
    procedure Assign(const ANode: IFluentSQLExpression);
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize(AAddParens: Boolean = False): String;
    property Term: String read GetTerm write SetTerm;
    property Operation: TExpressionOperation read GetOperation write SetOperation;
    property Left: IFluentSQLExpression read GetLeft write SetLeft;
    property Right: IFluentSQLExpression read GetRight write SetRight;
  end;

  IFluentSQLCriteriaExpression = interface
    ['{E55E5EAC-BA0A-49C7-89AF-C2BAF51E5561}']
    function AndOpe(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function AndOpe(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function AndOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function OrOpe(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function Ope(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: array of const): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: String): IFluentSQLCriteriaExpression; overload;
    function Fun(const AExpression: IFluentSQLExpression): IFluentSQLCriteriaExpression; overload;
    function AsString: String;
    function Expression: IFluentSQLExpression;
  end;

  IFluentSQLCaseWhenThen = interface
    ['{C08E0BA8-87EA-4DA7-A4F2-DD718DB2E972}']
    function GetThenExpression: IFluentSQLExpression;
    function GetWhenExpression: IFluentSQLExpression;
    procedure SetThenExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenExpression(const AValue: IFluentSQLExpression);
    //
    property WhenExpression: IFluentSQLExpression read GetWhenExpression write SetWhenExpression;
    property ThenExpression: IFluentSQLExpression read GetThenExpression write SetThenExpression;
  end;

  IFluentSQLCaseWhenList = interface
    ['{CD02CC25-7261-4C37-8D22-532320EFAEB1}']
    function GetWhenThen(AIdx: Integer): IFluentSQLCaseWhenThen;
    procedure SetWhenThen(AIdx: Integer; const AValue: IFluentSQLCaseWhenThen);
    //
    function Add: IFluentSQLCaseWhenThen; overload;
    function Add(const AWhenThen: IFluentSQLCaseWhenThen): Integer; overload;
    function Count: Integer;
    property WhenThen[AIdx: Integer]: IFluentSQLCaseWhenThen read GetWhenThen write SetWhenThen; default;
  end;

  IFluentSQLCase = interface
    ['{C3CDCEE4-990A-4709-9B24-D0A1DF2E3373}']
    function GetCaseExpression: IFluentSQLExpression;
    function GetElseExpression: IFluentSQLExpression;
    function GetWhenList: IFluentSQLCaseWhenList;
    procedure SetCaseExpression(const AValue: IFluentSQLExpression);
    procedure SetElseExpression(const AValue: IFluentSQLExpression);
    procedure SetWhenList(const AValue: IFluentSQLCaseWhenList);
    //
    function Serialize: String;
    property CaseExpression: IFluentSQLExpression read GetCaseExpression write SetCaseExpression;
    property WhenList: IFluentSQLCaseWhenList read GetWhenList write SetWhenList;
    property ElseExpression: IFluentSQLExpression read GetElseExpression write SetElseExpression;
  end;

  IFluentSQLCriteriaCase = interface
    ['{B542AEE6-5F0D-4547-A7DA-87785432BC65}']
    function _GetCase: IFluentSQLCase;
    //
    function AndOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: String): IFluentSQLCriteriaCase; overload;
    function ElseIf(const AValue: int64): IFluentSQLCriteriaCase; overload;
    function EndCase: IFluentSQL;
    function OrOpe(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: String): IFluentSQLCriteriaCase; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: String): IFluentSQLCriteriaCase; overload;
    function IfThen(const AValue: int64): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: String): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: array of const): IFluentSQLCriteriaCase; overload;
    function When(const ACondition: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    property CaseExpr: IFluentSQLCase read _GetCase;
  end;

  IFluentSQL = interface
    ['{DFDEA57B-A75B-450E-A576-DC49523B01E7}']
    function AndOpe(const AExpression: array of const): IFluentSQL; overload;
    function AndOpe(const AExpression: String): IFluentSQL; overload;
    function AndOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Alias(const AAlias: String): IFluentSQL;
    function CaseExpr(const AExpression: String = ''): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: array of const): IFluentSQLCriteriaCase; overload;
    function CaseExpr(const AExpression: IFluentSQLCriteriaExpression): IFluentSQLCriteriaCase; overload;
    function OnCond(const AExpression: String): IFluentSQL; overload;
    function OnCond(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: array of const): IFluentSQL; overload;
    function OrOpe(const AExpression: String): IFluentSQL; overload;
    function OrOpe(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function SetValue(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Extended; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Double; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; AColumnValue: Currency; ADecimalPlaces: Integer): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDate): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TDateTime): IFluentSQL; overload;
    function SetValue(const AColumnName: String; const AColumnValue: TGUID): IFluentSQL; overload;
    function All: IFluentSQL;
    function Clear: IFluentSQL;
    function ClearAll: IFluentSQL;
    function Column(const AColumnName: String = ''): IFluentSQL; overload;
    function Column(const ATableName: String; const AColumnName: String): IFluentSQL; overload;
    function Column(const AColumnsName: array of const): IFluentSQL; overload;
    function Column(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Delete: IFluentSQL;
    function Desc: IFluentSQL;
    function Distinct: IFluentSQL;
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
    function FullJoin(const ATableName: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String): IFluentSQL; overload;
    function FullJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function InnerJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function LeftJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function RightJoin(const ATableName: String; const AAlias: String): IFluentSQL; overload;
    function Insert: IFluentSQL;
    function AddRow: IFluentSQL;
    function Into(const ATableName: String): IFluentSQL;
    function IsEmpty: Boolean;
    function OrderBy(const AColumnName: String = ''): IFluentSQL; overload;
    function OrderBy(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function Select(const AColumnName: String = ''): IFluentSQL; overload;
    function Select(const ACaseExpression: IFluentSQLCriteriaCase): IFluentSQL; overload;
    function WithAlias(const AAlias: String): IFluentSQL;
    function Over(const APartitionBy, AOrderBy: String): IFluentSQL;
    function Union(const AQuery: IFluentSQL): IFluentSQL;
    function UnionAll(const AQuery: IFluentSQL): IFluentSQL;
    function Intersect(const AQuery: IFluentSQL): IFluentSQL;
    function Skip(const AValue: Integer): IFluentSQL;
    function Update(const ATableName: String): IFluentSQL;
    function Where(const AExpression: String = ''): IFluentSQL; overload;
    function Where(const AExpression: array of const): IFluentSQL; overload;
    function Where(const AExpression: IFluentSQLCriteriaExpression): IFluentSQL; overload;
    function Values(const AColumnName, AColumnValue: String): IFluentSQL; overload;
    function Values(const AColumnName: String; const AColumnValue: array of const): IFluentSQL; overload;
    function First(const AValue: Integer): IFluentSQL;
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
    function GreaterThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterThan(const AValue: TDateTime): IFluentSQL; overload;
    function GreaterEqThan(const AValue: Extended): IFluentSQL; overload;
    function GreaterEqThan(const AValue: Integer) : IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDate): IFluentSQL; overload;
    function GreaterEqThan(const AValue: TDateTime): IFluentSQL; overload;
    function LessThan(const AValue: Extended): IFluentSQL; overload;
    function LessThan(const AValue: Integer) : IFluentSQL; overload;
    function LessThan(const AValue: TDate): IFluentSQL; overload;
    function LessThan(const AValue: TDateTime): IFluentSQL; overload;
    function LessEqThan(const AValue: Extended): IFluentSQL; overload;
    function LessEqThan(const AValue: Integer) : IFluentSQL; overload;
    function LessEqThan(const AValue: TDate) : IFluentSQL; overload;
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
    function Exists(const AValue: String): IFluentSQL; overload;
    function NotExists(const AValue: String): IFluentSQL; overload;
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
    /// <summary>ESP-016 / ADR-016: append SQL only when serializing for ADialect; other engines omit. Not universal SQL.</summary>
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string): IFluentSQL; overload;
    /// <summary>ESP-016: same as string overload; scalars bind via IFluentSQLParams (placeholders :pN in AST dialect).</summary>
    function ForDialectOnly(const ADialect: TFluentSQLDriver; const AExpression: array of const): IFluentSQL; overload;
    //
    function AsFun: IFluentSQLFunctions;
    function AsString: String;
    function Params: IFluentSQLParams;
  end;

  IFluentSQLName = interface
    ['{FA82F4B9-1202-4926-8385-C2100EB0CA97}']
    function _GetAlias: String;
    function _GetCase: IFluentSQLCase;
    function _GetName: String;
    procedure _SetAlias(const Value: String);
    procedure _SetCase(const Value: IFluentSQLCase);
    procedure _SetName(const Value: String);
    //
    procedure Clear;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Name: String read _GetName write _SetName;
    property Alias: String read _GetAlias write _SetAlias;
    property CaseExpr: IFluentSQLCase read _GetCase write _SetCase;
  end;

  IFluentSQLNames = interface
    ['{6030F621-276C-4C52-9135-F029BEEEB39C}']
    function GetColumns(AIdx: Integer): IFluentSQLName;
    //
    function Add: IFluentSQLName; overload;
    procedure Add(const Value: IFluentSQLName); overload;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Columns[AIdx: Integer]: IFluentSQLName read GetColumns; default;
  end;

  IFluentSQLSection = interface
    ['{6FA93873-2285-4A08-B700-7FBAAE846F73}']
    function _GetName: String;
    //
    procedure Clear;
    function IsEmpty: Boolean;
    property Name: String read _GetName;
  end;

  TOrderByDirection = (dirAscending, dirDescending);

  IFluentSQLOrderByColumn = interface(IFluentSQLName)
    ['{AC57006D-9087-4319-8258-97E68801503A}']
    function _GetDirection: TOrderByDirection;
    procedure _SetDirection(const value: TOrderByDirection);
    //
    property Direction: TOrderByDirection read _GetDirection write _SetDirection;
  end;

  IFluentSQLOrderBy = interface(IFluentSQLSection)
    ['{8D3484F7-9856-4232-AFD5-A80FB4F7833E}']
    function Columns: IFluentSQLNames;
    function Serialize: String;
  end;

  TSelectQualifierType = (sqFirst, sqSkip, sqDistinct);

  IFluentSQLSelectQualifier = interface
    ['{44EBF85E-10BB-45C0-AC6E-336A82B3A81D}']
    function  _GetQualifier: TSelectQualifierType;
    function  _GetValue: Integer;
    procedure _SetQualifier(const Value: TSelectQualifierType);
    procedure _SetValue(const Value: Integer);
    //
    property Qualifier: TSelectQualifierType read _GetQualifier write _SetQualifier;
    property Value: Integer read _GetValue write _SetValue;
  end;

  IFluentSQLSelectQualifiers = interface
    ['{4AC225D9-2447-4906-8285-23D55F59B676}']
    function _GetQualifier(AIdx: Integer): IFluentSQLSelectQualifier;
    //
    function Add: IFluentSQLSelectQualifier; overload;
    procedure Add(AQualifier: IFluentSQLSelectQualifier); overload;
    procedure Clear;
    function ExecutingPagination: Boolean;
    function Count: Integer;
    function IsEmpty: Boolean;
    function SerializePagination: String;
    function SerializeDistinct: String;
    property Qualifier[AIdx: Integer]: IFluentSQLSelectQualifier read _GetQualifier; default;
  end;

  IFluentSQLSelect = interface(IFluentSQLSection)
    ['{E7EE1220-ACB9-4A02-82E5-C4F51AD2D333}']
    procedure Clear;
    function IsEmpty: Boolean;
    function Columns: IFluentSQLNames;
    function TableNames: IFluentSQLNames;
    function Qualifiers: IFluentSQLSelectQualifiers;
    function Serialize: String;
  end;

  IFluentSQLWhere = interface(IFluentSQLSection)
    ['{664D8830-662B-4993-BD9C-325E6C1A2ACA}']
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
    //
    function Serialize: String;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;

  IFluentSQLDelete = interface(IFluentSQLSection)
    ['{8823EABF-FCFB-4BDE-AF56-7053944D40DB}']
    function TableNames: IFluentSQLNames;
    function Serialize: String;
  end;

  TJoinType = (jtINNER, jtLEFT, jtRIGHT, jtFULL);

  IFluentSQLJoin = interface(IFluentSQLSection)
    ['{BCB6DF85-05DE-43A0-8622-5627B88FB914}']
    function _GetCondition: IFluentSQLExpression;
    function _GetJoinedTable: IFluentSQLName;
    function _GetJoinType: TJoinType;
    procedure _SetCondition(const Value: IFluentSQLExpression);
    procedure _SetJoinedTable(const Value: IFluentSQLName);
    procedure _SetJoinType(const Value: TJoinType);
    //
    property JoinedTable: IFluentSQLName read _GetJoinedTable write _SetJoinedTable;
    property JoinType: TJoinType read _GetJoinType write _SetJoinType;
    property Condition: IFluentSQLExpression read _GetCondition write _SetCondition;
  end;

  IFluentSQLJoins = interface
    ['{2A9F9075-01C3-433A-9E65-0264688D2E88}']
    function _GetJoins(AIdx: Integer): IFluentSQLJoin;
    procedure _SetJoins(AIdx: Integer; const Value: IFluentSQLJoin);
    //
    function Add: IFluentSQLJoin; overload;
    procedure Add(const AJoin: IFluentSQLJoin); overload;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    function Serialize: String;
    property Joins[AIidx: Integer]: IFluentSQLJoin read _GetJoins write _SetJoins; default;
  end;

  IFluentSQLGroupBy = interface(IFluentSQLSection)
    ['{820E003C-81FF-49BB-A7AC-2F00B58BE497}']
    function Columns: IFluentSQLNames;
    function Serialize: String;
  end;

  IFluentSQLHaving = interface(IFluentSQLSection)
    ['{FAD8D0B5-CF5A-4615-93A5-434D4B399E28}']
    function _GetExpression: IFluentSQLExpression;
    procedure _SetExpression(const Value: IFluentSQLExpression);
    //
    function Serialize: String;
    property Expression: IFluentSQLExpression read _GetExpression write _SetExpression;
  end;

  IFluentSQLNameValue = interface
    ['{FC6C53CA-7CD1-475B-935C-B356E73105CF}']
    function  _GetName: String;
    function  _GetValue: String;
    procedure _SetName(const Value: String);
    procedure _SetValue(const Value: String);
    //
    procedure Clear;
    function IsEmpty: Boolean;
    property Name: String read _GetName write _SetName;
    property Value: String read _GetValue write _SetValue;
  end;

  IFluentSQLNameValuePairs = interface
    ['{561CA151-60B9-45E1-A443-5BAEC88DA955}']
    function  _GetItem(AIdx: integer): IFluentSQLNameValue;
    //
    function Add: IFluentSQLNameValue; overload;
    procedure Add(const ANameValue: IFluentSQLNameValue); overload;
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    property Item[AIdx: Integer]: IFluentSQLNameValue read _GetItem; default;
  end;

  IFluentSQLInsert = interface(IFluentSQLSection)
    ['{61136DB2-EBEB-46D1-8B9B-F5B6DBD1A423}']
    function  _GetTableName: String;
    procedure _SetTableName(const value: String);
    //
    function Columns: IFluentSQLNames;
    function Values: IFluentSQLNameValuePairs;
    function AddRow: IFluentSQLInsert;
    function SerializedRowCount: Integer;
    function SerializedRow(AIndex: Integer): IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

  IFluentSQLUpdate = interface(IFluentSQLSection)
    ['{90F7AC38-6E5A-4F5F-9A78-482FE2DBF7B1}']
    function  _GetTableName: String;
    procedure _SetTableName(const value: String);
    //
    function Values: IFluentSQLNameValuePairs;
    function Serialize: String;
    property TableName: String read _GetTableName write _SetTableName;
  end;

  IFluentSQLAST = interface
    ['{09DC93FD-ABC4-4999-80AE-124EC1CAE9AC}']
    function _GetASTColumns: IFluentSQLNames;
    procedure _SetASTColumns(const Value: IFluentSQLNames);
    function _GetASTSection: IFluentSQLSection;
    procedure _SetASTSection(const Value: IFluentSQLSection);
    function _GetASTName: IFluentSQLName;
    procedure _SetASTName(const Value: IFluentSQLName);
    function _GetASTTableNames: IFluentSQLNames;
    procedure _SetASTTableNames(const Value: IFluentSQLNames);
    function _GetParams: IFluentSQLParams;
    function _GetWithAlias: String;
    procedure _SetWithAlias(const Value: String);
    function _GetUnionType: String;
    procedure _SetUnionType(const Value: String);
    function _GetUnionQuery: IFluentSQL;
    procedure _SetUnionQuery(const Value: IFluentSQL);
    //
    function GetSerializationDialect: TFluentSQLDriver;
    procedure AddDialectOnly(const ADialect: TFluentSQLDriver; const ASqlFragment: string);
    function DialectOnlyCount: Integer;
    function GetDialectOnlyItem(AIndex: Integer): TDialectOnlyFragment;
    //
    procedure Clear;
    function IsEmpty: Boolean;
    function Select: IFluentSQLSelect;
    function Delete: IFluentSQLDelete;
    function Insert: IFluentSQLInsert;
    function Update: IFluentSQLUpdate;
    function Joins: IFluentSQLJoins;
    function Where: IFluentSQLWhere;
    function GroupBy: IFluentSQLGroupBy;
    function Having: IFluentSQLHaving;
    function OrderBy: IFluentSQLOrderBy;
    property ASTColumns: IFluentSQLNames read _GetASTColumns write _SetASTColumns;
    property ASTSection: IFluentSQLSection read _GetASTSection write _SetASTSection;
    property ASTName: IFluentSQLName read _GetASTName write _SetASTName;
    property ASTTableNames: IFluentSQLNames read _GetASTTableNames write _SetASTTableNames;
    property Params: IFluentSQLParams read _GetParams;
    property WithAlias: String read _GetWithAlias write _SetWithAlias;
    property UnionType: String read _GetUnionType write _SetUnionType;
    property UnionQuery: IFluentSQL read _GetUnionQuery write _SetUnionQuery;
  end;

  IFluentSQLSerialize = interface
    ['{8F7A3C1F-2704-401F-B1DF-D334EEFFC8B7}']
    function AsString(const AAST: IFluentSQLAST): String;
  end;

  TFluentSQLOperatorCompare = (fcEqual, fcNotEqual,
    fcGreater, fcGreaterEqual,
    fcLess, fcLessEqual,
    fcIn, fcNotIn,
    fcIsNull, fcIsNotNull,
    fcBetween, fcNotBetween,
    fcExists, fcNotExists,
    fcLikeFull, fcLikeLeft, fcLikeRight,
    fcNotLikeFull, fcNotLikeLeft, fcNotLikeRight,
    fcLike, fcNotLike);

  IFluentSQLOperator = interface
    ['{A07D4935-0C52-4D8A-A3CF-5837AFE01C75}']
    function _GetColumnName: String;
    function _GetCompare: TFluentSQLOperatorCompare;
    function _GetParams: IFluentSQLParams;
    function _GetValue: Variant;
    function _GetDataType: TFluentSQLDataFieldType;
    procedure _SetColumnName(const Value: String);
    procedure _SetCompare(const Value: TFluentSQLOperatorCompare);
    procedure _SetParams(const Value: IFluentSQLParams);
    procedure _SetValue(const Value: Variant);
    procedure _SetDataType(const Value: TFluentSQLDataFieldType);
    //
    property ColumnName: String read _GetColumnName write _SetColumnName;
    property Compare: TFluentSQLOperatorCompare read _GetCompare write _SetCompare;
    property Params: IFluentSQLParams read _GetParams write _SetParams;
    property Value: Variant read _GetValue write _SetValue;
    property DataType: TFluentSQLDataFieldType read _GetDataType write _SetDataType;
    function AsString: String;
  end;

  IFluentSQLOperators = interface
    ['{7F855D42-FB26-4F21-BCBE-93BC407ED15B}']
    function IsEqual(const AValue: Extended) : String; overload;
    function IsEqual(const AValue: Integer): String; overload;
    function IsEqual(const AValue: String): String; overload;
    function IsEqual(const AValue: TDate): String; overload;
    function IsEqual(const AValue: TDateTime): String; overload;
    function IsEqual(const AValue: TGUID): String; overload;
    function IsNotEqual(const AValue: Extended): String; overload;
    function IsNotEqual(const AValue: Integer): String; overload;
    function IsNotEqual(const AValue: String): String; overload;
    function IsNotEqual(const AValue: TDate): String; overload;
    function IsNotEqual(const AValue: TDateTime): String; overload;
    function IsNotEqual(const AValue: TGUID): String; overload;
    function IsGreaterThan(const AValue: Extended): String; overload;
    function IsGreaterThan(const AValue: Integer): String; overload;
    function IsGreaterThan(const AValue: TDate): String; overload;
    function IsGreaterThan(const AValue: TDateTime): String; overload;
    function IsGreaterEqThan(const AValue: Extended): String; overload;
    function IsGreaterEqThan(const AValue: Integer): String; overload;
    function IsGreaterEqThan(const AValue: TDate): String; overload;
    function IsGreaterEqThan(const AValue: TDateTime): String; overload;
    function IsLessThan(const AValue: Extended): String; overload;
    function IsLessThan(const AValue: Integer): String; overload;
    function IsLessThan(const AValue: TDate): String; overload;
    function IsLessThan(const AValue: TDateTime): String; overload;
    function IsLessEqThan(const AValue: Extended): String; overload;
    function IsLessEqThan(const AValue: Integer) : String; overload;
    function IsLessEqThan(const AValue: TDate) : String; overload;
    function IsLessEqThan(const AValue: TDateTime) : String; overload;
    function IsNull: String;
    function IsNotNull: String;
    function IsLike(const AValue: String): String;
    function IsLikeFull(const AValue: String): String;
    function IsLikeLeft(const AValue: String): String;
    function IsLikeRight(const AValue: String): String;
    function IsNotLike(const AValue: String): String;
    function IsNotLikeFull(const AValue: String): String;
    function IsNotLikeLeft(const AValue: String): String;
    function IsNotLikeRight(const AValue: String): String;
    function IsIn(const AValue: TArray<Double>): String; overload;
    function IsIn(const AValue: TArray<String>): String; overload;
    function IsIn(const AValue: String): String; overload;
    function IsNotIn(const AValue: TArray<Double>): String; overload;
    function IsNotIn(const AValue: TArray<String>): String; overload;
    function IsNotIn(const AValue: String): String; overload;
    function IsExists(const AValue: String): String; overload;
    function IsNotExists(const AValue: String): String; overload;
  end;

  IFluentSQLFunctions = interface
    ['{5035E399-D3F0-48C6-BACB-9CA6D94B2BE7}']
    // Aggregation functions
    function Count(const AValue: String): String;
    function Sum(const AValue: String): String;
    function Min(const AValue: String): String;
    function Max(const AValue: String): String;
    function Average(const AValue: String): String;
    // String functions
    function Upper(const AValue: String): String;
    function Lower(const AValue: String): String;
    function Length(const AValue: String): String;
    function Trim(const AValue: String): String;
    function LTrim(const AValue: String): String;
    function RTrim(const AValue: String): String;
    function SubString(const AValue: String; const AFrom, AFor: Integer): String;
    function Concat(const AValue: array of String): String;
    // Null handling
    function Coalesce(const AValues: array of String): String;
    // Type conversion
    function Cast(const AExpression: String; const ADataType: String): String;
    // Date functions
    function Date(const AValue: String; const AFormat: String): String; overload;
    function Date(const AValue: String): String; overload;
    function Day(const AValue: String): String;
    function Month(const AValue: String): String;
    function Year(const AValue: String): String;
    function CurrentDate: String;
    function CurrentTimestamp: String;
    // Numeric functions
    function Round(const AValue: String; const ADecimals: Integer): String;
    function Floor(const AValue: String): String;
    function Ceil(const AValue: String): String;
    function Modulus(const AValue, ADivisor: String): String;
    function Abs(const AValue: String): String;
  end;

  /// <summary>ESP-017: logical column kinds for DDL; SQL text is produced per dialect.</summary>
  TDDLLogicalType = (
    dltInteger,
    dltBigInt,
    dltVarChar,
    dltBoolean,
    dltDate,
    dltDateTime,
    dltLongText,
    dltBlob
  );

  IFluentDDLColumn = interface
    ['{6E8A1F2C-9B4D-4E7A-8F31-2D5C6E7F8091}']
    function GetName: string;
    function GetLogicalType: TDDLLogicalType;
    /// <summary>For <c>dltVarChar</c>: max length; otherwise 0.</summary>
    function GetTypeArg: Integer;
    property Name: string read GetName;
    property LogicalType: TDDLLogicalType read GetLogicalType;
    property TypeArg: Integer read GetTypeArg;
  end;

  IFluentDDLTableDef = interface
    ['{7F9B2E3D-AC5E-4F8B-9442-3E6D7F8A9102}']
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    function GetColumnCount: Integer;
    function GetColumn(AIndex: Integer): IFluentDDLColumn;
    property Dialect: TFluentSQLDriver read GetDialect;
    property TableName: string read GetTableName;
  end;

  IFluentDDLBuilder = interface(IFluentDDLTableDef)
    ['{80AC3F4E-BD6F-409C-A853-4F7E8F9A0213}']
    function ColumnInteger(const AName: string): IFluentDDLBuilder;
    function ColumnBigInt(const AName: string): IFluentDDLBuilder;
    function ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLBuilder;
    function ColumnBoolean(const AName: string): IFluentDDLBuilder;
    function ColumnDate(const AName: string): IFluentDDLBuilder;
    function ColumnDateTime(const AName: string): IFluentDDLBuilder;
    function ColumnLongText(const AName: string): IFluentDDLBuilder;
    function ColumnBlob(const AName: string): IFluentDDLBuilder;
    function AsString: string;
  end;

  /// <summary>ESP-018 / ADR-018: read-only view of a DROP TABLE request for serializers.</summary>
  IFluentDDLDropTableDef = interface
    ['{91A3B4C5-D6E7-4F89-A012-345678901234}']
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    /// <summary>True when the caller requested an idempotent drop (IF EXISTS) where supported.</summary>
    function GetIfExists: Boolean;
    property Dialect: TFluentSQLDriver read GetDialect;
    property TableName: string read GetTableName;
  end;

  /// <summary>ESP-018: fluent builder for DROP TABLE SQL text (no execution).</summary>
  IFluentDDLDropBuilder = interface(IFluentDDLDropTableDef)
    ['{A2B4C6D8-E0F1-42A3-B456-789012345678}']
    /// <summary>Ask for DROP TABLE IF EXISTS (behaviour is dialect-specific; see ADR-018).</summary>
    function IfExists: IFluentDDLDropBuilder;
    function AsString: string;
  end;

  /// <summary>ESP-019 / ADR-019: read-only view of ALTER TABLE ADD (one column) for serializers.</summary>
  IFluentDDLAlterTableAddColumnDef = interface
    ['{C8E41D2A-9F3B-4E1C-A7D5-6B8E9F0A1B2C}']
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    /// <summary>The single column to add; <c>nil</c> if the builder has not received a Column* call yet.</summary>
    function GetColumn: IFluentDDLColumn;
    property Dialect: TFluentSQLDriver read GetDialect;
    property TableName: string read GetTableName;
    property Column: IFluentDDLColumn read GetColumn;
  end;

  /// <summary>ESP-019: fluent builder for ALTER TABLE ADD COLUMN SQL text (one logical column per AsString).</summary>
  IFluentDDLAlterTableAddBuilder = interface(IFluentDDLAlterTableAddColumnDef)
    ['{D9F52E3B-A04C-4F2D-B8E6-7C9F0A1B2C3D}']
    function ColumnInteger(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnBigInt(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnVarChar(const AName: string; ALength: Integer): IFluentDDLAlterTableAddBuilder;
    function ColumnBoolean(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnDate(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnDateTime(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnLongText(const AName: string): IFluentDDLAlterTableAddBuilder;
    function ColumnBlob(const AName: string): IFluentDDLAlterTableAddBuilder;
    function AsString: string;
  end;

  /// <summary>ESP-020 / ADR-020: read-only view of ALTER TABLE DROP COLUMN (one column) for serializers.</summary>
  IFluentDDLAlterTableDropColumnDef = interface
    ['{E1A24C5D-B36F-4A7B-8E8F-9A0B1C2D3E4F}']
    function GetDialect: TFluentSQLDriver;
    function GetTableName: string;
    /// <summary>The single column to drop; empty until the builder receives a DropColumn call.</summary>
    function GetColumnName: string;
    property Dialect: TFluentSQLDriver read GetDialect;
    property TableName: string read GetTableName;
    property ColumnName: string read GetColumnName;
  end;

  /// <summary>ESP-020: fluent builder for ALTER TABLE DROP COLUMN SQL text (one column target per AsString).</summary>
  IFluentDDLAlterTableDropBuilder = interface(IFluentDDLAlterTableDropColumnDef)
    ['{F2B35D6E-C470-5B8C-9F9A-0B1C2D3E4F5A}']
    function DropColumn(const AName: string): IFluentDDLAlterTableDropBuilder;
    function AsString: string;
  end;

implementation

end.


