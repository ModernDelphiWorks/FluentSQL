unit UTestFluentSQLFirebird;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Variants,
  FluentSQL,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestFluentSQLFirebird = class
  public
    [Test]
    procedure TestParams_Firebird_SelectWhereEqual;

    [Test]
    procedure TestParams_MySQL_SelectWhereEqual_UsesQuestionMark;

    [Test]
    procedure TestParams_PostgreSQL_SelectWhereEqual_UsesNamedParam;

    [Test]
    procedure TestMongoDB_SelectAll_NoWhere_GeneratesFindCommand;

    [Test]
    procedure TestMongoDB_SelectWhereEqual_GeneratesFilter;

    [Test]
    procedure TestParams_PostgreSQL_Insert_UsesNamedParams;

    [Test]
    procedure TestParams_Firebird_UpdateWhereEqual;

    [Test]
    procedure TestParams_Firebird_DeleteWhereEqual;

    [Test]
    procedure TestMongoDB_SelectProjectionAndSort_GeneratesMQL;

    [Test]
    procedure TestMongoDB_Insert_SerializesInsertOne;

    [Test]
    procedure TestMongoDB_Insert_SerializesInsertMany;

    [Test]
    procedure TestMongoDB_Update_SerializesUpdateMany;

    [Test]
    procedure TestMongoDB_Delete_SerializesDeleteMany;

    [Test]
    procedure TestMongoDB_SelectFragment_AlignsWithAsStringProjection;

    [Test]
    procedure TestMongoDB_WhereNot_GeneratesNor;

    [Test]
    procedure TestWithAlias_SerializesCTE;

    [Test]
    procedure TestOver_SerializesWindowFunction;

    [Test]
    procedure TestUnion_SerializesCompoundSelect;

    [Test]
    procedure TestIntersect_SerializesCompoundSelect;

    [Test]
    procedure TestParams_Firebird_Union_ParametersOnBothSides;

    [Test]
    procedure TestParams_Firebird_UnionAll_ParametersOnBothSides;

    [Test]
    procedure TestParams_Firebird_Intersect_ParametersOnBothSides;

    [Test]
    procedure TestParams_MySQL_Union_ParametersOnBothSides_UsesQuestionMarks;
  end;

implementation

