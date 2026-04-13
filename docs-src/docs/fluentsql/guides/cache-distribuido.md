---
sidebar_position: 14
---

# Cache Distribuído (Redis)

O FluentSQL oferece um mecanismo opcional de **caching** para as strings SQL geradas, permitindo otimizar a performance em cenários de alta volumetria onde a reconstrução da query a partir da AST (Árvore Sintática Abstrata) pode ser evitada.

## ESP-032: Suporte a Redis

A partir do **ESP-032**, é possível injetar um provedor de cache distribuído (Redis) no builder. Esta funcionalidade é **opt-in**, mantendo o núcleo do FluentSQL leve e sem dependências externas obrigatórias.

### Como usar

Para utilizar o cache, você deve fornecer uma implementação da interface `IFluentSQLCacheProvider`. O FluentSQL fornece um provedor padrão para Redis em `Source/Drivers/FluentSQL.Cache.Redis.pas`.

#### Implementação com TFluentSQLRedisCacheProvider

O provedor Redis utiliza o padrão *Command Executor* para se manter agnóstico em relação à biblioteca de cliente Redis que você utiliza (ex: *DelphiRedisClient*, *Redis4D*, etc.).

```delphi
uses
  FluentSQL,
  FluentSQL.Cache.Interfaces,
  FluentSQL.Cache.Redis;

var
  LProvider: IFluentSQLCacheProvider;
  SQL: string;
begin
  // 1. Inicialize o provedor Redis injetando o executor do seu cliente Redis preferido
  LProvider := TFluentSQLRedisCacheProvider.Create(
    function(const ACommand: string; const AArgs: TArray<string>): string
    begin
      // Exemplo hipotético de integração:
      // Result := MyRedisClient.ExecuteCommand(ACommand, AArgs);
    end
  );

  // 2. Utilize o cache no builder através dos métodos .WithCache e .WithTTL
  SQL := CreateFluentSQL(dbnFirebird)
    .WithCache(LProvider)
    .WithTTL(600) // TTL de 10 minutos (o padrão é 3600s / 1 hora)
    .Select.All
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
    
  // Na primeira execução, a query é serializada e armazenada no Redis.
  // Nas execuções subsequentes com o mesmo estado, a string é recuperada do cache.
end;
```

### Características Principais

*   **Hashing Determinístico**: A chave de cache é gerada a partir de um hash do estado structural da query e do identificador do dialeto.
*   **Fallback Silencioso**: Se o Redis estiver offline ou ocorrer um timeout, o FluentSQL captura a exceção internamente e gera o SQL normalmente através da serialização local. Sua aplicação continua funcionando sem interrupções.
*   **Independência de Cliente**: Graças ao uso de `reference to function`, você não fica preso a uma versão específica de driver Redis.

### Chaves de Cache

As chaves são geradas no Redis com o prefixo configurável (padrão: `fluentsql:cache:`). Exemplo de chave:
`fluentsql:cache:A7B2C9D1...`

### Quando usar?

O cache de strings SQL é recomendado para:
*   Ambientes distribuídos com múltiplas instâncias da aplicação.
*   Queries complexas com muitos Joins e cláusulas condicionais.
*   Aplicações que utilizam orquestradores de dados (como o DataEngine) onde a geração repetitiva de SQL pode ter um custo agregado relevante.
