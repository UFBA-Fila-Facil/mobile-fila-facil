# 📱 Fila Fácil - Mobile

App mobile de monitoramento colaborativo de filas em tempo real. Usa geolocalização (raio de 50m) e feedback dos usuários para estimar tamanho da fila e tempo de espera, com base também em confirmações de atendimento. MVP para validar previsões com dados colaborativos.

---

## 🏗️ Arquitetura

A aplicação segue uma abordagem baseada em **Clean Architecture**, combinada com **MVVM na camada de apresentação** e organização **modular por funcionalidades**.

### Camadas:

- **Presentation**
  - View (UI)
  - ViewModel (estado)

- **Domain**
  - Entities
  - UseCases
  - Interfaces de Repositórios

- **Data**
  - Models (DTOs)
  - Repositories (implementações)
  - DataSources (Firebase, APIs)

Essa abordagem garante:
- Baixo acoplamento  
- Alta testabilidade  
- Independência de frameworks  

📎 **Detalhamento completo da arquitetura:**  
👉 https://docs.google.com/document/d/1XpCFVeNQ8_a6tkknk9eWPZg38RT8X9b8EBf7Fyp4utQ/edit?usp=sharing

---

## 📂 Estrutura de Módulos

O projeto utiliza uma estrutura híbrida baseada em:

- Clean Architecture (camadas)
- Feature-first (por funcionalidade)
- Modularização

## 🔌 Injeção de Dependência

O projeto utiliza o pacote get_it como service locator.

**Instância global:**

```dart
final getIt = GetIt.instance;
// ou
final getIt = GetIt.I;
Formas de registro:
```

**1. Singleton**

Instância única durante toda a aplicação:

```dart
getIt.registerSingleton<Service>(ServiceImpl());
```

**2. Lazy Singleton**

Instância criada sob demanda:

```dart
getIt.registerLazySingleton<Service>(() => ServiceImpl());

```

**3. Factory**

Nova instância a cada solicitação:

```dart
getIt.registerFactory<Service>(() => ServiceImpl());

```

**Organização**

As dependências são registradas no diretório:

```bash
lib/app/di/
```

Responsável por:

- Configuração centralizada
- Gerenciamento de dependências
- Inversão de controle

### 🎯 Benefícios da Abordagem
- Separação clara de responsabilidades
- Escalabilidade por módulos
- Facilidade de testes
- Manutenção simplificada

### 🚀 Tecnologias
- Flutter
- Dart
- Firebase
- GetIt (Dependency Injection)

### Estrutura principal:

```bash
lib/
├── app/            # Configuração global (rotas, DI)
│   ├── routes/
│   ├── di/
│   └── app.dart
│
├── modules/
│   ├── core/       # Recursos globais
│   │   ├── authorization/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── errors/
│   │   └── data/
│   │       └── datasources/firebase/
│   │
│   ├── shared/     # Componentes reutilizáveis
│   │   ├── widgets/
│   │   ├── constants/
│   │   └── extensions/
│   │
│   ├── features/   # Funcionalidades da aplicação
│       ├── authentication/
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       │       ├── view/
│       │       └── viewmodel/
│       │
│       ├── paginaA/
│           ├── domain/
│           ├── data/
│           └── presentation/
│               ├── view/
│               └── viewmodel/
│
└── main.dart
```

### Cada feature segue o padrão:

```bash
feature/
├── domain/
├── data/
└── presentation/
```
📎 **Detalhamento completo da estrutura:**  
👉 https://medium.com/popcodemobile/inje%C3%A7%C3%A3o-de-depend%C3%AAncias-no-flutter-152704d4064d

## 🎙️ Integração com Bixby (Samsung)

O aplicativo é acessível via assistente de voz **Bixby** através da capsule `mobile_fila_facil.interacao_fila`, desenvolvida no Bixby Studio. A integração utiliza **deeplinks** com o scheme `filafacil://` para acionar telas específicas do app a partir de comandos de voz.

---

### Configuração do AndroidManifest.xml

