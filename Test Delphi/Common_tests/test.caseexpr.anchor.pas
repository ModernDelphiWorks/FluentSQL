{
  ------------------------------------------------------------------------------
  FluentSQL - ONDE O "CASE" SE ANCORA (T34)

  O QUE ESTE ARQUIVO TRAVA

  IFluentSQL.CaseExpr nao constroi so um CASE: ele tambem decide EM QUE NO da
  arvore o CASE vai morar. Ate esta tarefa, as duas decisoes eram tomadas sem
  perguntar NADA sobre o no corrente:

      LExpression := AExpression;
      if LExpression = '' then
        LExpression := FAST.ASTName.Name;      // o nome do no CORRENTE
      Result := TFluentSQLCriteriaCase.Create(Self, LExpression);
      if Assigned(FAST) then                   // guarda que protege o no errado
        FAST.ASTName.CaseExpr := Result.CaseExpr;

  FAST.ASTName e um CURSOR: aponta para o ultimo no tocado pela cadeia fluente.
  Depois de Column('TIPO') ele aponta para uma COLUNA; depois de From('T') ele
  aponta para a RELACAO; depois de InnerJoin('U') para a relacao do JOIN; e num
  Select sem coluna nenhuma ele e NIL.

  ============================================================================
  O IDIOMA QUE NAO PODE MORRER
  ============================================================================

  Com o cursor sobre uma COLUNA, as duas linhas acima formam um idioma
  DELIBERADO e publico - "transforme a ultima coluna num CASE simples sobre
  ela":

      .Select.Column('ID').Column('TIPO')
      .CaseExpr.When('1').IfThen('''A''').EndCase.Alias('R').From('T')
      -> SELECT ID, (CASE TIPO WHEN 1 THEN 'A' END) AS R FROM T

  Ele e a forma dominante da suite: apagar o atalho derruba 19 celulas verdes,
  entre elas a suite inteira do slot de valor (test.cases.value.pas) e o
  TestSelectColumnsCase dos cinco dialetos. E apagar o ANEXO derruba 25, porque
  sem ele o CASE nao chega ao SELECT: sai "SELECT ID, TIPO AS R FROM T", com o
  CASE inteiro perdido. Medido por mutacao, nao suposto.

  ============================================================================
  O DEFEITO: A PERGUNTA QUE FALTAVA
  ============================================================================

  O defeito nunca foi "o atalho existe". Foi "o atalho nao pergunta se o no
  corrente e uma COLUNA". Com o cursor em qualquer outro lugar, o mesmo codigo
  produz, em silencio:

    cursor na relacao do FROM
      SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' END)
      -> o FROM e SUBSTITUIDO. Nao e so SQL invalido: e PERDA DE ESTRUTURA.

    cursor na relacao do JOIN
      SELECT * FROM T INNER JOIN (CASE U WHEN 1 THEN 'A' END) ON
      -> a tabela juntada some, e o ON fica orfao.

    cursor NIL (Select sem coluna, ou nem Select)
      EAccessViolation lendo 00000000.
      E a guarda "if Assigned(FAST)" nao ajudava: FAST NUNCA e nil ali. Quem e
      nil e FAST.ASTName - desreferenciado DUAS LINHAS ACIMA da guarda, e
      tambem DENTRO dela. A guarda protegia o objeto errado.

  Por que a substituicao acontece: TFluentSQLName.Serialize (FluentSQL.Name.pas)
  PREFERE FCase a FName -

      if Assigned(FCase) then
        Result := '(' + FCase.Serialize + ')'
      else
        Result := FName;

  entao escrever CaseExpr num no de relacao apaga o texto daquele no.

  ============================================================================
  O ORACULO DE MOTOR REAL
  ============================================================================

  O texto que o HEAD emitia foi submetido VERBATIM, com massa de 3 linhas
  (PRODUCTS(ID, PRICE), duas com PRICE > 10). Transcricao em
  test.caseexpr.anchor.matrix.sql, ao lado deste arquivo.

      SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)

    PostgreSQL 16                     ERROR: syntax error at or near "CASE"
    MySQL 8.4                         ERROR 1064 (42000)
    SQL Server 2022 16.0.4265.3       Msg 156 Incorrect syntax near the keyword 'CASE'
    Firebird 5.0.4                    SQLSTATE 42000 / -104 / Token unknown - CASE
    Oracle AI 26ai Free 23.26.2.0.0   ORA-00907: missing right parenthesis
    DB2 v12.1.5.0                     SQL0104N ... SQLSTATE=42601
    InterBase                         NAO MEDIDO - nao ha imagem publica

  SEIS de sete RECUSAM. E a forma nova nao so passa no parser: ela DEVOLVE O
  DADO CERTO nos seis, 3 linhas, BARATO/CARO/CARO.

  ============================================================================
  A REGRA, EM UMA FRASE
  ============================================================================

      converter SQL invalido silencioso em SQL VALIDO quando o sentido e
      inequivoco, e em ERRO NOMEADO quando nao e. Nunca em descarte silencioso.

  Aplicada aos tres casos:

    no corrente E coluna ......... idioma preservado, byte a byte
    no corrente NAO e coluna,
      mas ha secao de colunas .... coluna NOVA, e o CASE vai nela como SEARCHED
                                   CASE. Um CASE num SELECT so tem um lugar
                                   sensato: a lista de projecao.
    nao ha secao de colunas ...... RECUSA nomeada. Ali o sentido NAO e
                                   inequivoco, e a alternativa (no-op)
                                   descartaria o CASE em silencio.
  ------------------------------------------------------------------------------
}

