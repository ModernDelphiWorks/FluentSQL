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
    /// <summary>
    ///   O ramo vtPointer de TUtils._StringVarRecAsParam (FluentSQL.Utils.pas)
    ///   e COMPARTILHADO pelo MERGE e por SetValue/Values. Ate esta celula, os
    ///   unicos testes que o cobriam eram de MERGE: apagar o ramo deixava a
    ///   suite verde para INSERT/UPDATE comum, que e o caminho muito mais
    ///   trafegado dos dois.
    /// </summary>
    [Test]
    procedure TestSetValueArrayOfConstNilRaisesInsteadOfWriting00000000;
    [Test]
    procedure TestValuesArrayOfConstNilRaisesInsteadOfWriting00000000;
    [Test]
    procedure TestUpdateSetValueArrayOfConstNilRaises;
    /// <summary>
    ///   OS IRMAOS DO nil. A guarda de vtPointer existia para impedir que um
    ///   "sem valor" virasse texto plausivel e fosse gravado como dado. Os
    ///   quatro abaixo sao a MESMA corrupcao pelo mesmo caminho, e nenhum era
    ///   pego. Medido nesta branch ANTES da guarda (dbnPostgreSQL,
    ///   .SetValue('X', [...]), saida do proprio AsString/Params):
    ///
    ///     [TObject.Create] -> VALUES (:p1)  p1 = 'TDummy'  (ClassName)
    ///     [TDummy]         -> VALUES (:p1)  p1 = 'TDummy'  (ClassName da classe)
    ///     [Unassigned]     -> VALUES (:p1)  p1 = ''        (string vazia)
    ///     [Null]           -> EVariantTypeCastError da RTL, "Could not convert
    ///                         variant of type (Null) into type (OleStr)"
    ///
    ///   Os tres primeiros nao levantavam nada: SQL bem-formado, dado errado,
    ///   nenhum motor reclama - exatamente o desfecho que a guarda de nil
    ///   fecha. O quarto ja falhava, mas com classe crua de RTL cuja mensagem
    ///   nao nomeia a chamada que a causou.
    /// </summary>
    [Test]
    procedure TestSetValueArrayOfConstObjectRaisesInsteadOfWritingClassName;
    [Test]
    procedure TestSetValueArrayOfConstClassRefRaisesInsteadOfWritingClassName;
    [Test]
    procedure TestSetValueArrayOfConstVariantNullRaisesNamedInsteadOfRtlCastError;
    [Test]
    procedure TestSetValueArrayOfConstVariantUnassignedRaisesInsteadOfWritingEmptyString;
    /// <summary>
    ///   O slot de valor comporta UM valor. Zero e mais de um emitiam SQL que
    ///   nenhum dos seis motores medidos aceita, e emitiam calados.
    /// </summary>
    [Test]
    procedure TestSetValueArrayOfConstEmptyRaisesInsteadOfEmittingValuesEmpty;
    [Test]
    procedure TestValuesArrayOfConstEmptyRaises;
    [Test]
    procedure TestUpdateSetValueArrayOfConstEmptyRaisesInsteadOfDanglingSet;
    [Test]
    procedure TestSetValueArrayOfConstTwoElementsRaisesInsteadOfJuxtaposedParams;
    [Test]
    procedure TestSetValueArrayOfConstRejectedCallLeavesNoHalfColumn;
  end;

implementation

uses
  SysUtils,
  Variants,
  FluentSQL.Interfaces,
  FluentSQL;

type
  /// <summary>
  ///   Classe de descarte, so para dar um ClassName reconhecivel ao TVarRec de
  ///   tipo vtObject / vtClass nas celulas de corrupcao silenciosa.
  /// </summary>
  TDescarte = class(TObject)
  end;

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
  esta em posicao de EXPRESSAO - o que vale para os 17 pontos de entrada
  publicos que passam por TUtils.SqlArrayOfConstToParameterizedSql, e nao so
  para a meia duzia que se costuma citar (Where, Column, Having, CaseExpr,
  Merge.On). Os 11 que essa lista curta omite incluem AndOpe, OrOpe,
  Expression, ForDialectOnly e os builders de IFluentSQLCriteriaCase e
  IFluentSQLCriteriaExpression; a lista completa com arquivo:linha esta na
  secao FRONTEIRA item (2) de test.setvalue.mssql.sql. Nesses 17
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

