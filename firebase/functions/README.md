# Firebase Cloud Functions - FilaFácil

## Sobre

Conjunto de Cloud Functions que processam geolocalização de usuários e atualizam filas de espera em tempo real.

## Funções Disponíveis

### `updateQueueUsers`
- **Trigger**: Cloud Scheduler (a cada 10 minutos)
- **Entrada**: HTTP POST
- **Saída**: JSON com resumo de processamento
- **Lógica**:
  1. Busca todos os estabelecimentos
  2. Para cada um, identifica usuários num raio de 20m
  3. Atualiza `queues` com quantidade de pessoas
  4. Cria referências em `usersInQueue`

### `cleanupStaleQueueUsers`
- **Trigger**: Manual ou scheduler adicional
- **Função**: Remove usuários que estão na fila há mais de 30 minutos
- **Objetivo**: Manter dados limpos e consistentes

## Estrutura do Projeto

```
firebase/functions/
├── src/
│   ├── index.ts          # Exports das functions
│   └── queue.ts          # Lógica de geolocalização
├── lib/                  # Compilado (gerado)
├── package.json          # Dependências
├── tsconfig.json         # Configuração TypeScript
├── .firebaserc            # Configuração Firebase
└── .gitignore            # Ignorar node_modules
```

## Instalação

```bash
cd firebase/functions
npm install
```

## Build

```bash
npm run build
```

## Deploy

```bash
npm run deploy
```

## Logs

```bash
npm run logs
```

## Desenvolvimento Local

```bash
npm run serve
```

Acesse `http://localhost:5001/` para testar.

## Variáveis de Configuração

| Variável | Valor | Descrição |
|----------|-------|-----------|
| RADIUS_METERS | 20 | Distância máxima em metros |
| EARTH_RADIUS_METERS | 6371000 | Raio da Terra em metros (Haversine) |

## Estrutura de Dados

### Entrada: Estabelecimentos
```typescript
{
  id: string;
  name: string;
  address: string;
  location: GeoPoint;
  capacity: number;
  serviceType: string;
}
```

### Entrada: Usuários
```typescript
{
  id: string;
  name: string;
  email: string;
  location: GeoPoint;
}
```

### Saída: Filas
```typescript
{
  establishmentId: string;
  quantityPeople: number;
  averageWaitTime: number;
  serviceType: string;
  updatedAt: Timestamp;
}
```

### Saída: Usuários na Fila
```typescript
{
  queueId: string;
  userId: string;
  distanceMeters: number;
  addedAt: Timestamp;
  wasServed: boolean;
}
```

## Monitoramento

### Cloud Console
https://console.cloud.google.com/functions

### Métricas
- Invocações
- Latência
- Taxa de erro
- Memória utilizada

### Alertas
Configure em **Cloud Monitoring > Alerting**

## Performance

- Tempo médio: 30-60 segundos
- Memória: ~200 MB
- Custo: ~$15-20/mês

## Troubleshooting

### Função não aparece no deploy
```bash
firebase functions:list
```

### Erro de compilação TypeScript
```bash
npm run build
# Verifique tsconfig.json
```

### Permissão negada
```bash
gcloud auth login
firebase login
```

### Función timeout (>120 segundos)
- Reduzir número de estabelecimentos
- Usar batch operations
- Incrementar memória alocada

## Referências

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Cloud Scheduler](https://cloud.google.com/scheduler/docs)
- [Firestore GeoPoint](https://firebase.google.com/docs/firestore/manage-data/add-data)
- [TypeScript Support](https://firebase.google.com/docs/functions/typescript)

