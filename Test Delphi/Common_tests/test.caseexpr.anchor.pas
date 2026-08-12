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

  ============================================================================
  ⭐ A LICAO QUE ESTE ARQUIVO EXISTE PARA NAO DEIXAR REPETIR
  ============================================================================

  A PRIMEIRA versao destes testes cobriu a ordem intercalada e MESMO ASSIM nao
  pegou o defeito principal. Porque intercalar secao NAO BASTA: o no em que o
  cursor cai depende da ORDEM DAS CHAMADAS, e duas cadeias com as MESMAS secoes
  em ordens diferentes sao CAMINHOS DISTINTOS.

      .Select.From('T').Column('TIPO').Where(...)    Column por ultimo
                                                     -> cursor na COLUNA
      .Select.Column('TIPO').From('T').Where(...)    From por ultimo
                                                     -> cursor na RELACAO

  As duas tem Select, Column, From e Where. Sao o mesmo conjunto de secoes. E
  produzem resultados OPOSTOS. A primeira versao escreveu so a segunda ordem, e
  por isso deu verde sobre um conserto que RECUSAVA a primeira - uma cadeia que
  emitia SQL valido nos sete.

  Por isso cada ponto da cadeia tem AQUI DUAS celulas, A e B, e nao uma.

  ============================================================================
  A PERGUNTA E DE NO, NAO DE SECAO
  ============================================================================

  A tentativa que falhou perguntava "o cursor esta na lista de colunas da secao
  CORRENTE?" - varrendo so FAST.ASTColumns. A diferenca em relacao a "este no e
  uma coluna?" e observavel, porque:

      FAST.ASTName    e DURAVEL   - atravessa a troca de secao
      FAST.ASTColumns e TROCADO   - _DefineSectionX o substitui POR BAIXO do
                                    cursor: vira nil no Where e no Having, e
                                    vira OUTRA lista no GroupBy e no OrderBy

  Com o cursor parado sobre uma coluna do SELECT, bastava entrar no WHERE para a
  pergunta de secao responder "nao e coluna" sobre o MESMO no. E no GroupBy era
  pior que recusa: o CASE ia para a clausula ERRADA e o SQL saia VALIDO E
  DIFERENTE -

      base    SELECT (CASE TIPO WHEN 1 THEN 'A' END) FROM T
      errado  SELECT TIPO FROM T GROUP BY (CASE WHEN 1 THEN 'A' END)

  - ou seja regressao de ruidoso para MUDO, que e o oposto do que esta casa faz.

  ============================================================================
  O IDIOMA QUE NAO PODE MORRER
  ============================================================================

      .Select.Column('ID').Column('TIPO')
      .CaseExpr.When('1').IfThen('''A''').EndCase.Alias('R').From('T')
      -> SELECT ID, (CASE TIPO WHEN 1 THEN 'A' END) AS R FROM T

  Medido por mutacao, e a base de contagem e SEMPRE a mesma - celulas que passam
  a falhar nos 11 RUNNERS, com -DDB2 -DINTERBASE:

      apagar o ATALHO  ->  31 celulas (24 em Common, 11 delas da T13)
      apagar o ANEXO   ->  39 celulas (28 em Common)

  Sem o anexo o CASE nao chega ao SELECT: sai "SELECT ID, TIPO AS R FROM T", com
  o CASE inteiro perdido. Nenhuma das duas linhas podia sair.

  ============================================================================
  O ORACULO DE MOTOR REAL
  ============================================================================

  Texto do HEAD anterior, submetido VERBATIM com massa de 3 linhas. Transcricao
  em test.caseexpr.anchor.matrix.sql.

      SELECT * FROM (CASE PRODUCTS WHEN PRICE > 10 THEN 'CARO' ELSE 'BARATO' END)

    PostgreSQL 16.14                  ERROR: syntax error at or near "CASE"
    MySQL 8.4.11                      ERROR 1064 (42000)
    SQL Server 2022 16.0.4265.3       Msg 156 Incorrect syntax near 'CASE'
    Firebird 5.0.4                    -104 / Token unknown - CASE
    Oracle AI 26ai Free 23.26.2.0.0   ORA-00907: missing right parenthesis
    DB2 v12.1.5.0                     SQL0104N ... SQLSTATE=42601
    SQLite 3.53.4                     Parse error near "CASE"
    InterBase                         NAO MEDIDO - nao ha imagem publica

  SUBMETIDOS 7: seis ATIVOS (com o SQLite) e um SOB DEFINE (o DB2, desligado no
  FluentSQL.inc). SETE de sete RECUSAM o texto antigo.

  E A FORMA NOVA NAO PASSA EM TODOS - a entrega nao afirma isso. Medido:

    projecao SEM estrela   "SELECT TIPO, (CASE ...) FROM PRODUCTS"
                           7 de 7 ACEITAM, dado certo
    projecao COM estrela   "SELECT *, (CASE ...) FROM PRODUCTS"
                           5 de 7. Firebird e Oracle RECUSAM, e a causa e a
                           VIRGULA depois da ESTRELA - defeito PRE-EXISTENTE do
                           All seguido de Column, fora do escopo desta tarefa
    ORDER BY               7 de 7 ACEITAM
    GROUP BY               1 de 7. Os outros seis recusam porque projetar TIPO
                           agrupando por outra expressao viola a regra de GROUP
                           BY - causa da CADEIA DO USUARIO, nao da ancoragem

  ============================================================================
  A REGRA
  ============================================================================

      converter SQL invalido silencioso em SQL VALIDO quando o sentido e
      inequivoco, e em ERRO NOMEADO quando nao e. Nunca em descarte silencioso.

  ============================================================================
  CATALOGADO E NAO CONSERTADO
  ============================================================================

  Dois CaseExpr seguidos sobre a MESMA coluna: o segundo descarta o primeiro em
  silencio. E PRE-EXISTENTE - medido identico na base e depois desta entrega - e
  e consequencia direta do idioma "substitui a ultima coluna". Nao ha celula
  aqui, e nao foi consertado: se virar tarefa, e decisao do dono.

  UPDATE COM LISTA DE COLUNAS ABERTA ANTES. A recusa do UPDATE vale quando
  nenhuma lista de colunas foi aberta - que e o caso de Update('T') direto. Mas

      Update('T').Values('A','1').OrderBy('') + CaseExpr
      -> UPDATE T SET A = :p1 ORDER BY (CASE WHEN 1 THEN 1 END) ASC

  emite CALADO, e na base levantava EAccessViolation: e loud->mute, a regressao
  que esta tarefa existe para nao cometer. A cadeia e absurda - OrderBy depois de
  Update - e o que falta e uma guarda de BUILDER que recuse OrderBy ali, que e
  outra tarefa e outra porta. Fica REGISTRADO e nao consertado, e a tabela do
  CHANGELOG diz que a linha do UPDATE so vale sem lista aberta.
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
    { --- o idioma canonico -------------------------------------------------- }
    [Test]
    [TestCase('Firebird',   '0')]
    [TestCase('MSSQL',      '1')]
    [TestCase('MySQL',      '2')]
    [TestCase('Oracle',     '3')]
    [TestCase('PostgreSQL', '4')]
    [TestCase('SQLite',     '5')]
    procedure TestIdiomaDaColunaCorrenteSobrevive(const AIdx: Integer);

    { --- searched CASE em coluna nova --------------------------------------- }
    [Test]
    [TestCase('Firebird',   '0')]
    [TestCase('MSSQL',      '1')]
    [TestCase('MySQL',      '2')]
    [TestCase('Oracle',     '3')]
    [TestCase('PostgreSQL', '4')]
    [TestCase('SQLite',     '5')]
    procedure TestDepoisDeFromViraSearchedCaseEmColunaNova(const AIdx: Integer);

    [Test]
    procedure TestProjecaoSemEstrelaEhAFormaAceitaPelosSete;
    [Test]
    procedure TestOFromNaoEMaisSubstituido;
    [Test]
    procedure TestSelectSemColunaNaoLevantaMaisAccessViolation;
    [Test]
    procedure TestCaseExprComExpressaoDepoisDeFromTambemAbreColunaNova;

    { --- ⭐ ORDEM INTERCALADA, NAS DUAS ORDENS ------------------------------ }
    { A = Column por ultimo -> cursor na COLUNA                                }
    [Test]
    procedure TestOrdemA_ColunaCorrente_Where;
    [Test]
    procedure TestOrdemA_ColunaCorrente_GroupBy;
    [Test]
    procedure TestOrdemA_ColunaCorrente_OrderBy;
    [Test]
    procedure TestOrdemA_ColunaCorrente_Having;
    [Test]
    procedure TestOrdemA_ColunaCorrente_InnerJoin;
    { o ramo OrderBy da varredura, que so ESTA celula cobre }
    [Test]
    procedure TestOrdemA_ColunaCorrente_ColunaDoOrderBy;
    { identidade do no nas TRES colecoes varridas }
    [Test]
    procedure TestIdentidadeDoNoSobreviveNasTresColecoes;
    { B = From por ultimo -> cursor na RELACAO                                 }
    [Test]
    procedure TestOrdemB_RelacaoCorrente_Where;
    [Test]
    procedure TestOrdemB_RelacaoCorrente_GroupBy;
    [Test]
    procedure TestOrdemB_RelacaoCorrente_OrderBy;
    [Test]
    procedure TestOrdemB_RelacaoCorrente_Having;
    [Test]
    procedure TestOrdemB_RelacaoCorrente_InnerJoin;

    { --- INSERT: lista de colunas que NAO aceita expressao ------------------ }
    [Test]
    procedure TestInsertSemColunaRecusa;
    [Test]
    procedure TestInsertComColunaRecusa;
    [Test]
    procedure TestInsertComArrayOfConstRecusaSemGravarParametro;
    [Test]
    procedure TestAMensagemDoInsertExplicaOQueAListaDoInsertE;
    { o contra-exemplo que a guarda DE SECAO deixava passar }
    [Test]
    procedure TestInsertComColunaEDepoisGroupByTambemRecusa;
    [Test]
    procedure TestInsertComColunaEDepoisOrderByTambemRecusa;

    { --- secoes que nao projetam -------------------------------------------- }
    [Test]
    procedure TestUpdateRecusa;
    [Test]
    procedure TestDeleteRecusa;
    [Test]
    procedure TestQueryPuroRecusaEmVezDeAccessViolation;
    [Test]
    procedure TestAMensagemDaRecusaNomeiaAChamadaEASaida;
    [Test]
    procedure TestARecusaNaoDeixaParametroParaTras;

    { --- a terceira sobrecarga: recusa NOMEADA ------------------------------ }
    [Test]
    procedure TestSobrecargaDeExpressionLevantaEmVezDeMentir;
    [Test]
    procedure TestAMensagemDaSobrecargaNomeiaOBloqueio;

    { --- controles ----------------------------------------------------------- }
    [Test]
    procedure TestCaseSimplesComExpressaoExplicitaContinuaIgual;
    [Test]
    procedure TestArrayOfConstContinuaHerdandoAColunaCorrente;
  end;

