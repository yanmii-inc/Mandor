# Security and Logging

- Never use `print()` or `debugPrint()`. Use `log()` from `dart:developer`.
- Never store sensitive data (tokens, credentials) in `SharedPreferences`. Use `flutter_secure_storage` or Hive.
- Every caught error must be at minimum logged with `log()`.