procedure TTestFluentSQLFirebird.TestParams_Firebird_SelectWhereEqual;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnFirebird)
    .Select.All
    .From('CLIENTES')
    .Where('ATIVO').Equal(1);

  LSQL := LQuery.AsString;
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE (ATIVO = :p1)', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual('1', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_MySQL_SelectWhereEqual_UsesQuestionMark;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMySQL)
    .Select.All
    .From('CLIENTES')
    .Where('ATIVO').Equal(1);

  LSQL := LQuery.AsString;
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE (ATIVO = ?)', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual('1', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_PostgreSQL_SelectWhereEqual_UsesNamedParam;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnPostgreSQL)
    .Select.All
    .From('CLIENTES')
    .Where('ATIVO').Equal(1);

  LSQL := LQuery.AsString;
  Assert.AreEqual('SELECT * FROM CLIENTES WHERE (ATIVO = :p1)', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual('1', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestMongoDB_SelectAll_NoWhere_GeneratesFindCommand;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Select.All
    .From('CLIENTES');

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"find":"CLIENTES","filter":{},"projection":{}}', LSQL);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_SelectWhereEqual_GeneratesFilter;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Select.All
    .From('CLIENTES')
    .Where('ATIVO').Equal(1);

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"find":"CLIENTES","filter":{"ATIVO":1},"projection":{}}', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('p1', LQuery.Params[0].Name);
  Assert.AreEqual('1', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_PostgreSQL_Insert_UsesNamedParams;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnPostgreSQL)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ISAQUE')
    .SetValue('IDADE', 30);

  LSQL := LQuery.AsString;
  Assert.AreEqual('INSERT INTO USUARIOS (NOME, IDADE) VALUES (:p1, :p2)', LSQL);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('ISAQUE', VarToStr(LQuery.Params[0].Value));
  Assert.AreEqual('30', VarToStr(LQuery.Params[1].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_Firebird_UpdateWhereEqual;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnFirebird)
    .Update('USUARIOS')
    .SetValue('NOME', 'ISAQUE')
    .Where('ID').Equal(10);

  LSQL := LQuery.AsString;
  Assert.AreEqual('UPDATE USUARIOS SET NOME = :p1 WHERE (ID = :p2)', LSQL);
  Assert.AreEqual(2, LQuery.Params.Count);
  Assert.AreEqual('ISAQUE', VarToStr(LQuery.Params[0].Value));
  Assert.AreEqual('10', VarToStr(LQuery.Params[1].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_Firebird_DeleteWhereEqual;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnFirebird)
    .Delete
    .From('USUARIOS')
    .Where('ID').Equal(10);

  LSQL := LQuery.AsString;
  Assert.AreEqual('DELETE FROM USUARIOS WHERE (ID = :p1)', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('10', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestMongoDB_SelectProjectionAndSort_GeneratesMQL;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .OrderBy('NOME');

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"find":"CLIENTES","filter":{"ATIVO":1},"projection":{"ID":1,"NOME":1},"sort":{"NOME":1}}', LSQL);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_Insert_SerializesInsertOne;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ISAQUE')
    .SetValue('IDADE', 30);

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"insertOne":{"collection":"USUARIOS","document":{"NOME":"ISAQUE","IDADE":30}}}', LSQL);
  Assert.AreEqual(2, LQuery.Params.Count);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_Insert_SerializesInsertMany;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ANA')
    .SetValue('IDADE', 20)
    .AddRow
    .SetValue('NOME', 'BOB')
    .SetValue('IDADE', 21);

  LSQL := LQuery.AsString;
  Assert.AreEqual(
    '{"insertMany":{"collection":"USUARIOS","documents":[{"NOME":"ANA","IDADE":20},{"NOME":"BOB","IDADE":21}]}}',
    LSQL);
  Assert.AreEqual(4, LQuery.Params.Count);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_Update_SerializesUpdateMany;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Update('USUARIOS')
    .SetValue('NOME', 'ISAQUE')
    .Where('ID').Equal(10);

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"updateMany":{"collection":"USUARIOS","filter":{"ID":10},"update":{"$set":{"NOME":"ISAQUE"}}}}', LSQL);
  Assert.AreEqual(2, LQuery.Params.Count);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_Delete_SerializesDeleteMany;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Delete
    .From('USUARIOS')
    .Where('ID').Equal(10);

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"deleteMany":{"collection":"USUARIOS","filter":{"ID":10}}}', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_SelectFragment_AlignsWithAsStringProjection;
var
  LQuery: IFluentSQL;
  LFull: String;
  LFragment: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .OrderBy('NOME');

  LFull := LQuery.AsString;
  LFragment := (LQuery as TFluentSQL).MongoSelectFragment;
  Assert.AreEqual('{"collection":"CLIENTES","projection":{"ID":1,"NOME":1}}', LFragment);
  Assert.IsTrue(Pos('"find":"CLIENTES"', LFull) > 0);
  Assert.IsTrue(Pos('"projection":{"ID":1,"NOME":1}', LFull) > 0);
end;

procedure TTestFluentSQLFirebird.TestMongoDB_WhereNot_GeneratesNor;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnMongoDB)
    .Select
    .All
    .From('CLIENTES')
    .Where('NOT (ATIVO = 1)');

  LSQL := LQuery.AsString;
  Assert.AreEqual('{"find":"CLIENTES","filter":{"$nor":[{"ATIVO":1}]},"projection":{}}', LSQL);
end;

procedure TTestFluentSQLFirebird.TestWithAlias_SerializesCTE;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('PEDIDOS')
    .Where('STATUS').Equal('ABERTO')
    .WithAlias('PEDIDOS_ABERTOS');

  LSQL := LQuery.AsString;
  Assert.AreEqual('WITH PEDIDOS_ABERTOS AS (SELECT ID FROM PEDIDOS WHERE (STATUS = :p1)) SELECT * FROM PEDIDOS_ABERTOS', LSQL);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual('ABERTO', VarToStr(LQuery.Params[0].Value));
end;

procedure TTestFluentSQLFirebird.TestOver_SerializesWindowFunction;
var
  LQuery: IFluentSQL;
  LSQL: String;
begin
  LQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .Column('ID').Count.Over('', 'ID').Alias('TOTAL')
    .From('PEDIDOS');

  LSQL := LQuery.AsString;
  Assert.AreEqual('SELECT ID, COUNT(ID) OVER (ORDER BY ID) AS TOTAL FROM PEDIDOS', LSQL);
end;

procedure TTestFluentSQLFirebird.TestUnion_SerializesCompoundSelect;
var
  LBaseQuery: IFluentSQL;
  LUnionQuery: IFluentSQL;
  LSQL: String;
