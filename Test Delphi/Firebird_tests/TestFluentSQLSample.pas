unit TestFluentSQLSample;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFluentSQLSample = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test1;
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

procedure TTestFluentSQLSample.Setup;
begin
end;

procedure TTestFluentSQLSample.TearDown;
begin
end;

procedure TTestFluentSQLSample.Test1;
begin
end;

procedure TTestFluentSQLSample.Test2(const AValue1 : Integer;const AValue2 : Integer);
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLSample);

end.
