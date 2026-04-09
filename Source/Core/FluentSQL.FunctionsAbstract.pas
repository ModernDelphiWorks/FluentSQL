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

unit FluentSQL.FunctionsAbstract;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces;

const
  ABSTRACT_METHOD_ERROR = 'Abstract method "%s" called in %s. ' +
                          'Derived classes must override this method to provide a concrete implementation.';

type
  TFluentSQLFunctionAbstract = class(TInterfacedObject, IFluentSQLFunctions)
  public
    function Count(const AValue: String): String; virtual;
    function Upper(const AValue: String): String; virtual;
    function Lower(const AValue: String): String; virtual;
    function Min(const AValue: String): String; virtual;
    function Max(const AValue: String): String; virtual;
    function Sum(const AValue: String): String; virtual;
    function Average(const AValue: String): String; virtual;
    function Coalesce(const AValues: array of String): String; virtual;
    function SubString(const AVAlue: String; const AStart, ALength: Integer): String; virtual;
    function Cast(const AExpression: String; const ADataType: String): String; virtual;
    function Convert(const ADataType: String; const AExpression: String;
      const AStyle: String): String; virtual;
    function Year(const AValue: String): String; virtual;
    function Concat(const AValue: array of String): String; virtual;
    function Length(const AValue: String): String; virtual;
    function Trim(const AValue: String): String; virtual;
    function LTrim(const AValue: String): String; virtual;
    function RTrim(const AValue: String): String; virtual;
    // Date
    function Date(const AVAlue: String; const AFormat: String): String; overload; virtual;
    function Date(const AVAlue: String): String; overload; virtual;
    function Day(const AValue: String): String; virtual;
    function Month(const AValue: String): String; virtual;
    function CurrentDate: String; virtual;
    function CurrentTimestamp: String; virtual;
    function Round(const AValue: String; const ADecimals: Integer): String; virtual;
    function Floor(const AValue: String): String; virtual;
    function Ceil(const AValue: String): String; virtual;
    function Modulus(const AValue, ADivisor: String): String; virtual;
    function Abs(const AValue: String): String; virtual;
  end;

implementation

{ TFluentSQLFunctionAbstract }

function TFluentSQLFunctionAbstract.Abs(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Abs', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Average(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Average', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Cast(const AExpression, ADataType: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Cast', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Ceil(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Ceil', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Coalesce(const AValues: array of String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Coalesce', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Concat(const AValue: array of String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Concat', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Convert(const ADataType, AExpression, AStyle: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Convert', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Count(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Count', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.CurrentDate: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CurrentDate', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.CurrentTimestamp: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CurrentTimestamp', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Date(const AVAlue, AFormat: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Date, Format', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Date(const AVAlue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Date', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Day(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Day', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Floor(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Floor', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Length(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Length', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Lower(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Lower', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.LTrim(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['LTrim', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Max(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Max', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Min(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Min', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Modulus(const AValue, ADivisor: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Modulus', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Month(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Month', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Round(const AValue: String; const ADecimals: Integer): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Round', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.RTrim(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['RTrim', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.SubString(const AVAlue: String; const AStart,
  ALength: Integer): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['SubString', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Sum(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Sum', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Trim(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Trim', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Upper(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Upper', Self.ClassName]);
end;

function TFluentSQLFunctionAbstract.Year(const AValue: String): String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Year', Self.ClassName]);
end;

end.




