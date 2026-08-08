unit test.merge.mssql;

interface

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestMergeMSSQL = class
  private
    /// <summary>
    ///   Devolve o valor do parametro de nome APlaceholder (':p1', ':p2', ...) ou
    ///   levanta se nao existir. Usado para provar que o valor do usuario foi
    ///   PARAR na lista de parametros, e nao no texto do SQL.
    /// </summary>
    function ParamValue(const AQuery: IFluentSQL; const APlaceholder: string): string;
    /// <summary>
    ///   Monta MERGE ... WHEN MATCHED THEN UPDATE(['NOME', AValue]) no dialeto MSSQL.
    /// </summary>
    function MergeUpdateWith(const AValue: string; out ASql: string): IFluentSQL;
    /// <summary>
    ///   Monta MERGE ... WHEN NOT MATCHED THEN INSERT(['NOME', AValue]) no dialeto MSSQL.
    /// </summary>
    function MergeInsertWith(const AValue: string; out ASql: string): IFluentSQL;
  public
    [Test]
    procedure TestMerge_BasicSyntax_GeneratesMSSQL;
    [Test]
    procedure TestMerge_WithArrayOfConstCondition_GeneratesExpected;
    [Test]
    procedure TestMerge_WithSourceQuery_GeneratesMSSQL;
    [Test]
    procedure TestMerge_UpdateWithValues_GeneratesMSSQL;
    [Test]
    procedure TestMerge_InsertWithValues_GeneratesMSSQL;

    { ---- Injecao: o valor do usuario NUNCA pode virar texto no SQL ---- }

    // Separador '|' (e nao a virgula padrao) porque varios payloads CONTEM virgula.
    [Test]
    [TestCase('AspaSimples',      'x'' OR ''1''=''1', '|')]
    [TestCase('DropTable',        'x''; DROP TABLE USERS; --', '|')]
    [TestCase('AspaDupla',        'x" OR "1"="1', '|')]
    [TestCase('PontoEVirgula',    'a; DELETE FROM USERS', '|')]
    [TestCase('TracoTraco',       'a -- comentario', '|')]
    [TestCase('ComentarioBloco',  'a /* bloco */ b', '|')]
    [TestCase('AspaDobrada',      'a'''' b', '|')]
    [TestCase('UnionSelect',      'a'' UNION SELECT NULL, NULL --', '|')]
    procedure TestMerge_UpdateHostileValue_NeverReachesSqlText(const AValue: string);

    [Test]
    [TestCase('AspaSimples',      'x'' OR ''1''=''1', '|')]
    [TestCase('DropTable',        'x''; DROP TABLE USERS; --', '|')]
    [TestCase('AspaDupla',        'x" OR "1"="1', '|')]
    [TestCase('PontoEVirgula',    'a; DELETE FROM USERS', '|')]
    [TestCase('TracoTraco',       'a -- comentario', '|')]
    [TestCase('ComentarioBloco',  'a /* bloco */ b', '|')]
    [TestCase('AspaDobrada',      'a'''' b', '|')]
    [TestCase('UnionSelect',      'a'' UNION SELECT NULL, NULL --', '|')]
    procedure TestMerge_InsertHostileValue_NeverReachesSqlText(const AValue: string);

    [Test]
    procedure TestMerge_LegitApostrophe_OBrien_RoundTripsIntact;
    [Test]
    procedure TestMerge_MixedTypes_AllValuesParameterizedInOrder;
    [Test]
    procedure TestMerge_ColumnNamesStayLiteral_OnlyValuesBecomeParams;

    { ---- Lista de pares malformada: falhar alto, nao emitir SQL quebrado ---- }

    [Test]
    procedure TestMerge_UpdateOddArray_RaisesInsteadOfEmittingBrokenSql;
    [Test]
    procedure TestMerge_InsertOddArray_RaisesInsteadOfEmittingBrokenSql;
    [Test]
    procedure TestMerge_EvenArray_DoesNotRaise;

    { ---- Lista VAZIA e forma SEM ARGUMENTOS: as duas emitiam SQL invalido ---- }

    [Test]
    procedure TestMerge_UpdateEmptyArray_RaisesInsteadOfEmittingUpdateSetSemicolon;
    [Test]
    procedure TestMerge_InsertEmptyArray_RaisesInsteadOfEmittingBareInsert;
    [Test]
    procedure TestMerge_UpdateNoArgs_RaisesInsteadOfEmittingUpdateSetSemicolon;
    [Test]
    procedure TestMerge_InsertNoArgs_RaisesInsteadOfEmittingBareInsert;
    /// <summary>
    ///   A guarda tem de levantar ANTES de registrar a clausula no MERGE: quem
    ///   engolir a excecao e chamar AsString nao pode encontrar meia clausula.
    /// </summary>
    [Test]
    procedure TestMerge_RaisedGuard_LeavesNoHalfClauseInSql;

    { ---- MERGE sem NENHUMA clausula WHEN: cabecalho solto, invalido ---- }

    [Test]
    procedure TestMerge_NoWhenClause_RaisesInsteadOfEmittingHeaderOnly;
    [Test]
    procedure TestMerge_OneWhenClause_DoesNotRaise;

    { ---- nil em posicao de valor: levantar, nunca gravar '00000000' ---- }

    [Test]
    procedure TestMerge_UpdateNilValue_RaisesInsteadOfCorruptingDataAsHexString;
    [Test]
    procedure TestMerge_InsertNilValue_RaisesInsteadOfCorruptingDataAsHexString;
  end;

