unit test.cache;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestCache = class
  public
    [Test]
    procedure TestCacheHit;
    [Test]
    procedure TestCacheMiss;
    [Test]
    procedure TestCacheFallback;
    [Test]
    procedure TestCollisionAvoidance;
  end;

implementation

uses
  SysUtils,
  Generics.Collections,
  FluentSQL.Interfaces,
  FluentSQL.Cache.Interfaces,
  FluentSQL.Cache.Redis,
  FluentSQL;

type
  TMockRedis = class
  public
    Storage: TDictionary<string, string>;
    CallCount: Integer;
    FailNext: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Execute(const ACommand: string; const AArgs: TArray<string>): string;
  end;

{ TMockRedis }

constructor TMockRedis.Create;
begin
  Storage := TDictionary<string, string>.Create;
  CallCount := 0;
  FailNext := False;
end;

destructor TMockRedis.Destroy;
begin
  Storage.Free;
  inherited;
end;

function TMockRedis.Execute(const ACommand: string; const AArgs: TArray<string>): string;
begin
  Inc(CallCount);
  if FailNext then
    raise Exception.Create('Redis Error');

  if ACommand = 'GET' then
  begin
    if not Storage.TryGetValue(AArgs[0], Result) then
      Result := '';
  end
  else if (ACommand = 'SET') or (ACommand = 'SETEX') then
  begin
    if ACommand = 'SET' then
      Storage.AddOrSetValue(AArgs[0], AArgs[1])
    else
      // SETEX <key> <ttl> <value>
      Storage.AddOrSetValue(AArgs[0], AArgs[2]);
    Result := 'OK';
  end;
end;

{ TTestCache }

procedure TTestCache.TestCacheHit;
var
  LMock: TMockRedis;
  LProvider: IFluentSQLCacheProvider;
  S1, S2: string;
begin
  LMock := TMockRedis.Create;
  try
    LProvider := TFluentSQLRedisCacheProvider.Create(LMock.Execute);
    
    // First call: Miss
    S1 := FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .AsString;
      
    Assert.AreEqual(2, LMock.CallCount); // 1 GET (miss) + 1 SET
    
    // Second call: Hit (re-runing same builder logic)
    S2 := FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .AsString;
      
    Assert.AreEqual(3, LMock.CallCount); // Prevous 2 + 1 GET (hit)
    Assert.AreEqual(S1, S2);
  finally
    LMock.Free;
  end;
end;

procedure TTestCache.TestCacheMiss;
var
  LMock: TMockRedis;
  LProvider: IFluentSQLCacheProvider;
begin
  LMock := TMockRedis.Create;
  try
    LProvider := TFluentSQLRedisCacheProvider.Create(LMock.Execute);
    
    FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .AsString;
      
    Assert.AreEqual(2, LMock.CallCount); // 1 GET (miss) + 1 SET
  finally
    LMock.Free;
  end;
end;

procedure TTestCache.TestCollisionAvoidance;
var
  LMock: TMockRedis;
  LProvider: IFluentSQLCacheProvider;
  S1, S2: string;
begin
  LMock := TMockRedis.Create;
  try
    LProvider := TFluentSQLRedisCacheProvider.Create(LMock.Execute);
    
    // Query without OrderBy
    S1 := FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .AsString;
      
    // Query WITH OrderBy
    S2 := FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .OrderBy('ID')
      .AsString;
      
    Assert.AreNotEqual(S1, S2, 'Queries with different structures must not return same cached result');
    Assert.AreEqual(4, LMock.CallCount); // (GET miss + SET) for S1 + (GET miss + SET) for S2
  finally
    LMock.Free;
  end;
end;

procedure TTestCache.TestCacheFallback;
var
  LMock: TMockRedis;
  LProvider: IFluentSQLCacheProvider;
  S: string;
begin
  LMock := TMockRedis.Create;
  try
    LMock.FailNext := True;
    LProvider := TFluentSQLRedisCacheProvider.Create(LMock.Execute);
    
    // FailNext throws on the first call (GET)
    S := FluentSQL.Query(dbnFirebird)
      .WithCache(LProvider)
      .Select.All.From('USERS')
      .AsString;
      
    Assert.AreEqual('SELECT * FROM USERS', S);
    Assert.AreEqual(1, LMock.CallCount); // Failed GET, then proceed with serialisation without SET (because it's not cached yet)
  finally
    LMock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCache);

end.
