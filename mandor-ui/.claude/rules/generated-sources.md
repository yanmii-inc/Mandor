# Generated Sources

`*.freezed.dart`, `*.g.dart`, and `translations.g.dart` are generated — never edit manually. Commit them to the repo.

```bash
dart run build_runner build --delete-conflicting-outputs  # Freezed classes
dart run slang                                            # i18n JSON files
```