implementation

const
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
  // A CELULA MAIS IMPORTANTE DESTE ARQUIVO, em cada dialeto. Faz parte das 31
  // que a mutacao "apague o atalho" derruba nos 11 runners.
  LQuery := FluentSQL.Query(cDIALETOS[AIdx])
    .Select.Column('ID').Column('TIPO')
    .CaseExpr
      .When('1').IfThen('''A''')
    .EndCase.Alias('R').From('T');
  // False = nao ignore caixa.
  Assert.AreEqual(
    'SELECT ID, (CASE TIPO WHEN 1 THEN ''A'' END) AS R FROM T',
    LQuery.AsString, False,
    'CaseExpr sem argumento sobre uma COLUNA e idioma publico: herda o nome da ' +
    'coluna e substitui a coluna na projecao');
end;

{ --- searched CASE ---------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestDepoisDeFromViraSearchedCaseEmColunaNova(const AIdx: Integer);
var
  LQuery: IFluentSQL;
begin
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

procedure TTestCaseExprAnchor.TestProjecaoSemEstrelaEhAFormaAceitaPelosSete;
var
  LQuery: IFluentSQL;
begin
  // A celula acima usa .All, e o texto que sai dela carrega "SELECT *," - forma
  // que o Firebird e a Oracle RECUSAM, e nao por causa do CASE: o Firebird
  // aponta a VIRGULA (coluna 9) e a Oracle devolve ORA-00923. "SELECT *, <expr>"
  // ja saia da base por All seguido de Column, e e defeito PRE-EXISTENTE do All,
  // com porta propria e fora do escopo desta tarefa.
  //
  // ESTA celula e o teste LIMPO da ancoragem: projetando coluna nomeada, o texto
  // novo e aceito pelos SETE motores submetidos, com o dado certo. Ela existe
  // para que a entrega nao seja lida como "a forma nova passa em todos" - passa
  // nesta forma; na forma com estrela, dois recusam por outra causa.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('PRODUCTS');
  LQuery.CaseExpr
    .When('PRICE > 10').IfThen('''CARO''')
    .ElseIf('''BARATO''');
  Assert.AreEqual(
    'SELECT TIPO, (CASE WHEN PRICE > 10 THEN ''CARO'' ELSE ''BARATO'' END) FROM PRODUCTS',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOFromNaoEMaisSubstituido;
var
  LSql: String;
begin
  LSql := FluentSQL.Query(dbnPostgreSQL).Select.All.From('PRODUCTS')
    .CaseExpr.When('PRICE > 10').IfThen('''CARO''').EndCase.AsString;
  Assert.Contains(LSql, 'FROM PRODUCTS', False,
    'A relacao tem de continuar no FROM. Recebido: ' + LSql);
  Assert.DoesNotContain(LSql, 'CASE PRODUCTS', False,
    'O nome da relacao nao pode virar operando do CASE. Recebido: ' + LSql);
end;

procedure TTestCaseExprAnchor.TestSelectSemColunaNaoLevantaMaisAccessViolation;
var
  LQuery: IFluentSQL;
begin
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
  // A ancoragem NAO depende de o argumento ser vazio.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select.All.From('T');
  LQuery.CaseExpr('TIPO').When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT *, (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.AsString, False);
end;

{ --- ORDEM A: Column por ultimo, cursor na COLUNA --------------------------- }

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_Where;
var
  LQuery: IFluentSQL;
begin
  // ESTA e a celula que a primeira versao do conserto QUEBROU e que os testes de
  // entao nao tinham. O cursor esta na COLUNA, e por isso o idioma vale mesmo
  // com a secao corrente sendo o WHERE - onde ASTColumns e nil.
  LQuery := FluentSQL.Query(dbnFirebird).Select.From('T').Column('TIPO')
    .Where('ID').Equal(1);
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT (CASE TIPO WHEN 1 THEN ''A'' END) FROM T WHERE (ID = :p1)',
    LQuery.AsString, False,
    'O no e duravel: entrar no WHERE nao transforma a coluna do SELECT em ' +
    'outra coisa');
end;

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_GroupBy;
var
  LQuery: IFluentSQL;
begin
  // E a celula que pegaria o pior sintoma da tentativa anterior: o CASE ir para
  // o GROUP BY e o SQL sair VALIDO E DIFERENTE.
  LQuery := FluentSQL.Query(dbnFirebird).Select.From('T').Column('TIPO').GroupBy('');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.AsString, False,
    'Com o cursor na coluna do SELECT, o CASE fica no SELECT - nao migra para o ' +
    'GROUP BY so porque a secao corrente mudou');
