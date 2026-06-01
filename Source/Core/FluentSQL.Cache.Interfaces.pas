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

unit FluentSQL.Cache.Interfaces;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

type
  /// <summary>ESP-032: Interface for optional SQL string caching.</summary>
  IFluentSQLCacheProvider = interface
    ['{B9E218D4-6F1A-4B8E-8C79-D8763B8F8943}']
    function Get(const AKey: string): string;
    procedure SetCache(const AKey, AValue: string; const ATTLSeconds: Integer);
  end;

implementation

end.
