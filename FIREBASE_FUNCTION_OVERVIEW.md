# Firebase Function para Filas Próximas - Resumo Executivo

## Visão Geral

Sistema automatizado que identifica usuários próximos (20m) a estabelecimentos cadastrados e atualiza filas em tempo real a cada 10 minutos.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Scheduler                           │
│                  (a cada 10 minutos)                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           Cloud Function: updateQueueUsers                  │
│                                                              │
│  1. Busca todos os estabelecimentos                         │
│  2. Para cada estabelecimento:                             │
│     - Busca todos os usuários                              │
│     - Calcula distância (Haversine)                        │
│     - Se distância ≤ 20m → Adiciona à fila                │
│  3. Atualiza Firestore com resultado                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
    ┌────────┐   ┌────────┐   ┌──────────────┐
    │ queues │   │usersIn │   │ Logs do      │
    │        │   │  Queue │   │ Firebase    │
    └────────┘   └────────┘   └──────────────┘
```

## Fluxo de Dados

### 1. Input: Dados do Firestore

**Estabelecimentos**
```
establishments/est123
├── name: "Mercado Fácil"
├── address: "Rua Central, 100"
├── location: GeoPoint(-23.5505, -46.6333)
├── capacity: 25
└── serviceType: "Caixas"
```

**Usuários**
```
users/user123
├── name: "João Silva"
├── email: "joao@exemplo.com"
├── location: GeoPoint(-23.5505, -46.6334)  ← 1 metro do estabelecimento
└── lastLocationUpdate: Timestamp
```

### 2. Processamento: Cálculo de Distância

```
Fórmula de Haversine:
- Latitude1: -23.5505
- Longitude1: -46.6333
- Latitude2: -23.5505
- Longitude2: -46.6334

Distância ≈ 1 metro ✓ (dentro do raio de 20m)
```

### 3. Output: Filas Atualizadas

**queues/est123**
```json
{
  "establishmentId": "est123",
  "establishmentName": "Mercado Fácil",
  "quantityPeople": 3,
  "averageWaitTime": 6,
  "serviceType": "Caixas",
  "updatedAt": "2026-06-09T10:00:00Z"
}
```

**usersInQueue/est123_user123**
```json
{
  "queueId": "est123",
  "userId": "user123",
  "distanceMeters": 1.0,
  "addedAt": "2026-06-09T10:00:00Z",
  "wasServed": false
}
```

## Sequência Temporal

```
10:00 - Cloud Scheduler dispara a função
10:00 - Function busca 5 estabelecimentos
10:00 - Function busca 50 usuários
10:00 - Function calcula 250 distâncias (5 × 50)
10:00 - Function atualiza 5 filas
10:01 - Função termina (duração típica: 30-60 segundos)

10:10 - Cloud Scheduler dispara novamente
...
```

## Configurações Recomendadas

| Parâmetro | Valor | Razão |
|-----------|-------|-------|
| Raio de Busca | 20 metros | Cobertura de ponto de entrada típico |
| Intervalo | 10 minutos | Balance entre dados atuais e custos |
| Retenção de Usuários | 30 minutos | Usuários que se afastaram são removidos |
| Zona Horária | America/Sao_Paulo | Evita execuções no horário noturno |
| Runtime | Node.js 18 | Suportado até 2030 |
| Memória | 256 MB | Adequado para processamento |
| Timeout | 120 segundos | 10 minutos excede típico |

## Custos Estimados (Google Cloud)

```
Execuções mensais: 144 (24h × 6/hora × 30 dias)

Cloud Functions:
- 144 invocações × $0.40/1M = $0.00005
- Tempo computação: 144 × 1 min × $0.0000167 = $0.0024

Firestore:
- Leituras: 144 × (5 est + 50 usu + 5 atualizações) = 80.000 leituras
- Escritas: 144 × (5 filas + 5×20 usuários) = 14.400 escritas
- Estimativa: $0,50-$1,00/mês com uso moderado

Cloud Scheduler:
- 144 jobs × $0.10 = $14,40/mês

TOTAL ESTIMADO: ~$15-16/mês
```

## Checklist de Implementação

- [ ] Criar Firebase Cloud Functions (Node.js 18)
- [ ] Instalar dependências: firebase-admin, firebase-functions
- [ ] Criar function `updateQueueUsers` com lógica de distância
- [ ] Criar índices Firestore compostos
- [ ] Configurar Google Cloud Scheduler
- [ ] Testar execução manual via Cloud Console
- [ ] Verificar logs em Firebase Console
- [ ] Implementar `LocationService` no app Flutter
- [ ] Adicionar permissões (Android e iOS)
- [ ] Testar geolocalização em device real
- [ ] Monitorar custos no Google Cloud Console
- [ ] Configurar alertas de erro em Cloud Monitoring

## Próximas Etapas

1. **Fila em Tempo Real** (RealTime)
   - Usar Firestore Stream para atualizar UI instantaneamente

2. **Notificações Push**
   - Avisar usuário quando entra em raio de fila

3. **Estimativa de Espera Refinada**
   - Usar histórico de tempo médio de atendimento
   - Considerar horário do dia

4. **Análise de Dados**
   - Dashboard com métricas de fluxo
   - Otimizar capacidade dos estabelecimentos

## Documentação de Referência

- Firebase Functions: https://firebase.google.com/docs/functions
- Cloud Scheduler: https://cloud.google.com/scheduler/docs
- Firestore GeoPoint: https://firebase.google.com/docs/firestore/data-model
- Haversine Formula: https://en.wikipedia.org/wiki/Haversine_formula