end;

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_OrderBy;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select.From('T').Column('TIPO').OrderBy('');
  LQuery.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual(
    'SELECT (CASE TIPO WHEN 1 THEN 1 END) FROM T',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_Having;
var
  LQuery: IFluentSQL;
begin
  // Aqui o cursor esta na coluna do GROUP BY - que TAMBEM e coluna, e por isso o
  // idioma vale e o CASE substitui aquela coluna.
  LQuery := FluentSQL.Query(dbnFirebird).Select.From('T').Column('TIPO')
    .GroupBy('TIPO').Having('X');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT TIPO FROM T GROUP BY (CASE TIPO WHEN 1 THEN ''A'' END) HAVING X',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_InnerJoin;
begin
  // O JOIN e o unico ponto em que as duas ordens coincidem: _CreateJoin aponta o
  // cursor para a relacao juntada SEMPRE, seja qual for a ordem anterior. Antes
  // saia "... INNER JOIN (CASE U WHEN 1 THEN 'A' END) ON" - a tabela juntada
  // sumia e o ON ficava orfao.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.From('T').Column('TIPO')
        .InnerJoin('U');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestOrdemA_ColunaCorrente_ColunaDoOrderBy;
var
  LQuery: IFluentSQL;
begin
  // O RAMO OrderBy DA VARREDURA - e esta e a UNICA celula que o cobre. Apagar a
  // linha "or (Assigned(FAST.OrderBy) and ...)" do predicado deixava a suite
  // INTEIRA verde antes desta celula existir, nos 11 runners, e mesmo assim o
  // ramo muda comportamento: sem ele o CASE deixa de SUBSTITUIR a coluna do
  // ORDER BY e passa a ACRESCENTAR outra -
  //
  //     com     ORDER BY (CASE B WHEN 1 THEN 1 END) ASC
  //     sem     ORDER BY B ASC, (CASE WHEN 1 THEN 1 END) ASC
  //
  // Os outros dois ramos ja tinham celula; este embarcou sem oraculo numa
  // entrega cuja tese e que lacuna de enumeracao mata rodada.
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('A').From('T').OrderBy('B');
  LQuery.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual(
    'SELECT A FROM T ORDER BY (CASE B WHEN 1 THEN 1 END) ASC',
    LQuery.AsString, False,
    'Com o cursor sobre a coluna do ORDER BY, o CASE SUBSTITUI aquela coluna - ' +
    'nao acrescenta uma segunda');
end;

procedure TTestCaseExprAnchor.TestIdentidadeDoNoSobreviveNasTresColecoes;
var
  LSelect, LGroupBy, LOrderBy: IFluentSQL;
begin
  // ⭐ A MINA QUE ESTA CELULA VIGIA.
  //
  // _NoCorrenteEstaNaLista compara IFluentSQLNames[i] com FAST.ASTName por
  // IDENTIDADE de interface. Em Delphi, obter IFluentSQLName por UPCAST de uma
  // interface derivada - IFluentSQLOrderByColumn, por exemplo - devolve um
  // PONTEIRO DIFERENTE do mesmo objeto (medido: ...78C contra ...794). Hoje
  // nenhum dos produtores de FAST.ASTName usa esse caminho, entao a comparacao
  // acerta. Se algum dia um deles passar a usar, o predicado responde False em
  // silencio e o defeito que esta tarefa consertou VOLTA sem alarme nenhum.
  //
  // Nao ha como comparar ponteiros a partir da API publica, e nao e preciso: a
  // identidade e OBSERVAVEL pelo SQL. Se o no e reencontrado, o CASE SUBSTITUI
  // a coluna; se nao e, ele ACRESCENTA outra. As tres cadeias abaixo fazem o
  // ida-e-volta - poe o no na colecao, deixa o cursor nele, e exige que
  // CaseExpr o reencontre - uma por colecao varrida.
  LSelect := FluentSQL.Query(dbnFirebird).Select.Column('A').Column('B');
  LSelect.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual('SELECT A, (CASE B WHEN 1 THEN 1 END) FROM T',
    LSelect.From('T').AsString, False,
    'Select.Columns: o no tem de ser reencontrado, senao sairia "A, B, (CASE...)"');

  LGroupBy := FluentSQL.Query(dbnFirebird).Select.Column('A').From('T').GroupBy('B');
  LGroupBy.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual('SELECT A FROM T GROUP BY (CASE B WHEN 1 THEN 1 END)',
    LGroupBy.AsString, False,
    'GroupBy.Columns: idem, senao sairia "GROUP BY B, (CASE...)"');

  LOrderBy := FluentSQL.Query(dbnFirebird).Select.Column('A').From('T').OrderBy('B');
  LOrderBy.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual('SELECT A FROM T ORDER BY (CASE B WHEN 1 THEN 1 END) ASC',
    LOrderBy.AsString, False,
    'OrderBy.Columns: e a colecao de MAIOR risco, porque e a unica cujos itens ' +
    'sao IFluentSQLOrderByColumn - a derivada de onde o upcast viria');
end;

{ --- ORDEM B: From por ultimo, cursor na RELACAO ---------------------------- }

procedure TTestCaseExprAnchor.TestOrdemB_RelacaoCorrente_Where;
begin
  // Mesmas secoes da ordem A, ordem trocada: agora o cursor esta na RELACAO e
  // nao ha lista de colunas na secao corrente. Antes saia
  // "SELECT TIPO FROM (CASE T WHEN 1 THEN 'A' END) WHERE (ID = :p1)".
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T')
        .Where('ID').Equal(1);
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestOrdemB_RelacaoCorrente_GroupBy;
var
  LQuery: IFluentSQL;
begin
  // Cursor na relacao, mas a secao corrente TEM lista de colunas: o CASE nasce
  // searched numa coluna nova DO GROUP BY - que e onde quem chamou GroupBy o
  // quer. E a medicao que derrubou a hipotese "a coluna nova vai sempre para a
  // projecao".
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T').GroupBy('');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual(
    'SELECT TIPO FROM T GROUP BY (CASE WHEN 1 THEN ''A'' END)',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemB_RelacaoCorrente_OrderBy;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T').OrderBy('');
  LQuery.CaseExpr.When('1').IfThen('1');
  Assert.AreEqual(
    'SELECT TIPO FROM T ORDER BY (CASE WHEN 1 THEN 1 END) ASC',
    LQuery.AsString, False);
end;

procedure TTestCaseExprAnchor.TestOrdemB_RelacaoCorrente_Having;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T')
        .Having('X');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestOrdemB_RelacaoCorrente_InnerJoin;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T')
        .InnerJoin('U');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

{ --- INSERT ----------------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestInsertSemColunaRecusa;
begin
  // O INSERT TEM lista de colunas, e e justamente por isso que precisa de recusa
  // PROPRIA: sem ela o CASE seria ancorado ali como em qualquer outra lista.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertComColunaRecusa;
begin
  // ESTA metade NAO e regressao desta entrega: na base ja saia, calado,
  // "INSERT INTO T ( (CASE A WHEN 1 THEN 'X' END) )".
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').Column('A');
      LQuery.CaseExpr.When('1').IfThen('''X''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertComArrayOfConstRecusaSemGravarParametro;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').Column('A');
  try
    LQuery.CaseExpr(['A', '=', 1]);
  except
    on E: EArgumentException do ;
  end;
  Assert.AreEqual(0, LQuery.Params.Count,
    'A recusa do INSERT corre ANTES de o array virar :pN - senao o parametro ' +
    'ficaria na colecao sem nada no SQL que o citasse');
end;

procedure TTestCaseExprAnchor.TestInsertComColunaEDepoisGroupByTambemRecusa;
begin
  // ⭐ O CONTRA-EXEMPLO. Houve uma versao desta entrega em que a recusa do
  // INSERT era escrita como FAST.ASTColumns = FAST.Insert.Columns - pergunta de
  // SECAO, o mesmo padrao que ja tinha derrubado a primeira rodada, agora dentro
  // do conserto dela. Ela deixava passar, calado:
  //
  //     INSERT INTO T ( A ) GROUP BY (CASE WHEN 1 THEN 1 END)
  //
  // porque o cursor estava numa coluna do INSERT enquanto a lista CORRENTE ja
  // era a do GROUP BY. A recusa e um ramo da varredura de NO justamente para
  // que a troca de secao nao a contorne.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').Column('A').GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertComColunaEDepoisOrderByTambemRecusa;
begin
  // O gemeo do anterior pela outra lista que _DefineSectionX troca.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').Column('A').OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestAMensagemDoInsertExplicaOQueAListaDoInsertE;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnFirebird).Insert.Into('T').CaseExpr;
    end);
  Assert.Contains(LMsg, 'INSERT', False,
    'A mensagem tem de dizer onde a chamada caiu. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada. Recebido: ' + LMsg);
end;

{ --- secoes que nao projetam ------------------------------------------------ }

procedure TTestCaseExprAnchor.TestUpdateRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Update('T');
      LQuery.CaseExpr.When('1').IfThen('''A''');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteRecusa;
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

procedure TTestCaseExprAnchor.TestQueryPuroRecusaEmVezDeAccessViolation;
begin
  // A guarda ANTERIOR formatava FAST.ASTSection.Name DENTRO do raise, e ali
  // ASTSection e nil: ela estourava com EAccessViolation de dentro de si mesma -
  // a mesma figura de "guarda no objeto errado" que esta tarefa corrige.
  Assert.WillRaise(
    procedure
    begin
      FluentSQL.Query(dbnPostgreSQL).CaseExpr;
    end,
    EArgumentException,
    'Num enunciado que nao abriu secao nenhuma a recusa tem de ser nomeada, e ' +
    'nao um EAccessViolation vindo de dentro da propria guarda');
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
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada que falhou. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'Column', False,
    'A mensagem tem de dizer qual e a saida. Recebido: ' + LMsg);
end;

procedure TTestCaseExprAnchor.TestARecusaNaoDeixaParametroParaTras;
var
  LQuery: IFluentSQL;
begin
  // O invariante que esta funcao sustenta, e nada alem dele: nenhum caminho de
  // recusa DESTA funcao grava parametro. O :p1 do Equal(1) e anterior a chamada
  // e continua contando.
  LQuery := FluentSQL.Query(dbnPostgreSQL).Select.Column('TIPO').From('T')
    .Where('ID').Equal(1);
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

procedure TTestCaseExprAnchor.TestSobrecargaDeExpressionLevantaEmVezDeMentir;
begin
  // Ela era PUBLICA e 100% inalcancavel - EAccessViolation em qualquer estado.
  // Nao foi "consertada para funcionar" porque a saida obvia (serializar e
  // delegar) MENTE quando a expressao vem de outro enunciado: medido, o SQL sai
  // citando :p1 com Params.Count = 0 no dono e o valor preso na colecao alheia.
  // Nao ha como distinguir os dois casos em runtime.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID');
      LQuery.CaseExpr(LQuery.Expression('TIPO'));
    end,
    EArgumentException,
    'Entre estourar, mentir em silencio e recusar dizendo o porque, a recusa e ' +
    'a unica honesta enquanto a fusao de colecoes de parametro nao existir');
end;

procedure TTestCaseExprAnchor.TestAMensagemDaSobrecargaNomeiaOBloqueio;
var
  LMsg: String;
begin
  LMsg := _MensagemDe(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.Column('ID');
      LQuery.CaseExpr(LQuery.Expression('TIPO'));
    end);
  // A mensagem tem de NOMEAR o bloqueio, para ninguem a ler como capricho.
  Assert.Contains(LMsg, 'parametro', False,
    'A mensagem tem de dizer que o bloqueio e de parametros. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada. Recebido: ' + LMsg);
end;

{ --- controles -------------------------------------------------------------- }

procedure TTestCaseExprAnchor.TestCaseSimplesComExpressaoExplicitaContinuaIgual;
var
  LQuery: IFluentSQL;
begin
  // CASE simples legitimo NAO pode morrer.
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
