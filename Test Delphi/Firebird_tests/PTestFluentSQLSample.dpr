program PTestFluentSQLSample;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  TestFluentSQLSample in 'TestFluentSQLSample.pas';

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
      TDUnitX.Options.XMLOutputFile := ChangeFileExt(ParamStr(0), '') + '-dunitx-results.xml'
    else
      // Veio da linha de comando: absolutiza contra o diretorio corrente, que e
      // o que 'custom.xml' quer dizer. Sem isto o DUnitX chama
      // ForceDirectories(ExtractFilePath(nome)) com string vazia e levanta
      // EInOutError, e a opcao passa a funcionar so com caminho completo - ou
      // seja, falha justo na forma mais obvia de argumento. ExpandFileName e
      // identidade para caminho ja absoluto e NAO valida a existencia do
      // destino: alvo impossivel continua estourando alto, com ExitCode != 0.
      TDUnitX.Options.XMLOutputFile := ExpandFileName(TDUnitX.Options.XMLOutputFile);
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
