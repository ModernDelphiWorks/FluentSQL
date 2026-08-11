{
  ------------------------------------------------------------------------------
  FluentSQL - matriz da COLUNA COMPUTADA por dialeto (T27)

  POR QUE ESTE ARQUIVO EXISTE

  Ate a T27 a celula do SQL Server fixava

      CREATE TABLE [VENDAS] (... [TOTAL] INT AS (QTD * PRECO))

  e passava. O texto e RECUSADO pelo motor. Medido no SQL Server 2022
  (16.0.4265.3) com SET PARSEONLY ON - que so parseia, nem resolve nome:

      [TOTAL] INT AS (QTD * PRECO) -> Msg 156, Level 15
                                      Incorrect syntax near the keyword 'AS'
      [TOTAL] AS (QTD * PRECO)     -> parseia limpo

  A gramatica de <computed_column_definition> no T-SQL e
  "column_name AS computed_column_expression": nao ha <data_type> nela. O tipo da
  coluna computada e DERIVADO da expressao.

  A ARMADILHA QUE ESTA MATRIZ TRAVA

  A correcao obvia - "parar de emitir o tipo antes da clausula de computacao" -
  conserta o T-SQL e QUEBRA o PostgreSQL, que EXIGE o tipo. Os cinco dialetos
  divergem, e a divergencia foi medida em motor, nao lida em documentacao:

    MSSQL 2022        [TOTAL] AS (QTD * PRECO)                       tipo PROIBIDO
    PostgreSQL 16.14  "TOTAL" INTEGER GENERATED ALWAYS AS (...) STORED  tipo EXIGIDO
    MySQL 8.4         `TOTAL` INT AS (...) VIRTUAL                   tipo aceito
    Oracle 23 Free    "TOTAL" NUMBER GENERATED ALWAYS AS (...) VIRTUAL tipo aceito
    Firebird 5.0.4    "TOTAL" INTEGER COMPUTED BY (...)               tipo aceito
    SQLite            nao chega a emitir: levanta ENotSupportedException

  Por isso a correcao mora num gancho de dialeto
  (TFluentDDLSerializeAbstract.ComputedColumnCarriesType, default True) e nao no
  caminho comum: quem nao sobrescreve continua emitindo byte a byte o que emitia.

  ESTE TESTE E ANTI-COLATERAL, E ELE CAI DE VERDADE

  Falsificado por mutacao dirigida, nao deduzido:
    * trocar o default de ComputedColumnCarriesType para False derruba as celulas
      de PostgreSQL, MySQL, Oracle e Firebird deste arquivo;
    * remover o override do MSSQL (voltando ao texto antigo) derruba a celula do
      MSSQL.
  Ou seja: a matriz distingue os dois lados. Um teste que so olhasse o MSSQL
  passaria com a mutacao que quebra os outros cinco - foi exatamente esse tipo de
  lacuna que deixou a celula errada verde ate aqui.

  CAIXA: todo Assert.AreEqual daqui passa False em IgnoreCase. O default do DUnitX
  ignora maiuscula/minuscula, e numa biblioteca cujo produto E texto SQL isso
  deixaria "as" passar por "AS".
  ------------------------------------------------------------------------------
}

unit test.computed.column.matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestComputedColumnMatrix = class
  public
    /// <summary>T-SQL: a coluna computada NAO carrega tipo (Msg 156 se carregar).</summary>
    [Test]
    procedure TestMSSQLNaoEmiteTipoNaColunaComputada;
    /// <summary>Anti-colateral: os demais dialetos continuam carregando o tipo.</summary>
    [Test]
    procedure TestDemaisDialetosContinuamCarregandoOTipo;
    /// <summary>A coluna COMUM nunca perdeu o tipo, nem no MSSQL.</summary>
    [Test]
    procedure TestColunaComumMantemTipoEmTodoDialeto;
    /// <summary>SQLite nao emite coluna computada: levanta erro nomeado.</summary>
    [Test]
    procedure TestSQLiteLevantaEmColunaComputada;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

