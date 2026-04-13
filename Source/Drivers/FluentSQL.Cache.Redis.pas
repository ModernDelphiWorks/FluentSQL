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

unit FluentSQL.Cache.Redis;

interface

uses
  SysUtils,
  FluentSQL.Cache.Interfaces;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

type
  /// <summary>Delegate to execute Redis commands, decoupling from specific client libraries.</summary>
  TRedisCommandExecutor = reference to function(const ACommand: string; const AArgs: TArray<string>): string;

  /// <summary>ESP-032: Redis-based implementation of IFluentSQLCacheProvider.</summary>
  TFluentSQLRedisCacheProvider = class(TInterfacedObject, IFluentSQLCacheProvider)
  strict private
    FExecutor: TRedisCommandExecutor;
    FKeyPrefix: string;
  public
    constructor Create(const AExecutor: TRedisCommandExecutor; const AKeyPrefix: string = 'fluentsql:cache:');
    function Get(const AKey: string): string;
    procedure SetCache(const AKey, AValue: string; const ATTLSeconds: Integer);
  end;

implementation

{ TFluentSQLRedisCacheProvider }

constructor TFluentSQLRedisCacheProvider.Create(const AExecutor: TRedisCommandExecutor; const AKeyPrefix: string);
begin
  inherited Create;
  FExecutor := AExecutor;
  FKeyPrefix := AKeyPrefix;
end;

function TFluentSQLRedisCacheProvider.Get(const AKey: string): string;
begin
  Result := '';
  if not Assigned(FExecutor) then
    Exit;

  try
    Result := FExecutor('GET', [FKeyPrefix + AKey]);
  except
    // Silent fallback per ESP-032
  end;
end;

procedure TFluentSQLRedisCacheProvider.SetCache(const AKey, AValue: string; const ATTLSeconds: Integer);
begin
  if not Assigned(FExecutor) then
    Exit;

  try
    if ATTLSeconds > 0 then
      FExecutor('SETEX', [FKeyPrefix + AKey, IntToStr(ATTLSeconds), AValue])
    else
      FExecutor('SET', [FKeyPrefix + AKey, AValue]);
  except
    // Silent fallback per ESP-032
  end;
end;

end.
