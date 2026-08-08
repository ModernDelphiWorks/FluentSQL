/*
  ------------------------------------------------------------------------------
  ORACULO DE PAGINACAO - MONGODB  (T10)

  MOTOR MEDIDO
    MongoDB 7.0.39 (imagem mongo:7), via mongosh

  COMO REPETIR
    docker run -d --name t10mongo -p 27117:27017 mongo:7
    docker cp test.pagination.mongodb.js t10mongo:/tmp/p.js
    docker exec t10mongo mongosh --quiet /tmp/p.js

  POR QUE ESTE ARQUIVO EXISTE
    FluentSQL.QualifierMongoDB.pas tinha o corpo de SerializePagination comentado
    e tres variaveis declaradas e nunca usadas (H2164 em toda compilacao). A
    pergunta era: a paginacao do MongoDB esta sendo IGNORADA em silencio?

    NAO. Os casos abaixo mostram os documentos de comando que o FluentSQL emite
    de fato rodando: o "skip" e o "limit" estao la, emitidos por
    FluentSQL.SerializeMongoDB.pas. O qualificador estava morto, nao a feature.
    O corpo comentado foi removido e substituido por um comentario que explica
    por que ele e vazio DE PROPOSITO.
  ------------------------------------------------------------------------------
*/

db = db.getSiblingDB('t10');
db.T.drop();
let docs = [];
for (let i = 1; i <= 60; i++)
  docs.push({ID: i, NOME: 'N' + String(i).padStart(3, '0'), ATIVO: 1, IDADE: 20});
db.T.insertMany(docs);

function run(rotulo, cmd) {
  print('=== ' + rotulo);
  print('    ' + JSON.stringify(cmd));
  try {
    let r = db.runCommand(cmd);
    if (r.cursor)
      print('    -> ' + JSON.stringify(r.cursor.firstBatch.map(d => d.ID !== undefined ? d.ID : d.NOME)));
    else
      print('    -> ' + JSON.stringify(r));
  } catch (e) { print('    -> ERRO ' + e); }
}

/*
  ==============================================================================
  PARTE 1 - FORMA "find": os limites sao CAMPOS do documento de comando.
  Nao ha cauda textual para concatenar - dai SerializePagination devolver ''.
  ==============================================================================
*/

run('01 First(3)',          {find:'T', filter:{}, projection:{_id:0,ID:1}, limit:3});
// -> [1,2,3]

run('02 Skip(57)',          {find:'T', filter:{}, projection:{_id:0,ID:1}, skip:57});
// -> [58,59,60]   << o "skip" chega ao motor; nao ha paginacao ignorada

run('03 First(3)+Skip(20)', {find:'T', filter:{}, projection:{_id:0,ID:1}, limit:3, skip:20});
// -> [21,22,23]

run('04 Where+First+Skip',  {find:'T', filter:{ATIVO:1}, projection:{_id:0,ID:1}, limit:3, skip:20});
// -> [21,22,23]   << o predicado sobrevive (regra da T9)

run('05 Where+OrderBy+First+Skip',
    {find:'T', filter:{ATIVO:1}, projection:{_id:0,ID:1}, sort:{NOME:1}, limit:3, skip:20});
// -> [21,22,23]

run('06 Distinct+First+Skip',
    {find:'T', filter:{}, projection:{NOME:1,_id:0}, limit:3, skip:20});
// -> ["N021","N022","N023"]

/*
  ==============================================================================
  PARTE 2 - FORMA "aggregate": aqui a ORDEM DOS ESTAGIOS e semantica.
  O FluentSQL emite $skip ANTES de $limit. Os dois casos abaixo mostram que a
  ordem nao e cosmetica.
  ==============================================================================
*/

run('08 GroupBy+First+Skip - $skip ANTES de $limit (o que o FluentSQL emite)',
    {aggregate:'T',
     pipeline:[{$group:{_id:'$NOME'}},{$project:{NOME:'$_id',_id:0}},{$skip:20},{$limit:3}],
     cursor:{}});
// -> 3 documentos. QUAIS tres VARIA entre execucoes: duas rodadas seguidas
//    devolveram ["N045","N013","N029"] e depois ["N019","N022","N056"].
//    Isso nao e instabilidade do driver - e a mesma semantica do PostgreSQL sem
//    ORDER BY: paginar sem ordenar devolve subconjunto arbitrario. So a
//    CONTAGEM e afirmavel aqui; nao transcreva os valores como se fossem fixos.

