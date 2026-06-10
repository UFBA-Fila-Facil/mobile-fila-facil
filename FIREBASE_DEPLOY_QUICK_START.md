# Guia Rápido: Deploy da Firebase Function

## 1. Preparação (Uma Única Vez)

```bash
# Instalar Firebase CLI (se não tiver)
npm install -g firebase-tools

# Navegar para pasta de functions
cd firebase/functions

# Instalar dependências
npm install

# Login no Firebase
firebase login

# Configurar projeto (substitua pelo seu)
firebase use --add
# Selecione: fila-facil-a7282
```

## 2. Build Local (Testar)

```bash
cd firebase/functions
npm run build
```

## 3. Deploy para Produção

```bash
cd firebase/functions
firebase deploy --only functions
```

## 4. Ver Logs em Tempo Real

```bash
firebase functions:log updateQueueUsers --follow
```

## 5. Testar Manualmente

### Via Google Cloud Console
1. Acesse: https://console.cloud.google.com/functions
2. Clique em `updateQueueUsers`
3. Aba **Teste**
4. Clique **Executar função**

### Via Firebase CLI
```bash
firebase functions:call updateQueueUsers --data ""
```

## 6. Configurar Scheduler

### Opção A: Via Google Cloud Console
```
https://console.cloud.google.com/cloudscheduler
```

1. **Criar Job**
2. Nome: `update-queue-users`
3. Frequência: `*/10 * * * *` (a cada 10 minutos)
4. Fuso horário: Seu fuso
5. Tipo: HTTP
6. URL: `https://us-central1-fila-facil-a7282.cloudfunctions.net/updateQueueUsers`
7. HTTP method: POST
8. Auth header: Adicionar OIDC → Conta do Firebase
9. **Criar**

### Opção B: Via gcloud CLI
```bash
gcloud scheduler jobs create pubsub update-queue-users \
  --schedule="*/10 * * * *" \
  --time-zone="America/Sao_Paulo" \
  --location=us-central1 \
  --message-body="{}" \
  --topic=firebase-functions
```

## 7. Monitorar

### Dashboard
https://console.cloud.google.com/functions/details/us-central1/updateQueueUsers/metrics

### Histórico de Execuções
```bash
firebase functions:log --limit=50
```

## Troubleshooting

### "Permission denied"
```bash
gcloud projects add-iam-policy-binding fila-facil-a7282 \
  --member=serviceAccount:firebase-adminsdk-HASH@fila-facil-a7282.iam.gserviceaccount.com \
  --role=roles/editor
```

### Verificar Status da Função
```bash
firebase functions:describe updateQueueUsers --region us-central1
```

### Forçar Execução do Scheduler
```bash
gcloud scheduler jobs run update-queue-users --location=us-central1
```
