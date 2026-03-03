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
  private
    procedure _RegisterDrivers;
    {$IFDEF FIREBIRD}procedure _RegisterFirebird;{$ENDIF}
    {$IFDEF MSSQL}procedure _RegisterMSSQL;{$ENDIF}
    {$IFDEF MYSQL}procedure _RegisterMySQL;{$ENDIF}
    {$IFDEF SQLITE}procedure _RegisterSQLite;{$ENDIF}
    {$IFDEF INTERBASE}procedure _RegisterInterbase;{$ENDIF}
    {$IFDEF DB2}procedure _RegisterDB2;{$ENDIF}
    {$IFDEF ORACLE}procedure _RegisterOracle;{$ENDIF}
    {$IFDEF INFORMIX}procedure _RegisterInformix;{$ENDIF}
    {$IFDEF POSTGRESQL}procedure _RegisterPostgreSQL;{$ENDIF}
    {$IFDEF ADS}procedure _RegisterADS;{$ENDIF}
    {$IFDEF ASA}procedure _RegisterASA;{$ENDIF}
    {$IFDEF ABSOLUTEDB}procedure _RegisterAbsoluteDB;{$ENDIF}
    {$IFDEF MONGODB}procedure _RegisterMongoDB;{$ENDIF}
    {$IFDEF ELEVATEDB}procedure _RegisterElevateDB;{$ENDIF}
    {$IFDEF NEXUSDB}procedure _RegisterNexusDB;{$ENDIF}
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
  end;

implementation

uses
  {$IFDEF FIREBIRD}FluentSQL.SerializeFirebird, FluentSQL.SelectFirebird, FluentSQL.FunctionsFirebird;{$ENDIF}
  {$IFDEF MSSQL}FluentSQL.SerializeMSSQL, FluentSQL.SelectMSSQL, FluentSQL.FunctionsMSSQL;{$ENDIF}
  {$IFDEF MYSQL}FluentSQL.SerializeMySQL, FluentSQL.SelectMySQL, FluentSQL.FunctionsMySQL;{$ENDIF}
  {$IFDEF SQLITE}FluentSQL.SerializeSQLite, FluentSQL.SelectSQLite, FluentSQL.FunctionsSQLite;{$ENDIF}
  {$IFDEF INTERBASE}FluentSQL.SerializeInterbase, FluentSQL.SelectInterbase, FluentSQL.FunctionsInterbase;{$ENDIF}
  {$IFDEF DB2}FluentSQL.SerializeDB2, FluentSQL.SelectDB2, FluentSQL.FunctionsDB2;{$ENDIF}
  {$IFDEF ORACLE}FluentSQL.SerializeOracle, FluentSQL.SelectOracle, FluentSQL.FunctionsOracle;{$ENDIF}
  {$IFDEF INFORMIX}FluentSQL.SerializeInformix, FluentSQL.SelectInformix, FluentSQL.FunctionsInformix;{$ENDIF}
  {$IFDEF POSTGRESQL}FluentSQL.SerializePostgreSQL, FluentSQL.SelectPostgreSQL, FluentSQL.FunctionsPostgreSQL;{$ENDIF}
  {$IFDEF ADS}FluentSQL.SerializeADS, FluentSQL.SelectADS, FluentSQL.FunctionsADS;{$ENDIF}
  {$IFDEF ASA}FluentSQL.SerializeASA, FluentSQL.SelectASA, FluentSQL.FunctionsASA;{$ENDIF}
  {$IFDEF ABSOLUTEDB}FluentSQL.SerializeAbsoluteDB, FluentSQL.SelectAbsoluteDB, FluentSQL.FunctionsAbsoluteDB;{$ENDIF}
  {$IFDEF MONGODB}FluentSQL.SerializeMongoDB, FluentSQL.SelectMongoDB, FluentSQL.FunctionsMongoDB;{$ENDIF}
  {$IFDEF ELEVATEDB}FluentSQL.SerializeElevateDB, FluentSQL.SelectElevateDB, FluentSQL.FunctionsElevateDB;{$ENDIF}
  {$IFDEF NEXUSDB}FluentSQL.SerializeNexusDB, FluentSQL.SelectNexusDB, FluentSQL.FunctionsNexusDB;{$ENDIF}

const
  TStrDBEngineName: array[dbnMSSQL..dbnNexusDB] of string = (
    'MSSQL', 'MySQL', 'Firebird', 'SQLite', 'Interbase', 'DB2',
    'Oracle', 'Informix', 'PostgreSQL', 'ADS', 'ASA', 'AbsoluteDB',
    'MongoDB', 'ElevateDB', 'NexusDB'
  );