unit test.caseexpr.anchor;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  FluentSQL,
  FluentSQL.Interfaces;

type
  [TestFixture]
  TTestCaseExprAnchor = class
  private
    function _MensagemDe(const AProc: TProc): String;
  public
    { --- o idioma canonico: o CASE simples herda a COLUNA corrente ---------- }
    [Test]
    [TestCase('Firebird',   '0')]
    [TestCase('MSSQL',      '1')]
    [TestCase('MySQL',      '2')]
    [TestCase('Oracle',     '3')]
    [TestCase('PostgreSQL', '4')]
    [TestCase('SQLite',     '5')]
    procedure TestIdiomaDaColunaCorrenteSobrevive(const AIdx: Integer);

    { --- expressao vazia SEM coluna corrente vira SEARCHED CASE ------------- }
    [Test]
    [TestCase('Firebird',   '0')]
    [TestCase('MSSQL',      '1')]
    [TestCase('MySQL',      '2')]
    [TestCase('Oracle',     '3')]
    [TestCase('PostgreSQL', '4')]
    [TestCase('SQLite',     '5')]
    procedure TestDepoisDeFromViraSearchedCaseEmColunaNova(const AIdx: Integer);

    { --- o FROM deixa de ser substituido ------------------------------------ }
    [Test]
    procedure TestOFromNaoEMaisSubstituido;
    [Test]
    procedure TestSelectSemColunaNaoLevantaMaisAccessViolation;
    [Test]
    procedure TestCaseExprComExpressaoDepoisDeFromTambemAbreColunaNova;

    { --- ORDEM INTERCALADA: os seis pontos da cadeia ------------------------ }
    [Test]
    procedure TestOrdemIntercalada_DepoisDeSelectSemColuna;
    [Test]
    procedure TestOrdemIntercalada_DepoisDeColumn;
    [Test]
    procedure TestOrdemIntercalada_DepoisDeFrom;
    [Test]
    procedure TestOrdemIntercalada_DepoisDeWhere;
    [Test]
    procedure TestOrdemIntercalada_DepoisDeInnerJoin;
    [Test]
    procedure TestOrdemIntercalada_DepoisDeOrderBy;

    { --- a recusa nomeada --------------------------------------------------- }
    [Test]
    procedure TestSemSecaoDeColunasRecusaComEArgumentException;
    [Test]
    procedure TestAMensagemDaRecusaNomeiaAChamadaEASaida;
    [Test]
    procedure TestARecusaNaoDeixaParametroParaTras;

    { --- a terceira sobrecarga, que estourava SEMPRE ------------------------ }
    [Test]
    procedure TestSobrecargaDeExpressionNaoEstouraMais;
    [Test]
    procedure TestSobrecargaDeExpressionDepoisDeFromAbreColunaNova;
    [Test]
    procedure TestSobrecargaDeExpressionCarregaOsParametrosDaExpressao;

    { --- controles: o que NAO pode ter mudado ------------------------------- }
    [Test]
    procedure TestCaseSimplesComExpressaoExplicitaContinuaIgual;
    [Test]
    procedure TestArrayOfConstContinuaHerdandoAColunaCorrente;
  end;

