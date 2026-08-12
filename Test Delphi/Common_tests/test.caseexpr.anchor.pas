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

      apagar o ATALHO  ->  33 nos 11 runners, 26 em Common, 11 da T13
      apagar o ANEXO   ->  41 nos 11 runners, 30 em Common, 13 da T13
      ramo Select      ->  37 nos 11 runners, 26 em Common
      ramo GroupBy     ->   2 nos 11 runners,  2 em Common
      ramo OrderBy     ->   2 nos 11 runners,  2 em Common

  E a particao das QUATRO PERGUNTAS da guarda, medida em Common, com o SITIO que
  cada numero mutou dito por extenso:

      (1) ha enunciado aberto?      corpo da guarda ............ 1 celula
      (2) a especie e secSelect?    corpo da guarda ............ 4 celulas
      (3) ha lista de colunas?      corpo da guarda ............ 7 celulas
      (4) acessoria tem projecao?   CORPO da guarda ............ 5 celulas
                                    so o sitio da COLUNA NOVA .. 4 celulas
                                    so o sitio da ANCORA ....... 1 celula

  Os dois sitios acima sao DISJUNTOS e somam o corpo: 4 + 1 = 5. Publicar so o
  "4" subdeclararia, porque deixaria de fora TestColunaCaindoDentroDoGroupBy-
  SemProjecaoRecusa, que e a unica que o sitio de ancora derruba - e foi ela que
  mostrou que a pergunta (4) tem de valer nos DOIS caminhos.

  E A (4) E CHAMADA DE TRES SITIOS, nao dois - o terceiro nao entra na tabela
  acima porque responde a OUTRO invariante, e a distincao importa para quem for
  mexer nele:

      FluentSQL.pas:505   ancora, sobrecarga String ......... derruba 1
      FluentSQL.pas:673   coluna nova ....................... derruba 4
      FluentSQL.pas:732   ancora, sobrecarga array of const . derruba 0

  O ZERO NAO E SITIO ESQUECIDO. O :732 existe pelo invariante de VAZAMENTO DE
  PARAMETRO (docstring em FluentSQL.pas:707-727) - a recusa tem de correr ANTES de SqlArrayOfConstToParameterizedSql
  gravar os :pN - e quem o expoe e a mutacao (3), nao a (4). Apagar aquele sitio
  achando que e redundante reabre o vazamento sem derrubar celula nenhuma da
  particao da (4).

  Os dois numeros de cada linha existem porque publicar so um confunde, e TODOS
  foram REMEDIDOS NO HEAD FINAL: numero de rodada anterior nao sobrevive a
  mudanca de codigo, e publicar um que nao reproduz e o mesmo defeito da citacao
  arquivo:linha que apodrece.

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
  O QUE ESTE ARQUIVO NAO COBRE, DITO DE PROPOSITO
  ============================================================================

  As celulas de recusa - DML, INSERT, secao sem projecao - rodam SO em
  dbnFirebird, e uma so vez cada. Nao e lacuna: elas medem GUARDA DE BUILDER,
  que corre antes de qualquer driver ser consultado e nao le dialeto nenhum. O
  que E por dialeto sao as celulas de TEXTO EMITIDO, e essas rodam nos seis
  ativos (TestIdiomaDaColunaCorrenteSobrevive e
  TestDepoisDeFromViraSearchedCaseEmColunaNova). Ampliar as de recusa para seis
  multiplicaria celulas sem medir nada novo.

  ============================================================================
  CATALOGADO E NAO CONSERTADO
  ============================================================================

  CADA ITEM ABAIXO FOI RODADO CONTRA O HEAD FINAL, e o texto e o que saiu.
  Nenhuma linha deste bloco sobrevive de rodada anterior - e a mesma regra dos
  numeros de mutacao, e ela existe porque uma versao anterior deste catalogo
  listava como ABERTO um defeito que a propria entrega ja tinha consertado, e
  que tinha celula VERDE 660 linhas abaixo provando o contrario.

  1. DOIS CaseExpr SEGUIDOS SOBRE A MESMA COLUNA - o segundo descarta o
     primeiro em silencio.

         .Select.Column('TIPO').CaseExpr.When('1')... e depois CaseExpr de novo
         -> SELECT (CASE TIPO WHEN 2 THEN 'SEGUNDO' END) FROM T

     PRE-EXISTENTE: medido identico na base e no HEAD. E consequencia direta do
     idioma "substitui a ultima coluna". Sem celula, sem conserto; se virar
     tarefa, e decisao do dono.

  2. "FROM" PENDURADO num Select sem relacao.

         .Select.Column('K') + CaseExpr, sem From
         -> SELECT (CASE K WHEN 1 THEN 1 END) FROM

     PRE-EXISTENTE e IDENTICO na base - a varredura cartesiana confirmou nas
     duas arvores. E defeito do serializador do FROM vazio, com porta propria, e
     nao da ancoragem. Esta entrega nao o cria nem o piora: ela apenas passou a
     alcanca-lo em cadeias que antes estouravam antes de chegar la.

  O QUE NAO ESTA MAIS AQUI, e por que: "UPDATE com lista de colunas aberta
  antes" era item deste catalogo ate a rodada anterior. Ele foi CONSERTADO por
  esta entrega - Update('T').Values('A','1').OrderBy('') + CaseExpr levanta
  EArgumentException, e TestUpdateComOrderByIntercaladoRecusa assere essa cadeia
  exata. Mante-lo seria descrever como aberto um buraco fechado.

  ⚠️ E ESSA CELULA E COBERTA EM DOBRO, o que importa saber antes de mexer nela:
  ela NAO cai sob nenhuma das quatro mutacoes individuais - medido, q1=q2=q3=q4
  devolvem zero para ela - e cai sob o PAR (2)+(4). Com a especie neutralizada,
  a pergunta da clausula acessoria responde no lugar, porque Select.Columns esta
  vazia; com a acessoria neutralizada, a especie responde. Duas guardas cobrem a
  mesma cadeia.
  Isto NAO enfraquece a retirada do item: o que sustenta a retirada e a celula
  estar VERDE, e ela esta. O que nao se pode dizer e que ela "morre sob a
  mutacao da guarda de especie" - essa frase estava aqui, foi INFERIDA de qual
  guarda dispara primeiro, e nao reproduz.

  A LICAO DE METODO, que vale para todo este arquivo: inferir qual guarda
  responde NAO e medir qual mutacao derruba a celula. Quando duas guardas cobrem
  a mesma cadeia, apagar uma nao derruba nada - a outra responde. Cobertura em
  dobro se parece com particao quando lida no codigo, e so a execucao as
  distingue. Toda frase de mutacao neste arquivo veio de um resultado com o nome
  da celula no conjunto de vermelhos daquele mutante.
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
    { ⭐ CASE em DML: as duas ordens, e a guarda do #167 aplicada aqui }
    [Test]
    procedure TestDeleteComGroupByIntercaladoRecusa;
    [Test]
    procedure TestDeleteComOrderByIntercaladoRecusa;
    [Test]
    procedure TestUpdateComGroupByIntercaladoRecusa;
    [Test]
    procedure TestUpdateComOrderByIntercaladoRecusa;
    [Test]
    procedure TestDeleteSemFromRecusa;
    { ⭐ o buraco que as DUAS metades da forma do #167 deixavam passar }
    [Test]
    procedure TestDeleteSemFromComGroupByRecusa;
    [Test]
    procedure TestDeleteSemFromComOrderByRecusa;
    [Test]
    procedure TestDeleteSemFromComWhereRecusa;
    [Test]
    procedure TestUpdateSemValuesComGroupByRecusa;
    [Test]
    procedure TestUpdateSemValuesComOrderByRecusa;
    [Test]
    procedure TestSelectDepoisDeDeleteLiberaOCaseExpr;
    [Test]
    procedure TestSelectDepoisDeUpdateLiberaOCaseExpr;
    [Test]
    procedure TestAMensagemDoDmlPrescreveOutraAcao;
    [Test]
    procedure TestDeleteRecusa;
    [Test]
    procedure TestQueryPuroRecusaEmVezDeAccessViolation;
    { ⭐ lista de colunas SEM enunciado aberto - e nao e so DELETE/UPDATE }
    { ⭐ as 3 familias que a VARREDURA CARTESIANA achou - nenhuma foi nomeada
      por revisao, todas sairam de "o texto emitido E um enunciado?" }
    [Test]
    procedure TestInsertComGroupByIntercaladoRecusa;
    [Test]
    procedure TestInsertComOrderByIntercaladoRecusa;
    [Test]
    procedure TestInsertSemIntoComGroupByRecusa;
    [Test]
    procedure TestInsertSemIntoComOrderByRecusa;
    [Test]
    procedure TestSelectSemProjecaoComGroupByRecusa;
    [Test]
    procedure TestSelectSemProjecaoComOrderByRecusa;
    [Test]
    procedure TestColunaCaindoDentroDoGroupBySemProjecaoRecusa;
    [Test]
    procedure TestGroupBySemEnunciadoAbertoRecusa;
    [Test]
    procedure TestSemEnunciadoAPrescricaoEhAbrirSelectENaoProjetar;
    [Test]
    procedure TestOrderBySemEnunciadoAbertoRecusa;
    [Test]
    procedure TestClearAllApagaAEspecieDoEnunciado;
    [Test]
    procedure TestClearAllFechaOEnunciado;
    [Test]
    procedure TestAMensagemDaRecusaNomeiaAChamadaEASaida;
    [Test]
    procedure TestNenhumaMensagemPrescreveAClausulaQueRoteiaParaODefeito;
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
  // O RAMO OrderBy DA VARREDURA. Antes desta celula existir, apagar a linha
  // "or (Assigned(FAST.OrderBy) and ...)" do predicado deixava a suite INTEIRA
  // verde nos 11 runners - e mesmo assim o ramo muda comportamento: sem ele o
  // CASE deixa de SUBSTITUIR a coluna do ORDER BY e passa a ACRESCENTAR outra -
  //
  //     com     ORDER BY (CASE B WHEN 1 THEN 1 END) ASC
  //     sem     ORDER BY B ASC, (CASE WHEN 1 THEN 1 END) ASC
  //
  // Os outros dois ramos ja tinham celula; este embarcou sem oraculo numa
  // entrega cuja tese e que lacuna de enumeracao mata rodada.
  //
  // NAO E A UNICA celula que o cobre, e a afirmacao de unicidade que estava
  // aqui nasceu vencida DENTRO do commit que criou a segunda:
  // TestIdentidadeDoNoSobreviveNasTresColecoes tambem cai quando o ramo e
  // apagado. Medido no HEAD final: apagar o ramo OrderBy derruba DUAS celulas,
  // esta e aquela. Afirmacao de unicidade tem de ser medida no HEAD, e nao
  // escrita de memoria - e a mesma disciplina da citacao arquivo:linha.
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

procedure TTestCaseExprAnchor.TestDeleteComGroupByIntercaladoRecusa;
begin
  // ⭐ A LICAO DA T30, APLICADA AQUI. GroupBy('') nao emite uma letra e mesmo
  // assim TROCA a secao ativa - e a secao do GROUP BY TEM lista de colunas.
  // Sem a marca DURAVEL, a coluna nova nasceria nela e sairia, calado:
  //     DELETE FROM T GROUP BY (CASE WHEN 1 THEN 1 END)
  // Na base saia "DELETE FROM (CASE T ...)", tambem invalido: aqui a mudanca e
  // invalido -> RECUSADO, sem regressao.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.From('T').GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteComOrderByIntercaladoRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.From('T').OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestUpdateComGroupByIntercaladoRecusa;
begin
  // NATUREZA DIFERENTE DA DO DELETE, e por isso celula propria: aqui a base
  // levantava EAccessViolation. Sem esta guarda a entrega trocaria CRASH por
  // "UPDATE T SET A = :p1 GROUP BY (CASE ...)" CALADO - loud->mute, a regressao
  // que esta tarefa existe para nao cometer, e que ela mesma introduziria.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Update('T').Values('A', '1').GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestUpdateComOrderByIntercaladoRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Update('T').Values('A', '1').OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteSemFromComGroupByRecusa;
begin
  // ⭐ O BURACO QUE CUSTOU UMA RODADA, e ele estava UM PASSO ADIANTE do que a
  // guarda anterior enumerava. Aquela lia duas coisas - a marca durável
  // (not FAST.Delete.IsEmpty) e a secao ativa - e AS DUAS SAO FALSAS aqui:
  //
  //   Delete SEM From    -> nao alimenta Delete.TableNames, nao ha marca
  //   GroupBy('')        -> ja tirou FActiveSection de secDelete
  //
  // O que saia era pior que nas cadeias COM From: nao sobrava DELETE nenhum,
  // so "GROUP BY (CASE WHEN 1 THEN 1 END)" - um fragmento que nem enunciado e.
  // E na base aquilo levantava EAccessViolation, entao seria crash -> texto
  // invalido CALADO: loud->mute introduzido pela entrega que veio mata-lo.
  //
  // A licao nao e "faltava uma terceira metade": e que a pergunta estava
  // errada. "O cursor esta num DELETE agora?" e transitorio; "este enunciado E
  // um DELETE?" e duravel, e e a que FStatementKind responde.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteSemFromComOrderByRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteSemFromComWhereRecusa;
begin
  // O Where nao abre lista de colunas, entao esta cadeia ja era recusada pela
  // guarda generica. A celula existe para que a ENUMERACAO fique fechada: as
  // tres clausulas que trocam a secao sem emitir letra estao cobertas.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.Where('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestUpdateSemValuesComGroupByRecusa;
begin
  // O gemeo no UPDATE. Update('T') SEM Values ja grava TableName, entao aqui a
  // marca antiga existia - mas a celula fica, porque e a especie que responde
  // agora e a enumeracao tem de valer para os dois verbos.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Update('T').GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestUpdateSemValuesComOrderByRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Update('T').OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestDeleteSemFromRecusa;
var
  LMsg: String;
begin
  // DELETE sem From: nao ha relacao alvo, e portanto nao havia marca a ler na
  // forma antiga desta guarda. Quem responde e a ESPECIE do enunciado.
  //
  // ⚠️ ASSERE A PRESCRICAO, e nao so a classe - e a diferenca foi MEDIDA. Com a
  // guarda de especie removida a chamada CONTINUA levantando
  // EArgumentException, porque cai na guarda GENERICA (no DELETE nao ha lista
  // de colunas). Um WillRaise pela classe daria VERDE sobre a guarda removida.
  // O que muda e QUAL mensagem o chamador recebe - e a generica prescreve
  // "chame depois de GroupBy(...)", que aqui ROTEIA PARA O BURACO.
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnFirebird).Delete.CaseExpr;
    end);
  Assert.Contains(LMsg, 'Select', False,
    'PRESCRICAO: quem esta num DELETE puro tem de ser mandado abrir um Select, ' +
    'e nao chamar GroupBy. Recebido: ' + LMsg);
  Assert.DoesNotContain(LMsg, 'GroupBy', False,
    'A prescricao generica roteia para Delete.GroupBy('''') + CaseExpr, que e ' +
    'exatamente a cadeia do defeito. Recebido: ' + LMsg);
end;

procedure TTestCaseExprAnchor.TestSelectDepoisDeDeleteLiberaOCaseExpr;
var
  LQuery: IFluentSQL;
begin
  // O QUE CONTINUA LIBERADO. Trocar para SELECT chama ClearAll, que limpa a
  // marca duravel - e o CaseExpr volta. Sem esta celula a guarda poderia virar
  // permanente por engano.
  LQuery := FluentSQL.Query(dbnFirebird).Delete.From('X');
  LQuery := LQuery.Select.Column('TIPO');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual('SELECT (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.From('T').AsString, False);
end;

procedure TTestCaseExprAnchor.TestSelectDepoisDeUpdateLiberaOCaseExpr;
var
  LQuery: IFluentSQL;
begin
  LQuery := FluentSQL.Query(dbnFirebird).Update('X').Values('A', '1');
  LQuery := LQuery.Select.Column('TIPO');
  LQuery.CaseExpr.When('1').IfThen('''A''');
  Assert.AreEqual('SELECT (CASE TIPO WHEN 1 THEN ''A'' END) FROM T',
    LQuery.From('T').AsString, False);
end;

procedure TTestCaseExprAnchor.TestAMensagemDoDmlPrescreveOutraAcao;
var
  LMsg: String;
begin
  // ⭐ ESTA CELULA FIXA A PRESCRICAO, E NAO O DIAGNOSTICO - e a distincao e a
  // regra da casa, nao estilo:
  //
  //   DIAGNOSTICO ... "em que estado voce esta". E o que o HUMANO le, e
  //     renomea-lo nao muda codigo nenhum. Vale a T35: nao vira celula.
  //   PRESCRICAO ... "que codigo escrever a seguir". E CONTRATO: ela determina
  //     a proxima linha que o chamador escreve, e prescricao errada produz SQL
  //     errado.
  //
  // Aqui as duas mensagens candidatas PRESCREVEM ACOES DIFERENTES, e por isso a
  // mensagem e load-bearing:
  //
  //   generica ... "chame depois de Select/Column(...), de GroupBy(...) ou de
  //                 OrderBy(...)"
  //   do DML .... "passe em Values/SetValue, ou na condicao do Where, ou abra
  //                 um Select"
  //
  // E a divergencia IMPORTA porque a prescricao generica ROTEIA PARA DENTRO DO
  // BURACO: quem esta num Delete puro e segue "chame depois de GroupBy(...)" ao
  // pe da letra escreve Delete.GroupBy('') + CaseExpr - que era exatamente a
  // cadeia que emitia fragmento invalido calado. Uma mensagem que manda o
  // chamador para o defeito nao e "menos especifica": e errada.
  LMsg := _MensagemDe(
    procedure
    begin
      FluentSQL.Query(dbnFirebird).Delete.From('T').CaseExpr;
    end);
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'Select', False,
    'PRESCRICAO: a saida de quem queria projetar e abrir um Select. ' +
    'Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'Values', False,
    'PRESCRICAO: a saida de quem queria GRAVAR o resultado do CASE. ' +
    'Recebido: ' + LMsg);
  Assert.DoesNotContain(LMsg, 'GroupBy', False,
    'A mensagem do DML NAO pode prescrever GroupBy - e a prescricao que ' +
    'roteia o chamador para a cadeia que emitia fragmento invalido calado. ' +
    'Recebido: ' + LMsg);
  Assert.DoesNotContain(LMsg, 'OrderBy', False,
    'Idem para OrderBy. Recebido: ' + LMsg);
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

procedure TTestCaseExprAnchor.TestInsertComGroupByIntercaladoRecusa;
begin
  // ⭐ O GEMEO DO INSERT, e ele existia porque a recusa do INSERT era feita por
  // COMPARACAO DE COLECAO (ASTColumns = Insert.Columns) - pergunta de SECAO. Uma
  // clausula intercalada bastava para ASTColumns deixar de ser a do INSERT, e o
  // CASE nascia na lista do GROUP BY:
  //     INSERT INTO T GROUP BY (CASE WHEN 1 THEN 1 END)
  // Na base: EAccessViolation. Crash -> texto invalido calado, nos 6 ativos.
  //
  // Agora a recusa e pela ESPECIE, que nenhuma clausula muda.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertComOrderByIntercaladoRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.Into('T').OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertSemIntoComGroupByRecusa;
begin
  // A segunda familia: sem Into nao ha nem relacao alvo, e saia so o fragmento
  // "GROUP BY (CASE ...)". E o INSERT sem Into que FALSIFICAVA o invariante do
  // FStatementAberto: ele e True - Insert ABRIU enunciado - e mesmo assim o
  // texto nao era enunciado nenhum.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestInsertSemIntoComOrderByRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Insert.OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestSelectSemProjecaoComGroupByRecusa;
begin
  // ⭐ A TERCEIRA FAMILIA, e a que NAO E DML - por isso nenhuma guarda de verbo
  // a pegaria. Select ABRE enunciado e a especie E secSelect, mas a projecao
  // esta vazia, e GROUP BY sozinho nao e enunciado:
  //     Select.GroupBy('') + CaseExpr -> GROUP BY (CASE WHEN 1 THEN 1 END)
  // GROUP BY e ORDER BY sao ADJUNTOS de uma projecao que tem de existir.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestSelectSemProjecaoComOrderByRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestColunaCaindoDentroDoGroupBySemProjecaoRecusa;
begin
  // O caso que sobreviveu a PRIMEIRA tentativa de fechar a familia 3, e que so
  // a varredura devolveu: aqui o Column('K') cai DENTRO de GroupBy.Columns -
  // porque ASTColumns ja e a do GROUP BY - e o cursor ANCORA nele. Nao ha
  // coluna nova a criar, entao uma guarda que so perguntasse no caminho da
  // coluna nova nao corria, e o fragmento saia igual.
  //
  // O que decide nao e "vou criar coluna?", e sim "em que lista o CASE fica?".
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Select.GroupBy('').Column('K');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestGroupBySemEnunciadoAbertoRecusa;
begin
  // ⭐ O DEFEITO ERA MAIOR QUE DELETE/UPDATE, e so apareceu quando se mediu o
  // CONTROLE de um enunciado que NUNCA foi DELETE:
  //
  //     Query(dbnFirebird).GroupBy('') + CaseExpr
  //     base: EAccessViolation   ->   sem esta guarda: "GROUP BY (CASE ...)"
  //
  // GroupBy('') abre lista de colunas SEM que exista enunciado, e a coluna nova
  // nascia nela: sai um fragmento que nem enunciado e. Crash -> texto invalido
  // CALADO, de novo, e desta vez fora do DML.
  //
  // A licao: ter LISTA onde encaixar nao e o mesmo que ter ENUNCIADO que
  // contenha. A guarda pergunta as duas coisas.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestSemEnunciadoAPrescricaoEhAbrirSelectENaoProjetar;
var
  LSemEnunciado, LSemProjecao: String;
begin
  // ⭐ A CELULA QUE TORNA A PERGUNTA "HA ENUNCIADO?" LOAD-BEARING, e o TIPO de
  // nao-redundancia dela precisa ficar escrito com precisao: e DE MENSAGEM, e
  // nao de aceitar/recusar. Medido: apagando aquela pergunta, a cadeia CONTINUA
  // sendo recusada, e com a MESMA classe - quem responde no lugar e a pergunta
  // (4), "a clausula acessoria tem projecao?". Nenhuma celula de WillRaise cai.
  // O que muda e a PRESCRICAO que o chamador recebe.
  //
  // O que muda e a PRESCRICAO, e as duas nao sao intercambiaveis:
  //
  //   sem enunciado ..... "Abra um Select antes"
  //   sem projecao ...... "chame Column(...) ou All"
  //
  // E seguir a prescricao ERRADA nao resolve, o que foi MEDIDO:
  //     Query(d).GroupBy('').Column('K') + CaseExpr  -> continua recusando
  // porque sem Select nao ha enunciado, e Column sozinho nao abre nenhum. Quem
  // recebesse "chame Column(...)" nesse estado tentaria, falharia de novo, e
  // nao teria como saber que o que falta e o Select.
  LSemEnunciado := _MensagemDe(
    procedure begin FluentSQL.Query(dbnFirebird).GroupBy('').CaseExpr end);
  LSemProjecao := _MensagemDe(
    procedure begin FluentSQL.Query(dbnFirebird).Select.GroupBy('').CaseExpr end);

  Assert.Contains(LSemEnunciado, 'Abra um Select', False,
    'Sem enunciado, a unica saida e abrir um Select. Recebido: ' + LSemEnunciado);
  Assert.Contains(LSemProjecao, 'Column(', False,
    'Com Select aberto e projecao vazia, a saida e projetar. Recebido: ' + LSemProjecao);
  Assert.AreNotEqual(LSemEnunciado, LSemProjecao,
    'Os dois estados exigem ACOES diferentes do chamador, entao as mensagens ' +
    'nao podem ser a mesma - e por isso a pergunta "ha enunciado?" nao e ' +
    'redundante com a de projecao vazia');
end;

procedure TTestCaseExprAnchor.TestOrderBySemEnunciadoAbertoRecusa;
begin
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).OrderBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException);
end;

procedure TTestCaseExprAnchor.TestClearAllApagaAEspecieDoEnunciado;
var
  LMsg: String;
begin
  // ClearAll apaga o enunciado, e apagar o enunciado apaga a ESPECIE dele. Sem
  // esta linha a marca de um DELETE que nao existe mais sobreviveria, e a
  // recusa MENTIRIA - diria "voce esta num DELETE" a quem acabou de limpar o
  // DELETE. E a celula assere a PRESCRICAO justamente porque as duas mensagens
  // candidatas prescrevem acoes diferentes: a do DML manda abrir um Select, a
  // generica manda abrir projecao. Aqui a certa e a generica.
  LMsg := _MensagemDe(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.From('T').ClearAll.GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end);
  Assert.DoesNotContain(LMsg, 'DELETE', False,
    'Depois de ClearAll nao ha DELETE nenhum: dizer que ha e MENTIR sobre o ' +
    'estado. Recebido: ' + LMsg);
end;

procedure TTestCaseExprAnchor.TestClearAllFechaOEnunciado;
begin
  // O GEMEO da celula acima, e SEPARADO dela de proposito: ClearAll limpa DUAS
  // coisas - a especie e o fato de haver enunciado - e cada uma tem a sua
  // mutacao. Junta-las numa celula so faria as duas mutacoes caírem no mesmo
  // nome, e a particao deixaria de ser disjunta.
  Assert.WillRaise(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnFirebird).Delete.From('T').ClearAll.GroupBy('');
      LQuery.CaseExpr.When('1').IfThen('1');
    end,
    EArgumentException,
    'ClearAll fecha o enunciado: depois dele nao ha onde o CASE morar, e emitir ' +
    'fragmento seria trocar o crash da base por texto invalido calado');
  // ALCANCE, dito para o nome da celula nao prometer mais do que ela mede: o
  // que esta travado e a forma de argumento VAZIO - GroupBy('')/OrderBy(''). Com
  // argumento, GroupBy('X') poe a coluna na lista e o caminho de ANCORA responde
  // antes; ali o comportamento e o MESMO da base, e nao e esta celula que o
  // fecha nem esta entrega que o cria.
end;

procedure TTestCaseExprAnchor.TestAMensagemDaRecusaNomeiaAChamadaEASaida;
var
  LMsg: String;
begin
  // O caso do DELETE tem guarda PROPRIA desde que o CASE em DML passou a ser
  // recusado, e mensagem propria - ver TestAMensagemDoDmlNomeiaAsTresSaidas.
  // Esta celula mede a mensagem GENERICA, e por isso usa um caminho que ainda
  // cai nela: cursor na relacao, secao WHERE.
  LMsg := _MensagemDe(
    procedure
    var LQuery: IFluentSQL;
    begin
      LQuery := FluentSQL.Query(dbnPostgreSQL).Select.Column('TIPO').From('T')
        .Where('ID').Equal(1);
      LQuery.CaseExpr;
    end);
  Assert.Contains(LMsg, 'CaseExpr', False,
    'A mensagem tem de nomear a chamada que falhou. Recebido: ' + LMsg);
  Assert.Contains(LMsg, 'Column', False,
    'A mensagem tem de dizer qual e a saida. Recebido: ' + LMsg);
end;

procedure TTestCaseExprAnchor.TestNenhumaMensagemPrescreveAClausulaQueRoteiaParaODefeito;
var
  LSemEnunciado, LDml, LSemProjecao, LAcessoria: String;
begin
  // ⭐ O ASSERT NEGATIVO APLICADO A TODAS AS QUATRO MENSAGENS, e nao so a do
  // DML. A prescricao e CONTRATO: determina o proximo codigo que o chamador
  // escreve. Uma versao anterior da mensagem generica dizia "chame depois de
  // Select/Column(...), de GroupBy(...) ou de OrderBy(...)" - e era JUSTAMENTE
  // essa a mensagem que Query(d).GroupBy('') + CaseExpr recebia. Quem a
  // seguisse ao pe da letra REFARIA a cadeia do defeito.
  //
  // Nenhuma das quatro pode prescrever GroupBy nem OrderBy, porque as quatro
  // sao emitidas em estados onde essas duas clausulas sao parte do problema.
  LSemEnunciado := _MensagemDe(
    procedure begin FluentSQL.Query(dbnFirebird).GroupBy('').CaseExpr end);
  LDml := _MensagemDe(
    procedure begin FluentSQL.Query(dbnFirebird).Delete.From('T').CaseExpr end);
  LSemProjecao := _MensagemDe(
    procedure
    var Q: IFluentSQL;
    begin
      Q := FluentSQL.Query(dbnFirebird).Select.Column('TIPO').From('T').Where('ID').Equal(1);
      Q.CaseExpr;
    end);
  LAcessoria := _MensagemDe(
    procedure begin FluentSQL.Query(dbnFirebird).Select.GroupBy('').CaseExpr end);

  Assert.DoesNotContain(LSemEnunciado, 'GroupBy(', False,
    'A mensagem de "sem enunciado" nao pode mandar chamar GroupBy - e a chamada ' +
    'que produz o proprio estado. Recebido: ' + LSemEnunciado);
  Assert.DoesNotContain(LSemEnunciado, 'OrderBy(', False,
    'Idem OrderBy. Recebido: ' + LSemEnunciado);
  Assert.DoesNotContain(LDml, 'GroupBy(', False,
    'Recebido: ' + LDml);
  Assert.DoesNotContain(LSemProjecao, 'GroupBy(', False,
    'Recebido: ' + LSemProjecao);
  Assert.DoesNotContain(LAcessoria, 'GroupBy(', False,
    'A mensagem da clausula acessoria nao pode prescrever a propria clausula ' +
    'acessoria. Recebido: ' + LAcessoria);
  // MEDIDO: esta celula cai sob as mutacoes (2), (3) e (4) - NAO sob a (1).
  // Sao tres, e nomeadas, porque cada uma dessas tres apaga a mensagem que uma
  // das quatro chamadas acima espera receber.
  // E o positivo: todas tem de apontar a projecao, que e a saida real.
  Assert.Contains(LSemEnunciado, 'Select', False, 'Recebido: ' + LSemEnunciado);
  Assert.Contains(LDml, 'Select', False, 'Recebido: ' + LDml);
  Assert.Contains(LSemProjecao, 'Column', False, 'Recebido: ' + LSemProjecao);
  Assert.Contains(LAcessoria, 'Column', False, 'Recebido: ' + LAcessoria);
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
