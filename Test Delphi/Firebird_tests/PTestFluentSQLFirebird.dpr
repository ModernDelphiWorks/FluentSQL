program PTestFluentSQLFirebird;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
{$DEFINE MYSQL}
{$DEFINE POSTGRESQL}
{$DEFINE MONGODB}
{$DEFINE SQLITE}
{$DEFINE MSSQL}
{$DEFINE FIREBIRD}
{$DEFINE ORACLE}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  UTestFluentSQLFirebird in 'UTestFluentSQLFirebird.pas',
  test.core.params in '..\test.core.params.pas',
  test.ddl.firebird in 'test.ddl.firebird.pas',
  test.operators.isin.firebird in 'test.operators.isin.firebird.pas',
  FluentSQL.Ast in '..\..\Source\Core\FluentSQL.Ast.pas',
  FluentSQL.Cache.Interfaces in '..\..\Source\Core\FluentSQL.Cache.Interfaces.pas',
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
  FluentSQL.Params in '..\..\Source\Core\FluentSQL.Params.pas',
  FluentSQL in '..\..\Source\Core\FluentSQL.pas',
  FluentSQL.Qualifier in '..\..\Source\Core\FluentSQL.Qualifier.pas',
  FluentSQL.Register in '..\..\Source\Core\FluentSQL.Register.pas',
  FluentSQL.Section in '..\..\Source\Core\FluentSQL.Section.pas',
  FluentSQL.Select in '..\..\Source\Core\FluentSQL.Select.pas',
  FluentSQL.Serialize in '..\..\Source\Core\FluentSQL.Serialize.pas',
  FluentSQL.DDL.Serialize in '..\..\Source\Core\FluentSQL.DDL.Serialize.pas',
  FluentSQL.DDL.SerializeAbstract in '..\..\Source\Core\FluentSQL.DDL.SerializeAbstract.pas',
  FluentSQL.DDL in '..\..\Source\Core\FluentSQL.DDL.pas',
  FluentSQL.DDL.Serialize.Firebird in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.Firebird.pas',
  FluentSQL.DDL.Serialize.MySQL in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.MySQL.pas',
  FluentSQL.DDL.Serialize.PostgreSQL in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.PostgreSQL.pas',
  FluentSQL.Update in '..\..\Source\Core\FluentSQL.Update.pas',
  FluentSQL.Utils in '..\..\Source\Core\FluentSQL.Utils.pas',
  FluentSQL.Where in '..\..\Source\Core\FluentSQL.Where.pas',
  FluentSQL.FunctionsDB2 in '..\..\Source\Drivers\FluentSQL.FunctionsDB2.pas',
  FluentSQL.FunctionsFirebird in '..\..\Source\Drivers\FluentSQL.FunctionsFirebird.pas',
  FluentSQL.FunctionsInterbase in '..\..\Source\Drivers\FluentSQL.FunctionsInterbase.pas',
  FluentSQL.FunctionsMSSQL in '..\..\Source\Drivers\FluentSQL.FunctionsMSSQL.pas',
  FluentSQL.FunctionsMySQL in '..\..\Source\Drivers\FluentSQL.FunctionsMySQL.pas',
  FluentSQL.FunctionsMongoDB in '..\..\Source\Drivers\FluentSQL.FunctionsMongoDB.pas',
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
  FluentSQL.Select.Firebird in '..\..\Source\Drivers\FluentSQL.Select.Firebird.pas',
  FluentSQL.SelectInterbase in '..\..\Source\Drivers\FluentSQL.SelectInterbase.pas',
  FluentSQL.SelectMongoDB in '..\..\Source\Drivers\FluentSQL.SelectMongoDB.pas',
  FluentSQL.Select.MSSQL in '..\..\Source\Drivers\FluentSQL.Select.MSSQL.pas',
  FluentSQL.Select.MySQL in '..\..\Source\Drivers\FluentSQL.Select.MySQL.pas',
  FluentSQL.Select.Oracle in '..\..\Source\Drivers\FluentSQL.Select.Oracle.pas',
  FluentSQL.Select.PostgreSQL in '..\..\Source\Drivers\FluentSQL.Select.PostgreSQL.pas',
  FluentSQL.SerializeDB2 in '..\..\Source\Drivers\FluentSQL.SerializeDB2.pas',
  FluentSQL.SerializeFirebird in '..\..\Source\Drivers\FluentSQL.SerializeFirebird.pas',
  FluentSQL.SerializeInterbase in '..\..\Source\Drivers\FluentSQL.SerializeInterbase.pas',
  FluentSQL.SerializeMongoDB in '..\..\Source\Drivers\FluentSQL.SerializeMongoDB.pas',
  FluentSQL.SerializeMSSQL in '..\..\Source\Drivers\FluentSQL.SerializeMSSQL.pas',
  FluentSQL.SerializeMySQL in '..\..\Source\Drivers\FluentSQL.SerializeMySQL.pas',
  FluentSQL.SerializeOracle in '..\..\Source\Drivers\FluentSQL.SerializeOracle.pas',
  FluentSQL.SerializePostgreSQL in '..\..\Source\Drivers\FluentSQL.SerializePostgreSQL.pas',
  FluentSQL.SerializeSQLite in '..\..\Source\Drivers\FluentSQL.SerializeSQLite.pas',
  FluentSQL.DDL.Serialize.SQLite in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.SQLite.pas',
  FluentSQL.DDL.Serialize.MSSQL in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.MSSQL.pas',
  FluentSQL.DDL.Serialize.Oracle in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.Oracle.pas';

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
    TDUnitX.Options.XMLOutputFile := '.\dunitx-results.xml';
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