implementation

const
  /// Os seis dialetos que os .dpr desta pasta ligam por {$DEFINE}. O texto do
  /// CASE e ANSI e igual nos seis - o que a celula por dialeto trava e que
  /// nenhum driver resolva a ancoragem de outro jeito.
  cDIALETOS: array[0..5] of TFluentSQLDriver =
    (dbnFirebird, dbnMSSQL, dbnMySQL, dbnOracle, dbnPostgreSQL, dbnSQLite);

{ helpers }

function TTestCaseExprAnchor._MensagemDe(const AProc: TProc): String;
begin
  Result := '';
  try
    AProc();
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

{ --- o idioma canonico ------------------------------------------------------ }

procedure TTestCaseExprAnchor.TestIdiomaDaColunaCorrenteSobrevive(const AIdx: Integer);
var
  LQuery: IFluentSQL;
begin
  // A CELULA MAIS IMPORTANTE DESTE ARQUIVO. Com o cursor sobre uma COLUNA,
  // CaseExpr sem argumento continua herdando o NOME dela como operando do CASE
  // simples, e o CASE continua substituindo aquela coluna na projecao. Sao as 19
  // celulas que a mutacao "apague o atalho" derruba - esta aqui as representa em
  // cada dialeto.
  LQuery := FluentSQL.Query(cDIALETOS[AIdx])
    .Select.Column('ID').Column('TIPO')
    .CaseExpr
      .When('1').IfThen('''A''')
    .EndCase.Alias('R').From('T');
  // False = nao ignore caixa.
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False,
    'CaseExpr sem argumento sobre uma COLUNA e idioma publico: ele herda o nome ' +
    'da coluna e substitui a coluna na projecao');
end;

