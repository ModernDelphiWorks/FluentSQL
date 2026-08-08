unit test.core.params;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestCoreParams = class
  public
    [Test]
    procedure TestParamExtraction;
    [Test]
    procedure TestMultipleParams;
    [Test]
    procedure TestInsertUpdateParams;
    [Test]
    procedure TestWhereArrayOfConst;
    [Test]
    procedure TestHavingArrayOfConst;
    [Test]
    procedure TestInsertValuesArrayOfConst;
    [Test]
    procedure TestCaseWhenArrayOfConst;
    [Test]
    procedure TestCriteriaExpressionArrayOfConstViaWhere;
    [Test]
    procedure TestCriteriaExpressionChainedArrayOfConstMySQL;
    [Test]
    procedure TestColumnArrayOfConstFirebird;
    [Test]
    procedure TestColumnArrayOfConstMySQL;
    [Test]
    procedure TestCaseExprArrayOfConstFirebird;
    [Test]
    procedure TestCaseExprArrayOfConstMySQL;
    [Test]
    procedure TestInsertBatchTwoRowsFirebird;
    [Test]
    procedure TestInsertBatchTwoRowsMySQL;
    [Test]
    procedure TestDialectOnlyOmittedWhenNotTargetDialect;
    [Test]
    procedure TestDialectOnlyEmittedForTargetDialect;
    [Test]
    procedure TestDialectOnlyArrayOfConstBindsParams;
    /// <summary>
    ///   SetValue/Values(array of const) e posicao de VALOR - o lado direito de
    ///   "COLUNA = ...". Ali a RN-P3 nao vale: string tambem tem de virar :pN.
    ///   Antes, o numerico parametrizava e a string ia VERBATIM para o texto do
    ///   SQL, sem aspas e sem escape, dentro do MESMO slot.
    /// </summary>
    [Test]
    procedure TestSetValueArrayOfConstStringBecomesParam;
    [Test]
    procedure TestValuesArrayOfConstStringBecomesParam;
    [Test]
    procedure TestSetValueArrayOfConstHostileStringNeverReachesSqlText;
  end;

implementation

uses
  SysUtils,
  FluentSQL.Interfaces,
  FluentSQL;

