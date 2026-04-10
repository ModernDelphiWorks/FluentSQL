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

unit FluentSQL.Params;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  Classes,
  Variants,
  Generics.Collections,
  FluentSQL.Interfaces;

type
  TFluentSQLParam = class(TInterfacedObject, IFluentSQLParam)
  private
    FName: string;
    FValue: Variant;
    FDataType: TFluentSQLDataFieldType;
  protected
    function GetName: string;
    function GetValue: Variant;
    function GetDataType: TFluentSQLDataFieldType;
  public
    constructor Create(const AName: string; const AValue: Variant; ADataType: TFluentSQLDataFieldType);
  end;

  TFluentSQLParams = class(TInterfacedObject, IFluentSQLParams)
  private
    FItems: TList<IFluentSQLParam>;
  protected
    function GetItem(AIndex: Integer): IFluentSQLParam;
    function Count: Integer;
    procedure Clear;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AValue: Variant; ADataType: TFluentSQLDataFieldType): string;
  end;

  TFluentSQLParamView = class(TInterfacedObject, IFluentSQLParam)
  private
    FInner: IFluentSQLParam;
    FName: string;
    function GetName: string;
    function GetValue: Variant;
    function GetDataType: TFluentSQLDataFieldType;
  public
    constructor Create(const AInner: IFluentSQLParam; const AName: string);
  end;

  TFluentSQLMergedParams = class(TInterfacedObject, IFluentSQLParams)
  private
    FPrimary: IFluentSQLParams;
    FSecondary: IFluentSQLParams;
  protected
    function GetItem(AIndex: Integer): IFluentSQLParam;
    function Count: Integer;
    procedure Clear;
  public
    constructor Create(const APrimary, ASecondary: IFluentSQLParams);
    function Add(const AValue: Variant; ADataType: TFluentSQLDataFieldType): string;
  end;

implementation

{ TFluentSQLParam }

constructor TFluentSQLParam.Create(const AName: string; const AValue: Variant;
  ADataType: TFluentSQLDataFieldType);
begin
  FName := AName;
  FValue := AValue;
  FDataType := ADataType;
end;

function TFluentSQLParam.GetDataType: TFluentSQLDataFieldType;
begin
  Result := FDataType;
end;

function TFluentSQLParam.GetName: string;
begin
  Result := FName;
end;

function TFluentSQLParam.GetValue: Variant;
begin
  Result := FValue;
end;

{ TFluentSQLParams }

function TFluentSQLParams.Add(const AValue: Variant;
  ADataType: TFluentSQLDataFieldType): string;
begin
  Result := 'p' + IntToStr(FItems.Count + 1);
  FItems.Add(TFluentSQLParam.Create(Result, AValue, ADataType));
  Result := ':' + Result;
end;

procedure TFluentSQLParams.Clear;
begin
  FItems.Clear;
end;

function TFluentSQLParams.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TFluentSQLParams.Create;
begin
  FItems := TList<IFluentSQLParam>.Create;
end;

destructor TFluentSQLParams.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TFluentSQLParams.GetItem(AIndex: Integer): IFluentSQLParam;
begin
  Result := FItems[AIndex];
end;

{ TFluentSQLParamView }

constructor TFluentSQLParamView.Create(const AInner: IFluentSQLParam; const AName: string);
begin
  inherited Create;
  FInner := AInner;
  FName := AName;
end;

function TFluentSQLParamView.GetDataType: TFluentSQLDataFieldType;
begin
  Result := FInner.DataType;
end;

function TFluentSQLParamView.GetName: string;
begin
  Result := FName;
end;

function TFluentSQLParamView.GetValue: Variant;
begin
  Result := FInner.Value;
end;

{ TFluentSQLMergedParams }

function TFluentSQLMergedParams.Add(const AValue: Variant;
  ADataType: TFluentSQLDataFieldType): string;
begin
  Result := FPrimary.Add(AValue, ADataType);
end;

function TFluentSQLMergedParams.Count: Integer;
begin
  Result := FPrimary.Count + FSecondary.Count;
end;

procedure TFluentSQLMergedParams.Clear;
begin
  FPrimary.Clear;
end;

constructor TFluentSQLMergedParams.Create(const APrimary, ASecondary: IFluentSQLParams);
begin
  inherited Create;
  FPrimary := APrimary;
  FSecondary := ASecondary;
end;

function TFluentSQLMergedParams.GetItem(AIndex: Integer): IFluentSQLParam;
var
  LName: string;
begin
  if AIndex < FPrimary.Count then
    Result := FPrimary[AIndex]
  else
  begin
    LName := 'p' + IntToStr(AIndex + 1);
    Result := TFluentSQLParamView.Create(FSecondary[AIndex - FPrimary.Count], LName);
  end;
end;

end.