const
  cDIALETO: array[TFluentSQLDriver] of String = (
    'dbnMSSQL', 'dbnMySQL', 'dbnFirebird', 'dbnSQLite', 'dbnInterbase',
    'dbnDB2', 'dbnOracle', 'dbnPostgreSQL', 'dbnMongoDB'
  );

/// <summary>
///   Dialeto ligado em FluentSQL.inc / linha de comando? Detectado em runtime,
///   nao assumido - mesma tecnica de test.alias.matrix.pas. Sem isto a matriz
///   passaria a MEDIR MENOS conforme os defines, calada.
///
///   O registro de DDL nao levanta EFluentSQLDriverNotRegistered como o de DML:
///   TFluentSQLRegister.DDLSerialize (FluentSQL.Register.pas:291) levanta
///   ENotSupportedException com "O DDL serialize do banco X nao esta
///   registrado!". Por isso a guarda olha as DUAS - so a de DML deixaria o
///   Interbase/DB2 desligados quebrarem a matriz em vez de saírem dela.
/// </summary>
function _EstaRegistrado(const ADriver: TFluentSQLDriver): Boolean;
begin
  Result := True;
  try
    FluentSQL.Schema(ADriver).Table('T').Create.ColumnInteger('A').AsString;
  except
    on E: EFluentSQLDriverNotRegistered do
      Result := False;
    on E: ENotSupportedException do
    begin
      // So a ausencia de registro tira o dialeto da matriz. Qualquer outro
      // ENotSupportedException e defeito e tem de continuar subindo - engolir
      // tudo aqui faria a matriz encolher em silencio, que e o defeito que esta
      // tarefa esta caçando.
      if Pos('DDL serialize', E.Message) = 0 then
        raise;
      Result := False;
    end;
  end;
end;

function _Computada(const ADriver: TFluentSQLDriver): String;
begin
  Result := FluentSQL.Schema(ADriver).Table('VENDAS').Create
    .ColumnInteger('ID')
    .ColumnInteger('QTD')
    .ColumnInteger('PRECO')
    .ColumnInteger('TOTAL').ComputedBy('QTD * PRECO')
    .AsString;
end;

procedure TTestComputedColumnMatrix.TestMSSQLNaoEmiteTipoNaColunaComputada;
var
  LSql: String;
begin
  if not _EstaRegistrado(dbnMSSQL) then
    Assert.Fail('dbnMSSQL nao registrado: esta matriz nao mede nada sem ele.');
  LSql := _Computada(dbnMSSQL);
  Assert.AreEqual(
    'CREATE TABLE [VENDAS] ([ID] INT, [QTD] INT, [PRECO] INT, [TOTAL] AS (QTD * PRECO))',
    LSql, False, 'T-SQL: <computed_column_definition> nao tem <data_type>.');
  // A forma exata que o motor recusou, travada como texto proibido: se alguem
  // reintroduzir o tipo por outro caminho, esta linha cai mesmo que a de cima
  // tenha sido reescrita junto.
  Assert.DoesNotContain(LSql, '[TOTAL] INT AS', False,
    'Msg 156 no SQL Server 2022: tipo antes de AS na coluna computada.');
end;

procedure TTestComputedColumnMatrix.TestDemaisDialetosContinuamCarregandoOTipo;
var
  LCelulas: Integer;