{ ---------------------------------------------------------------------------
  nil EM POSICAO DE VALOR - CAMINHO SetValue / Values

  A guarda esta em TUtils._StringVarRecAsParam, ramo vtPointer
  (FluentSQL.Utils.pas), e esse ramo e COMPARTILHADO por dois caminhos:

    SqlArrayOfConstToNameValuePairs  -> Merge.Update / Merge.Insert
    _ArrayOfConstToSql(..., True)    -> SetValue / Values

  Ate estas tres celulas, so o primeiro tinha oraculo. Medido por mutacao:
  trocar a condicao do ramo por `if False` derrubava 2 testes, ambos de MERGE,
  e NENHUM de SetValue - ou seja, a guarda do caminho mais trafegado dos dois
  (INSERT/UPDATE comum) estava sem cobertura nenhuma.

  Antes da guarda, o `nil` chegava como vtPointer, _VarRecToString o mapeava
  por IntToHex e a coluna recebia a STRING '00000000' - dado corrompido em
  silencio, sem erro em lugar nenhum.

  Que o nil devesse virar NULL em vez de levantar e decisao de convencao, e
  NAO foi tomada aqui. Estes testes travam o comportamento atual: LEVANTA.
  --------------------------------------------------------------------------- }

procedure TTestCoreParams.TestSetValueArrayOfConstNilRaisesInsteadOfWriting00000000;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('NOME', [nil]);
    end,
    EArgumentException,
    'nil em slot de valor de SetValue tem de levantar, nao virar ''00000000''');
end;

procedure TTestCoreParams.TestValuesArrayOfConstNilRaisesInsteadOfWriting00000000;
begin
  // Values e o irmao de SetValue no mesmo slot; celula propria para que
  // redirecionar so um dos dois nao passe despercebido.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .Values('NOME', [nil]);
    end,
    EArgumentException,
    'nil em slot de valor de Values tem de levantar');
end;

procedure TTestCoreParams.TestUpdateSetValueArrayOfConstNilRaises;
begin
  // O mesmo slot no UPDATE: _InternalSet aceita secInsert e secUpdate, e a
  // guarda tem de valer nos dois.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Update('USUARIOS')
        .SetValue('NOME', [nil]);
    end,
    EArgumentException,
    'nil em slot de valor de UPDATE tem de levantar');
end;

{ ---------------------------------------------------------------------------
  OS IRMAOS DO nil NO MESMO SLOT - objeto, referencia de classe, Null, Unassigned

  A guarda de vtPointer fechava UM dos cinco TVarRec que nao carregam dado
  algum e que _VarRecToString converte em texto plausivel. Os outros quatro
  seguiam passando, pelo MESMO _StringVarRecAsParam e portanto pelos MESMOS
  dois caminhos (SetValue/Values e Merge.Update/Insert).

  Medido nesta branch antes da guarda - nao e suposicao:

    .SetValue('X', [TDescarte.Create]) -> INSERT ... VALUES (:p1)  p1='TDescarte'
    .SetValue('X', [TDescarte])        -> INSERT ... VALUES (:p1)  p1='TDescarte'
    .SetValue('X', [Unassigned])       -> INSERT ... VALUES (:p1)  p1=''
    .SetValue('X', [Null])             -> EVariantTypeCastError (RTL)
    .Merge...Update(['NOME', obj])     -> SET [NOME] = :p1         p1='TDescarte'

  Os tres primeiros sao a corrupcao silenciosa que a guarda de nil existe para
  impedir, so que por outra porta: o SQL sai bem-formado e a coluna recebe
  texto que o chamador nunca escreveu. O quarto ja levantava, mas com classe da
  RTL, cuja mensagem nao diz qual chamada a causou.

  Como no nil, NAO se deu semantica de NULL a nenhum deles: isso e decisao de
  convencao e continua pendente. Estes testes travam o comportamento novo -
  LEVANTA EArgumentException, na linha que o consumidor escreveu.
  --------------------------------------------------------------------------- }

