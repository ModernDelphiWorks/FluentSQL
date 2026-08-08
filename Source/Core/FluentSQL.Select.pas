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

unit FluentSQL.Select;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  FluentSQL.Interfaces,
  FluentSQL.Qualifier,
  FluentSQL.Section,
  FluentSQL.Name;

type
  TFluentSQLSelect = class(TFluentSQLSection, IFluentSQLSelect)
  protected
    FColumns: IFluentSQLNames;
    FTableNames: IFluentSQLNames;
    FQualifiers: IFluentSQLSelectQualifiers;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; override;
    function IsEmpty: Boolean; override;
    function Columns: IFluentSQLNames;
    function TableNames: IFluentSQLNames;
    function Qualifiers: IFluentSQLSelectQualifiers;
    function Serialize: String; virtual;
  end;

implementation

uses
  FluentSQL.Utils,
  FluentSQL.QualifierFirebird;

{ TSelect }

procedure TFluentSQLSelect.Clear;
begin
  FColumns.Clear;
  FTableNames.Clear;
  if Assigned(FQualifiers) then
    FQualifiers.Clear;
end;

function TFluentSQLSelect.Columns: IFluentSQLNames;
begin
  Result := FColumns;
end;

constructor TFluentSQLSelect.Create;
begin
  inherited Create('Select');
  FColumns := TFluentSQLNames.Create;
  FTableNames := TFluentSQLNames.Create;
end;

destructor TFluentSQLSelect.Destroy;
begin
  FColumns := nil;
  FTableNames := nil;
  FQualifiers := nil;
  inherited;
end;

function TFluentSQLSelect.IsEmpty: Boolean;
begin
  Result := (FColumns.IsEmpty and FTableNames.IsEmpty);
end;

function TFluentSQLSelect.Qualifiers: IFluentSQLSelectQualifiers;
begin
  Result := FQualifiers;
end;

/// <summary>
///   Forma neutra: SELECT [DISTINCT] &lt;colunas&gt; FROM &lt;tabelas&gt;.
///
///   NAO chama SerializePagination. Emitir a paginacao entre o SELECT e a lista
///   de colunas so e gramatical no Firebird e no Interbase, e esses dois montam
///   a propria forma. Nos outros seis dialetos a paginacao e CAUDA, concatenada
///   pelo serializador depois de tudo. Este metodo carregava o prefixo do
///   Firebird como se fosse regra geral, e foi copiado assim para o SQLite -
///   onde produzia "SELECT LIMIT 10 OFFSET 20 * FROM T", que nenhum SQLite
///   aceita, com ou sem filtro.
/// </summary>
function TFluentSQLSelect.Serialize: String;
begin
  if IsEmpty then
    Result := ''
  else
    Result := TUtils.Concat(['SELECT',
                             FQualifiers.SerializeDistinct,
                             FColumns.Serialize,
                             'FROM',
                             FTableNames.Serialize]);
end;

function TFluentSQLSelect.TableNames: IFluentSQLNames;
begin
  Result := FTableNames;
end;

end.




