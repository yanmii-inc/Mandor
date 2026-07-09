# Architecture

Four layers, each with a single responsibility:

1. **Presentation** — widgets, controllers, states. Lives under `pages/<feature>/presentation/`.
2. **Application** — optional services that bridge presentation ↔ domain. Lives under `pages/<feature>/application/`.
3. **Domain** — entities (plain Dart objects the UI consumes). Lives under `common/domain/`.
4. **Data** — repositories, DTOs (request/response models), mappers, data sources (remote/local). Lives under `common/data/`.

State management is **Riverpod** throughout. No BLoC, no GetX, no Provider.

## Project Structure

Combine Feature-First (presentation + application) with Layer-First (domain + data shared across features):

```
lib/
├── i18n/                        # Slang translation JSON files (per feature)
│   └── translations.g.dart      # Generated — never edit
└── src/
    ├── app/
    │   ├── config/flavors.dart  # F class — flavor access at runtime
    │   └── runner.dart
    ├── app.dart
    ├── common/
    │   ├── data/
    │   │   ├── sources/remote/config/  # DioClient, Result<T>, NetworkExceptions, Endpoint
    │   │   ├── models/                 # DTOs: requests/, responses/
    │   │   ├── mappers/
    │   │   └── repositories/
    │   └── domain/                     # Entities and abstract repository interfaces
    ├── pages/
    │   └── <feature>/
    │       ├── application/
    │       └── presentation/
    │           ├── <feature>_screen.dart
    │           ├── <feature>_controller.dart
    │           └── <feature>_state.dart
    ├── common_widgets/
    ├── constants/
    ├── routing/routes.dart
    └── utils/extensions/
```

Each layer has a barrel file (e.g. `repositories/repositories.dart`). Every new file must be exported from its layer's barrel.

## Repository Split

Abstract interfaces live in `common/domain/repositories/` — the domain layer owns the contract. Concrete implementations live in `common/data/repositories/` — the data layer owns the detail. Never put an implementation in `domain/` or an interface in `data/`.

## config.dart Barrel

`sources/remote/config/config.dart` re-exports `endpoint.dart`, `network_exceptions.dart`, `result.dart`, and `dio_client.dart`. Import `config.dart` as a single entry point for all of these — do not import each file individually unless you need only one.

## DTOs: json_serializable

Request/response models use `json_serializable` — never write `toJson`/`fromJson` manually. Annotate with `@JsonSerializable()` and add `part '<file>.g.dart'`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  const LoginResponse({required this.code, required this.message});
  final int code;
  final String message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
```

Use Freezed (not `json_serializable`) only when you need sealed unions, `copyWith`, or pattern matching — i.e. states, `Result<T>`, `NetworkExceptions`, and domain entities.

## New Remote API Class Pattern

Every API class exposes a `Provider` in the same file and receives `Dio` via `dioClientProvider`:

```dart
class ProductApi {
  ProductApi(this._dio);
  final Dio _dio;

  Future<ProductResponse> fetchProduct(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('${Endpoint.product}/$id');
    return ProductResponse.fromJson(response.data!);
  }
}

final productApiProvider = Provider<ProductApi>((ref) {
  return ProductApi(ref.watch(dioClientProvider).dio);
});
```
