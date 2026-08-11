program TestFluentSQL_Common;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
{$DEFINE FIREBIRD}
{$DEFINE MSSQL}
{$DEFINE MYSQL}
{$DEFINE ORACLE}
{$DEFINE POSTGRESQL}
{$DEFINE SQLITE}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  test.alias.matrix in 'test.alias.matrix.pas',
  test.builder.guards in 'test.builder.guards.pas',
  test.cache in 'test.cache.pas',
  test.cases.value in 'test.cases.value.pas',
  test.cast.matrix in 'test.cast.matrix.pas',
  test.computed.column.matrix in 'test.computed.column.matrix.pas',
  test.date.literal.matrix in 'test.date.literal.matrix.pas',
  test.delete.alias.matrix in 'test.delete.alias.matrix.pas',
  test.delete.multirelacao in 'test.delete.multirelacao.pas',
  test.exists.subquery.matrix in 'test.exists.subquery.matrix.pas',
  test.ddl.identity in 'test.ddl.identity.pas',
  test.ddl.numeric in 'test.ddl.numeric.pas',
  test.ddl.procedures in 'test.ddl.procedures.pas',
  test.ddl.schemas in 'test.ddl.schemas.pas',
  test.ddl.sequences in 'test.ddl.sequences.pas',
  test.merge.matrix in 'test.merge.matrix.pas',
  test_esp074_unit in 'test_esp074_unit.pas',
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
    // ATENCAO a quem coleta por glob '*-dunitx-results.xml': nao e so
    // --xmlfile/--xml que redireciona. O DUnitX registra uma opcao SEM NOME e
    // OCULTA que grava no mesmo Options.XMLOutputFile
    // (DUnitX.OptionsDefinition.pas:124-129), entao um argumento POSICIONAL
    // solto - 'runner.exe lixo.txt' - manda o resultado para 'lixo.txt' e
    // nenhum XML derivado nasce. Os testes rodam, o processo sai com 0 e o
    // glob nao acha nada. Nao ha guarda contra isso de proposito: a semantica
    // ratificada e que a linha de comando manda. Fica declarado.
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
    // sucesso. O que ESTE piso cobre e o caso em que os fixtures EXISTEM e a
    // selecao nao casa com teste nenhum - qualquer filtro vazio (--run,
    // --include, --exclude, --runlist; todos desaguam no mesmo
    // TDUnitXFilterBuilder.BuildFilter). Ai o DUnitX nao levanta nada: devolve
    // Tests Found: 0 com AllPassed = True, e sem o piso o projeto sai com 0,
    // some da soma da suite sem uma linha de aviso e a soma continua 'batendo'
    // com uma suite menor.
    // NAO e este piso que cobre 'nenhum fixture registrado': nesse caso o
    // DUnitX levanta ENoTestsRegistered (DUnitX.TestRunner.pas:599) e quem
    // transforma aquilo em codigo != 0 e a guarda do except, mais abaixo.
    // Nao ha lista de fixtures esperados aqui de proposito: lista escrita a mao
    // apodrece no primeiro teste que alguem acrescenta. O piso derivado nao
    // apodrece - e a lacuna fica declarada: queda PARCIAL (205 -> 3) passa.
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