run('08b a ordem TROCADA: $limit antes de $skip',
    {aggregate:'T',
     pipeline:[{$group:{_id:'$NOME'}},{$project:{NOME:'$_id',_id:0}},{$limit:3},{$skip:20}],
     cursor:{}});
// -> []   << ZERO documentos: pega 3 e depois pula 20 dos 3.

/*
  LEITURA DE 08 x 08b: com a ordem trocada a consulta devolve conjunto VAZIO, sem
  erro nenhum - o pior tipo de defeito. E tambem por isso que $skip vem antes:
  nessa ordem o otimizador consegue coalescer $sort/$skip/$limit num unico
  estagio. FluentSQL.SerializeMongoDB.pas emite nesta ordem.
*/

/*
  ==============================================================================
  PARTE Z - First(0): o defeito MAIS SILENCIOSO dos sete dialetos

  "limit" nao significa o que parece quando vale zero. Os casos Z1..Z3 sao o que
  o FluentSQL emitia ATE a T10 - e nao foi a T10 que introduziu isto: e defeito
  antigo, que so apareceu quando se foi medir First(0) nos sete dialetos.
  ==============================================================================
*/

run('Z1 First(0) na forma ANTIGA: "limit":0',
    {find:'T', filter:{}, projection:{_id:0,ID:1}, limit:0});
/*
  SAIDA: 60 documentos - a colecao INTEIRA.

  LEITURA: limit:0 quer dizer SEM LIMITE. O usuario pediu NADA e recebia TUDO,
  sem erro e sem aviso. Nos outros seis dialetos First(0) devolvia zero linhas -
  ou, no MSSQL, erro alto; so aqui devolvia dado errado calado.
*/

run('Z2 First(0)+Skip(20) na forma ANTIGA',
    {find:'T', filter:{}, projection:{_id:0,ID:1}, limit:0, skip:20});
/* SAIDA: 40 documentos. Mesmo defeito, agora com o salto aplicado. */

run('Z3 First(0) na forma ANTIGA, no pipeline: $limit 0',
    {aggregate:'T', pipeline:[{$group:{_id:'$NOME'}},{$limit:0}], cursor:{}});
/*
  SAIDA BRUTA:
    MongoServerError: the limit must be positive

  LEITURA: no pipeline o mesmo pedido falha ALTO. Os dois caminhos do mesmo
  driver discordavam entre si sobre o que First(0) significa.
*/

/*
  ------------------------------------------------------------------------------
  FORMA ESCOLHIDA: pular tudo, com 2^63-1.

  ATENCAO AO REPETIR: este numero NAO pode ser escrito como literal JavaScript.
  O mongosh o converte para double e o servidor recusa com "Cannot represent as
  a 64-bit integer: $skip: 9.223372036854776e+18". Isso e do CONSOLE, nao do
  servidor - com EJSON.parse do TEXTO, que e o que o FluentSQL produz e o que um
  driver real entrega, o servidor aceita. Z4..Z6 usam EJSON.parse por isso.
  ------------------------------------------------------------------------------
*/

function runTexto(r, txt) {
  print('=== ' + r);
  print('    ' + txt);
  try { let x = db.runCommand(EJSON.parse(txt, {relaxed:false}));
    print('    -> ' + (x.cursor ? x.cursor.firstBatch.length + ' documentos'
                                : JSON.stringify(x).substring(0,120))); }
  catch(e){ print('    -> ERRO ' + e); }
}

runTexto('Z4 First(0), forma NOVA (find)',
  '{"find":"T","filter":{},"projection":{},"skip":9223372036854775807}');
/* SAIDA: 0 documentos. */

runTexto('Z5 First(0), forma NOVA (pipeline)',
  '{"aggregate":"T","pipeline":[{"$group":{"_id":"$NOME"}},{"$skip":9223372036854775807}],"cursor":{}}');
/* SAIDA: 0 documentos. Os dois caminhos passam a concordar. */

runTexto('Z6 First(0) com filtro do usuario',
  '{"find":"T","filter":{"ATIVO":1},"projection":{},"skip":9223372036854775807}');
/* SAIDA: 0 documentos - e o filtro do usuario continua intacto. */

run('Z7 Skip(0) - inalterado e correto',
    {find:'T', filter:{}, projection:{_id:0,ID:1}, skip:0});
/* SAIDA: 60 documentos. Skip(0) e "nao pule nada", nao "sem Skip". */

run('Z8 First(10)+Skip(0) - inalterado e correto',
    {find:'T', filter:{}, projection:{_id:0,ID:1}, limit:10, skip:0});
/* SAIDA: 10 documentos. */
