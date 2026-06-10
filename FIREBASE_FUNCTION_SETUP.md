# Guia de Configuração: Firebase Function com Cloud Scheduler

## 1. Preparação do Projeto Firebase

### 1.1 Estrutura de Pastas
```
mobile-fila-facil/
├── firebase/
│   └── functions/
│       ├── src/
│       │   ├── index.ts
│       │   └── queue.ts
│       ├── .env
│       ├── package.json
│       ├── tsconfig.json
│       └── .firebaserc
```

### 1.2 Instalação de Dependências

```bash
cd firebase/functions
npm install firebase-functions firebase-admin geofire
npm install --save-dev @types/node typescript
```

## 2. Configuração de Autenticação Firestore

### 2.1 Regras de Segurança do Firestore
A função usa credenciais do serviço Firebase, não precisa de regras especiais.

### 2.2 Índices Firestore Necessários

Criar índice composto em **Firestore > Índices**:
- Collection: `users`
- Campos: `location` (Geo Point), `createdAt` (Ascending)
- Status: Ativo

Criar índice composto em **Firestore > Índices**:
- Collection: `establishments`
- Campos: `location` (Geo Point)
- Status: Ativo

## 3. Configuração do Cloud Scheduler

### 3.1 Criar Trigger Agendado

1. Acesse **Google Cloud Console > Cloud Scheduler**
2. Clique em **Criar Job**
3. Configure:
   - **Nome**: `update-queue-users`
   - **Frequência (cron)**: `*/10 * * * *` (a cada 10 minutos)
   - **Fuso horário**: Seu fuso horário
   - **Tipo de execução**: HTTP
   - **URL**: `https://REGION-PROJECT_ID.cloudfunctions.net/updateQueueUsers`
   - **HTTP method**: POST
   - **Autenticação**: Adicionar token OIDC da conta de serviço do Firebase
   - **Corpo**: (deixar em branco)

### 3.2 Regiões Disponíveis
- `us-central1`
- `europe-west1`
- `asia-northeast1`

## 4. Estrutura de Dados Esperada no Firestore

### 4.1 Collection: `users`
```json
{
  "_id": "user123",
  "name": "João Silva",
  "email": "joao@exemplo.com",
  "location": {
    "latitude": -23.5505,
    "longitude": -46.6333
  },
  "createdAt": "2026-06-09T10:00:00Z"
}
```

### 4.2 Collection: `establishments`
```json
{
  "_id": "est123",
  "name": "Mercado Fácil",
  "address": "Rua Central, 100",
  "location": {
    "latitude": -23.5505,
    "longitude": -46.6333
  },
  "capacity": 25,
  "serviceType": "Caixas"
}
```

### 4.3 Collection: `queues`
```json
{
  "_id": "queue123",
  "establishmentId": "est123",
  "quantityPeople": 8,
  "averageWaitTime": 15,
  "serviceType": "Caixas",
  "updatedAt": "2026-06-09T10:00:00Z"
}
```

### 4.4 Collection: `usersInQueue`
```json
{
  "_id": "queue123_user1",
  "queueId": "queue123",
  "userId": "user123",
  "distanceMeters": 18.5,
  "addedAt": "2026-06-09T10:00:00Z",
  "wasServed": false
}
```

## 5. Deploy da Function

### 5.1 Deploy via Firebase CLI

```bash
# Login se ainda não estiver autenticado
firebase login

# Deploy apenas da function
firebase deploy --only functions:updateQueueUsers

# Deploy com logs em tempo real
firebase deploy --only functions:updateQueueUsers && firebase functions:log --follow
```

### 5.2 Verificar Deploy

```bash
firebase functions:list
firebase functions:describe updateQueueUsers
```

### 5.3 Ver Logs

```bash
# Últimos logs
firebase functions:log updateQueueUsers --limit 50

# Logs em tempo real
firebase functions:log updateQueueUsers --follow
```

## 6. Monitoramento

### 6.1 Google Cloud Console

1. Acesse **Cloud Functions**
2. Clique em `updateQueueUsers`
3. Abas disponíveis:
   - **Métricas**: Visualizar invocações, latência, erros
   - **Logs**: Ver execução detalhada
   - **Triggers**: Ver histórico de triggers

### 6.2 Alertas Recomendados

Configure alertas no **Cloud Console > Alerting**:
- Função não foi executada há 30 minutos
- Taxa de erro > 5%
- Latência média > 30 segundos

## 7. Variáveis de Ambiente (.env)

```env
FIRESTORE_PROJECT_ID=seu-projeto
RADIUS_METERS=20
QUEUE_UPDATE_INTERVAL_MINUTES=10
```

## 8. Troubleshooting

### Erro: "Function not found"
- Verifique se o Firebase CLI está configurado: `firebase use --add`
- Confirme se a region está correta no `firebase.json`

### Erro: "Permission denied"
- Adicione permissões à conta de serviço em **IAM**:
  - Cloud Functions Service Agent
  - Editor (no mínimo Firestore Editor)

### Erro: "Geohash not working"
- Verifique se os documentos têm campos `location` do tipo GeoPoint
- Firestore requer GeoPoint, não simples objeto com latitude/longitude

### Função não dispara no horário
- Verifique fuso horário do Cloud Scheduler
- Confirme se Cloud Scheduler está ativo
- Aguarde 5 minutos da primeira criação do job