procedure TTestCoreParams.TestSetValueArrayOfConstObjectRaisesInsteadOfWritingClassName;
var
  LObj: TObject;
begin
  LObj := TDescarte.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        FluentSQL.Query(dbnPostgreSQL)
          .Insert
          .Into('USUARIOS')
          .SetValue('NOME', [LObj]);
      end,
      EArgumentException,
      'objeto em slot de valor virava a string ''TDescarte'' e ia gravado como dado');
  finally
    LObj.Free;
  end;
end;

procedure TTestCoreParams.TestSetValueArrayOfConstClassRefRaisesInsteadOfWritingClassName;
begin
  // vtClass e o irmao de vtObject em _VarRecToString: os dois saem por
  // ClassName. Celula propria para que fechar so um dos dois nao passe.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('NOME', [TDescarte]);
    end,
    EArgumentException,
    'referencia de classe em slot de valor virava a string ''TDescarte''');
end;

procedure TTestCoreParams.TestSetValueArrayOfConstVariantNullRaisesNamedInsteadOfRtlCastError;
begin
  // Antes: EVariantTypeCastError "Could not convert variant of type (Null)
  // into type (OleStr)" - levantava, mas com classe da RTL. O consumidor que
  // captura EArgumentException das outras guardas nao pegava esta.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('NOME', [Null]);
    end,
    EArgumentException,
    'Null em slot de valor tem de levantar a MESMA classe das outras guardas');
end;

procedure TTestCoreParams.TestSetValueArrayOfConstVariantUnassignedRaisesInsteadOfWritingEmptyString;
begin
  // Antes: VALUES (:p1) com p1 = '' - a coluna recebia string VAZIA em vez de
  // ficar intacta. E o caso mais silencioso dos cinco: nem excecao, nem lixo
  // visivel no dado.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('NOME', [Unassigned]);
    end,
    EArgumentException,
    'Unassigned em slot de valor virava string vazia, calado');
end;

{ ---------------------------------------------------------------------------
  CARDINALIDADE DO SLOT DE VALOR - zero e "dois ou mais"

  O array de SetValue/Values e o lado direito de "COLUNA = ...": UM valor.
  Fora disso o texto emitido nao e SQL de dialeto nenhum, e saia calado:

    .SetValue('X', [])                        -> INSERT INTO T (X) VALUES ()
    .Update('T').SetValue('X', [])            -> UPDATE T SET X =
    .SetValue('D', ['CURRENT','TIMESTAMP'])   -> VALUES (:p1 :p2)

  O terceiro e o mais traicoeiro dos tres: tem parametros de verdade e parece
  correto, mas os placeholders saem JUSTAPOSTOS, sem virgula - o joiner de
  _ArrayOfConstToSql separa com espaco, o que e certo em posicao de EXPRESSAO
  (os elementos formam um fragmento) e sem sentido em posicao de VALOR.

  Medido em execucao real, seis motores. Leia as duas formas separadamente,
  porque elas NAO tem o mesmo placar:

    LISTA VAZIA - zero dos seis aceitam:
      MSSQL 2022 16.0.4265.3  Msg 102 near ')' / near ';'
      PostgreSQL 16.14        syntax error at or near ")" / near ";"
      Oracle Free 23          ORA-00936 missing expression (as duas)
      Firebird 5.0.4          -104 Token unknown ')' / -104 Unexpected end
      MySQL 8.4.11            ERROR 1136 column count / ERROR 1064
      SQLite 3.53.4           Parse error near ")" / near ";"

    DOIS OU MAIS - cinco recusam por sintaxe, e o ORACLE NAO:
      MSSQL Msg 102 near '@p2'; PostgreSQL near "$2"; Firebird -104 Token
      unknown '?'; MySQL ERROR 1064 near '?)'; SQLite Parse error near "?".
      O Oracle le ":p1 :p2" como bind + variavel INDICADORA (:host:indicator),
      ou seja UM valor: com duas colunas da ORA-00947 (nao ORA-01745), e com
      UMA coluna a forma e ACEITA - "1 row created", grava :p1 e descarta :p2
      calado. Perda silenciosa de valor, pior que o erro de sintaxe dos outros.
      Nao escreva "zero aceitam" para esta forma.

  Controle: "VALUES (:p1, :p2)" com virgula executa em MSSQL, PostgreSQL,
  MySQL, SQLite e Oracle; no Firebird via isql ele passa a GRAMATICA e para no
  bind (SQLSTATE 07002, "No SQLDA for input values provided"), porque o isql
  nao liga parametro - fase diferente do -104 que a forma justaposta recebe.
  Saida bruta, versoes e docker exec em test.setvalue.mssql.sql.

  E a mesma regua ja aplicada ao MERGE: entre emitir SQL que nenhum motor
  executa e recusar a chamada na linha que a causou, recusa.
  --------------------------------------------------------------------------- }