{ --- searched CASE ---------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestDepoisDeFromViraSearchedCaseEmColunaNova(const AIdx: Integer);
var
  LQuery: IFluentSQL;
begin
  // Com o cursor na RELACAO, nao ha coluna a herdar: o CASE nasce SEARCHED e vai
  // para uma coluna NOVA, sem tocar no FROM.
  LQuery := FluentSQL.Query(cDIALETOS[AIdx]).Select.All.From('PRODUCTS');
  LQuery.CaseExpr
    .When('PRICE > 10').IfThen('''CARO''')
    .ElseIf('''BARATO''');
  Assert.AreEqual(
    'SELECT *, (CASE WHEN PRICE > 10 THEN ''CARO'' ELSE ''BARATO'' END) FROM PRODUCTS',
    LQuery.AsString, False,
    'Sem coluna corrente o CASE tem de nascer SEARCHED numa coluna nova, e nao ' +
    'adotar o nome da relacao como operando');
end;

procedure TTestCaseExprAnchor.TestOFromNaoEMaisSubstituido;
var
  LSql: String;
begin
  LSql := FluentSQL.Query(dbnPostgreSQL).Select.All.From('PRODUCTS')
    .CaseExpr.When('PRICE > 10').IfThen('''CARO''').EndCase.AsString;
  // O oraculo especifico da PERDA DE ESTRUTURA: o nome da relacao tem de
  // continuar no statement, e nao pode aparecer em posicao de operando de CASE.
  Assert.Contains(LSql, 'FROM PRODUCTS', False,
    'A relacao tem de continuar no FROM. Recebido: ' + LSql);
  Assert.DoesNotContain(LSql, 'CASE PRODUCTS', False,
    'O nome da relacao nao pode virar operando do CASE. Recebido: ' + LSql);
end;

procedure TTestCaseExprAnchor.TestSelectSemColunaNaoLevantaMaisAccessViolation;
var
  LQuery: IFluentSQL;
begin
  // O cursor e NIL aqui. Antes: EAccessViolation lendo 00000000, porque a
  // guarda "if Assigned(FAST)" perguntava pelo objeto errado.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select;
  LQuery.CaseExpr.When('1').IfThen('''A''').EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT (CASE WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestCaseExprComExpressaoDepoisDeFromTambemAbreColunaNova;
var
  LQuery: IFluentSQL;
begin
  // A ancoragem NAO depende de o argumento ser vazio: CaseExpr('TIPO') com o
  // cursor na relacao tambem tem de abrir coluna nova em vez de comer o FROM.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select.All.From('T');
  LQuery.CaseExpr('TIPO').When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT *, (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.AsString, False);
end;

{ --- ORDEM INTERCALADA ------------------------------------------------------ }

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeSelectSemColuna;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select;
  LQuery.CaseExpr.When('1').IfThen('''A''').EndCase.Alias('R').From('T');
  Assert.AreEqual('SELECT (CASE WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeColumn;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO');
  LQuery.CaseExpr.When('1').IfThen('''A''').EndCase.Alias('R').From('T');
  Assert.AreEqual('SELECT (CASE TIPO WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False,
    'Este e o unico dos seis pontos em que o atalho de heranca vale');
end;

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeFrom;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select.All.From('T');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual('SELECT *, (CASE WHEN 1 THEN ''A'' END) FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeWhere;
begin
  // Na secao WHERE nao ha secao de colunas: o sentido NAO e inequivoco e a
  // chamada e RECUSADA. Antes daqui saia "SELECT * FROM (CASE T WHEN 1 THEN 'A'
  // END) WHERE (ID = :p1)" - o FROM comido, calado.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.All.From('T').Where('ID').Equal(1);
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeInnerJoin;
begin
  // O SEXTO SINTOMA, achado pela ordem intercalada e por nada mais: com o cursor
  // na relacao do JOIN, o HEAD emitia
  //   SELECT * FROM T INNER JOIN (CASE U WHEN 1 THEN 'A' END) ON
  // - a tabela juntada some e o ON fica orfao. A secao JOIN tambem nao tem
  // secao de colunas, entao cai na mesma recusa.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.All.From('T').InnerJoin('U');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestOrdemIntercalada_DepoisDeOrderBy;
var
  LQuery: IFluentSQL;
begin
  // O ORDER BY TEM secao de colunas, e o cursor esta sobre a coluna que acabou
  // de ser adicionada - entao o atalho de heranca vale aqui tambem, e vale de
  // proposito: e a mesma regra, nao uma excecao.
  LQuery := FluentSQL.Query(dbnFirebird).Select.All.From('T').OrderBy('ID');
  LQuery.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual('SELECT * FROM T ORDER BY (CASE ID WHEN 1 THEN 1 END) ASC',
    LQuery.AsString, False);
end;

{ --- a recusa nomeada ------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestSemSecaoDeColunasRecusaComEArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL).Delete.From('T').CaseExpr;
    end,
    EArgumentException,
    'Fora de secao de colunas o CASE nao tem onde morar: recusar e a unica ' +
    'saida que nao descarta a chamada em silencio');
end;

procedure TTestCaseExprAnchor.TestAMensagemDaRecusaNomeiaAChamadaEASaida;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL).Delete.From('T').CaseExpr;
    end);
  // False = nao ignore caixa: a mensagem tem de citar os metodos como eles se
  // escrevem na API.
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada que falhou. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'Column', False,
    'A mensagem tem de dizer qual e a saida. Recebido: ' + LMsg);
end;

procedure TTestCaseExprAnchor.TestARecusaNaoDeixaParametroParaTras;
var
  LQuery: IFluentSQL;
