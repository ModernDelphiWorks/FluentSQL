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
  estagio. FluentSQL.SerializeMongoDB.pas:811-814 emite nesta ordem.
*/