Para que os deeplinks do Bixby funcionem, o app precisa registrar o scheme `filafacil` como intent-filter:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="filafacil" />
</intent-filter>
```

---

### Comandos disponíveis

#### 1. Fui atendido

Informa que o próprio usuário foi atendido na fila.

| | |
|---|---|
| **Comando de voz** | "Com o Fila Fácil, informe que fui atendido" |
| **Deeplink acionado** | `filafacil://served` |
| **Parâmetros** | Nenhum |
| **Action Bixby** | `ServedAction` |

Variações reconhecidas:
- "Fui atendido"
- "Já fui atendido"
- "Fui atendida"
- "Confirmar atendimento"

---

#### 2. Chegou um cliente

Registra a chegada de um cliente em um estabelecimento específico.

| | |
|---|---|
| **Comando de voz** | "Com o Fila Fácil, informe que chegou um cliente em Alpha Club" |
| **Deeplink acionado** | `filafacil://customer-arrived?establishmentName=Alpha%20Club` |
| **Parâmetros** | `establishmentName` — nome do estabelecimento (obrigatório) |
| **Action Bixby** | `CustomerArrivedAction` |

Variações reconhecidas:
- "Chegou um cliente em {estabelecimento}"
- "Cliente chegou em {estabelecimento}"
- "Novo cliente em {estabelecimento}"
- "Informe chegada de cliente em {estabelecimento}"

---

#### 3. Cliente atendido

Registra que um cliente foi atendido em um estabelecimento específico.

| | |
|---|---|
| **Comando de voz** | "Com o Fila Fácil, informe que foi atendido um cliente em Alpha Club" |
| **Deeplink acionado** | `filafacil://serve-customer?establishmentName=Alpha%20Club` |
| **Parâmetros** | `establishmentName` — nome do estabelecimento (obrigatório) |
| **Action Bixby** | `CustomerServedAction` |

Variações reconhecidas:
- "Cliente atendido em {estabelecimento}"
- "Atendeu um cliente em {estabelecimento}"
- "Confirmar atendimento de cliente em {estabelecimento}"
- "Cliente foi atendido em {estabelecimento}"

---

### Estrutura da Capsule Bixby

```
mobile_fila_facil.interacao_fila/
├── capsule.bxb                          # Configuração geral (targets, versão, seção)
├── code/
│   ├── ServedAction.js                  # Retorna deeplink filafacil://served
│   ├── CustomerArrivedAction.js         # Retorna deeplink com establishmentName
│   └── CustomerServedAction.js          # Retorna deeplink com establishmentName
├── models/
│   ├── actions/
│   │   ├── ServedAction.model.bxb
│   │   ├── CustomerArrivedAction.model.bxb
│   │   └── CustomerServedAction.model.bxb
│   └── concepts/
│       ├── DeepLinkResult.model.bxb     # Tipo text que transporta a URI
│       ├── EstablishmentName.model.bxb  # Parâmetro de nome do estabelecimento
│       └── ServedResult.model.bxb
└── resources/
    ├── base/
    │   ├── endpoints.bxb                # Mapeamento actions → arquivos JS
    │   └── views/
    │       └── DeepLink.view.bxb        # View com app-launch para abrir deeplink
    ├── pt-BR/
    │   ├── capsule-info.bxb
    │   ├── hints.bxb                    # Sugestões exibidas ao usuário
    │   ├── dialogs/
    │   └── training/                    # Frases de treino do NL por action
    └── en-US/
        ├── capsule-info.bxb
        └── hints.bxb
```

---

### Como o deeplink é aberto

O Bixby não permite abrir deeplinks diretamente via JavaScript por restrições de segurança da plataforma. O fluxo utilizado é:

```
Comando de voz
      ↓
Action JS executa → retorna URI como DeepLinkResult (text)
      ↓
DeepLink.view.bxb renderiza com app-launch { payload-uri }
      ↓
Bixby aciona o deeplink no Android → app abre na tela correta
```

