/*
  ORACULO DE MOTOR REAL - T14 / CASE sem nenhum ramo WHEN
  ==============================================================================

  POR QUE ESTE ARQUIVO EXISTE

  TFluentSQLCriteriaCase.ElseIf nao tinha guarda nenhuma. Chamado antes de
  qualquer When, ele preenchia FCase.ElseExpression e a serializacao emitia,
  calada, um CASE sem WHEN:

      CASE ELSE <valor> END

  A guarda que passou a recusar essa chamada (FluentSQL.Cases.pas,
  TFluentSQLCriteriaCase._AssertHaveWhen) so se justifica se NENHUM motor
  aceitar essa forma - senao seria a biblioteca recusando SQL valido. Mediu-se.

  Este arquivo e uma MEDICAO, nao uma suite: nenhum teste DUnitX o executa. O
  teste que trava a regressao e test.builder.guards.pas.

  Motores e como subiram: identicos aos de test.cases.bind.matrix.sql, mesmos
  containers, mesma sessao. Versoes reconfirmadas la.

  ==============================================================================
  A FORMA MEDIDA
  ==============================================================================

  PostgreSQL 16.14 .......... RECUSA
    SELECT CASE ELSE 1 END AS r;
      ERROR:  syntax error at or near "ELSE"
      LINE 1: SELECT CASE ELSE 1 END AS r;
                          ^

  SQL Server 2022 (RTM-CU26) 16.0.4265.3 ... RECUSA
    SELECT CASE ELSE 1 END AS r;
      Msg 156, Level 15, State 1, Server 13613932577d, Line 1
      Incorrect syntax near the keyword 'ELSE'.

  Oracle AI Database 26ai Free Release 23.26.2.0.0 ... RECUSA
    SELECT CASE ELSE 1 END AS r FROM DUAL;
      SELECT CASE ELSE 1 END AS r FROM DUAL
                  *
      ERROR at line 1:
      ORA-00923: FROM keyword not found where expected

  Tres motores, tres recusas, tres mensagens distintas - e nenhuma delas aponta
  para a linha do ElseIf que causou o problema, porque o erro so aparece quando
  a string chega ao banco, possivelmente muito longe da chamada.

  Nao foram medidos MySQL, SQLite, Firebird e DB2 nesta forma: "CASE ELSE ...
  END" viola a gramatica do <case specification> do SQL-92, onde o
  <searched case> exige um ou mais <searched when clause> antes do
  <else clause> opcional. Tres motores de familias diferentes recusando por
  sintaxe ja fecha a pergunta que interessa - "existe motor que aceita?" - e
  nenhum dos tres precisou sequer chegar a executar. Se algum dos quatro nao
  medidos aceitasse, seria extensao propria dele, nao a intersecao que esta
  biblioteca exprime.

  ==============================================================================
  O IRMAO QUE JA TINHA GUARDA - E POR QUE ERA GUARDA DE MENTIRA
  ==============================================================================

  IfThen tinha Assert em vez de raise. Assert e removido pelo compilador com
  $C-, que e o default de release. A medicao aqui e do compilador, nao do banco,
  e esta transcrita em test.builder.guards.pas e no relatorio da tarefa:

    build com $C+ (default do dcc32), codigo anterior:
      Method raised [EAssertionFailed] was expecting [EArgumentException].
      TFluentSQLCriteriaCase.IfThen: Missing When (...\FluentSQL.Cases.pas, line 377)

      (o "line 377" e literal da saida e vem da arvore de MUTACAO, em que o
       Assert foi reintroduzido na posicao que o IfThen ocupa nesta branch. Na
       arvore anterior, 283512c, o mesmo Assert estava em FluentSQL.Cases.pas:340.
       O numero muda; a classe da excecao, que e o que o teste afirma, nao.)

    build com -$C- (release), codigo anterior:
      Method raised [EArgumentOutOfRangeException] was expecting [EArgumentException].
      List index out of bounds (-1).
      TList<FluentSQL.Interfaces.IFluentSQLCaseWhenThen> is empty

  A segunda e a que o consumidor veria em producao: nao nomeia IfThen, nao
  nomeia When, nao nomeia a unit do chamador.

  O mesmo para IFluentSQL.Desc, cuja guarda tambem era Assert:

    build com -$C- (release), codigo anterior:
      Method raised [EArgumentOutOfRangeException] was expecting [EArgumentException].
      List index out of bounds (-1).
      TList<FluentSQL.Interfaces.IFluentSQLName> is empty
*/
