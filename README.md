# FixGo

MVP de marketplace de servicios técnicos (plomería, electricidad, carpintería, etc.) conectando clientes con técnicos verificados.

## Arquitectura

Siguiendo **DDD-lite + MVVM + Riverpod** según [docs/domain_ddd_guidelines.md](docs/domain_ddd_guidelines.md) y [docs/mvvm_riverpod_pattern.md](docs/mvvm_riverpod_pattern.md):

```
lib/
├── domain/              # Capa de dominio (sin dependencias externas)
│   ├── core/            # Primitivas: Result<T>, ValueObject, Entity, Failures
│   ├── request/         # Bounded context: Solicitudes y Ofertas
│   ├── technician/      # Bounded context: Perfiles de técnico
│   ├── user/            # Bounded context: Usuarios
│   ├── category/        # Bounded context: Categorías de servicio
│   ├── rating/          # Bounded context: Calificaciones
│   └── services/        # Servicios de dominio puros
├── application/         # Casos de uso / ViewModels (Riverpod)
│   ├── service_request/
│   ├── technician/
│   ├── home/
│   ├── user/
│   └── providers/       # Providers de repositorios
├── infrastructure/      # Implementaciones externas
│   ├── repositories/    # Mock repos (reemplazar por Firebase)
│   ├── models/          # Mappers DTO ↔ Domain
│   └── services/        # Service locator (GetIt)
├── presentation/        # UI (Flutter widgets)
│   └── features/
└── app/                 # Configuración de la app
```

## Reglas clave

- **Dominio sin dependencias**: `lib/domain/` no importa Flutter, Firebase, Riverpod, ni IO
- **Value Objects solo con invariante**: `Price`, `Coordinates`, `Email`, etc.
- **Entidades por identidad**: `Entity<T>` compara por `id`
- **Result<T> sealed**: `Ok<T>` / `Err<Failure>` en lugar de `dartz`/excepciones
- **Domain services son funciones puras**: Sin `ref`, sin estado, sin IO
- **ViewModels**: `StateNotifier`/`Notifier` con `AsyncValue` para loading/error
- **Navegación en la View**: ViewModels retornan `sealed` results, la View navega

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` | Estado reactivo |
| `riverpod_annotation` + `riverpod_generator` | Providers type-safe |
| `freezed` + `freezed_annotation` | Estados inmutables, sealed classes |
| `json_annotation` + `json_serializable` | Serialización DTOs |
| `get_it` | Service locator para DI |
| `intl` | i18n |

## Instalación

```bash
# 1. Clonar
git clone https://github.com/kaylo0ng/fixgo-app.git
cd fixgo-app

# 2. Dependencias
flutter pub get

# 3. Generar código (Riverpod, Freezed, JSON)
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecutar
flutter run
```

## Flujo principal (MVP)

1. **Cliente** publica solicitud → `ServiceRequestViewModel.createRequest()`
2. **Técnicos cercanos** reciben notificación → `OfferMatchingService.findBestOffers()`
3. **Técnico** envía oferta → `ServiceRequestViewModel.submitOffer()`
4. **Cliente** acepta oferta → `ServiceRequestViewModel.acceptOffer()`
5. **Técnico** ejecuta servicio → Estados: `assigned → inProgress → completed`
6. **Cliente** califica → `Rating` + `RatingCalculator`

## Bounded Contexts

| Contexto | Entidades | Invariantes clave |
|----------|-----------|-------------------|
| `request` | `ServiceRequest`, `Offer` | State machine (draft→published→assigned→inProgress→completed→rated) |
| `technician` | `TechnicianProfile` | Verificación, categorías, radio de disponibilidad |
| `user` | `AppUser` | Roles (client/technician), email único |
| `category` | `ServiceCategory` | 10 categorías predefinidas |
| `rating` | `Rating` | Score 1-5, promedio ponderado |

## Repositorios (Puerto/Adaptador)

Interfaces en `domain/*/repositories.dart` → Implementaciones en `infrastructure/repositories/`:

- `IServiceRequestRepository` → `MockServiceRequestRepository`
- `IOfferRepository` → `MockOfferRepository`
- `ITechnicianProfileRepository` → `MockTechnicianProfileRepository`
- `IRatingRepository` → `MockRatingRepository`
- `IUserRepository` → `MockUserRepository`
- `ICategoryRepository` → `MockCategoryRepository`

> **Próximo paso**: Reemplazar mocks por implementaciones Firebase/Firestore en `infrastructure/repositories/`.

## Comandos útiles

```bash
# Generar código
dart run build_runner build --delete-conflicting-outputs

# Watch mode (desarrollo)
dart run build_runner watch --delete-conflicting-outputs

# Analizar
dart analyze

# Tests
flutter test

# Formatear
dart format .
```

## Estructura de providers (Riverpod)

```dart
// Repositories (Application layer)
final serviceRequestRepositoryProvider = Provider<IServiceRequestRepository>(...);
final offerRepositoryProvider = Provider<IOfferRepository>(...);
final technicianProfileRepositoryProvider = Provider<ITechnicianProfileRepository>(...);

// ViewModels (Application layer)
final serviceRequestViewModelProvider = StateNotifierProvider<ServiceRequestViewModel, ServiceRequestState>(...);
final technicianViewModelProvider = StateNotifierProvider<TechnicianViewModel, TechnicianState>(...);
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(...);
final appUserViewModelProvider = StateNotifierProvider<AppUserViewModel, AppUserState>(...);
```

## Migración a Firebase (TODO)

1. Crear `FirebaseServiceRequestRepository` implementando `IServiceRequestRepository`
2. Usar `DTOMapper` para convertir Domain ↔ Firestore documents
3. Registrar en `service_locator.dart` o providers
4. Configurar reglas de seguridad Firestore
5. Agregar `cloud_firestore` a dependencias

## Licencia

MIT