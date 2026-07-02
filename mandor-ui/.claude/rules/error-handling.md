# Result\<T\> and Error Handling

All repository methods return `Result<T>` — never throw raw exceptions to the UI.

```dart
// In repository implementation:
try {
  final response = await _api.login(request);
  return Result.success(response.message);
} catch (e, st) {
  return Result.failure(NetworkExceptions.getException(e, st), st);
}
```

`Result<T>` is a Freezed sealed union with two variants: `Success<T>(data)` and `Failure<T>(error, stackTrace)`.

## Critical — Freezed 3.x Extension Method Scoping

`when`, `maybeWhen`, `map`, `maybeMap`, etc. are defined as extension methods on `Result<T>`, not as class methods. Extension methods are NOT brought into scope via transitive imports in Dart — the file defining them must be **directly imported**.

Always import `config.dart` directly in any file that calls `.when()` or `.maybeWhen()` on a `Result`:

```dart
import 'package:mobile/src/common/data/sources/remote/config/config.dart';
```

## NetworkExceptions Variants

Available cases for `maybeMap` / `maybeWhen`:
`requestCancelled`, `unauthorizedRequest`, `badRequest`, `notFound`, `methodNotAllowed`,
`notAcceptable`, `requestTimeout`, `badCertificate`, `sendTimeout`, `conflict`,
`internalServerError`, `notImplemented`, `serviceUnavailable`, `noInternetConnection`,
`formatException`, `unableToProcess`, `defaultError`, `unexpectedError`, `unProcessableEntity`

**Bad — silent:**
```dart
try {
  await repository.fetchData();
} catch (e) {
  // do nothing
}
```

**Good — specific cases first, generic fallback:**
```dart
result.when(
  success: (data) => state = MyState.success(data),
  failure: (error, st) {
    log('Failed: $error', stackTrace: st);
    state = MyState.error(error.maybeMap(
      unauthorizedRequest: (_) => 'Session expired.',
      noInternetConnection: (_) => 'No internet connection.',
      orElse: () => 'Something went wrong. Please try again.',
    ));
  },
);
```
