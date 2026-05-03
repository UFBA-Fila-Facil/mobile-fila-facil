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

## 📌 Observações

Este projeto foi estruturado com foco em boas práticas modernas de arquitetura mobile, sendo facilmente escalável e adaptável a novas funcionalidades.