constructor TFluentSQLRegister.Create;
begin
  FCQLSelect := TDictionary<string, IFluentSQLSelect>.Create;
  FCQLWhere := TDictionary<string, IFluentSQLWhere>.Create;
  FCQLSerialize := TDictionary<string, IFluentSQLSerialize>.Create;
  FCQLFunctions := TDictionary<string, IFluentSQLFunctions>.Create;

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
  {$IFDEF INFORMIX}_RegisterInformix;{$ENDIF}
  {$IFDEF POSTGRESQL}_RegisterPostgreSQL;{$ENDIF}
  {$IFDEF ADS}_RegisterADS;{$ENDIF}
  {$IFDEF ASA}_RegisterASA;{$ENDIF}
  {$IFDEF ABSOLUTEDB}_RegisterAbsoluteDB;{$ENDIF}
  {$IFDEF MONGODB}_RegisterMongoDB;{$ENDIF}
  {$IFDEF ELEVATEDB}_RegisterElevateDB;{$ENDIF}
  {$IFDEF NEXUSDB}_RegisterNexusDB;{$ENDIF}
end;

{$IFDEF FIREBIRD}
procedure TFluentSQLRegister._RegisterFirebird;
begin
  Self.RegisterSerialize(dbnFirebird, TFluentSQLSerializerFirebird.Create);
  Self.RegisterSelect(dbnFirebird, TFluentSQLSelectFirebird.Create);
  Self.RegisterFunctions(dbnFirebird, TFluentSQLFunctionsFirebird.Create);
end;
{$ENDIF}

{$IFDEF MSSQL}
procedure TFluentSQLRegister._RegisterMSSQL;
begin
  Self.RegisterSerialize(dbnMSSQL, TFluentSQLSerializerMSSQL.Create);
  Self.RegisterSelect(dbnMSSQL, TIFluentSQLSelectMSSQL.Create);
  Self.RegisterFunctions(dbnMSSQL, TFluentSQLFunctionsMSSQL.Create);
end;
{$ENDIF}

{$IFDEF MYSQL}
procedure TFluentSQLRegister._RegisterMySQL;
begin
  Self.RegisterSerialize(dbnMySQL, TFluentSQLSerializerMySQL.Create);
  Self.RegisterSelect(dbnMySQL, TIFluentSQLSelectMySQL.Create);
  Self.RegisterFunctions(dbnMySQL, TFluentSQLFunctionsMySQL.Create);
end;
{$ENDIF}

{$IFDEF SQLITE}
procedure TFluentSQLRegister._RegisterSQLite;
begin
  Self.RegisterSerialize(dbnSQLite, TFluentSQLSerializerSQLite.Create);
  Self.RegisterSelect(dbnSQLite, TIFluentSQLSelectSQLite.Create);
  Self.RegisterFunctions(dbnSQLite, TFluentSQLFunctionsSQLite.Create);
end;
{$ENDIF}

{$IFDEF INTERBASE}
procedure TFluentSQLRegister._RegisterInterbase;
begin
  Self.RegisterSerialize(dbnInterbase, TFluentSQLSerializerInterbase.Create);
  Self.RegisterSelect(dbnInterbase, TIFluentSQLSelectInterbase.Create);
  Self.RegisterFunctions(dbnInterbase, TFluentSQLFunctionsInterbase.Create);
end;
{$ENDIF}

{$IFDEF DB2}
procedure TFluentSQLRegister._RegisterDB2;
begin
  Self.RegisterSerialize(dbnDB2, TFluentSQLSerializeDB2.Create);
  Self.RegisterSelect(dbnDB2, TIFluentSQLSelectDB2.Create);
  Self.RegisterFunctions(dbnDB2, TFluentSQLFunctionsDB2.Create);
end;
{$ENDIF}

{$IFDEF ORACLE}
procedure TFluentSQLRegister._RegisterOracle;
begin
  Self.RegisterSerialize(dbnOracle, TFluentSQLSerializeOracle.Create);
  Self.RegisterSelect(dbnOracle, TIFluentSQLSelectOracle.Create);
  Self.RegisterFunctions(dbnOracle, TFluentSQLFunctionsOracle.Create);
end;
{$ENDIF}

{$IFDEF INFORMIX}
procedure TFluentSQLRegister._RegisterInformix;
begin
  Self.RegisterSerialize(dbnInformix, TFluentSQLSerializeInformix.Create);
  Self.RegisterSelect(dbnInformix, TIFluentSQLSelectInformix.Create);
  Self.RegisterFunctions(dbnInformix, TFluentSQLFunctionsInformix.Create);
