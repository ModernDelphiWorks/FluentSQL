program PTestFluentCQLFirebird;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  FastMM4,
  DUnitX.MemoryLeakMonitor.FastMM4,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  UTestFluent.CQLFirebird in 'UTestFluent.CQLFirebird.pas',
  FluentSQL.Ast in '..\..\Source\Core\FluentSQL.Ast.pas',
  FluentSQL.Cases in '..\..\Source\Core\FluentSQL.Cases.pas',
  FluentSQL.Core in '..\..\Source\Core\FluentSQL.Core.pas',
  FluentSQL.Delete in '..\..\Source\Core\FluentSQL.Delete.pas',
  FluentSQL.Expression in '..\..\Source\Core\FluentSQL.Expression.pas',
  FluentSQL.Functions in '..\..\Source\Core\FluentSQL.Functions.pas',
  FluentSQL.FunctionsAbstract in '..\..\Source\Core\FluentSQL.FunctionsAbstract.pas',
  FluentSQL.GroupBy in '..\..\Source\Core\FluentSQL.GroupBy.pas',
  FluentSQL.Having in '..\..\Source\Core\FluentSQL.Having.pas',
  FluentSQL.Insert in '..\..\Source\Core\FluentSQL.Insert.pas',
  FluentSQL.Interfaces in '..\..\Source\Core\FluentSQL.Interfaces.pas',
  FluentSQL.Joins in '..\..\Source\Core\FluentSQL.Joins.pas',
  FluentSQL.Name in '..\..\Source\Core\FluentSQL.Name.pas',
  FluentSQL.NameValue in '..\..\Source\Core\FluentSQL.NameValue.pas',
  FluentSQL.Operators in '..\..\Source\Core\FluentSQL.Operators.pas',
  FluentSQL.OrderBy in '..\..\Source\Core\FluentSQL.OrderBy.pas',
  FluentSQL in '..\..\Source\Core\FluentSQL.pas',
  FluentSQL.Qualifier in '..\..\Source\Core\FluentSQL.Qualifier.pas',
  FluentSQL.Register in '..\..\Source\Core\FluentSQL.Register.pas',
  FluentSQL.Section in '..\..\Source\Core\FluentSQL.Section.pas',
  FluentSQL.Select in '..\..\Source\Core\FluentSQL.Select.pas',
  FluentSQL.Serialize in '..\..\Source\Core\FluentSQL.Serialize.pas',
  FluentSQL.Update in '..\..\Source\Core\FluentSQL.Update.pas',
  FluentSQL.Utils in '..\..\Source\Core\FluentSQL.Utils.pas',
  FluentSQL.Where in '..\..\Source\Core\FluentSQL.Where.pas',
  FluentSQL.FunctionsDB2 in '..\..\Source\Drivers\FluentSQL.FunctionsDB2.pas',
  FluentSQL.FunctionsFirebird in '..\..\Source\Drivers\FluentSQL.FunctionsFirebird.pas',
  FluentSQL.FunctionsInterbase in '..\..\Source\Drivers\FluentSQL.FunctionsInterbase.pas',
  FluentSQL.FunctionsMSSQL in '..\..\Source\Drivers\FluentSQL.FunctionsMSSQL.pas',
  FluentSQL.FunctionsMySQL in '..\..\Source\Drivers\FluentSQL.FunctionsMySQL.pas',
  FluentSQL.FunctionsOracle in '..\..\Source\Drivers\FluentSQL.FunctionsOracle.pas',
  FluentSQL.FunctionsPostgreSQL in '..\..\Source\Drivers\FluentSQL.FunctionsPostgreSQL.pas',
  FluentSQL.FunctionsSQLite in '..\..\Source\Drivers\FluentSQL.FunctionsSQLite.pas',
  FluentSQL.QualifierDB2 in '..\..\Source\Drivers\FluentSQL.QualifierDB2.pas',
  FluentSQL.QualifierFirebird in '..\..\Source\Drivers\FluentSQL.QualifierFirebird.pas',
  FluentSQL.QualifierInterbase in '..\..\Source\Drivers\FluentSQL.QualifierInterbase.pas',
  FluentSQL.QualifierMongoDB in '..\..\Source\Drivers\FluentSQL.QualifierMongoDB.pas',
  FluentSQL.QualifierMSSQL in '..\..\Source\Drivers\FluentSQL.QualifierMSSQL.pas',
  FluentSQL.QualifierMySQL in '..\..\Source\Drivers\FluentSQL.QualifierMySQL.pas',
  FluentSQL.QualifierOracle in '..\..\Source\Drivers\FluentSQL.QualifierOracle.pas',
  FluentSQL.QualifierPostgreSQL in '..\..\Source\Drivers\FluentSQL.QualifierPostgreSQL.pas',
  FluentSQL.QualifierSQLite in '..\..\Source\Drivers\FluentSQL.QualifierSQLite.pas',
  FluentSQL.Select.SQLite in '..\..\Source\Drivers\FluentSQL.Select.SQLite.pas',
  FluentSQL.SelectDB2 in '..\..\Source\Drivers\FluentSQL.SelectDB2.pas',
  FluentSQL.SelectFirebird in '..\..\Source\Drivers\FluentSQL.SelectFirebird.pas',
  FluentSQL.SelectInterbase in '..\..\Source\Drivers\FluentSQL.SelectInterbase.pas',
  FluentSQL.SelectMongoDB in '..\..\Source\Drivers\FluentSQL.SelectMongoDB.pas',
  FluentSQL.SelectMSSQL in '..\..\Source\Drivers\FluentSQL.SelectMSSQL.pas',
  FluentSQL.SelectMySQL in '..\..\Source\Drivers\FluentSQL.SelectMySQL.pas',
  FluentSQL.SelectOracle in '..\..\Source\Drivers\FluentSQL.SelectOracle.pas',
  FluentSQL.SelectPostgreSQL in '..\..\Source\Drivers\FluentSQL.SelectPostgreSQL.pas',
  FluentSQL.SerializeDB2 in '..\..\Source\Drivers\FluentSQL.SerializeDB2.pas',
  FluentSQL.SerializeFirebird in '..\..\Source\Drivers\FluentSQL.SerializeFirebird.pas',
  FluentSQL.SerializeInterbase in '..\..\Source\Drivers\FluentSQL.SerializeInterbase.pas',
  FluentSQL.SerializeMongoDB in '..\..\Source\Drivers\FluentSQL.SerializeMongoDB.pas',
  FluentSQL.SerializeMSSQL in '..\..\Source\Drivers\FluentSQL.SerializeMSSQL.pas',
  FluentSQL.SerializeMySQL in '..\..\Source\Drivers\FluentSQL.SerializeMySQL.pas',
  FluentSQL.SerializeOracle in '..\..\Source\Drivers\FluentSQL.SerializeOracle.pas',
  FluentSQL.SerializePostgreSQL in '..\..\Source\Drivers\FluentSQL.SerializePostgreSQL.pas',
  FluentSQL.SerializeSQLite in '..\..\Source\Drivers\FluentSQL.SerializeSQLite.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    TDUnitX.Options.ExitBehavior := TDUnitXExitBehavior.Pause;
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