implementation

uses
  System.SysUtils,
  System.Variants;

{ TTestMergeMSSQL }

function TTestMergeMSSQL.ParamValue(const AQuery: IFluentSQL;
  const APlaceholder: string): string;
var
  I: Integer;
  LName: string;
begin
  LName := APlaceholder;
  if LName.StartsWith(':') then
    LName := LName.Substring(1);
  for I := 0 to AQuery.Params.Count - 1 do
    if AQuery.Params[I].Name = LName then
      Exit(VarToStrDef(AQuery.Params[I].Value, ''));
  raise Exception.CreateFmt('Parametro "%s" nao existe na lista (Count=%d).',
    [LName, AQuery.Params.Count]);
end;

function TTestMergeMSSQL.MergeUpdateWith(const AValue: string;
  out ASql: string): IFluentSQL;
begin
  Result := FluentSQL.Query(dbnMSSQL);
  Result.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', AValue]);
  ASql := Result.AsString;
end;

function TTestMergeMSSQL.MergeInsertWith(const AValue: string;
  out ASql: string): IFluentSQL;
begin
  Result := FluentSQL.Query(dbnMSSQL);
  Result.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['NOME', AValue]);
  ASql := Result.AsString;
end;

procedure TTestMergeMSSQL.TestMerge_BasicSyntax_GeneratesMSSQL;
var
  LSql: string;