begin
  LBaseQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('CLIENTES_ATIVOS');

  LUnionQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('CLIENTES_INATIVOS');

  LSQL := LBaseQuery.Union(LUnionQuery).AsString;
  Assert.AreEqual('SELECT ID FROM CLIENTES_ATIVOS UNION SELECT ID FROM CLIENTES_INATIVOS', LSQL);
end;

procedure TTestFluentSQLFirebird.TestIntersect_SerializesCompoundSelect;
var
  LBaseQuery: IFluentSQL;
  LIntersectQuery: IFluentSQL;
  LSQL: String;
begin
  LBaseQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('CLIENTES_ATIVOS');

  LIntersectQuery := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('CLIENTES_PREFERENCIAIS');

  LSQL := LBaseQuery.Intersect(LIntersectQuery).AsString;
  Assert.AreEqual('SELECT ID FROM CLIENTES_ATIVOS INTERSECT SELECT ID FROM CLIENTES_PREFERENCIAIS', LSQL);
end;

procedure TTestFluentSQLFirebird.TestParams_Firebird_Union_ParametersOnBothSides;
var
  LBase, LRight, LCompound: IFluentSQL;
  LSQL: String;
begin
  LBase := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T1')
    .Where('X').Equal(1);
  LRight := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T2')
    .Where('Y').Equal(2);
  LCompound := LBase.Union(LRight);
  LSQL := LCompound.AsString;
  Assert.AreEqual(
    'SELECT ID FROM T1 WHERE (X = :p1) UNION SELECT ID FROM T2 WHERE (Y = :p2)',
    LSQL);
  Assert.AreEqual(2, LCompound.Params.Count);
  Assert.AreEqual('p1', LCompound.Params[0].Name);
  Assert.AreEqual('p2', LCompound.Params[1].Name);
  Assert.AreEqual('1', VarToStr(LCompound.Params[0].Value));
  Assert.AreEqual('2', VarToStr(LCompound.Params[1].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_Firebird_UnionAll_ParametersOnBothSides;
var
  LBase, LRight, LCompound: IFluentSQL;
  LSQL: String;
begin
  LBase := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T1')
    .Where('A').Equal(10);
  LRight := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T2')
    .Where('B').Equal(20);
  LCompound := LBase.UnionAll(LRight);
  LSQL := LCompound.AsString;
  Assert.AreEqual(
    'SELECT ID FROM T1 WHERE (A = :p1) UNION ALL SELECT ID FROM T2 WHERE (B = :p2)',
    LSQL);
  Assert.AreEqual(2, LCompound.Params.Count);
  Assert.AreEqual('10', VarToStr(LCompound.Params[0].Value));
  Assert.AreEqual('20', VarToStr(LCompound.Params[1].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_Firebird_Intersect_ParametersOnBothSides;
var
  LBase, LRight, LCompound: IFluentSQL;
  LSQL: String;
begin
  LBase := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T1')
    .Where('U').Equal(3);
  LRight := TCQ(dbnFirebird)
    .Select
    .Column('ID')
    .From('T2')
    .Where('V').Equal(4);
  LCompound := LBase.Intersect(LRight);
  LSQL := LCompound.AsString;
  Assert.AreEqual(
    'SELECT ID FROM T1 WHERE (U = :p1) INTERSECT SELECT ID FROM T2 WHERE (V = :p2)',
    LSQL);
  Assert.AreEqual(2, LCompound.Params.Count);
  Assert.AreEqual('3', VarToStr(LCompound.Params[0].Value));
  Assert.AreEqual('4', VarToStr(LCompound.Params[1].Value));
end;

procedure TTestFluentSQLFirebird.TestParams_MySQL_Union_ParametersOnBothSides_UsesQuestionMarks;
var
  LBase, LRight, LCompound: IFluentSQL;
  LSQL: String;
begin
  LBase := TCQ(dbnMySQL)
    .Select
    .Column('ID')
    .From('T1')
    .Where('X').Equal(1);
  LRight := TCQ(dbnMySQL)
    .Select
    .Column('ID')
    .From('T2')
    .Where('Y').Equal(2);
  LCompound := LBase.Union(LRight);
  LSQL := LCompound.AsString;
  Assert.AreEqual(
    'SELECT ID FROM T1 WHERE (X = ?) UNION SELECT ID FROM T2 WHERE (Y = ?)',
    LSQL);
  Assert.AreEqual(2, LCompound.Params.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFluentSQLFirebird);
end.