A view `DeepLink.view.bxb` é compartilhada entre todas as actions, pois todas retornam o mesmo tipo `DeepLinkResult`.

---

### Conceitos Bixby reutilizados

| Conceito | Tipo | Uso |
|---|---|---|
| `DeepLinkResult` | `text` | URI de destino retornada por todas as actions |
| `EstablishmentName` | `text` | Nome do estabelecimento capturado da fala do usuário |

---

## 📍 Estabelecimentos Próximos

A tela inicial exibe automaticamente os estabelecimentos mais próximos do usuário, com base em sua localização atual.

### Regra de negócio

| Critério | Valor |
|---|---|
| Raio máximo | 1 km |
| Máximo de resultados | 5 |
| Ordenação | Distância crescente |
| Pré-requisito | Estabelecimento precisa ter `location` (GeoPoint) cadastrado |

### Fluxo

```
Abertura da HomeScreen
      ↓
Solicita permissão de localização (se ainda não concedida)
      ↓
Obtém posição atual via GPS (precisão média)
      ↓
Busca todos os estabelecimentos no Firestore
      ↓
Filtra os que possuem GeoPoint e estão a ≤ 1 km (fórmula de Haversine)
      ↓
Ordena por distância crescente → retorna os 5 mais próximos
      ↓
Exibe na seção "Estabelecimentos próximos" da HomeScreen
```

### Cálculo de distância

Utiliza a **fórmula de Haversine** para calcular a distância geodésica (em km) entre as coordenadas do usuário e as de cada estabelecimento:

```dart
// lib/services/nearby_establishments_service.dart
double _haversineDistance(double lat1, double lon1, double lat2, double lon2)
```

A distância é exibida ao usuário formatada:
- Abaixo de 100 m → `"350 m"`
- Acima de 100 m → `"0.8 km"`

### Permissões Android

Declaradas em `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

A solicitação em runtime é gerenciada pelo pacote `geolocator`. Se o usuário negar a permissão ou o GPS estiver desligado, a seção exibe *"Não foi possível obter a localização."*

### Arquivos envolvidos

| Arquivo | Responsabilidade |
|---|---|
| `lib/services/nearby_establishments_service.dart` | Obtém localização, busca Firestore, filtra por distância |
| `lib/screens/home_screen.dart` | Exibe a seção e o card de cada estabelecimento próximo |

| Classe | Papel |
|---|---|
| `NearbyEstablishmentsService` | Orquestra permissão, posição GPS e filtragem por raio |
| `NearbyEstablishment` | DTO — agrega `Establishment` e a `distanceKm` calculada |

---

## 🔔 Notificações Push

O app envia notificações ao usuário em dois momentos:

| Evento | Mensagem |
|---|---|
| Usuário atinge posição 1 na fila | *"Atenção, você é o próximo a ser atendido."* |
| Posição do usuário == capacidade do estabelecimento | *"Atenção, você pode ser atendido a qualquer momento."* |

### Arquitetura de notificações

```
App aberto (foreground)
  → QueueNotificationMonitor (stream Firestore em tempo real)
      → flutter_local_notifications

App em segundo plano — Android
  → Android Foreground Service (flutter_foreground_task)
      mantém o processo vivo → QueueNotificationMonitor continua ativo

App em segundo plano — iOS / App encerrado
  → Cloudflare Worker (cron) ou Firebase Cloud Function
      → FCM HTTP v1 API → sistema operacional exibe a notificação
```

### Cloudflare Worker

Um **Cloudflare Worker** (`cloudflare/worker.js`) executa a cada 1 minuto via Cron Trigger e monitora as entradas ativas na coleção `user_queues` do Firestore. Quando detecta uma mudança de posição relevante, envia uma notificação push via **Firebase Cloud Messaging (FCM HTTP v1 API)**.

*
---
---

## 📌 Observações

Este projeto foi estruturado com foco em boas práticas modernas de arquitetura mobile, sendo facilmente escalável e adaptável a novas funcionalidades.