begin
  // ATENCAO - este teste passava sobre SQL INVALIDO. Usava ".Update" e ".Insert"
  // sem argumentos, forma que emite "UPDATE SET ;" e "INSERT;" - recusada por
  // todo motor com MERGE (ver test.merge.mssql.sql, secao LISTA VAZIA / FORMA
  // SEM ARGUMENTOS). Passava porque assertava com Pos() sobre PREFIXOS
  // ('WHEN MATCHED THEN UPDATE' casa em 'UPDATE SET ;' tao bem quanto em
  // 'UPDATE SET [X] = :p1'), e prefixo nao sabe distinguir SQL valido de
  // truncado. Foi essa fragilidade que deixou uma forma quebrada atravessar a
  // suite verde por completo.
  //
  // Agora: forma VALIDA, e uma unica assercao de SQL INTEIRO, case-sensitive
  // (Assert.AreEqual do DUnitX e case-insensitive por omissao; numa biblioteca
  // cujo produto e texto SQL isso deixa passar regressao de caixa).
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using('SOURCE', 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update(['VALOR', 10])
      .WhenNotMatched
        .Insert(['ID', 1])
    .AsString;

  Assert.AreEqual(
    'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)' +
    ' WHEN MATCHED THEN UPDATE SET [VALOR] = :p1' +
    ' WHEN NOT MATCHED THEN INSERT ([ID]) VALUES (:p2);',
    LSql, False, 'MERGE completo do MSSQL, texto exato');
end;

procedure TTestMergeMSSQL.TestMerge_WithArrayOfConstCondition_GeneratesExpected;
var
  LSql: string;
begin
  // Idem: usava ".Update" sem argumentos e assertava por Pos() so no trecho do ON.
  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET')
      .Using('SOURCE')
      .On(['ID =', 100])
      .WhenMatched
        .Update(['NOME', 'ana'])
    .AsString;

  // O 100 do On vira :p1 (escalar numerico em posicao de expressao ja
  // parametrizava) e o 'ana' do Update vira :p2, na ordem de construcao.
  Assert.AreEqual(
    'MERGE INTO [TARGET] USING [SOURCE] ON (ID = :p1)' +
    ' WHEN MATCHED THEN UPDATE SET [NOME] = :p2;',
    LSql, False, 'ON(array of const) + UPDATE, texto exato');
end;

procedure TTestMergeMSSQL.TestMerge_WithSourceQuery_GeneratesMSSQL;
var
  LSource: IFluentSQL;
  LSql: string;
begin
  // Idem: usava ".Update"/".Insert" sem argumentos e assertava por Pos() so no
  // trecho do USING.
  LSource := FluentSQL.Query(dbnMSSQL).Select('ID').Column('NOME').From('PESSOAS');

  LSql := FluentSQL.Query(dbnMSSQL)
    .Merge
      .Into('TARGET', 't')
      .Using(LSource, 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update(['VALOR', 10])
      .WhenNotMatched
        .Insert(['ID', 1])
    .AsString;

  Assert.AreEqual(
    'MERGE INTO [TARGET] AS [t] USING (SELECT ID, NOME FROM PESSOAS) AS [s]' +
    ' ON (t.ID = s.ID)' +
    ' WHEN MATCHED THEN UPDATE SET [VALOR] = :p1' +
    ' WHEN NOT MATCHED THEN INSERT ([ID]) VALUES (:p2);',
    LSql, False, 'USING (subconsulta), texto exato');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateWithValues_GeneratesMSSQL;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', 'TESTE', 'VALOR', 10.5]);
  LSql := LQuery.AsString;

  // SQL INTEIRO e case-sensitive, e nao Pos() sobre um trecho: foi asserção por
  // substring que deixou uma forma quebrada atravessar a suite verde inteira
  // (ver TestMerge_BasicSyntax_GeneratesMSSQL). Um trecho nao sabe o que sobra
  // fora dele.
  Assert.AreEqual(
    'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)' +
    ' WHEN MATCHED THEN UPDATE SET [NOME] = :p1, [VALOR] = :p2;',
    LSql, False, 'UPDATE SET com parametros, texto exato');
  Assert.AreEqual('TESTE', ParamValue(LQuery, ':p1'), False, 'p1 deve carregar o valor string');
  Assert.AreEqual(2, LQuery.Params.Count, 'string e numero, dois parametros');
end;

procedure TTestMergeMSSQL.TestMerge_InsertWithValues_GeneratesMSSQL;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 1, 'NOME', 'TESTE']);
  LSql := LQuery.AsString;

  // SQL INTEIRO e case-sensitive - ver o comentario em
  // TestMerge_UpdateWithValues_GeneratesMSSQL.
  Assert.AreEqual(
    'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)' +
    ' WHEN NOT MATCHED THEN INSERT ([ID], [NOME]) VALUES (:p1, :p2);',
    LSql, False, 'INSERT com parametros, texto exato');
  Assert.AreEqual('1', ParamValue(LQuery, ':p1'), False, 'p1 = 1');
  Assert.AreEqual('TESTE', ParamValue(LQuery, ':p2'), False, 'p2 = TESTE');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateHostileValue_NeverReachesSqlText(
  const AValue: string);
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := MergeUpdateWith(AValue, LSql);

  Assert.IsFalse(LSql.Contains(AValue),
    'O valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('[NOME] = :p1'),
    'A coluna deve receber placeholder, nao literal. SQL=' + LSql);
  Assert.AreEqual(1, LQuery.Params.Count, 'exatamente um parametro');
  Assert.AreEqual(AValue, ParamValue(LQuery, ':p1'), False,
    'o valor tem de chegar INTACTO na lista de parametros');