begin
  // O invariante que test.cases.value.pas ja aplica a IfThen/ElseIf vale aqui:
  // um caminho de recusa nao pode deixar :pN orfao na colecao.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select.All.From('T').Where('ID').Equal(1);
  Assert.AreEqual(1, LQuery.Params.Count, 'pre-condicao');
  try
    LQuery.CaseExpr(['TIPO', '=', 9]);
  except
    on E: EArgumentException do ;
  end;
  Assert.AreEqual(1, LQuery.Params.Count,
    'A recusa nao pode ter deixado o :pN do array of const na colecao');
end;

{ --- a terceira sobrecarga -------------------------------------------------- }

procedure TTestCaseExprAnchor.TestSobrecargaDeExpressionNaoEstouraMais;
var
  LQuery: IFluentSQL;
begin
  // CaseExpr(IFluentSQLCriteriaExpression) era 100% inalcancavel: ela fazia
  // Create(Self, '') e logo Result.AndOpe(...), e AndOpe le FLastExpression, que
  // so e preenchido por When. Recem-criado, FLastExpression e NIL -> AV em
  // QUALQUER estado. Medido em tres estados distintos, AV nos tres.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID');
  LQuery.CaseExpr(LQuery.Expression('TIPO')).When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.From('T').AsString, False,
    'A sobrecarga de Expression tem de se comportar como as outras duas: o ' +
    'argumento e o OPERANDO do CASE simples');
end;

procedure TTestCaseExprAnchor.TestSobrecargaDeExpressionDepoisDeFromAbreColunaNova;
var
  LQuery: IFluentSQL;
begin
  // E ela obedece a MESMA regra de ancoragem das outras duas - o conserto e no
  // ponto unico, nao replicado em tres.
  LQuery := FluentSQL.Query(dbnFirebird).Select.All.From('T');
  LQuery.CaseExpr(LQuery.Expression('TIPO')).When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT *, (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestSobrecargaDeExpressionCarregaOsParametrosDaExpressao;
var
  LQuery: IFluentSQL;
begin
  // Expression(['...']) ja parametriza escalares. O que a sobrecarga faz e levar
  // o TEXTO ja parametrizado para o operando - o :pN tem de continuar unico e
  // referenciado no SQL.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID');
  LQuery.CaseExpr(LQuery.Expression(['TIPO', '*', 2])).When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT (CASE TIPO * :p1 WHEN 1 THEN ''A'' END) FROM T',
    LQuery.From('T').AsString, False);
  Assert.AreEqual(1, LQuery.Params.Count);
  Assert.AreEqual(2, Integer(LQuery.Params[0].Value));
end;

{ --- controles -------------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestCaseSimplesComExpressaoExplicitaContinuaIgual;
var
  LQuery: IFluentSQL;
begin
  // CASE simples legitimo NAO pode morrer: e a forma valida de
  // "CASE <coluna> WHEN <valor>", e ela nao passa pelo atalho.
  LQuery := FluentSQL.Query(dbnPostgreSQL)
    .Select.Column('ID')
    .CaseExpr('TIPO')
      .When('1').IfThen('''A''')
    .EndCase.Alias('R').From('T');
  Assert.AreEqual(
    'SELECT (CASE TIPO WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestArrayOfConstContinuaHerdandoAColunaCorrente;
var
  LQuery: IFluentSQL;
begin
  // A sobrecarga de array of const delega a de String: ela nao tem atalho
  // proprio, e por isso o conserto num ponto vale para as tres.
  LQuery := FluentSQL.Query(dbnFirebird)
    .Select.Column('ID').Column('TIPO_CLIENTE')
    .CaseExpr(['TIPO_CLIENTE', '*', 2])
      .When([0]).IfThen('''FISICA''')
    .EndCase.Alias('R').From('CLIENTES');
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO_CLIENTE * :p1 WHEN :p2 THEN ''FISICA'' END) AS R FROM CLIENTES',
    LQuery.AsString, False);
  Assert.AreEqual(2, LQuery.Params.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCaseExprAnchor);

end.
