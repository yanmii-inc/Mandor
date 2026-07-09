# Localization

Uses [slang](https://pub.dev/packages/slang). Translation files: `lib/i18n/<feature>/`.

- Base locale: **Indonesian** (`id`). Secondary: English (`en`).
- After editing any `.i18n.json`, run `dart run slang`.
- Mark strings not yet wired into slang:

```dart
'Thank you for registering'.hardcoded
```