end;

procedure TTestMergeMSSQL.TestMerge_InsertHostileValue_NeverReachesSqlText(
  const AValue: string);
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := MergeInsertWith(AValue, LSql);

  Assert.IsFalse(LSql.Contains(AValue),
    'O valor hostil vazou para o texto do SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('VALUES (:p1)'),
    'O VALUES deve conter placeholder, nao literal. SQL=' + LSql);
  Assert.AreEqual(1, LQuery.Params.Count, 'exatamente um parametro');
  Assert.AreEqual(AValue, ParamValue(LQuery, ':p1'), False,
    'o valor tem de chegar INTACTO na lista de parametros');
end;

procedure TTestMergeMSSQL.TestMerge_LegitApostrophe_OBrien_RoundTripsIntact;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // Aspa legitima: tem que FUNCIONAR, nao ser mutilada por escape.
  LQuery := MergeInsertWith('O''Brien', LSql);

  Assert.IsFalse(LSql.Contains('O''Brien'),
    'Nome legitimo tambem nao pode virar texto no SQL. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('VALUES (:p1)'), 'placeholder esperado. SQL=' + LSql);
  Assert.AreEqual('O''Brien', ParamValue(LQuery, ':p1'), False,
    'O''Brien tem de sair do outro lado exatamente igual, sem aspa dobrada');
end;

procedure TTestMergeMSSQL.TestMerge_MixedTypes_AllValuesParameterizedInOrder;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 7, 'NOME', 'ANA', 'SALARIO', 1234.56, 'ATIVO', True]);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('([ID], [NOME], [SALARIO], [ATIVO]) VALUES (:p1, :p2, :p3, :p4)'),
    'todos os quatro valores viram placeholders, na ordem. SQL=' + LSql);
  Assert.AreEqual(4, LQuery.Params.Count, 'quatro parametros');
  Assert.AreEqual('7', ParamValue(LQuery, ':p1'), False);
  Assert.AreEqual('ANA', ParamValue(LQuery, ':p2'), False);
end;

procedure TTestMergeMSSQL.TestMerge_ColumnNamesStayLiteral_OnlyValuesBecomeParams;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // O nome da coluna e identificador: continua literal (delimitado), nunca parametro.
  // Se o nome virasse :pN o SQL seria sintaticamente invalido.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Update(['NOME', 'ANA', 'IDADE', 30]);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('UPDATE SET [NOME] = :p1, [IDADE] = :p2'),
    'nomes literais, valores parametrizados. SQL=' + LSql);
  Assert.AreEqual(2, LQuery.Params.Count, 'so os dois VALORES viram parametro');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateOddArray_RaisesInsteadOfEmittingBrokenSql;
begin
  // Antes: .Update(['NOME']) emitia "UPDATE SET [NOME] = ;", que o SQL Server 2022
  // recusa com Msg 102, Incorrect syntax near ';'. Falha longe da linha que a
  // causou. Agora falha na chamada.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenMatched
            .Update(['NOME']);
    end,
    EArgumentException,
    'Lista de pares com contagem impar tem de levantar, nao emitir SET [NOME] = ;');
end;

procedure TTestMergeMSSQL.TestMerge_InsertOddArray_RaisesInsteadOfEmittingBrokenSql;
begin
  // Antes: .Insert(['ID', 1, 'NOME']) emitia "VALUES (:p1, )", recusado com
  // Msg 102, Incorrect syntax near ')'.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenNotMatched
            .Insert(['ID', 1, 'NOME']);
    end,
    EArgumentException,
    'Lista de pares com contagem impar tem de levantar, nao emitir VALUES (:p1, )');
end;

procedure TTestMergeMSSQL.TestMerge_EvenArray_DoesNotRaise;
var
  LQuery: IFluentSQL;
  LSql: string;
