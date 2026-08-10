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

unit FluentSQL.FunctionsMongoDB;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL.FunctionsAbstract;

type
  /// <summary>
  ///   Funcoes do dialeto MongoDB.
  ///
  ///   POR QUE ESTA CLASSE QUASE SO LEVANTA EXCECAO:
  ///
  ///   O FluentSQL.SerializeMongoDB.pas nao interpreta expressao alguma. O que
  ///   ele le da coluna do SELECT e (a) um nome de campo, que passa por
  ///   NormalizeFieldName, ou (b) um marcador de agregacao, reconhecido por
  ///   prefixo em :476, :606, :625, :688 e :1011 - e ele aceita DUAS formas de
  ///   marcador: o esquema textual 'AGG:XXX:' e a forma ANSI 'SUM(' / 'COUNT(' /
  ///   'MIN(' / 'MAX(' / 'AVG(' / 'AVERAGE('.
  ///
  ///   Como Count/Sum/Min/Max/Average estao no padrao A (o core emite ANSI sem
  ///   consultar o driver), quem chega no serializador e sempre a forma ANSI. O
  ///   ramo 'AGG:' e o produtor que existia aqui nunca se encontraram: os
  ///   overrides de agregacao desta classe eram codigo morto, e foram removidos.
  ///   A agregacao MongoDB continua funcionando exatamente como antes, pelo ramo
  ///   ANSI do serializador.
  ///
  ///   Para as funcoes ESCALARES (padrao B) o MongoDB nao tem para onde ir. O
  ///   equivalente MQL de UPPER seria {"$toUpper": "$campo"}, mas devolver isso
  ///   daqui faria o serializador trata-lo como NOME DE CAMPO e produzir MQL
  ///   invalido em silencio - o mesmo modo de falha do CEIL no MSSQL. Enquanto o
  ///   serializador nao souber montar $project com expressao, a resposta correta
  ///   e um erro nomeado e tratavel.
  /// </summary>
  TFluentSQLFunctionsMongoDB = class(TFluentSQLFunctionAbstract)
  public
    constructor Create;
    // String
    function Length(const AValue: String): String; override;
    function Trim(const AValue: String): String; override;
    function LTrim(const AValue: String): String; override;
    function RTrim(const AValue: String): String; override;
    function SubString(const AValue: String; const AStart, ALength: Integer): String; override;
    function Concat(const AValue: array of String): String; override;
    // Null handling
    function Coalesce(const AValues: array of String): String; override;
    // Date
    function Date(const AValue: String; const AFormat: String): String; overload; override;
    function Date(const AValue: String): String; overload; override;
    function Day(const AValue: String): String; override;
    function Month(const AValue: String): String; override;
    function Year(const AValue: String): String; override;
    function CurrentDate: String; override;
    function CurrentTimestamp: String; override;
    // Numeric
    function Ceil(const AValue: String): String; override;
    function Modulus(const AValue, ADivisor: String): String; override;
    // Type conversion
    function Cast(const AExpression: String; const ADataType: TFluentSQLDataFieldType;
      const ALength: Integer = 0): String; overload; override;
  end;

implementation


const
  cDIALECT = 'MongoDB';

constructor TFluentSQLFunctionsMongoDB.Create;
begin
  inherited;
end;

function TFluentSQLFunctionsMongoDB.Length(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Length', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Trim(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Trim', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.LTrim(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('LTrim', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.RTrim(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('RTrim', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.SubString(const AValue: String; const AStart,
  ALength: Integer): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('SubString', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Concat(const AValue: array of String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Concat', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Coalesce(const AValues: array of String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Coalesce', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Date(const AValue, AFormat: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Date', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Date(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Date', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Day(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Day', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Month(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Month', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Year(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Year', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.CurrentDate: String;
begin
  raise EFluentSQLFunctionNotSupported.Create('CurrentDate', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.CurrentTimestamp: String;
begin
  raise EFluentSQLFunctionNotSupported.Create('CurrentTimestamp', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Ceil(const AValue: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Ceil', cDIALECT);
end;

function TFluentSQLFunctionsMongoDB.Modulus(const AValue, ADivisor: String): String;
begin
  raise EFluentSQLFunctionNotSupported.Create('Modulus', cDIALECT);
end;

// A sobrecarga de enum entra na regra geral desta classe: escalar levanta erro
// nomeado. Isto FECHA UMA das seis celulas de MQL invalido em silencio que a T3
// deixou registradas como divida - a de Cast. Antes, Cast estava no padrao A, o
// core respondia 'CAST(x AS INTEGER)' sem consultar este driver, o
// SerializeMongoDB nao reconhecia o prefixo 'CAST(' e a coluna caia em
// NormalizeFieldName e era DESCARTADA sem aviso.
//
// Continuam em silencio, porque continuam no padrao A: Abs, Upper, Lower, Round,
// Floor - e a sobrecarga Cast(String, String), que por decisao permanece no padrao
// A. Ver a nota MONGODB em Source\Core\FluentSQL.Functions.pas.
//
// A guarda de portabilidade vem ANTES do raise proprio de proposito: para um tipo
// fora da intersecao, quem pediu dftGuid aqui recebe a MESMA mensagem que receberia
// no PostgreSQL. Recusa uniforme so e uniforme se valer tambem nos drivers que
// recusam tudo - senao a mensagem viraria pista de qual driver esta ligado.
function TFluentSQLFunctionsMongoDB.Cast(const AExpression: String;
  const ADataType: TFluentSQLDataFieldType; const ALength: Integer): String;
begin
  _AssertCastTypeIsPortable(ADataType);
  raise EFluentSQLFunctionNotSupported.Create('Cast(TFluentSQLDataFieldType)', cDIALECT);
end;

end.