begin
  // O CONTRASTE. Se a correcao do T-SQL tivesse ido para o caminho comum, todas
  // estas celulas cairiam - inclusive a do PostgreSQL, que EXIGE o tipo e
  // devolveria erro de sintaxe sem ele.
  LCelulas := 0;

  if _EstaRegistrado(dbnPostgreSQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, ' +
      '"TOTAL" INTEGER GENERATED ALWAYS AS (QTD * PRECO) STORED)',
      _Computada(dbnPostgreSQL), False,
      'PostgreSQL EXIGE o tipo na coluna gerada.');
  end;

  if _EstaRegistrado(dbnMySQL) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE `VENDAS` (`ID` INT, `QTD` INT, `PRECO` INT, ' +
      '`TOTAL` INT AS (QTD * PRECO) VIRTUAL)',
      _Computada(dbnMySQL), False, 'MySQL aceita o tipo na coluna gerada.');
  end;

  if _EstaRegistrado(dbnFirebird) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "VENDAS" ("ID" INTEGER, "QTD" INTEGER, "PRECO" INTEGER, ' +
      '"TOTAL" INTEGER COMPUTED BY (QTD * PRECO))',
      _Computada(dbnFirebird), False, 'Firebird aceita o tipo antes de COMPUTED BY.');
  end;

  if _EstaRegistrado(dbnOracle) then
  begin
    Inc(LCelulas);
    Assert.AreEqual(
      'CREATE TABLE "VENDAS" ("ID" NUMBER(10), "QTD" NUMBER(10), "PRECO" NUMBER(10), ' +
      '"TOTAL" NUMBER(10) GENERATED ALWAYS AS (QTD * PRECO) VIRTUAL)',
      _Computada(dbnOracle), False, 'Oracle aceita o tipo na coluna virtual.');
  end;

  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestComputedColumnMatrix.TestColunaComumMantemTipoEmTodoDialeto;
var
  LDriver: TFluentSQLDriver;
  LSql: String;
  LLista: String;
  LAbre: Integer;
  LCelulas: Integer;
begin
  // O gancho so pode alcancar a coluna COMPUTADA. Uma coluna comum tem de
  // continuar com tipo em TODO dialeto - inclusive no MSSQL, que e o unico que
  // sobrescreve o gancho. Sem esta celula, um override que devolvesse False
  // para toda coluna passaria despercebido nos testes de coluna computada.
  LCelulas := 0;
  for LDriver := Low(TFluentSQLDriver) to High(TFluentSQLDriver) do
  begin
    if (LDriver = dbnMongoDB) or (not _EstaRegistrado(LDriver)) then
      Continue;
    Inc(LCelulas);
    LSql := FluentSQL.Schema(LDriver).Table('T').Create.ColumnInteger('A').AsString;
    LAbre := Pos('(', LSql);
    Assert.IsTrue(LAbre > 0, cDIALETO[LDriver] + ': DDL degenerado, sem lista de colunas.');
    // A verificacao e ESTRUTURAL de proposito, e nao uma tabela de textos por
    // dialeto: o que se afirma e que a definicao da coluna tem MAIS DE UM TOKEN
    // - nome e tipo separados por espaco. Se o gancho vazar para a coluna comum,
    // a lista vira "([A])" / "(\"A\")" / "(`A`)", sem espaco nenhum, e esta
    // linha cai em qualquer dialeto, com qualquer delimitador e qualquer nome de
    // tipo.
    // Foi assim que ela virou load-bearing: a primeira versao deste teste usava
    // DoesNotContain('(A)') e NAO caiu na mutacao que faz exatamente isso,
    // porque o nome sai delimitado. Teste que nao cai na mutacao que ele diz
    // vigiar e decoracao.
    LLista := Copy(LSql, LAbre + 1, Length(LSql) - LAbre);
    Assert.IsTrue(Pos(' ', LLista) > 0,
      cDIALETO[LDriver] + ': coluna comum perdeu o tipo -> ' + LSql);
  end;
  Assert.IsTrue(LCelulas > 0, 'Nenhum dialeto percorrido: a matriz nao mede nada.');
end;

procedure TTestComputedColumnMatrix.TestSQLiteLevantaEmColunaComputada;
begin
  if not _EstaRegistrado(dbnSQLite) then
    Assert.Fail('dbnSQLite nao registrado: esta matriz nao mede nada sem ele.');
  // O SQLite nao entra na matriz de texto: ele recusa a operacao com erro
  // nomeado, que e a regra da casa (erro nomeado > SQL que o motor recusa).
  Assert.WillRaise(
    procedure
    begin
      _Computada(dbnSQLite);
    end,
    ENotSupportedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestComputedColumnMatrix);

end.