end;
{$ENDIF}

{$IFDEF POSTGRESQL}
procedure TFluentSQLRegister._RegisterPostgreSQL;
begin
  Self.RegisterSerialize(dbnPostgreSQL, TFluentSQLSerializerPostgreSQL.Create);
  Self.RegisterSelect(dbnPostgreSQL, TIFluentSQLSelectPostgreSQL.Create);
  Self.RegisterFunctions(dbnPostgreSQL, TFluentSQLFunctionsPostgreSQL.Create);
end;
{$ENDIF}

{$IFDEF ADS}
procedure TFluentSQLRegister._RegisterADS;
begin
  Self.RegisterSerialize(dbnADS, TFluentSQLSerializeADS.Create);
  Self.RegisterSelect(dbnADS, TIFluentSQLSelectADS.Create);
  Self.RegisterFunctions(dbnADS, TFluentSQLFunctionsADS.Create);
end;
{$ENDIF}

{$IFDEF ASA}
procedure TFluentSQLRegister._RegisterASA;
begin
  Self.RegisterSerialize(dbnASA, TFluentSQLSerializeASA.Create);
  Self.RegisterSelect(dbnASA, TIFluentSQLSelectASA.Create);
  Self.RegisterFunctions(dbnASA, TFluentSQLFunctionsASA.Create);
end;
{$ENDIF}

{$IFDEF ABSOLUTEDB}
procedure TFluentSQLRegister._RegisterAbsoluteDB;
begin
  Self.RegisterSerialize(dbnAbsoluteDB, TFluentSQLSerializeAbsoluteDB.Create);
  Self.RegisterSelect(dbnAbsoluteDB, TIFluentSQLSelectAbsoluteDB.Create);
  Self.RegisterFunctions(dbnAbsoluteDB, TFluentSQLFunctionsAbsoluteDB.Create);
end;
{$ENDIF}

{$IFDEF MONGODB}
procedure TFluentSQLRegister._RegisterMongoDB;
begin
  Self.RegisterSerialize(dbnMongoDB, TFluentSQLSerializerMongoDB.Create);
  Self.RegisterSelect(dbnMongoDB, TIFluentSQLSelectMongoDB.Create);
  Self.RegisterFunctions(dbnMongoDB, TFluentSQLFunctionsMongoDB.Create);
end;
{$ENDIF}

{$IFDEF ELEVATEDB}
procedure TFluentSQLRegister._RegisterElevateDB;
begin
  Self.RegisterSerialize(dbnElevateDB, TFluentSQLSerializeElevateDB.Create);
  Self.RegisterSelect(dbnElevateDB, TIFluentSQLSelectElevateDB.Create);
  Self.RegisterFunctions(dbnElevateDB, TFluentSQLFunctionsElevateDB.Create);
end;
{$ENDIF}

{$IFDEF NEXUSDB}
procedure TFluentSQLRegister._RegisterNexusDB;
begin
  Self.RegisterSerialize(dbnNexusDB, TFluentSQLSerializeNexusDB.Create);
  Self.RegisterSelect(dbnNexusDB, TIFluentSQLSelectNexusDB.Create);
  Self.RegisterFunctions(dbnNexusDB, TFluentSQLFunctionsNexusDB.Create);
end;
{$ENDIF}

function TFluentSQLRegister.Functions(const ADriverName: TFluentSQLDriver): IFluentSQLFunctions;
begin
  Result := nil;
  if FCQLFunctions.ContainsKey(TStrDBEngineName[ADriverName]) then
    Result := FCQLFunctions[TStrDBEngineName[ADriverName]];
end;

function TFluentSQLRegister.Select(const ADriverName: TFluentSQLDriver): IFluentSQLSelect;
begin
  Result := nil;
  if not FCQLSelect.ContainsKey(TStrDBEngineName[ADriverName]) then
    raise Exception.Create('O select do banco ' + TStrDBEngineName[ADriverName] + ' não está registrado, adicione a unit "FluentSQL.Select.???.pas" onde ??? nome do banco, na cláusula USES do seu projeto!');

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
    raise Exception.Create('O serialize do banco ' + TStrDBEngineName[ADriverName] + ' não está registrado, adicione a unit "FluentSQL.Serialize.???.pas" onde ??? nome do banco, na cláusula USES do seu projeto!');

  Result := FCQLSerialize[TStrDBEngineName[ADriverName]];
end;

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

end.