begin
  // Contagem par e NAO VAZIA passa limpo. A versao anterior deste comentario
  // afirmava que a lista vazia tambem passava, "porque e par" - afirmacao falsa:
  // zero pares serializa como "UPDATE SET ;" / "INSERT;", que e o MESMO SQL
  // invalido que a guarda existe para impedir. A lista vazia tem teste proprio,
  // e ele afirma que ela LEVANTA.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenNotMatched
      .Insert(['ID', 1, 'NOME', 'ana']);
  LSql := LQuery.AsString;

  Assert.IsTrue(LSql.Contains('([ID], [NOME]) VALUES (:p1, :p2)'),
    'contagem par continua serializando normalmente. SQL=' + LSql);
  Assert.AreEqual(2, LQuery.Params.Count, 'dois valores, dois parametros');
end;

{ ---------------------------------------------------------------------------
  LISTA VAZIA e FORMA SEM ARGUMENTOS

  As duas produzem o MESMO texto - zero pares nome/valor -, e por isso o mesmo
  SQL invalido:

    .Update([])  e  .Update   ->  ... WHEN MATCHED THEN UPDATE SET ;
    .Insert([])  e  .Insert   ->  ... WHEN NOT MATCHED THEN INSERT;

  Medido em motor real: nenhum dos motores com MERGE aceita nenhuma das duas.
  Oraculo com container, versao e saida bruta em
  Test Delphi\Common_tests\test.merge.mssql.sql, secao
  LISTA VAZIA / FORMA SEM ARGUMENTOS.
  --------------------------------------------------------------------------- }

procedure TTestMergeMSSQL.TestMerge_UpdateEmptyArray_RaisesInsteadOfEmittingUpdateSetSemicolon;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenMatched
            .Update([]);
    end,
    EArgumentException,
    'Lista vazia tem de levantar, nao emitir "UPDATE SET ;"');
end;

procedure TTestMergeMSSQL.TestMerge_InsertEmptyArray_RaisesInsteadOfEmittingBareInsert;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenNotMatched
            .Insert([]);
    end,
    EArgumentException,
    'Lista vazia tem de levantar, nao emitir "INSERT;"');
end;

procedure TTestMergeMSSQL.TestMerge_UpdateNoArgs_RaisesInsteadOfEmittingUpdateSetSemicolon;
begin
  // Esta e a forma que o guia dml-merge.md ENSINAVA ate esta revisao, como
  // resposta a "quero copiar coluna a coluna da fonte". Ela nunca funcionou.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenMatched
            .Update;
    end,
    EArgumentException,
    '.Update sem argumentos tem de levantar, nao emitir "UPDATE SET ;"');
end;

procedure TTestMergeMSSQL.TestMerge_InsertNoArgs_RaisesInsteadOfEmittingBareInsert;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenNotMatched
            .Insert;
    end,
    EArgumentException,
    '.Insert sem argumentos tem de levantar, nao emitir "INSERT;"');
end;

procedure TTestMergeMSSQL.TestMerge_RaisedGuard_LeavesNoHalfClauseInSql;
var
  LQuery: IFluentSQL;
  LMerge: IFluentSQLMerge;
  LSql: string;
  LRaised: Boolean;
begin
  // A clausula e registrada no MERGE apenas em _Apply, DEPOIS da validacao
  // (FluentSQL.Merge.pas). Se voltar a ser registrada em WhenMatched, quem
  // engolir a excecao ve "WHEN MATCHED THEN" pela metade no texto emitido.
  //
  // A clausula VALIDA que vem depois nao e enfeite: sem ela o MERGE ficaria
  // com ZERO clausulas e o AsString levantaria a guarda de "MERGE sem WHEN"
  // (TestMerge_NoWhenClause_...), o que impediria esta celula de olhar o
  // TEXTO emitido - que e exatamente o que ela existe para olhar.
  //
  // A referencia LMerge tem de ser guardada: TFluentSQL.Merge (FluentSQL.pas:1257)
  // CONSTROI um MERGE novo a cada chamada e o instala no AST, entao um segundo
  // LQuery.Merge descartaria o primeiro em silencio.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LMerge := LQuery.Merge;
  LRaised := False;
  try
    LMerge
      .Into('TARGET', 't')
      .Using('SOURCE', 's')
      .On('t.ID = s.ID')
      .WhenMatched
        .Update(['NOME']);   // impar: levanta
  except
    on E: EArgumentException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'a guarda tinha de ter levantado');

  LMerge.WhenNotMatched.Insert(['ID', 1]);

  LSql := LQuery.AsString;
  Assert.IsFalse(LSql.Contains('WHEN MATCHED'),
    'a clausula recusada nao pode aparecer no SQL. SQL=' + LSql);
  Assert.IsFalse(LSql.Contains('UPDATE SET'),
    'nao pode sobrar UPDATE SET pela metade. SQL=' + LSql);
  Assert.IsTrue(LSql.Contains('WHEN NOT MATCHED THEN INSERT ([ID]) VALUES (:p1)'),
    'a clausula valida seguinte tem de aparecer inteira. SQL=' + LSql);
