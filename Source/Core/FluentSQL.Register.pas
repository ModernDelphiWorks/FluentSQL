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

unit FluentSQL.Register;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

{$include ..\FluentSQL.inc}

interface

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  TFluentSQLRegister = class
  strict private
    FCQLSerialize: TDictionary<string, IFluentSQLSerialize>;
    FCQLSelect: TDictionary<string, IFluentSQLSelect>;
    FCQLWhere: TDictionary<string, IFluentSQLWhere>;
    FCQLFunctions: TDictionary<string, IFluentSQLFunctions>;
    FCQLDDLSerialize: TDictionary<string, IFluentDDLSerialize>;
  private
    procedure _RegisterDrivers;
    {$IFDEF FIREBIRD}procedure _RegisterFirebird;{$ENDIF}
    {$IFDEF MSSQL}procedure _RegisterMSSQL;{$ENDIF}
    {$IFDEF MYSQL}procedure _RegisterMySQL;{$ENDIF}
    {$IFDEF SQLITE}procedure _RegisterSQLite;{$ENDIF}
    {$IFDEF INTERBASE}procedure _RegisterInterbase;{$ENDIF}
    {$IFDEF DB2}procedure _RegisterDB2;{$ENDIF}
    {$IFDEF ORACLE}procedure _RegisterOracle;{$ENDIF}
    {$IFDEF POSTGRESQL}procedure _RegisterPostgreSQL;{$ENDIF}
    {$IFDEF MONGODB}procedure _RegisterMongoDB;{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterSelect(const ADriverName: TFluentSQLDriver; const ACQLSelect: IFluentSQLSelect);
    function Select(const ADriverName: TFluentSQLDriver): IFluentSQLSelect;
    procedure RegisterWhere(const ADriverName: TFluentSQLDriver; const ACQLWhere: IFluentSQLWhere);
    function Where(const ADriverName: TFluentSQLDriver): IFluentSQLWhere;
    procedure RegisterFunctions(const ADriverName: TFluentSQLDriver; const ACQLFunctions: IFluentSQLFunctions);
    function Functions(const ADriverName: TFluentSQLDriver): IFluentSQLFunctions;
    procedure RegisterSerialize(const ADriverName: TFluentSQLDriver; const ACQLSelect: IFluentSQLSerialize);
    function Serialize(const ADriverName: TFluentSQLDriver): IFluentSQLSerialize;
    procedure RegisterDDLSerialize(const ADriverName: TFluentSQLDriver; const ACQLDDLSerialize: IFluentDDLSerialize);
    function DDLSerialize(const ADriverName: TFluentSQLDriver): IFluentDDLSerialize;
  end;

implementation

uses
  {$IFDEF FIREBIRD}FluentSQL.SerializeFirebird, FluentSQL.Select.Firebird, FluentSQL.FunctionsFirebird, FluentSQL.DDL.Serialize.Firebird,{$ENDIF}
  {$IFDEF MSSQL}FluentSQL.SerializeMSSQL, FluentSQL.Select.MSSQL, FluentSQL.FunctionsMSSQL, FluentSQL.DDL.Serialize.MSSQL,{$ENDIF}
  {$IFDEF MYSQL}FluentSQL.SerializeMySQL, FluentSQL.Select.MySQL, FluentSQL.FunctionsMySQL, FluentSQL.DDL.Serialize.MySQL,{$ENDIF}
  {$IFDEF SQLITE}FluentSQL.SerializeSQLite, FluentSQL.Select.SQLite, FluentSQL.FunctionsSQLite, FluentSQL.DDL.Serialize.SQLite,{$ENDIF}
  {$IFDEF INTERBASE}FluentSQL.SerializeInterbase, FluentSQL.SelectInterbase, FluentSQL.FunctionsInterbase,{$ENDIF}
  {$IFDEF DB2}FluentSQL.SerializeDB2, FluentSQL.SelectDB2, FluentSQL.FunctionsDB2,{$ENDIF}
  {$IFDEF ORACLE}FluentSQL.SerializeOracle, FluentSQL.Select.Oracle, FluentSQL.FunctionsOracle, FluentSQL.DDL.Serialize.Oracle,{$ENDIF}
  {$IFDEF POSTGRESQL}FluentSQL.SerializePostgreSQL, FluentSQL.Select.PostgreSQL, FluentSQL.FunctionsPostgreSQL, FluentSQL.DDL.Serialize.PostgreSQL,{$ENDIF}
  {$IFDEF MONGODB}FluentSQL.SerializeMongoDB, FluentSQL.SelectMongoDB, FluentSQL.FunctionsMongoDB, FluentSQL.DDL.Serialize.MongoDB,{$ENDIF}
  FluentSQL.Utils;

const
  /// <summary>
  ///   Nome de cada dialeto, na MESMA ordem do enum TFluentSQLDriver. O indice e
  ///   posicional: desalinhar aqui faz o Register devolver o driver errado, em
  ///   silencio. Declarado como array[TFluentSQLDriver] (e nao array[dbnA..dbnZ])
  ///   de proposito: assim qualquer membro adicionado ou removido do enum quebra
  ///   a compilacao com E2072 ate ser refletido nesta lista.
  /// </summary>
  TStrDBEngineName: array[TFluentSQLDriver] of string = (
    'MSSQL', 'MySQL', 'Firebird', 'SQLite', 'Interbase', 'DB2',
    'Oracle', 'PostgreSQL', 'MongoDB'
  );

constructor TFluentSQLRegister.Create;
begin
  FCQLSelect := TDictionary<string, IFluentSQLSelect>.Create;
  FCQLWhere := TDictionary<string, IFluentSQLWhere>.Create;
  FCQLSerialize := TDictionary<string, IFluentSQLSerialize>.Create;
  FCQLFunctions := TDictionary<string, IFluentSQLFunctions>.Create;
  FCQLDDLSerialize := TDictionary<string, IFluentDDLSerialize>.Create;

  _RegisterDrivers;
end;

destructor TFluentSQLRegister.Destroy;
var
  LKey: string;
begin
  for LKey in FCQLSerialize.Keys do
    FCQLSerialize[LKey] := nil;
  FCQLSerialize.Free;

  for LKey in FCQLSelect.Keys do
    FCQLSelect[LKey] := nil;
  FCQLSelect.Free;

  for LKey in FCQLWhere.Keys do
    FCQLWhere[LKey] := nil;
  FCQLWhere.Free;

  for LKey in FCQLFunctions.Keys do
    FCQLFunctions[LKey] := nil;
  FCQLFunctions.Free;

  for LKey in FCQLDDLSerialize.Keys do
    FCQLDDLSerialize[LKey] := nil;
  FCQLDDLSerialize.Free;

  inherited;
end;

procedure TFluentSQLRegister._RegisterDrivers;
begin
  {$IFDEF FIREBIRD}_RegisterFirebird;{$ENDIF}
  {$IFDEF MSSQL}_RegisterMSSQL;{$ENDIF}
  {$IFDEF MYSQL}_RegisterMySQL;{$ENDIF}
  {$IFDEF SQLITE}_RegisterSQLite;{$ENDIF}
  {$IFDEF INTERBASE}_RegisterInterbase;{$ENDIF}
  {$IFDEF DB2}_RegisterDB2;{$ENDIF}
  {$IFDEF ORACLE}_RegisterOracle;{$ENDIF}
  {$IFDEF POSTGRESQL}_RegisterPostgreSQL;{$ENDIF}
  {$IFDEF MONGODB}_RegisterMongoDB;{$ENDIF}
end;

{$IFDEF FIREBIRD}
procedure TFluentSQLRegister._RegisterFirebird;
begin
  Self.RegisterSerialize(dbnFirebird, TFluentSQLSerializerFirebird.Create);
  Self.RegisterSelect(dbnFirebird, TFluentSQLSelectFirebird.Create);
  Self.RegisterFunctions(dbnFirebird, TFluentSQLFunctionsFirebird.Create);
  Self.RegisterDDLSerialize(dbnFirebird, TFluentDDLSerializerFirebird.Create);
end;
{$ENDIF}

{$IFDEF MSSQL}
procedure TFluentSQLRegister._RegisterMSSQL;
begin
  Self.RegisterSerialize(dbnMSSQL, TFluentSQLSerializerMSSQL.Create);
  Self.RegisterSelect(dbnMSSQL, TFluentSQLSelectMSSQL.Create);
  Self.RegisterFunctions(dbnMSSQL, TFluentSQLFunctionsMSSQL.Create);
  Self.RegisterDDLSerialize(dbnMSSQL, TFluentDDLSerializerMSSQL.Create);
end;
{$ENDIF}

{$IFDEF MYSQL}
procedure TFluentSQLRegister._RegisterMySQL;
begin
  Self.RegisterSerialize(dbnMySQL, TFluentSQLSerializerMySQL.Create);
  Self.RegisterSelect(dbnMySQL, TFluentSQLSelectMySQL.Create);
  Self.RegisterFunctions(dbnMySQL, TFluentSQLFunctionsMySQL.Create);
  Self.RegisterDDLSerialize(dbnMySQL, TFluentDDLSerializerMySQL.Create);
end;
{$ENDIF}

{$IFDEF SQLITE}
procedure TFluentSQLRegister._RegisterSQLite;
begin
  Self.RegisterSerialize(dbnSQLite, TFluentSQLSerializerSQLite.Create);
  Self.RegisterSelect(dbnSQLite, TFluentSQLSelectSQLite.Create);
  Self.RegisterFunctions(dbnSQLite, TFluentSQLFunctionsSQLite.Create);
  Self.RegisterDDLSerialize(dbnSQLite, TFluentDDLSerializerSQLite.Create);
end;
{$ENDIF}

{$IFDEF INTERBASE}
procedure TFluentSQLRegister._RegisterInterbase;
begin
  Self.RegisterSerialize(dbnInterbase, TFluentSQLSerializerInterbase.Create);
  Self.RegisterSelect(dbnInterbase, TFluentSQLSelectInterbase.Create);
  Self.RegisterFunctions(dbnInterbase, TFluentSQLFunctionsInterbase.Create);
end;
{$ENDIF}

{$IFDEF DB2}
procedure TFluentSQLRegister._RegisterDB2;
begin
  Self.RegisterSerialize(dbnDB2, TFluentSQLSerializeDB2.Create);
  Self.RegisterSelect(dbnDB2, TFluentSQLSelectDB2.Create);
  Self.RegisterFunctions(dbnDB2, TFluentSQLFunctionsDB2.Create);
end;
{$ENDIF}

{$IFDEF ORACLE}
procedure TFluentSQLRegister._RegisterOracle;
begin
  Self.RegisterSerialize(dbnOracle, TFluentSQLSerializeOracle.Create);
  Self.RegisterSelect(dbnOracle, TFluentSQLSelectOracle.Create);
  Self.RegisterFunctions(dbnOracle, TFluentSQLFunctionsOracle.Create);
  Self.RegisterDDLSerialize(dbnOracle, TFluentDDLSerializerOracle.Create);
end;
{$ENDIF}

{$IFDEF POSTGRESQL}
procedure TFluentSQLRegister._RegisterPostgreSQL;
begin
  Self.RegisterSerialize(dbnPostgreSQL, TFluentSQLSerializerPostgreSQL.Create);
  Self.RegisterSelect(dbnPostgreSQL, TFluentSQLSelectPostgreSQL.Create);
  Self.RegisterFunctions(dbnPostgreSQL, TFluentSQLFunctionsPostgreSQL.Create);
  Self.RegisterDDLSerialize(dbnPostgreSQL, TFluentDDLSerializerPostgreSQL.Create);
end;
{$ENDIF}

{$IFDEF MONGODB}
procedure TFluentSQLRegister._RegisterMongoDB;
begin
  Self.RegisterSerialize(dbnMongoDB, TFluentSQLSerializerMongoDB.Create);
  Self.RegisterSelect(dbnMongoDB, TFluentSQLSelectMongoDB.Create);
  Self.RegisterFunctions(dbnMongoDB, TFluentSQLFunctionsMongoDB.Create);
  Self.RegisterDDLSerialize(dbnMongoDB, TFluentDDLSerializerMongoDB.Create);
end;
{$ENDIF}

/// <summary>
///   ESP-T3: nunca devolve nil. Um dialeto sem funcoes registradas antes voltava
///   nil e o dereference em FluentSQL.Functions.pas virava EAccessViolation opaca
///   no consumidor. Agora o erro e nomeado e tratavel.
/// </summary>
function TFluentSQLRegister.Functions(const ADriverName: TFluentSQLDriver): IFluentSQLFunctions;
begin
  if not FCQLFunctions.ContainsKey(TStrDBEngineName[ADriverName]) then
    raise EFluentSQLDriverNotRegistered.Create('As funcoes do banco ' + TStrDBEngineName[ADriverName] +
      ' nao estao registradas. Ligue o {$DEFINE} correspondente em FluentSQL.inc e ' +
      'adicione a unit "FluentSQL.Functions???.pas" na clausula USES do seu projeto!');

  Result := FCQLFunctions[TStrDBEngineName[ADriverName]];
end;

function TFluentSQLRegister.Select(const ADriverName: TFluentSQLDriver): IFluentSQLSelect;
begin
  Result := nil;
  if not FCQLSelect.ContainsKey(TStrDBEngineName[ADriverName]) then
    raise EFluentSQLDriverNotRegistered.Create('O select do banco ' + TStrDBEngineName[ADriverName] + ' n�o est� registrado, adicione a unit "FluentSQL.Select.???.pas" onde ??? nome do banco, na cl�usula USES do seu projeto!');

  Result := FCQLSelect[TStrDBEngineName[ADriverName]];
end;

procedure TFluentSQLRegister.RegisterFunctions(const ADriverName: TFluentSQLDriver; const ACQLFunctions: IFluentSQLFunctions);
begin
  FCQLFunctions.AddOrSetValue(TStrDBEngineName[ADriverName], ACQLFunctions);
end;

procedure TFluentSQLRegister.RegisterSelect(const ADriverName: TFluentSQLDriver; const ACQLSelect: IFluentSQLSelect);
begin
  FCQLSelect.AddOrSetValue(TStrDBEngineName[ADriverName], ACQLSelect);
end;

function TFluentSQLRegister.Serialize(const ADriverName: TFluentSQLDriver): IFluentSQLSerialize;
begin
  if not FCQLSerialize.ContainsKey(TStrDBEngineName[ADriverName]) then
    raise EFluentSQLDriverNotRegistered.Create('O serialize do banco ' + TStrDBEngineName[ADriverName] + ' n�o est� registrado, adicione a unit "FluentSQL.Serialize.???.pas" onde ??? nome do banco, na cl�usula USES do seu projeto!');

  Result := FCQLSerialize[TStrDBEngineName[ADriverName]];
end;

/// <summary>
///   ATENCAO: este getter devolve nil DE PROPOSITO e nao deve virar excecao.
///   Nenhum _Register* chama RegisterWhere, entao FCQLWhere esta sempre vazio;
///   FluentSQL.Ast.pas:139-141 testa o nil e cai no TFluentSQLWhere generico.
///   Fazer isto levantar quebra a construcao de TODA query.
/// </summary>
function TFluentSQLRegister.Where(const ADriverName: TFluentSQLDriver): IFluentSQLWhere;
begin
  Result := nil;
  if FCQLWhere.ContainsKey(TStrDBEngineName[ADriverName]) then
    Result := FCQLWhere[TStrDBEngineName[ADriverName]];
end;

procedure TFluentSQLRegister.RegisterSerialize(const ADriverName: TFluentSQLDriver; const ACQLSelect: IFluentSQLSerialize);
begin
  FCQLSerialize.AddOrSetValue(TStrDBEngineName[ADriverName], ACQLSelect);
end;

procedure TFluentSQLRegister.RegisterWhere(const ADriverName: TFluentSQLDriver; const ACQLWhere: IFluentSQLWhere);
begin
  FCQLWhere.AddOrSetValue(TStrDBEngineName[ADriverName], ACQLWhere);
end;

function TFluentSQLRegister.DDLSerialize(const ADriverName: TFluentSQLDriver): IFluentDDLSerialize;
begin
  if not FCQLDDLSerialize.ContainsKey(TStrDBEngineName[ADriverName]) then
    raise ENotSupportedException.Create('O DDL serialize do banco ' + TStrDBEngineName[ADriverName] + ' no est registrado!');

  Result := FCQLDDLSerialize[TStrDBEngineName[ADriverName]];
end;

procedure TFluentSQLRegister.RegisterDDLSerialize(const ADriverName: TFluentSQLDriver; const ACQLDDLSerialize: IFluentDDLSerialize);
begin
  FCQLDDLSerialize.AddOrSetValue(TStrDBEngineName[ADriverName], ACQLDDLSerialize);
end;

end.


