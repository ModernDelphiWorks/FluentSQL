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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnMySQL)
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
  LQuery := CreateFluentSQL(dbnPostgreSQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnPostgreSQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnMySQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnMySQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnMySQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnMySQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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
  LQuery := CreateFluentSQL(dbnPostgreSQL)
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
  LQuery := CreateFluentSQL(dbnFirebird)
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

initialization
  TDUnitX.RegisterTestFixture(TTestCoreParams);

end.