end;

{ ---------------------------------------------------------------------------
  MERGE SEM NENHUMA CLAUSULA WHEN

  Sai so o cabecalho - "MERGE INTO [T] AS [t] USING [S] AS [s] ON (...);" - que
  e a instrucao pela metade, e saia CALADO. Medido em execucao real, nenhum
  motor aceita:
    SQL Server 2022 16.0.4265.3  Msg 102, Incorrect syntax near ';'
    Oracle Free 23               ORA-02000: missing WHEN keyword
    PostgreSQL 16.14             syntax error at or near ";"
    Firebird 5.0.4               -104 Unexpected end of command
    MySQL 8.4.11 / SQLite 3.53.4 recusam a palavra MERGE, que nao existe la
  Controle: o MESMO texto com "WHEN MATCHED THEN UPDATE SET D = 'z'" e aceito
  por MSSQL, Oracle, PostgreSQL e Firebird - logo a recusa e da forma sem WHEN.
  --------------------------------------------------------------------------- }

procedure TTestMergeMSSQL.TestMerge_NoWhenClause_RaisesInsteadOfEmittingHeaderOnly;
begin
  // Antes: 'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID);'
  // com zero parametros, sem aviso nenhum.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .AsString;
    end,
    EArgumentException,
    'MERGE sem WHEN emitia so o cabecalho, que nenhum motor executa');
end;

procedure TTestMergeMSSQL.TestMerge_OneWhenClause_DoesNotRaise;
var
  LQuery: IFluentSQL;
begin
  // Controle da celula acima: UMA clausula basta, e o SQL sai inteiro. Sem
  // este controle, a guarda poderia estar recusando MERGE valido tambem.
  LQuery := FluentSQL.Query(dbnMSSQL);
  LQuery.Merge
    .Into('TARGET', 't')
    .Using('SOURCE', 's')
    .On('t.ID = s.ID')
    .WhenMatched
      .Delete;

  Assert.AreEqual(
    'MERGE INTO [TARGET] AS [t] USING [SOURCE] AS [s] ON (t.ID = s.ID)' +
    ' WHEN MATCHED THEN DELETE;',
    LQuery.AsString, False, 'uma clausula basta, texto exato');
end;

{ ---------------------------------------------------------------------------
  nil EM POSICAO DE VALOR

  O par nome/valor nao exprime NULL. Antes, o `nil` escrito no array chegava
  como vtPointer, _VarRecToString o mapeava por IntToHex e o valor gravado na
  coluna era a STRING '00000000' - dado corrompido, em silencio, sem erro em
  lugar nenhum. Entre gravar lixo calado e recusar a chamada, recusa.
  --------------------------------------------------------------------------- }

procedure TTestMergeMSSQL.TestMerge_UpdateNilValue_RaisesInsteadOfCorruptingDataAsHexString;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenMatched
            .Update(['NOME', nil]);
    end,
    EArgumentException,
    'nil em posicao de valor tem de levantar, nao gravar a string ''00000000''');
end;

procedure TTestMergeMSSQL.TestMerge_InsertNilValue_RaisesInsteadOfCorruptingDataAsHexString;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnMSSQL)
        .Merge
          .Into('TARGET', 't')
          .Using('SOURCE', 's')
          .On('t.ID = s.ID')
          .WhenNotMatched
            .Insert(['NOME', nil]);
    end,
    EArgumentException,
    'nil em posicao de valor tem de levantar, nao gravar a string ''00000000''');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMergeMSSQL);
end.
