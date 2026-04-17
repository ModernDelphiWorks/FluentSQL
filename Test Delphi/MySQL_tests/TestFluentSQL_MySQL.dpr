program TestFluentSQL_MySQL;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  test.functions.mysql in 'test.functions.mysql.pas',
  test.select.mysql in 'test.select.mysql.pas',
  test.core.params in '..\test.core.params.pas',
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
  FluentSQL.Params in '..\..\Source\Core\FluentSQL.Params.pas',
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
  FluentSQL.SerializeSQLite in '..\..\Source\Drivers\FluentSQL.SerializeSQLite.pas';

{$IFNDEF TESTINSIGHT}
var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    TDUnitX.CheckCommandLine;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False;

    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
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