procedure TTestCoreParams.TestParamExtraction;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .All
    .From('CLIENTES')
    .Where('ID').Equal(10)
    .AndOpe('NOME').Equal('JOAO');

  // SQL esperado deve conter placeholders :p1 e :p2
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE (ID = :p1) AND (NOME = :p2)', LQuery.AsString);
  
  // Validar coleção de parâmetros
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual(10, Integer(LQuery.Params[0].Value));
  Assert.AreEqual('p2', LQuery.Params[1].Name);
  Assert.AreEqual('JOAO', String(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestMultipleParams;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnMySQL)
    .Select
    .All
    .From('PRODUTOS')
    .Where('PRECO').GreaterThan(100.50)
    .AndOpe('CATEGORIA').InValues(TArray<String>.Create('A', 'B', 'C'));

  Assert.AreEqual('SELECT * FROM PRODUTOS WHERE (PRECO > ?) AND (CATEGORIA IN (?, ?, ?))', LQuery.AsString);
  Assert.AreEqual(4, LQuery.Params.Count);
end;

procedure TTestCoreParams.TestInsertUpdateParams;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ISAQUE')
    .SetValue('IDADE', 30);

  Assert.AreEqual('INSERT INTO USUARIOS (NOME, IDADE) VALUES (:p1, :p2)', LQuery.AsString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('ISAQUE', String(LQuery.Params[0].Value));
  Assert.AreEqual(30, Integer(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestWhereArrayOfConst;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .All
    .From('CLIENTES')
    .Where(['ID', '=', 42]);
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE ID = :p1', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(42, Integer(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestHavingArrayOfConst;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .All
    .From('PEDIDOS')
    .GroupBy('CLIENTE_ID')
    .Having(['SUM_TOTAL', '>', 1000]);
  Assert.AreEqual('SELECT * FROM PEDIDOS GROUP BY CLIENTE_ID HAVING SUM_TOTAL > :p1', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(1000, Integer(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestInsertValuesArrayOfConst;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'TESTE')
    .Values('NIVEL', [7]);
  Assert.AreEqual('INSERT INTO USUARIOS (NOME, NIVEL) VALUES (:p1, :p2)', LQuery.AsString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('TESTE', String(LQuery.Params[0].Value));
  Assert.AreEqual(7, Integer(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestCaseWhenArrayOfConst;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .Column('ID')
    .Column('TIPO_CLIENTE')
    .CaseExpr
      .When([0]).IfThen('''FISICA''')
      .When([1]).IfThen('''JURIDICA''')
      .ElseIf('''OUTRO''')
    .EndCase
    .Alias('TIPO_PESSOA')
    .From('CLIENTES');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO_CLIENTE WHEN :p1 THEN ''FISICA'' WHEN :p2 THEN ''JURIDICA'' ELSE ''OUTRO'' END) AS TIPO_PESSOA FROM CLIENTES',
    LQuery.AsString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual(0, Integer(LQuery.Params[0].Value));
  Assert.AreEqual(1, Integer(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestCriteriaExpressionArrayOfConstViaWhere;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .All
    .From('CLIENTES');
  LQuery := LQuery.Where(LQuery.Expression(['ID', '=', 99]));
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE ID = :p1', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(99, Integer(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestCriteriaExpressionChainedArrayOfConstMySQL;
var
  LQuery: IFluentSQL;
  LExpr: IFluentSQLCriteriaExpression;
begin
  LQuery := FluentSQL.Query(dbnMySQL)
    .Select
    .All
    .From('PEDIDOS');
  LExpr := LQuery.Expression(['STATUS', '=', 1]);
  LExpr.AndOpe(['TOTAL', '>', 500]);
  LQuery := LQuery.Where(LExpr);
  Assert.AreEqual('SELECT * FROM PEDIDOS WHERE (STATUS = ?) AND (TOTAL > ?)', LQuery.AsString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual(1, Integer(LQuery.Params[0].Value));
  Assert.AreEqual(500, Integer(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestColumnArrayOfConstFirebird;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .Column(['QTD', '*', 2])
    .From('ITENS');
  Assert.AreEqual('SELECT QTD * :p1 FROM ITENS', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual(2, Integer(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestColumnArrayOfConstMySQL;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnMySQL)
    .Select
    .Column(['PRECO', '+', 10])
    .From('PRODUTOS');
  Assert.AreEqual('SELECT PRECO + ? FROM PRODUTOS', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(10, Integer(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestCaseExprArrayOfConstFirebird;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .Column('ID')
    .Column('TIPO_CLIENTE')
    .CaseExpr(['TIPO_CLIENTE', '*', 2])
      .When([0]).IfThen('''FISICA''')
      .When([1]).IfThen('''JURIDICA''')
      .ElseIf('''OUTRO''')
    .EndCase
    .Alias('TIPO_PESSOA')
    .From('CLIENTES');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO_CLIENTE * :p1 WHEN :p2 THEN ''FISICA'' WHEN :p3 THEN ''JURIDICA'' ELSE ''OUTRO'' END) AS TIPO_PESSOA FROM CLIENTES',
    LQuery.AsString);
  Assert.AreEqual(3, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual(2, Integer(LQuery.Params[0].Value));
  Assert.AreEqual(0, Integer(LQuery.Params[1].Value));
  Assert.AreEqual(1, Integer(LQuery.Params[2].Value));
end;

procedure TTestCoreParams.TestCaseExprArrayOfConstMySQL;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnMySQL)
    .Select
    .Column('ID')
    .Column('TIPO_CLIENTE')
    .CaseExpr(['TIPO_CLIENTE', '*', 2])
      .When([0]).IfThen('''FISICA''')
      .When([1]).IfThen('''JURIDICA''')
      .ElseIf('''OUTRO''')
    .EndCase
    .Alias('TIPO_PESSOA')
    .From('CLIENTES');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO_CLIENTE * ? WHEN ? THEN ''FISICA'' WHEN ? THEN ''JURIDICA'' ELSE ''OUTRO'' END) AS TIPO_PESSOA FROM CLIENTES',
    LQuery.AsString);
  Assert.AreEqual(3, LQuery.Params.Count);
  Assert.AreEqual(2, Integer(LQuery.Params[0].Value));
  Assert.AreEqual(0, Integer(LQuery.Params[1].Value));
  Assert.AreEqual(1, Integer(LQuery.Params[2].Value));
end;

procedure TTestCoreParams.TestInsertBatchTwoRowsFirebird;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ANA')
    .SetValue('IDADE', 20)
    .AddRow
    .SetValue('NOME', 'BOB')
    .SetValue('IDADE', 21);
  Assert.AreEqual(
    'INSERT INTO USUARIOS (NOME, IDADE) VALUES (:p1, :p2), (:p3, :p4)',
    LQuery.AsString);
  Assert.AreEqual(4, LQuery.Params.Count);
  Assert.AreEqual('ANA', String(LQuery.Params[0].Value));
  Assert.AreEqual(20, Integer(LQuery.Params[1].Value));
  Assert.AreEqual('BOB', String(LQuery.Params[2].Value));
  Assert.AreEqual(21, Integer(LQuery.Params[3].Value));
end;

procedure TTestCoreParams.TestInsertBatchTwoRowsMySQL;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnMySQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ANA')
    .SetValue('IDADE', 20)
    .AddRow
    .SetValue('NOME', 'BOB')
    .SetValue('IDADE', 21);
  Assert.AreEqual(
    'INSERT INTO USUARIOS (NOME, IDADE) VALUES (?, ?), (?, ?)',
    LQuery.AsString);
  Assert.AreEqual(4, LQuery.Params.Count);
end;

procedure TTestCoreParams.TestDialectOnlyOmittedWhenNotTargetDialect;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Insert
    .Into('T')
    .SetValue('A', 1)
    .ForDialectOnly(dbnPostgreSQL, ' RETURNING ID')
    .ForDialectOnly(dbnMySQL, '');
  Assert.AreEqual('INSERT INTO T (A) VALUES (:p1)', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
end;

procedure TTestCoreParams.TestDialectOnlyEmittedForTargetDialect;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('T')
    .SetValue('A', 1)
    .ForDialectOnly(dbnPostgreSQL, ' RETURNING ID');
  Assert.AreEqual('INSERT INTO T (A) VALUES (:p1) RETURNING ID', LQuery.AsString);
  Assert.AreEqual(1, LQuery.Params.Count);
end;

procedure TTestCoreParams.TestDialectOnlyArrayOfConstBindsParams;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select
    .All
    .From('T')
    .Where('ID').Equal(1)
    .ForDialectOnly(dbnFirebird, [' OFFSET ', 0]);
  Assert.AreEqual('SELECT * FROM T WHERE (ID = :p1) OFFSET :p2', LQuery.AsString);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual(1, Integer(LQuery.Params[0].Value));
  Assert.AreEqual(0, Integer(LQuery.Params[1].Value));
end;

{ ---------------------------------------------------------------------------
  SetValue / Values (array of const) - SLOT DE VALOR

  Estes tres travam a correcao de um defeito de ASSIMETRIA: no MESMO slot,
  .Values('NIVEL', [7]) ja saia como :p1 (ver TestInsertValuesArrayOfConst
  acima) enquanto .SetValue('NOME', ['TESTE']) saia como o texto TESTE cru,
  sem aspas e sem escape. Numerico parametrizava, string nao.

  Nao e caso de RN-P3: a RN-P3 deixa string literal quando o array of const
  esta em posicao de EXPRESSAO (Where, Column, Having, CaseExpr, Merge.On), onde
  a string pode legitimamente ser fragmento de SQL. Aqui o array e o lado
  DIREITO de "COLUNA = ..." - o proprio _InternalSet o afirma com
  _AssertSection([secInsert, secUpdate]) - e nessa posicao string nao tem como
  ser fragmento, so pode ser dado.
  --------------------------------------------------------------------------- }

procedure TTestCoreParams.TestSetValueArrayOfConstStringBecomesParam;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', ['TESTE'])
    .SetValue('NIVEL', [7]);

  // Antes: 'INSERT INTO USUARIOS (NOME, NIVEL) VALUES (TESTE, :p1)' com 1
  // parametro - a string ia verbatim e o PostgreSQL a leria como identificador.
  Assert.AreEqual('INSERT INTO USUARIOS (NOME, NIVEL) VALUES (:p1, :p2)',
    LQuery.AsString, False, 'string e numero, o MESMO slot, os DOIS parametrizados');
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('TESTE', String(LQuery.Params[0].Value));
  Assert.AreEqual(7, Integer(LQuery.Params[1].Value));
end;

procedure TTestCoreParams.TestValuesArrayOfConstStringBecomesParam;
var
  LQuery: IFluentSQL;
begin
  // Values e o mesmo caminho de SetValue (ambos chamam _InternalSet); esta
  // celula existe para que renomear ou redirecionar um dos dois nao passe.
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .Values('NOME', ['ANA']);

  Assert.AreEqual('INSERT INTO USUARIOS (NOME) VALUES (:p1)',
    LQuery.AsString, False, 'Values(array of const) tambem parametriza string');
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('ANA', String(LQuery.Params[0].Value));
end;

procedure TTestCoreParams.TestSetValueArrayOfConstHostileStringNeverReachesSqlText;
const
  HOSTILE = 'x''; DROP TABLE USERS; --';
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', [HOSTILE]);
  LSql := LQuery.AsString;

  // Antes: 'INSERT INTO USUARIOS (NOME) VALUES (x''; DROP TABLE USERS; --)'
  // com ZERO parametros - o payload era texto do SQL, nao dado.
  Assert.IsFalse(LSql.Contains(HOSTILE),
    'o valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.AreEqual('INSERT INTO USUARIOS (NOME) VALUES (:p1)', LSql, False);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(HOSTILE, String(LQuery.Params[0].Value),
    'o valor tem de chegar INTACTO na lista de parametros');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCoreParams);

end.
