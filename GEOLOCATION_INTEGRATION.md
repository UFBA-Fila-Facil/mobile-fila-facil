# Integração de Geolocalização no App Flutter

## 1. Adicionar Dependência

```bash
flutter pub add geolocator
```

### Atualizar pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  geolocator: ^10.1.0
  cloud_firestore: ^4.17.5
```

## 2. Configurar Permissões

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<application>
  <!-- ... resto da configuração ... -->
</application>
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos de sua localização para encontrar filas próximas</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Precisamos de sua localização para encontrar filas próximas</string>
```

## 3. Criar Serviço de Geolocalização

### lib/services/location_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore;
  
  LocationService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Solicita permissão e retorna a localização do usuário
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return null;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  /// Atualiza a localização do usuário no Firestore
  Future<void> updateUserLocation(String userId) async {
    try {
      final position = await getCurrentLocation();
      
      if (position == null) {
        print('Não foi possível obter a localização');
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      
      print('Localização atualizada: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Erro ao atualizar localização: $e');
    }
  }

  /// Stream para atualizar localização continuamente
  Stream<Position> getLocationStream({
    int distanceFilter = 10, // Atualiza a cada 10 metros
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
```

## 4. Integrar no App

### Exemplo: Atualizar localização ao abrir HomeScreen

```dart
import 'package:mobile_fila_facil/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;
  final LocationService? locationService;

  const HomeScreen({
    super.key,
    required this.authService,
    EstablishmentService? establishmentService,
    LocationService? locationService,
  }) : 
    establishmentService = establishmentService ?? EstablishmentService(),
    locationService = locationService ?? LocationService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _updateUserLocation();
    
    // Atualizar localização a cada 30 segundos
    Future.delayed(Duration.zero, () {
      _startLocationUpdates();
    });
  }

  void _updateUserLocation() {
    final user = widget.authService.currentUser;
    if (user != null) {
      widget.locationService?.updateUserLocation(user.uid);
    }
  }

  void _startLocationUpdates() {
    final user = widget.authService.currentUser;
    if (user == null) return;

    widget.locationService?.getLocationStream(distanceFilter: 20).listen((position) {
      _updateUserLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... resto da tela ...
  }
}
```

## 5. Estrutura de Dados Esperada no Firestore

### Collection: `users`

```json
{
  "_id": "user123",
  "name": "João Silva",
  "email": "joao@exemplo.com",
  "location": {
    "_latitude": -23.5505,
    "_longitude": -46.6333
  },
  "lastLocationUpdate": "2026-06-09T10:00:00Z",
  "createdAt": "2026-06-01T08:00:00Z"
}
```

### Collection: `establishments`

```json
{
  "_id": "est123",
  "name": "Mercado Fácil",
  "address": "Rua Central, 100",
  "location": {
    "_latitude": -23.5505,
    "_longitude": -46.6333
  },
  "capacity": 25,
  "serviceType": "Caixas",
  "adminId": "admin1"
}
```

## 6. Testar Localmente

### Android Emulator

```bash
# Abrir Android Studio > Extended Controls
# Localização > Testes de localização
# Digitar: -23.5505, -46.6333
```

### iOS Simulator

```bash
# Abrir Features > Location > Custom Location
# Digitar: -23.5505, -46.6333
```

## 7. Troubleshooting

### Erro: "Serviços de localização desabilitados"
- Verifique se GPS está ativo no dispositivo
- Verifique permissões em Configurações

### Localização retorna null
- Confirme que a permissão foi concedida
- Teste em dispositivo real (emulador pode ter limitações)
- Aumente o timeout da requisição

### App se torna lento
- Reduza a frequência de atualizações
- Use `distanceFilter` para atualizar apenas em movimentos significativos

## 8. Fluxo Completo

1. **Usuário faz login** → `LocationService` solicita permissão
2. **HomeScreen abre** → Localização inicial é enviada
3. **Usuário se move** → Localização é atualizada a cada 20 metros
4. **Cloud Scheduler (a cada 10 min)** → `updateQueueUsers()` roda:
   - Calcula distância de cada usuário a cada estabelecimento
   - Atualiza `quantityPeople` em `queues`
   - Cria referências em `usersInQueue`
5. **App monitora Stream de filas** → Mostra usuários próximos e informações de espera