procedure TTestCoreParams.TestSetValueArrayOfConstEmptyRaisesInsteadOfEmittingValuesEmpty;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('NOME', []);
    end,
    EArgumentException,
    'lista vazia emitia "INSERT INTO USUARIOS (NOME) VALUES ()", calada');
end;

procedure TTestCoreParams.TestValuesArrayOfConstEmptyRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .Values('NOME', []);
    end,
    EArgumentException,
    'Values e o irmao de SetValue no mesmo slot; a regua tem de ser a mesma');
end;

procedure TTestCoreParams.TestUpdateSetValueArrayOfConstEmptyRaisesInsteadOfDanglingSet;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Update('USUARIOS')
        .SetValue('NOME', []);
    end,
    EArgumentException,
    'no UPDATE a lista vazia emitia "UPDATE USUARIOS SET NOME =", calada');
end;

procedure TTestCoreParams.TestSetValueArrayOfConstTwoElementsRaisesInsteadOfJuxtaposedParams;
begin
  // Antes: 'INSERT INTO USUARIOS (DATA) VALUES (:p1 :p2)' com DOIS parametros -
  // placeholders justapostos, sem virgula. Invalido em todo dialeto, e com
  // Params.Count = 2 para disfarcar.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL)
        .Insert
        .Into('USUARIOS')
        .SetValue('DATA', ['CURRENT', 'TIMESTAMP']);
    end,
    EArgumentException,
    'dois elementos num slot de um valor emitiam "VALUES (:p1 :p2)"');
end;

procedure TTestCoreParams.TestSetValueArrayOfConstRejectedCallLeavesNoHalfColumn;
var
  LQuery: IFluentSQL;
  LSql: string;
  LRaised: Boolean;
begin
  // A guarda esta em TUtils.SqlArrayOfConstToParameterizedValue, ANTES de
  // _InternalSet - entao a coluna recusada nao chega a entrar na lista. Se a
  // ordem inverter, quem engolir a excecao passa a ver a coluna orfa no SQL.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Insert.Into('USUARIOS');
  LRaised := False;
  try
    LQuery.SetValue('DATA', []);
  except
    on E: EArgumentException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'a guarda tinha de ter levantado');

  LQuery.SetValue('NOME', ['ANA']);
  LSql := LQuery.AsString;
  Assert.AreEqual('INSERT INTO USUARIOS (NOME) VALUES (:p1)', LSql, False,
    'a coluna recusada nao pode sobrar no SQL. SQL=' + LSql);
  Assert.AreEqual(1, LQuery.Params.Count, 'e nao pode sobrar parametro orfao');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCoreParams);

end.
