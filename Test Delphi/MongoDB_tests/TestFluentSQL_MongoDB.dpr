program TestFluentSQL_MongoDB;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
{$DEFINE MONGODB}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  test.ddl.mongodb in 'test.ddl.mongodb.pas',
  test.dml.mongodb in 'test.dml.mongodb.pas',
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
  FluentSQL.Update in '..\..\Source\Core\FluentSQL.Update.pas',
  FluentSQL.Utils in '..\..\Source\Core\FluentSQL.Utils.pas',
  FluentSQL.Where in '..\..\Source\Core\FluentSQL.Where.pas',
  FluentSQL.DDL.Serialize.MongoDB in '..\..\Source\Drivers\FluentSQL.DDL.Serialize.MongoDB.pas',
  FluentSQL.FunctionsMongoDB in '..\..\Source\Drivers\FluentSQL.FunctionsMongoDB.pas',
  FluentSQL.QualifierMongoDB in '..\..\Source\Drivers\FluentSQL.QualifierMongoDB.pas',
  FluentSQL.SelectMongoDB in '..\..\Source\Drivers\FluentSQL.SelectMongoDB.pas',
  FluentSQL.SerializeMongoDB in '..\..\Source\Drivers\FluentSQL.SerializeMongoDB.pas';

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
    TDUnitX.CheckCommandLine;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := False;

    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;

    // Nome do XML DERIVADO DO EXECUTAVEL, nunca uma string fixa: dois .dpr que
    // gravem 'dunitx-results.xml' no mesmo diretorio se sobrescrevem e a medicao do
    // primeiro some sem uma linha de aviso. Derivar de ParamStr(0) mantem o nome
    // unico ate quando alguem copia este .dpr para criar o proximo projeto.
    // So vale como DEFAULT. Se a linha de comando pediu --xmlfile/--xml, o
    // CheckCommandLine acima ja gravou o destino em Options.XMLOutputFile (o
    // default do DUnitX e string vazia) e quem chamou manda: sobrescrever aqui
    // sem guarda faz o arquivo nascer em outro lugar e o coletor achar o nada.
    if TDUnitX.Options.XMLOutputFile = '' then
      TDUnitX.Options.XMLOutputFile := ChangeFileExt(ParamStr(0), '') + '-dunitx-results.xml';
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    results := runner.Execute;
    // Piso de honestidade: runner que nao encontrou caso nenhum nao sai com
    // sucesso. Sem isto um projeto que compila mas perde o registro dos fixtures
    // some da soma da suite sem uma linha de aviso - e a soma continua 'batendo'
    // com uma suite menor. Nao ha lista de fixtures esperados aqui de proposito:
    // lista escrita a mao apodrece no primeiro teste que alguem acrescenta.
    if results.TestCount = 0 then
    begin
      System.Writeln('FATAL: nenhum caso de teste foi encontrado neste projeto.');
      System.ExitCode := EXIT_ERRORS;
    end;
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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      // Excecao no bootstrap (alvo de XML invalido, opcao malformada) tem de sair
      // com codigo != 0: sem isto o processo morre antes de rodar um unico caso e
      // a automacao le a ausencia de resultado como sucesso. So EXIT_OK e
      // sobrescrito, para nao apagar o EXIT_OPTIONS_ERROR que o proprio
      // CheckCommandLine ja tenha posto.
      if System.ExitCode = EXIT_OK then
        System.ExitCode := EXIT_ERRORS;
    end;
  end;
{$ENDIF}
end.
